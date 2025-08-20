import 'package:supabase_flutter/supabase_flutter.dart';
import '../exceptions/app_exceptions.dart';

class NotificationService {
  final SupabaseClient _supabase;

  NotificationService(this._supabase);

  // Create notification in database
  Future<void> createNotification({
    required String userId,
    required String title,
    required String message,
    String? type,
    String? relatedId,
  }) async {
    try {
      await _supabase.from('notifications').insert({
        'user_id': userId,
        'title': title,
        'message': message,
        'type': type ?? 'general',
        'related_id': relatedId,
        'is_read': false,
      });
    } on PostgrestException catch (e) {
      throw DatabaseException('Erro ao criar notificação. Por favor, tente novamente mais tarde.');
    } catch (e) {
      throw DatabaseException('Erro inesperado ao criar notificação. Por favor, tente novamente mais tarde.');
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

      return response.map((notif) => NotificationModel.fromJson(notif)).toList();
    } on PostgrestException catch (e) {
      throw DatabaseException('Erro ao buscar notificações. Por favor, tente novamente mais tarde.');
    } catch (e) {
      throw DatabaseException('Erro inesperado ao buscar notificações. Por favor, tente novamente mais tarde.');
    }
  }

  // Get unread notifications count
  Future<int> getUnreadCount(String userId) async {
    try {
      final response = await _supabase
          .from('notifications')
          .select('count')
          .eq('user_id', userId)
          .eq('is_read', false);

      return response.first['count'] as int;
    } on PostgrestException catch (e) {
      throw DatabaseException('Erro ao buscar contador. Por favor, tente novamente mais tarde.');
    } catch (e) {
      throw DatabaseException('Erro inesperado ao buscar contador. Por favor, tente novamente mais tarde.');
    }
  }

  // Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    try {
      await _supabase
          .from('notifications')
          .update({'is_read': true})
          .eq('id', notificationId);
    } on PostgrestException catch (e) {
      throw DatabaseException('Erro ao marcar como lida. Por favor, tente novamente mais tarde.');
    } catch (e) {
      throw DatabaseException('Erro inesperado ao marcar como lida. Por favor, tente novamente mais tarde.');
    }
  }

  // Mark all notifications as read
  Future<void> markAllAsRead(String userId) async {
    try {
      await _supabase
          .from('notifications')
          .update({'is_read': true})
          .eq('user_id', userId)
          .eq('is_read', false);
    } on PostgrestException catch (e) {
      throw DatabaseException('Erro ao marcar todas como lidas. Por favor, tente novamente mais tarde.');
    } catch (e) {
      throw DatabaseException('Erro inesperado ao marcar todas como lidas. Por favor, tente novamente mais tarde.');
    }
  }

  // Stream notifications for real-time updates
  Stream<List<NotificationModel>> streamUserNotifications(String userId) {
    return _supabase
        .from('notifications')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .map((data) => data.map((notif) => NotificationModel.fromJson(notif)).toList());
  }

  // Stream unread count
  Stream<int> streamUnreadCount(String userId) {
    return _supabase
        .from('notifications')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .map((data) => data.where((notif) => !notif['is_read']).length);
  }

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
    await createNotification(
      userId: userId,
      title: title,
      message: message,
      type: 'offer',
      relatedId: offerId,
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
  final String id;
  final String userId;
  final String title;
  final String message;
  final String type;
  final String? relatedId;
  final bool isRead;
  final DateTime createdAt;

  NotificationModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.message,
    required this.type,
    this.relatedId,
    required this.isRead,
    required this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'],
      userId: json['user_id'],
      title: json['title'],
      message: json['message'],
      type: json['type'],
      relatedId: json['related_id'],
      isRead: json['is_read'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'message': message,
      'type': type,
      'related_id': relatedId,
      'is_read': isRead,
      'created_at': createdAt.toIso8601String(),
    };
  }
}