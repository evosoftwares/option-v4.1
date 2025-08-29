import 'package:flutter/foundation.dart';

@immutable
class TripChat {

  const TripChat({
    required this.id,
    required this.tripId,
    required this.senderId,
    required this.message,
    this.isRead = false,
    this.readAt,
    required this.createdAt,
  });

  factory TripChat.fromJson(Map<String, dynamic> json) => TripChat(
        id: json['id'] as String,
        tripId: json['trip_id'] as String,
        senderId: json['sender_id'] as String,
        message: json['message'] as String,
        isRead: json['is_read'] as bool? ?? false,
        readAt: json['read_at'] != null 
            ? DateTime.parse(json['read_at'] as String)
            : null,
        createdAt: DateTime.parse(json['created_at'] as String),
      );
  final String id;
  final String tripId;
  final String senderId;
  final String message;
  final bool isRead;
  final DateTime? readAt;
  final DateTime createdAt;

  Map<String, dynamic> toJson() => {
        'id': id,
        'trip_id': tripId,
        'sender_id': senderId,
        'message': message,
        'is_read': isRead,
        'read_at': readAt?.toIso8601String(),
        'created_at': createdAt.toIso8601String(),
      };

  Map<String, dynamic> toInsertJson() => {
        'trip_id': tripId,
        'sender_id': senderId,
        'message': message,
        'is_read': isRead,
        'read_at': readAt?.toIso8601String(),
      };

  TripChat copyWith({
    String? id,
    String? tripId,
    String? senderId,
    String? message,
    bool? isRead,
    DateTime? readAt,
    DateTime? createdAt,
  }) =>
      TripChat(
        id: id ?? this.id,
        tripId: tripId ?? this.tripId,
        senderId: senderId ?? this.senderId,
        message: message ?? this.message,
        isRead: isRead ?? this.isRead,
        readAt: readAt ?? this.readAt,
        createdAt: createdAt ?? this.createdAt,
      );

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    
    return other is TripChat && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'TripChat(id: $id, tripId: $tripId, senderId: $senderId, message: $message, isRead: $isRead, readAt: $readAt, createdAt: $createdAt)';
}