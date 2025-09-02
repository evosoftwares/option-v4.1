import 'package:flutter/material.dart';

/// Modelo para horários de trabalho do motorista (versão simplificada do driver_schedules)
/// Representa os intervalos de tempo em que o motorista está disponível para trabalhar
class WorkingHours {
  const WorkingHours({
    required this.id,
    required this.driverId,
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  /// ID único do registro
  final String id;

  /// ID do motorista
  final String driverId;

  /// Dia da semana (0=Domingo, 1=Segunda, ..., 6=Sábado)
  final int dayOfWeek;

  /// Horário de início (formato HH:mm:ss)
  final String startTime;

  /// Horário de fim (formato HH:mm:ss)
  final String endTime;

  /// Se o horário está ativo
  final bool isActive;

  /// Data de criação
  final DateTime createdAt;

  /// Data de última atualização
  final DateTime updatedAt;

  /// Converte de JSON do Supabase
  factory WorkingHours.fromJson(Map<String, dynamic> json) {
    return WorkingHours(
      id: json['id'].toString(),
      driverId: json['driver_id'] as String,
      dayOfWeek: json['day_of_week'] as int,
      startTime: json['start_time'] as String,
      endTime: json['end_time'] as String,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  /// Converte para JSON do Supabase
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'driver_id': driverId,
      'day_of_week': dayOfWeek,
      'start_time': startTime,
      'end_time': endTime,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Cria uma cópia com campos alterados
  WorkingHours copyWith({
    String? id,
    String? driverId,
    int? dayOfWeek,
    String? startTime,
    String? endTime,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return WorkingHours(
      id: id ?? this.id,
      driverId: driverId ?? this.driverId,
      dayOfWeek: dayOfWeek ?? this.dayOfWeek,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Converte string de tempo para TimeOfDay
  TimeOfDay parseStartTime() {
    final parts = startTime.split(':');
    return TimeOfDay(
      hour: int.parse(parts[0]),
      minute: int.parse(parts[1]),
    );
  }

  /// Converte string de tempo para TimeOfDay
  TimeOfDay parseEndTime() {
    final parts = endTime.split(':');
    return TimeOfDay(
      hour: int.parse(parts[0]),
      minute: int.parse(parts[1]),
    );
  }

  /// Formata TimeOfDay para string no formato HH:mm:ss
  static String formatTimeOfDay(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}:00';
  }

  /// Verifica se o horário atual está dentro do intervalo de trabalho
  /// Considera casos que cruzam a meia-noite (ex: 22:00 às 06:00)
  bool isWorkingNow() {
    final now = TimeOfDay.now();
    final start = parseStartTime();
    final end = parseEndTime();
    
    final nowMinutes = now.hour * 60 + now.minute;
    final startMinutes = start.hour * 60 + start.minute;
    final endMinutes = end.hour * 60 + end.minute;
    
    if (startMinutes <= endMinutes) {
      // Caso normal: mesmo dia (ex: 08:00 às 18:00)
      return nowMinutes >= startMinutes && nowMinutes < endMinutes;
    } else {
      // Caso que cruza meia-noite (ex: 22:00 às 06:00)
      return nowMinutes >= startMinutes || nowMinutes < endMinutes;
    }
  }

  /// Retorna o nome do dia da semana
  String get dayName {
    const days = [
      'Domingo',
      'Segunda-feira',
      'Terça-feira',
      'Quarta-feira',
      'Quinta-feira',
      'Sexta-feira',
      'Sábado',
    ];
    return days[dayOfWeek];
  }

  /// Retorna o nome abreviado do dia da semana
  String get dayAbbreviation {
    const days = ['Dom', 'Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb'];
    return days[dayOfWeek];
  }

  @override
  String toString() {
    return 'WorkingHours(id: $id, driverId: $driverId, dayOfWeek: $dayOfWeek, startTime: $startTime, endTime: $endTime)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is WorkingHours &&
        other.id == id &&
        other.driverId == driverId &&
        other.dayOfWeek == dayOfWeek &&
        other.startTime == startTime &&
        other.endTime == endTime &&
        other.isActive == isActive;
  }

  @override
  int get hashCode {
    return Object.hash(id, driverId, dayOfWeek, startTime, endTime, isActive);
  }
}