import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/feature_flags.dart';
import '../exceptions/app_exceptions.dart';
import '../models/supabase/driver.dart';
import '../models/supabase/trip_request.dart';
import '../models/trip_request_data.dart';
import '../services/driver_service.dart';
import '../services/notification_service.dart';
import '../services/transaction_service.dart';
import '../services/trip_service.dart';

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
      // Validações iniciais
      _validateTripRequestInput(passengerId, prioritizedDrivers, tripData);
      
      final targetDriver = prioritizedDrivers.first;
      final fallbackDriverIds = _extractFallbackDriverIds(prioritizedDrivers);
      
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

  /// Valida os parâmetros de entrada da solicitação
  void _validateTripRequestInput(String passengerId, List<Driver> prioritizedDrivers, TripRequestData tripData) {
    if (passengerId.isEmpty) {
      throw const ValidationException('ID do passageiro não pode estar vazio');
    }
    
    if (prioritizedDrivers.isEmpty) {
      throw const ValidationException('Lista de motoristas priorizados não pode estar vazia');
    }
    
    if (tripData.originLatitude == 0 && tripData.originLongitude == 0) {
      throw const ValidationException('Coordenadas de origem inválidas');
    }
    
    if (tripData.destinationLatitude == 0 && tripData.destinationLongitude == 0) {
      throw const ValidationException('Coordenadas de destino inválidas');
    }
  }

  /// Extrai IDs dos motoristas de fallback
  List<String> _extractFallbackDriverIds(List<Driver> prioritizedDrivers) {
    return prioritizedDrivers
        .skip(1)
        .take(FeatureFlags().maxFallbackAttempts)
        .map((d) => d.id)
        .toList();
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
      _cancelTimeoutTimer(requestId);
      
      // Cancelar subscription se existir
      _cancelSubscription(requestId);
      
      if (accepted) {
        // Criar viagem a partir da solicitação
        await _createTripFromRequest(requestId);
        
        // Atualizar status da solicitação
        await _updateRequestStatus(requestId, 'accepted');
        
        _logMatching('Viagem criada com sucesso a partir da solicitação $requestId');
      } else {
        // Atualizar status da solicitação para recusado
        await _updateRequestStatus(requestId, 'rejected');
        
        // Tentar próximo motorista se houver fallback disponível
        await _tryNextFallbackDriver(requestId);
      }
    } catch (e) {
      _logMatching('Erro ao processar resposta do motorista: $e');
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
  
  /// Cancela o timer de timeout para uma solicitação
  void _cancelTimeoutTimer(String requestId) {
    _activeTimers[requestId]?.cancel();
    _activeTimers.remove(requestId);
  }

  /// Cancela a subscription de monitoramento para uma solicitação
  void _cancelSubscription(String requestId) {
    _activeSubscriptions[requestId]?.cancel();
    _activeSubscriptions.remove(requestId);
  }

  /// Cria uma viagem a partir de uma solicitação aceita
  Future<void> _createTripFromRequest(String requestId) async {
    try {
      // Buscar dados da solicitação
      final requestData = await _supabase
          .from('trip_requests')
          .select()
          .eq('id', requestId)
          .single();

      // Criar viagem usando os dados da solicitação
      final tripData = {
        'passenger_id': requestData['passenger_id'],
        'driver_id': requestData['accepted_by_driver_id'],
        'origin_address': requestData['origin_address'],
        'origin_latitude': requestData['origin_latitude'],
        'origin_longitude': requestData['origin_longitude'],
        'destination_address': requestData['destination_address'],
        'destination_latitude': requestData['destination_latitude'],
        'destination_longitude': requestData['destination_longitude'],
        'vehicle_category': requestData['vehicle_category'],
        'estimated_fare': requestData['estimated_fare'],
        'estimated_distance_km': requestData['estimated_distance_km'],
        'estimated_duration_minutes': requestData['estimated_duration_minutes'],
        'status': 'requested',
        'created_at': DateTime.now().toIso8601String(),
      };

      await _supabase.from('trips').insert(tripData);
      
      _logMatching('Viagem criada com sucesso a partir da solicitação $requestId');
    } catch (e) {
      _logMatching('Erro ao criar viagem a partir da solicitação $requestId: $e');
      throw DatabaseException('Erro ao criar viagem: $e');
    }
  }

  /// Atualiza o status de uma solicitação
  Future<void> _updateRequestStatus(String requestId, String status) async {
    try {
      await _supabase.from('trip_requests').update({
        'status': status,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', requestId);
      
      _logMatching('Status da solicitação $requestId atualizado para: $status');
    } catch (e) {
      _logMatching('Erro ao atualizar status da solicitação $requestId: $e');
      throw DatabaseException('Erro ao atualizar status da solicitação: $e');
    }
  }

  /// Tenta o próximo motorista de fallback
  Future<void> _tryNextFallbackDriver(String requestId) async {
    try {
      // Buscar dados da solicitação
      final requestData = await _supabase
          .from('trip_requests')
          .select()
          .eq('id', requestId)
          .single();

      final fallbackDrivers = List<String>.from(requestData['fallback_drivers'] ?? []);
      final currentIndex = requestData['current_fallback_index'] ?? 0;

      if (currentIndex < fallbackDrivers.length) {
        final nextDriverId = fallbackDrivers[currentIndex];
        
        _logMatching('Tentando próximo motorista de fallback: $nextDriverId');
        
        // Atualizar solicitação para próximo motorista
        await _supabase.from('trip_requests').update({
          'target_driver_id': nextDriverId,
          'current_fallback_index': currentIndex + 1,
          'status': 'pending',
          'updated_at': DateTime.now().toIso8601String(),
        }).eq('id', requestId);
        
        // Enviar notificação para o próximo motorista
        if (FeatureFlags().enablePushNotifications) {
          await _sendDriverNotification(nextDriverId, requestId);
        }
        
        // Iniciar novo timer de timeout
        if (FeatureFlags().enableFallbackSystem) {
          _startTimeoutTimer(requestId, nextDriverId);
        }
      } else {
        // Não há mais motoristas de fallback disponíveis
        await _updateRequestStatus(requestId, 'expired');
        await _notifyPassengerNoDriverFound(requestData['passenger_id']);
      }
    } catch (e) {
      _logMatching('Erro ao tentar próximo motorista de fallback: $e');
      throw DatabaseException('Erro ao processar fallback: $e');
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
              orElse: () => _createEmptyTripRequest(),
            ))
        .where((request) => request.id.isNotEmpty);

  /// Cria um objeto TripRequest vazio para casos de não encontrado
  TripRequest _createEmptyTripRequest() {
    return TripRequest(
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
      needsGrocerySpace: false,
      isCondoOrigin: false,
      isCondoDestination: false,
      needsAc: false,
      numberOfStops: 0,
      estimatedDistanceKm: 0,
      estimatedDurationMinutes: 0,
      estimatedFare: 0,
      status: 'not_found',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }



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