import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/supabase/trip_request.dart';
import '../models/trip_request_data.dart';
import '../models/supabase/driver.dart';
import '../services/trip_service.dart';
import '../services/driver_service.dart';
import '../services/notification_service.dart';
import '../services/transaction_service.dart';
import '../exceptions/app_exceptions.dart';
import '../config/feature_flags.dart';

class TripRequestManager {
  TripRequestManager(this._supabase) :
    _tripService = TripService(_supabase),
    _driverService = DriverService(_supabase),
    _notificationService = NotificationService(_supabase);

  final SupabaseClient _supabase;
  final TripService _tripService;
  final DriverService _driverService;
  final NotificationService _notificationService;
  
  final Map<String, Timer> _activeTimers = {};
  final Map<String, StreamSubscription> _activeSubscriptions = {};

  /// Cria uma solicitação direcionada para um motorista específico
  /// com sistema de fallback automático e transação atômica
  Future<String> createDirectedTripRequest({
    required String passengerId,
    required List<Driver> prioritizedDrivers,
    required TripRequestData tripData,
  }) async {
    try {
      final targetDriver = prioritizedDrivers.first;
      final fallbackDriverIds = prioritizedDrivers
          .skip(1)
          .take(FeatureFlags().maxFallbackAttempts)
          .map((d) => d.id)
          .toList();
      
      // Log do início do processo
      _logMatching('Iniciando solicitação direcionada para driver ${targetDriver.id}');
      
      // Executar seleção com transação atômica para evitar conflitos
      final requestId = await TransactionService.executeWithPessimisticLock(
        'driver_selection_${targetDriver.id}',
        () async {
          // Verificar disponibilidade em tempo real do motorista
          final isAvailable = await _verifyDriverAvailability(targetDriver.id);
          if (!isAvailable) {
            throw const ConcurrencyException(
              'Motorista não está mais disponível. Selecionando próximo motorista...',
            );
          }
          
          // Criar trip_request direcionado usando TripRequestData
          final requestData = tripData.toDatabase(
            passengerId: passengerId,
            targetDriverId: targetDriver.id,
            fallbackDrivers: fallbackDriverIds,
          );
          
          final request = await _supabase
              .from('trip_requests')
              .insert(requestData)
              .select()
              .single();
          
          return request['id'] as String;
        },
        lockTimeout: const Duration(seconds: 5),
      );
      
      // Enviar notificação push se habilitado
      if (FeatureFlags().enablePushNotifications) {
        await _sendDriverNotification(targetDriver.id, requestId);
      }
      
      // Iniciar timer de timeout se sistema de fallback habilitado
      if (FeatureFlags().enableFallbackSystem) {
        _startTimeoutTimer(requestId, targetDriver.id);
      }
      
      _logMatching('Solicitação $requestId criada com sucesso');
      return requestId;
      
    } on ConcurrencyException catch (e) {
      _logMatching('Conflito de concorrência: ${e.message}');
      
      // Tentar com próximo motorista da lista
      if (prioritizedDrivers.length > 1) {
        final remainingDrivers = prioritizedDrivers.skip(1).toList();
        return createDirectedTripRequest(
          passengerId: passengerId,
          prioritizedDrivers: remainingDrivers,
          tripData: tripData,
        );
      }
      
      throw const DatabaseException('Nenhum motorista disponível no momento');
    } catch (e) {
      _logMatching('Erro ao criar solicitação direcionada: $e');
      throw DatabaseException('Erro ao criar solicitação de viagem: $e');
    }
  }

  /// Processa resposta do motorista (aceitar/recusar)
  Future<void> handleDriverResponse({
    required String requestId,
    required String driverId,
    required bool accepted,
  }) async {
    try {
      _logMatching('Driver $driverId respondeu: ${accepted ? 'ACEITO' : 'RECUSADO'}');
      
      // Cancelar timer se existir
      _activeTimers[requestId]?.cancel();
      _activeTimers.remove(requestId);
      
      if (accepted) {
        await _acceptRequest(requestId, driverId);
      } else {
        await _processRejectionOrTimeout(requestId, isTimeout: false);
      }
    } catch (e) {
      _logMatching('Erro ao processar resposta do driver: $e');
      throw DatabaseException('Erro ao processar resposta do motorista: $e');
    }
  }
  
