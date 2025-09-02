import 'package:flutter/material.dart';

class DriverSchedule {
  const DriverSchedule({
    required this.id,
    required this.driverId,
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    required this.isActive,
    required this.createdAt,
  });

  factory DriverSchedule.fromJson(Map<String, dynamic> json) => DriverSchedule(
      id: json['id'] as String,
      driverId: json['driver_id'] as String,
      dayOfWeek: json['day_of_week'] as int,
      startTime: _parseTime(json['start_time']),
      endTime: _parseTime(json['end_time']),
      isActive: json['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
    );

  static TimeOfDay _parseTime(dynamic timeData) {
    if (timeData is String) {
      // Formato "HH:MM:SS" ou "HH:MM"
      final parts = timeData.split(':');
      if (parts.length >= 2) {
        return TimeOfDay(
          hour: int.parse(parts[0]),
          minute: int.parse(parts[1]),
        );
      }
    }
    
    // Fallback para 00:00 se não conseguir parsear
    return const TimeOfDay(hour: 0, minute: 0);
  }

  static String _formatTime(TimeOfDay time) => '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}:00';

  final String id;
  final String driverId;
  final int dayOfWeek; // 0 = Domingo, 1 = Segunda, ..., 6 = Sábado
  final TimeOfDay startTime;
  final TimeOfDay endTime;
  final bool isActive;
  final DateTime createdAt;

  /// Retorna o nome do dia da semana
  String get dayOfWeekName {
    const days = [
      'Domingo',
      'Segunda-feira',
      'Terça-feira',
      'Quarta-feira',
      'Quinta-feira',
      'Sexta-feira',
      'Sábado',
    ];
    
    if (dayOfWeek >= 0 && dayOfWeek < days.length) {
      return days[dayOfWeek];
    }
    return 'Dia inválido';
  }

  /// Retorna o horário formatado
  String get timeRange => '${_formatTimeDisplay(startTime)} às ${_formatTimeDisplay(endTime)}';

  String _formatTimeDisplay(TimeOfDay time) => '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';

  /// Verifica se o horário atual está dentro do período de trabalho
  bool isWorkingNow() {
    final now = DateTime.now();
    final currentDayOfWeek = now.weekday % 7; // Converter para formato 0-6
    
    if (currentDayOfWeek != dayOfWeek || !isActive) {
      return false;
    }

    final nowTime = TimeOfDay.fromDateTime(now);
    final nowMinutes = nowTime.hour * 60 + nowTime.minute;
    final startMinutes = startTime.hour * 60 + startTime.minute;
    final endMinutes = endTime.hour * 60 + endTime.minute;

    // Verificar se é um horário que passa da meia-noite
    if (endMinutes < startMinutes) {
      // Horário noturno que cruza a meia-noite
      return nowMinutes >= startMinutes || nowMinutes <= endMinutes;
    } else {
      // Horário normal durante o dia
      return nowMinutes >= startMinutes && nowMinutes <= endMinutes;
    }
  }

  Map<String, dynamic> toJson() => {
      'id': id,
      'driver_id': driverId,
      'day_of_week': dayOfWeek,
      'start_time': _formatTime(startTime),
      'end_time': _formatTime(endTime),
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
    };

  DriverSchedule copyWith({
    String? id,
    String? driverId,
    int? dayOfWeek,
    TimeOfDay? startTime,
    TimeOfDay? endTime,
    bool? isActive,
    DateTime? createdAt,
  }) => DriverSchedule(
      id: id ?? this.id,
      driverId: driverId ?? this.driverId,
      dayOfWeek: dayOfWeek ?? this.dayOfWeek,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
}