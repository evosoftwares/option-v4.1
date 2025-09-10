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

  factory TripChat.fromJson(Map<String, dynamic> json) {
    try {
      debugPrint('🔄 TripChat.fromJson: $json');
      
      // 🔍 DIAGNÓSTICO: Verificar campos obrigatórios
      final requiredFields = ['id', 'trip_id', 'sender_id', 'message', 'created_at'];
      final missingFields = requiredFields.where((field) => json[field] == null).toList();
      
      if (missingFields.isNotEmpty) {
        debugPrint('❌ DIAGNÓSTICO: Campos obrigatórios faltando: $missingFields');
        debugPrint('📋 JSON completo: $json');
        throw Exception('Campos obrigatórios faltando na tabela trip_chats: $missingFields');
      }
      
      // 🔍 DIAGNÓSTICO: Verificar campos opcionais
      final hasIsRead = json.containsKey('is_read');
      final hasReadAt = json.containsKey('read_at');
      debugPrint('🔍 DIAGNÓSTICO: Campos opcionais - is_read: $hasIsRead, read_at: $hasReadAt');
      
      // 🔍 VALIDAÇÃO: Se campos opcionais estiverem faltando, logar aviso específico
      if (!hasIsRead || !hasReadAt) {
        debugPrint('🚨 VALIDAÇÃO: ESTRUTURA INCOMPLETA DETECTADA!');
        debugPrint('🚨 VALIDAÇÃO: Os campos is_read e/ou read_at não existem na tabela trip_chats');
        debugPrint('🚨 VALIDAÇÃO: Execute os comandos SQL:');
        debugPrint('🚨 VALIDAÇÃO: ALTER TABLE trip_chats ADD COLUMN is_read BOOLEAN DEFAULT false;');
        debugPrint('🚨 VALIDAÇÃO: ALTER TABLE trip_chats ADD COLUMN read_at TIMESTAMP WITH TIME ZONE;');
      }
      
      final result = TripChat(
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
      
      debugPrint('✅ TripChat.fromJson concluído: ${result.id}');
      return result;
    } catch (e) {
      debugPrint('❌ Erro em TripChat.fromJson: $e');
      debugPrint('📋 JSON recebido: $json');
      rethrow;
    }
  }
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