  /// Inicia timer de timeout para solicitação
  void _startTimeoutTimer(String requestId, String driverId) {
    final timeoutDuration = Duration(seconds: FeatureFlags().timeoutSeconds);
    
    _activeTimers[requestId] = Timer(
      timeoutDuration,
      () => _handleTimeout(requestId, driverId),
    );
    
    _logMatching('Timer de ${timeoutDuration.inSeconds}s iniciado para request $requestId');
  }
  
  /// Lida com timeout de solicitação
  Future<void> _handleTimeout(String requestId, String driverId) async {
    _logMatching('Timeout atingido para request $requestId, driver $driverId');
    await _processRejectionOrTimeout(requestId, isTimeout: true);
  }
  
  /// Processa rejeição ou timeout com fallback automático
  Future<void> _processRejectionOrTimeout(String requestId, {required bool isTimeout}) async {
    try {
      // Buscar request atual
      final currentRequest = await _supabase
          .from('trip_requests')
          .select()
          .eq('id', requestId)
          .single();
      
      final fallbackDrivers = List<String>.from(currentRequest['fallback_drivers'] ?? []);
      final currentIndex = currentRequest['current_fallback_index'] ?? 0;
      final timeoutCount = currentRequest['timeout_count'] ?? 0;
      
      // Verificar se ainda há motoristas de fallback
      if (currentIndex < fallbackDrivers.length) {
        final nextDriverId = fallbackDrivers[currentIndex];
        
        _logMatching('Redirecionando para driver fallback $nextDriverId (índice $currentIndex)');
        
        // Atualizar request para próximo motorista
        await _supabase.from('trip_requests').update({
          'target_driver_id': nextDriverId,
          'current_fallback_index': currentIndex + 1,
          'timeout_count': isTimeout ? timeoutCount + 1 : timeoutCount,
          'expires_at': DateTime.now().add(
            Duration(seconds: FeatureFlags().timeoutSeconds)
          ).toIso8601String(),
        }).eq('id', requestId);
        
        // Enviar notificação para próximo motorista
        if (FeatureFlags().enablePushNotifications) {
          await _sendDriverNotification(nextDriverId, requestId);
        }
        
        // Iniciar novo timer
        if (FeatureFlags().enableFallbackSystem) {
          _startTimeoutTimer(requestId, nextDriverId);
        }
        
      } else {
        // Sem mais fallbacks - marcar como expired
        _logMatching('Nenhum motorista de fallback disponível. Request $requestId expirado.');
        
        await _supabase.from('trip_requests').update({
          'status': 'expired',
          'target_driver_id': null,
        }).eq('id', requestId);
        
        // Notificar passageiro que não encontrou motorista
        await _notifyPassengerNoDriverFound(currentRequest['passenger_id']);
      }
      
    } catch (e) {
      _logMatching('Erro ao processar fallback: $e');
      // Log error mas não propagar para não quebrar o fluxo
    }
  }
  
  /// Aceita solicitação e atualiza status
  Future<void> _acceptRequest(String requestId, String driverId) async {
    await _supabase.from('trip_requests').update({
      'status': 'accepted',
      'accepted_by_driver_id': driverId,
      'accepted_at': DateTime.now().toIso8601String(),
    }).eq('id', requestId);
    
    // Marcar oferta como selecionada se existir
    try {
      await _supabase.from('driver_offers').update({
        'was_selected': true,
      }).eq('request_id', requestId).eq('driver_id', driverId);
    } catch (e) {
      // Não falhar se não houver oferta
      _logMatching('Oferta não encontrada para request $requestId, driver $driverId');
    }
    
    _logMatching('Request $requestId aceito pelo driver $driverId');
  }
  
  /// Envia notificação push para motorista
  Future<void> _sendDriverNotification(String driverId, String requestId) async {
    try {
      await _notificationService.sendDriverNotification(driverId, requestId);
    } catch (e) {
      _logMatching('Erro ao enviar notificação para driver $driverId: $e');
    }
  }
  
  /// Notifica passageiro quando nenhum motorista foi encontrado
  Future<void> _notifyPassengerNoDriverFound(String passengerId) async {
    try {
      await _notificationService.createNotification(
        userId: passengerId,
        title: 'Nenhum motorista disponível',
        message: 'Não foi possível encontrar um motorista para sua solicitação. Tente novamente.',
        type: 'trip_expired',
        priority: 'high',
      );
    } catch (e) {
      _logMatching('Erro ao notificar passageiro $passengerId: $e');
    }
  }
  
