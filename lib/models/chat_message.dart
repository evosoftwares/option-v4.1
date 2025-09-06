import 'package:flutter/foundation.dart';
import 'supabase/trip_chat.dart';

enum MessageSender { passenger, driver }

enum MessageStatus { sending, sent, delivered, read, failed }

@immutable
class ChatMessage {

  const ChatMessage({
    required this.id,
    required this.tripId,
    required this.senderId,
    required this.message,
    required this.senderType,
    required this.status,
    required this.timestamp,
    required this.isFromCurrentUser,
  });

  factory ChatMessage.fromTripChat({
    required TripChat tripChat,
    required String currentUserId,
    required bool isDriverSender,
  }) {
    try {
      debugPrint('🔄 ChatMessage.fromTripChat: tripChat=${tripChat.id}, currentUserId=$currentUserId, isDriverSender=$isDriverSender');
      
      final isFromCurrent = tripChat.senderId == currentUserId;
      final senderType = isDriverSender ? MessageSender.driver : MessageSender.passenger;
      final status = tripChat.isRead ? MessageStatus.read : MessageStatus.delivered;

      final result = ChatMessage(
        id: tripChat.id,
        tripId: tripChat.tripId,
        senderId: tripChat.senderId,
        message: tripChat.message,
        senderType: senderType,
        status: status,
        timestamp: tripChat.createdAt,
        isFromCurrentUser: isFromCurrent,
      );
      
      debugPrint('✅ ChatMessage.fromTripChat concluído: ${result.id}, isFromCurrentUser: ${result.isFromCurrentUser}');
      return result;
    } catch (e) {
      debugPrint('❌ Erro em ChatMessage.fromTripChat: $e');
      debugPrint('📋 TripChat: ${tripChat.toString()}');
      debugPrint('📋 currentUserId: $currentUserId');
      debugPrint('📋 isDriverSender: $isDriverSender');
      rethrow;
    }
  }

  factory ChatMessage.sending({
    required String tripId,
    required String senderId,
    required String message,
    required MessageSender senderType,
  }) =>
      ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        tripId: tripId,
        senderId: senderId,
        message: message,
        senderType: senderType,
        status: MessageStatus.sending,
        timestamp: DateTime.now(),
        isFromCurrentUser: true,
      );
  final String id;
  final String tripId;
  final String senderId;
  final String message;
  final MessageSender senderType;
  final MessageStatus status;
  final DateTime timestamp;
  final bool isFromCurrentUser;

  ChatMessage copyWith({
    String? id,
    String? tripId,
    String? senderId,
    String? message,
    MessageSender? senderType,
    MessageStatus? status,
    DateTime? timestamp,
    bool? isFromCurrentUser,
  }) =>
      ChatMessage(
        id: id ?? this.id,
        tripId: tripId ?? this.tripId,
        senderId: senderId ?? this.senderId,
        message: message ?? this.message,
        senderType: senderType ?? this.senderType,
        status: status ?? this.status,
        timestamp: timestamp ?? this.timestamp,
        isFromCurrentUser: isFromCurrentUser ?? this.isFromCurrentUser,
      );

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    
    return other is ChatMessage && 
           other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'ChatMessage(id: $id, tripId: $tripId, senderId: $senderId, message: $message, senderType: $senderType, status: $status, timestamp: $timestamp, isFromCurrentUser: $isFromCurrentUser)';
}