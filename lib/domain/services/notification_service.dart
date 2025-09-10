import 'dart:convert';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/exceptions/app_exceptions.dart';
import 'local_notification_service.dart';
import 'onesignal_service.dart';
import 'app_logger.dart';

class NotificationService {

  NotificationService(this._supabase) : _localNotificationService = LocalNotificationService();
  final SupabaseClient _supabase;
  final LocalNotificationService _localNotificationService;

  // Create notification in database
  Future<void> createNotification({
    required String userId,
    required String title,
    required String message,
    String? type,
    String? relatedId,
    String? priority,
  }) async {
    final startTime = DateTime.now();
    
    try {
      AppLogger.process('Criando notificação', tag: 'NOTIFICATION');
      AppLogger.create('Notification', userId, tag: 'NOTIFICATION', data: {
        'title': title,
        'type': type ?? 'general',
        'priority': priority ?? 'normal',
        'has_related_id': relatedId != null
      });
      
      await _supabase.from('notifications').insert({
        'user_id': userId,
        'title': title,
        'body': message,
        'type': type ?? 'general',
        'data': relatedId != null ? {'related_id': relatedId} : null,
        'priority': priority ?? 'normal',
        'is_read': false,
      });
      
      final duration = DateTime.now().difference(startTime);
      AppLogger.performance('create_notification', duration, tag: 'NOTIFICATION');
      AppLogger.notification(type ?? 'general', userId, title: title, success: true);
      AppLogger.success('Notificação criada com sucesso', tag: 'NOTIFICATION');
      
    } on PostgrestException catch (e) {
      AppLogger.error('PostgrestException ao criar notificação', tag: 'NOTIFICATION', error: e);
      AppLogger.notification(type ?? 'general', userId, title: title, success: false);
      throw const DatabaseException('Erro ao criar notificação. Por favor, tente novamente mais tarde.');
    } catch (e) {
      AppLogger.error('Erro inesperado ao criar notificação', tag: 'NOTIFICATION', error: e);
      AppLogger.notification(type ?? 'general', userId, title: title, success: false);
      throw const DatabaseException('Erro inesperado ao criar notificação. Por favor, tente novamente mais tarde.');
    }
  }

  // Get user notifications
  Future<List<NotificationModel>> getUserNotifications(String userId) async {
    try {
      final response = await _supabase
          .from('notifications')
          .select()
          .eq('user_id', userId)
          .order('sent_at', ascending: false)
          .limit(50);

      return response.map(NotificationModel.fromJson).toList();
    } on PostgrestException {
      throw const DatabaseException('Erro ao buscar notificações. Por favor, tente novamente mais tarde.');
    } catch (e) {
      throw const DatabaseException('Erro inesperado ao buscar notificações. Por favor, tente novamente mais tarde.');
    }
  }

  // Get unread notifications count
  Future<int> getUnreadCount(String userId) async {
    try {
      final response = await _supabase
          .from('notifications')
          .select()
          .eq('user_id', userId)
          .eq('is_read', false);

      return (response as List).length;
    } on PostgrestException {
      throw const DatabaseException('Erro ao buscar contador. Por favor, tente novamente mais tarde.');
    } catch (e) {
      throw const DatabaseException('Erro inesperado ao buscar contador. Por favor, tente novamente mais tarde.');
    }
  }

  // Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    try {
      await _supabase
          .from('notifications')
          .update({
            'is_read': true,
            'read_at': DateTime.now().toIso8601String(),
          })
          .eq('id', notificationId);
    } on PostgrestException {
      throw const DatabaseException('Erro ao marcar como lida. Por favor, tente novamente mais tarde.');
    } catch (e) {
      throw const DatabaseException('Erro inesperado ao marcar como lida. Por favor, tente novamente mais tarde.');
    }
  }

  // Mark all notifications as read
  Future<void> markAllAsRead(String userId) async {
    try {
      await _supabase
          .from('notifications')
          .update({
            'is_read': true,
            'read_at': DateTime.now().toIso8601String(),
          })
          .eq('user_id', userId)
          .eq('is_read', false);
    } on PostgrestException {
      throw const DatabaseException('Erro ao marcar todas como lidas. Por favor, tente novamente mais tarde.');
    } catch (e) {
      throw const DatabaseException('Erro inesperado ao marcar todas como lidas. Por favor, tente novamente mais tarde.');
    }
  }

  // Stream notifications for real-time updates
  Stream<List<NotificationModel>> streamUserNotifications(String userId) => _supabase
        .from('notifications')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('sent_at') // Corrigido: usar 'sent_at' do banco com ordem descendente
        .map((data) => data.map(NotificationModel.fromJson).toList());

  // Stream unread count
  Stream<int> streamUnreadCount(String userId) => _supabase
        .from('notifications')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .map((data) => data.where((notif) => !notif['is_read']).length);

  // Send trip-related notification
  Future<void> sendTripNotification({
    required String userId,
    required String tripId,
    required String title,
    required String message,
  }) async {
    await createNotification(
      userId: userId,
      title: title,
      message: message,
      type: 'trip',
      relatedId: tripId,
    );
  }

  // Send offer-related notification
  Future<void> sendOfferNotification({
    required String userId,
    required String offerId,
    required String title,
    required String message,
  }) async {
    // Save notification to database
    await createNotification(
      userId: userId,
      title: title,
      message: message,
      type: 'offer',
      relatedId: offerId,
    );

    // Show local notification with custom sound for ride offers
    await _localNotificationService.showRideOfferNotification(
      title: title,
      body: message,
      offerId: offerId,
    );
  }

  // Send chat notification
  Future<void> sendChatNotification({
    required String userId,
    required String chatId,
    required String senderName,
    required String message,
  }) async {
    await createNotification(
      userId: userId,
      title: 'Nova mensagem de $senderName',
      message: message,
      type: 'chat',
      relatedId: chatId,
    );
  }

  /// Send driver notification for targeted trip requests with robust fallback system
  /// Customized message for drivers with passenger information
  Future<void> sendDriverNotification(String driverId, String requestId) async {
    const maxRetries = 3;
    const retryDelay = Duration(seconds: 2);
    
    for (var attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        print('🔔 Tentativa $attempt/$maxRetries - Enviando notificação para motorista $driverId');
        
        // 1. Buscar dados do motorista, passageiro e request em paralelo para otimizar
        final results = await Future.wait([
          _supabase
              .from('drivers')
              .select('onesignal_player_id, push_token, app_users(full_name, phone)')
              .eq('id', driverId)
              .single(),
          _supabase
              .from('trip_requests')
              .select('*, app_users!passenger_id(full_name, phone)')
              .eq('id', requestId)
              .single(),
        ]);
        
        final driverData = results[0];
        final requestData = results[1];
        
        // 2. Extrair dados necessários
        final playerId = driverData['onesignal_player_id'] as String?;
        final passengerName = requestData['app_users']?['full_name'] as String? ?? 'Passageiro';
        
        // 3. Criar payload da notificação personalizado para motorista
        const title = 'Nova Solicitação de Viagem';
        final body = 'Passageiro: $passengerName\n'
            'De: ${requestData['origin_address']}\n'
            'Para: ${requestData['destination_address']}';
        
        final notificationData = {
          'type': 'trip_request',
          'request_id': requestId,
          'origin': requestData['origin_address'],
          'destination': requestData['destination_address'],
          'passenger_name': passengerName,
          'estimated_fare': requestData['estimated_fare']?.toString() ?? '0',
          'expires_at': requestData['expires_at'],
        };
        
        var notificationSent = false;
        var failureReason = '';
        
        // 4. Tentar OneSignal primeiro (método preferido)
        if (playerId != null && playerId.isNotEmpty) {
          print('📱 [NOTIFICATION_SERVICE] Tentando OneSignal Push');
          print('📱 [NOTIFICATION_SERVICE] Player ID: ${playerId.substring(0, 12)}...');
          print('📱 [NOTIFICATION_SERVICE] Título: $title');
          print('📱 [NOTIFICATION_SERVICE] Body: $body');
          print('📱 [NOTIFICATION_SERVICE] Data: $notificationData');
          
          final success = await OneSignalService().sendNotificationToPlayerId(
            playerId: playerId,
            title: title,
            body: body,
            data: notificationData,
          );
          
          if (success) {
            notificationSent = true;
            print('🎉 [NOTIFICATION_SERVICE] OneSignal push ENVIADO COM SUCESSO!');
            print('✅ [NOTIFICATION_SERVICE] Notificação entregue via OneSignal');
          } else {
            failureReason += 'OneSignal failed; ';
            print('❌ OneSignal push falhou');
          }
        } else {
          failureReason += 'No OneSignal Player ID; ';
          print('⚠️ Motorista não tem OneSignal Player ID');
        }
        
        // 5. Fallback: Salvar sempre no database
        try {
          await createNotification(
            userId: driverId,
            title: title,
            message: body,
            type: 'trip_request',
            relatedId: requestId,
            priority: 'high',
          );
          print('✅ Notificação salva no database');
        } catch (e) {
          failureReason += 'Database save failed: $e; ';
          print('❌ Erro ao salvar no database: $e');
        }
        
        // 6. Fallback: Notificação local (sempre executar)
        try {
          await _localNotificationService.showRideOfferNotification(
            title: title,
            body: body,
            offerId: requestId,
            isDriver: true,
          );
          print('✅ Notificação local exibida');
        } catch (e) {
          failureReason += 'Local notification failed: $e; ';
          print('❌ Erro na notificação local: $e');
        }
        
        // 7. Atualizar timestamp da última notificação
        try {
          await _supabase
              .from('drivers')
              .update({'last_notification_at': DateTime.now().toIso8601String()})
              .eq('id', driverId);
        } catch (e) {
          print('⚠️ Erro ao atualizar last_notification_at: $e');
        }
        
        // Se chegou até aqui, tentativa foi bem-sucedida (pelo menos parcialmente)
        if (notificationSent || attempt == maxRetries) {
          if (!notificationSent && failureReason.isNotEmpty) {
            print('⚠️ Notificação enviada apenas via fallback. Razões: $failureReason');
          }
          return; // Sair do loop de tentativas
        }
        
      } catch (e, stackTrace) {
        print('❌ Erro na tentativa $attempt para motorista $driverId: $e');
        
        if (attempt < maxRetries) {
          print('🔄 Aguardando ${retryDelay.inSeconds}s antes da próxima tentativa...');
          await Future.delayed(retryDelay);
        } else {
          print('💥 Todas as tentativas falharam para motorista $driverId');
          print('Stack trace: $stackTrace');
          
          // Última tentativa: notificação local de emergência
          try {
            await _localNotificationService.showRideOfferNotification(
              title: 'Nova Solicitação de Viagem',
              body: 'Erro na sincronização. Verifique suas solicitações.',
              offerId: requestId,
              isDriver: true,
            );
            print('🆘 Notificação de emergência enviada');
          } catch (emergencyError) {
            print('💀 Falha crítica: notificação de emergência também falhou: $emergencyError');
          }
        }
      }
    }
  }

  /// Send passenger notification when their trip request is accepted or rejected
  /// Customized message for passengers with driver information
  Future<void> sendPassengerNotification({
    required String passengerId,
    required String tripRequestId,
    required String notificationType,
    required String driverName,
    String? driverPhone,
    String? vehicleModel,
    String? vehiclePlate,
  }) async {
    String title;
    String body;
    
    switch (notificationType) {
      case 'trip_accepted':
        title = 'Solicitação Aceita!';
        body = 'Seu motorista $driverName aceitou sua solicitação.\n'
            '${vehicleModel != null ? 'Veículo: $vehicleModel' : ''}'
            '${vehiclePlate != null ? '\nPlaca: $vehiclePlate' : ''}';
        break;
      case 'trip_rejected':
        title = 'Solicitação Recusada';
        body = 'Infelizmente, $driverName não pode atender sua solicitação neste momento. '
            'Estamos buscando outro motorista para você.';
        break;
      case 'trip_expired':
        title = 'Nenhum Motorista Encontrado';
        body = 'Não conseguimos encontrar um motorista disponível para sua solicitação. '
            'Por favor, tente novamente.';
        break;
      default:
        title = 'Atualização de Viagem';
        body = 'Há uma atualização sobre sua solicitação de viagem.';
    }
    
    try {
      // Save to database
      await createNotification(
        userId: passengerId,
        title: title,
        message: body,
        type: notificationType,
        relatedId: tripRequestId,
        priority: 'high',
      );
      
      // Try to send push notification
      final passengerData = await _supabase
          .from('app_users')
          .select('onesignal_player_id')
          .eq('id', passengerId)
          .single();
      
      final playerId = passengerData['onesignal_player_id'] as String?;
      
      if (playerId != null && playerId.isNotEmpty) {
        final notificationData = {
          'type': notificationType,
          'request_id': tripRequestId,
          'driver_name': driverName,
          'driver_phone': driverPhone,
          'vehicle_model': vehicleModel,
          'vehicle_plate': vehiclePlate,
        };
        
        await OneSignalService().sendNotificationToPlayerId(
          playerId: playerId,
          title: title,
          body: body,
          data: notificationData,
        );
      }
      
      // Show local notification
      await _localNotificationService.showRideOfferNotification(
        title: title,
        body: body,
        offerId: tripRequestId,
        isDriver: false, // Passenger notification
      );
      
      print('✅ Notificação de passageiro enviada com sucesso');
    } catch (e) {
      print('❌ Erro ao enviar notificação para passageiro: $e');
    }
  }
}