  /// Log condicional baseado em feature flag
  void _logMatching(String message) {
    if (FeatureFlags().enableMatchingLogs) {
      print('🎯 MATCHING: $message');
    }
  }
  
  /// Limpar recursos ao destruir o service
  void dispose() {
    for (final timer in _activeTimers.values) {
      timer.cancel();
    }
    _activeTimers.clear();
    
    for (final subscription in _activeSubscriptions.values) {
      subscription.cancel();
    }
    _activeSubscriptions.clear();
    
    _logMatching('TripRequestManager disposed - recursos limpos');
  }

  /// Cancela o monitoramento de uma solicitação
  void cancelMonitoring(String requestId) {
    _activeTimers[requestId]?.cancel();
    _activeTimers.remove(requestId);
    
    _activeSubscriptions[requestId]?.cancel();
    _activeSubscriptions.remove(requestId);
  }

  /// Monitora mudanças de status de uma solicitação
  Stream<TripRequest?> monitorRequestStatus(String requestId) => _tripService.subscribeToTripRequests()
        .map((requests) => requests.firstWhere(
              (r) => r.id == requestId,
              orElse: () => TripRequest(
                id: '',
                passengerId: '',
                originAddress: '',
                originLatitude: 0,
                originLongitude: 0,
                destinationAddress: '',
                destinationLatitude: 0,
                destinationLongitude: 0,
                vehicleCategory: '',
                needsPet: false,
                needsGrocery: false,
                isCondoDestination: false,
                isCondoOrigin: false,
                needsAc: false,
                numberOfStops: 0,
                estimatedDistanceKm: 0,
                estimatedDurationMinutes: 0,
                estimatedFare: 0,
                status: 'not_found',
                createdAt: DateTime.now(),
                updatedAt: DateTime.now(),
              ),
            ))
        .where((request) => request.id.isNotEmpty);



  /// Verifica se um motorista está disponível em tempo real
  /// Checa se está online, não está em viagem ativa e não tem solicitação pendente
  Future<bool> _verifyDriverAvailability(String driverId) async {
    try {
      // 1. Verificar se o motorista está online
      final driverData = await _supabase
          .from('drivers')
          .select('is_online, approval_status')
          .eq('id', driverId)
          .single();
      
      if (driverData['is_online'] != true || driverData['approval_status'] != 'approved') {
        return false;
      }
      
      // 2. Verificar se não está em viagem ativa
       final activeTrips = await _supabase
           .from('trips')
           .select('id')
           .eq('driver_id', driverId)
           .inFilter('status', ['ongoing', 'arrived', 'picked_up'])
           .limit(1);
      
      if (activeTrips.isNotEmpty) {
        return false;
      }
      
      // 3. Verificar se não tem solicitação pendente
      final pendingRequests = await _supabase
          .from('trip_requests')
          .select('id')
          .eq('target_driver_id', driverId)
          .eq('status', 'pending')
          .limit(1);
      
      if (pendingRequests.isNotEmpty) {
        return false;
      }
      
      return true;
    } catch (e) {
      _logMatching('Erro ao verificar disponibilidade do motorista $driverId: $e');
      return false;
    }
  }

  /// Obtém estatísticas de solicitações direcionadas
  Future<Map<String, dynamic>> getTargetedRequestStats({
    String? driverId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      dynamic query = _supabase
          .from('trip_requests')
          .select('status, target_driver_id, created_at')
          .not('target_driver_id', 'is', null);

      if (driverId != null) {
        query = query.eq('target_driver_id', driverId);
      }

      if (startDate != null) {
        query = query.gte('created_at', startDate.toIso8601String());
      }

      if (endDate != null) {
        query = query.lte('created_at', endDate.toIso8601String());
      }

      final response = await query;
      
      final stats = {
        'total': response.length,
        'accepted': response.where((r) => r['status'] == 'accepted').length,
        'expired': response.where((r) => r['status'] == 'expired').length,
        'pending': response.where((r) => r['status'] == 'pending').length,
      };

      stats['acceptance_rate'] = stats['total'] > 0 
          ? (stats['accepted'] / stats['total'] * 100).toStringAsFixed(1)
          : '0.0';

      return stats;
    } catch (e) {
      throw DatabaseException('Erro ao obter estatísticas: $e');
    }
  }


}