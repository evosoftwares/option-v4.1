import 'package:supabase_flutter/supabase_flutter.dart';
import '../exceptions/app_exceptions.dart';
import 'local_notification_service.dart';
import 'dart:convert';

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
        .order('created_at', ascending: false)
        .map((data) => data.map((notif) => NotificationModel.fromJson(notif)).toList());

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