class NotificationModel {

  NotificationModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.message,
    required this.type,
    this.data,
    this.priority,
    required this.isRead,
    this.readAt,
    required this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    // Handle json['data'] possibly being a JSON string or a Map
    Map<String, dynamic>? parsedData;
    final dynamic rawData = json['data'];
    if (rawData is Map<String, dynamic>) {
      parsedData = rawData;
    } else if (rawData is String && rawData.isNotEmpty) {
      try {
        parsedData = jsonDecode(rawData) as Map<String, dynamic>;
      } catch (_) {
        parsedData = null;
      }
    }

    return NotificationModel(
      id: json['id'],
      userId: json['user_id'],
      title: json['title'],
      message: json['body'], // Campo 'body' no banco
      type: json['type'] ?? 'general',
      data: parsedData,
      priority: json['priority'],
      isRead: json['is_read'] ?? false,
      readAt: json['read_at'] != null ? DateTime.parse(json['read_at']) : null,
      createdAt: json['sent_at'] != null ? DateTime.parse(json['sent_at']) : DateTime.now(), // Corrigido: usar 'sent_at' do banco
    );
  }
  final String id;
  final String userId;
  final String title;
  final String message;
  final String type;
  final Map<String, dynamic>? data;
  final String? priority;
  final bool isRead;
  final DateTime? readAt;
  final DateTime createdAt;

  String? get relatedId => data?['related_id'];

  Map<String, dynamic> toJson() => {
      'id': id,
      'user_id': userId,
      'title': title,
      'body': message,
      'type': type,
      'data': data,
      'priority': priority,
      'is_read': isRead,
      'read_at': readAt?.toIso8601String(),
      'sent_at': createdAt.toIso8601String(), // Corrigido: usar 'sent_at' do banco
    };
}