import 'dart:convert';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../exceptions/app_exceptions.dart';
import 'fcm_service.dart';
import 'local_notification_service.dart';

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
    try {
      await _supabase.from('notifications').insert({
        'user_id': userId,
        'title': title,
        'body': message,
        'type': type ?? 'general',
        'data': relatedId != null ? {'related_id': relatedId} : null,
        'priority': priority ?? 'normal',
        'is_read': false,
      });
    } on PostgrestException {
      throw const DatabaseException('Erro ao criar notificação. Por favor, tente novamente mais tarde.');
    } catch (e) {
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
          .order('created_at', ascending: false)
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
        .order('created_at')
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

  /// Send driver notification for targeted trip requests
  Future<void> sendDriverNotification(String driverId, String requestId) async {
    try {
      // 1. Buscar FCM token do motorista
      final driverData = await _supabase
          .from('drivers')
          .select('fcm_token, app_users(full_name)')
          .eq('id', driverId)
          .single();
      
      final fcmToken = driverData['fcm_token'] as String?;
      if (fcmToken == null) {
        print('❌ Motorista $driverId não tem FCM token');
        // Continue sem FCM, apenas salvar notificação no database
      }
      
      // 2. Buscar dados do request para payload
      final requestData = await _supabase
          .from('trip_requests')
          .select()
          .eq('id', requestId)
          .single();
      
      // 3. Criar payload da notificação
      const title = 'Nova Solicitação de Viagem';
      final body = 'De: ${requestData['origin_address']}\nPara: ${requestData['destination_address']}';
      
      final payload = {
        'title': title,
        'body': body,
        'data': {
          'type': 'trip_request',
          'request_id': requestId,
          'origin': requestData['origin_address'],
          'destination': requestData['destination_address'],
          'estimated_fare': requestData['estimated_fare']?.toString() ?? '0',
          'expires_at': requestData['expires_at'],
        }
      };
      
      // 4. Enviar via FCM se token disponível
      if (fcmToken != null) {
        await _sendFCMNotification(fcmToken, payload);
      }
      
      // 5. Salvar no database também
      await createNotification(
        userId: driverId,
        title: title,
        message: body,
        type: 'trip_request',
        relatedId: requestId,
        priority: 'high',
      );
      
      // 6. Show local notification with custom sound
      await _localNotificationService.showRideOfferNotification(
        title: title,
        body: body,
        offerId: requestId,
        isDriver: true, // Sempre true pois é notificação para motorista
      );
      
    } catch (e) {
      print('❌ Erro ao enviar notificação para motorista $driverId: $e');
      // Log error mas não propagar para não quebrar fluxo
    }
  }
  
  /// Send FCM notification using HTTP API
  Future<void> _sendFCMNotification(String fcmToken, Map<String, dynamic> payload) async {
    try {
      // Use FCMService que já tem a implementação completa
       final success = await FCMService().sendNotificationToToken(
        token: fcmToken,
        title: payload['title'] ?? '',
        body: payload['body'] ?? '',
        data: payload['data'] as Map<String, dynamic>? ?? {},
      );
      
      if (success) {
        print('🔔 FCM Notification sent successfully to ${fcmToken.substring(0, 20)}...');
      } else {
        print('❌ Failed to send FCM notification to ${fcmToken.substring(0, 20)}...');
      }
      
    } catch (e) {
      print('❌ Error sending FCM notification: $e');
      // Log error but don't throw to avoid breaking the flow
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
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : DateTime.now(),
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
      'created_at': createdAt.toIso8601String(),
    };
}