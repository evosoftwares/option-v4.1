import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../exceptions/app_exceptions.dart';
import '../models/supabase/driver_schedule.dart';

class DriverScheduleService {
  DriverScheduleService(this._supabase);
  final SupabaseClient _supabase;

  /// Busca todos os horários de um motorista
  Future<List<DriverSchedule>> getDriverSchedules(String driverId) async {
    try {
      final response = await _supabase
          .from('driver_schedules')
          .select()
          .eq('driver_id', driverId)
          .order('day_of_week', ascending: true);

      return (response as List<dynamic>)
          .map((json) => DriverSchedule.fromJson(json as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      throw DatabaseException(
        'Erro ao buscar horários de trabalho. Por favor, tente novamente mais tarde.',
        e.code,
      );
    } catch (e) {
      throw const DatabaseException(
        'Erro inesperado ao buscar horários de trabalho. Por favor, tente novamente mais tarde.',
      );
    }
  }

  /// Busca horários ativos de um motorista
  Future<List<DriverSchedule>> getActiveSchedules(String driverId) async {
    try {
      final response = await _supabase
          .from('driver_schedules')
          .select()
          .eq('driver_id', driverId)
          .eq('is_active', true)
          .order('day_of_week', ascending: true);

      return (response as List<dynamic>)
          .map((json) => DriverSchedule.fromJson(json as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      throw DatabaseException(
        'Erro ao buscar horários ativos. Por favor, tente novamente mais tarde.',
        e.code,
      );
    } catch (e) {
      throw const DatabaseException(
        'Erro inesperado ao buscar horários ativos. Por favor, tente novamente mais tarde.',
      );
    }
  }

  /// Cria um novo horário de trabalho
  Future<DriverSchedule> createSchedule({
    required String driverId,
    required int dayOfWeek,
    required TimeOfDay startTime,
    required TimeOfDay endTime,
    bool isActive = true,
  }) async {
    try {
      // Valida se o dia da semana está no range correto (0-6)
      if (dayOfWeek < 0 || dayOfWeek > 6) {
        throw const ValidationException('Dia da semana deve estar entre 0 (domingo) e 6 (sábado).');
      }

      // Valida se não existe conflito de horários
      await _validateScheduleConflict(driverId, dayOfWeek, startTime, endTime);

      final insertData = {
        'driver_id': driverId,
        'day_of_week': dayOfWeek,
        'start_time': '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}:00',
        'end_time': '${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}:00',
        'is_active': isActive,
      };

      final response = await _supabase
          .from('driver_schedules')
          .insert(insertData)
          .select()
          .single();

      return DriverSchedule.fromJson(response);
    } on PostgrestException catch (e) {
      throw DatabaseException(
        'Erro ao criar horário de trabalho. Por favor, tente novamente mais tarde.',
        e.code,
      );
    } catch (e) {
      if (e is ValidationException) rethrow;
      throw const DatabaseException(
        'Erro inesperado ao criar horário de trabalho. Por favor, tente novamente mais tarde.',
      );
    }
  }

  /// Atualiza um horário existente
  Future<DriverSchedule> updateSchedule({
    required String scheduleId,
    int? dayOfWeek,
    TimeOfDay? startTime,
    TimeOfDay? endTime,
    bool? isActive,
  }) async {
    try {
      final updateData = <String, dynamic>{};

      if (dayOfWeek != null) {
        if (dayOfWeek < 0 || dayOfWeek > 6) {
          throw const ValidationException('Dia da semana deve estar entre 0 (domingo) e 6 (sábado).');
        }
        updateData['day_of_week'] = dayOfWeek;
      }

      if (startTime != null) {
        updateData['start_time'] = 
            '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}:00';
      }

      if (endTime != null) {
        updateData['end_time'] = 
            '${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}:00';
      }

      if (isActive != null) {
        updateData['is_active'] = isActive;
      }

      if (updateData.isEmpty) {
        throw const ValidationException('Nenhum campo foi fornecido para atualização.');
      }

      final response = await _supabase
          .from('driver_schedules')
          .update(updateData)
          .eq('id', scheduleId)
          .select()
          .single();

      return DriverSchedule.fromJson(response);
    } on PostgrestException catch (e) {
      throw DatabaseException(
        'Erro ao atualizar horário. Por favor, tente novamente mais tarde.',
        e.code,
      );
    } catch (e) {
      if (e is ValidationException) rethrow;
      throw const DatabaseException(
        'Erro inesperado ao atualizar horário. Por favor, tente novamente mais tarde.',
      );
    }
  }

  /// Remove um horário
  Future<void> deleteSchedule(String scheduleId) async {
    try {
      await _supabase
          .from('driver_schedules')
          .delete()
          .eq('id', scheduleId);
    } on PostgrestException catch (e) {
      throw DatabaseException(
        'Erro ao remover horário. Por favor, tente novamente mais tarde.',
        e.code,
      );
    } catch (e) {
      throw const DatabaseException(
        'Erro inesperado ao remover horário. Por favor, tente novamente mais tarde.',
      );
    }
  }

  /// Verifica se o motorista está em horário de trabalho no momento
  Future<bool> isDriverWorkingNow(String driverId) async {
    try {
      final schedules = await getActiveSchedules(driverId);
      final now = DateTime.now();
      final currentDayOfWeek = now.weekday % 7; // Converter para formato 0-6

      for (final schedule in schedules) {
        if (schedule.dayOfWeek == currentDayOfWeek && schedule.isWorkingNow()) {
          return true;
        }
      }

      return false;
    } catch (e) {
      // Em caso de erro, assume que não está trabalhando
      return false;
    }
  }

  /// Obtém o próximo horário de trabalho do motorista
  Future<DriverSchedule?> getNextWorkingSchedule(String driverId) async {
    try {
      final schedules = await getActiveSchedules(driverId);
      if (schedules.isEmpty) return null;

      final now = DateTime.now();
      final currentDayOfWeek = now.weekday % 7;
      final currentTime = TimeOfDay.fromDateTime(now);
      final currentMinutes = currentTime.hour * 60 + currentTime.minute;

      // Primeiro, procura por horários ainda hoje
      for (final schedule in schedules) {
        if (schedule.dayOfWeek == currentDayOfWeek) {
          final startMinutes = schedule.startTime.hour * 60 + schedule.startTime.minute;
          if (startMinutes > currentMinutes) {
            return schedule;
          }
        }
      }

      // Se não encontrou hoje, procura nos próximos dias
      for (int i = 1; i <= 7; i++) {
        final targetDay = (currentDayOfWeek + i) % 7;
        for (final schedule in schedules) {
          if (schedule.dayOfWeek == targetDay) {
            return schedule;
          }
        }
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  /// Valida se há conflito de horários no mesmo dia
  Future<void> _validateScheduleConflict(
    String driverId,
    int dayOfWeek,
    TimeOfDay startTime,
    TimeOfDay endTime,
  ) async {
    final existingSchedules = await _supabase
        .from('driver_schedules')
        .select()
        .eq('driver_id', driverId)
        .eq('day_of_week', dayOfWeek)
        .eq('is_active', true);

    if (existingSchedules.isEmpty) return;

    final startMinutes = startTime.hour * 60 + startTime.minute;
    final endMinutes = endTime.hour * 60 + endTime.minute;

    for (final scheduleJson in existingSchedules) {
      final schedule = DriverSchedule.fromJson(scheduleJson as Map<String, dynamic>);
      final existingStartMinutes = schedule.startTime.hour * 60 + schedule.startTime.minute;
      final existingEndMinutes = schedule.endTime.hour * 60 + schedule.endTime.minute;

      // Verifica sobreposição
      final hasOverlap = (startMinutes < existingEndMinutes && endMinutes > existingStartMinutes);

      if (hasOverlap) {
        throw ValidationException(
          'Conflito de horário detectado com horário existente: ${schedule.timeRange}',
        );
      }
    }
  }

  /// Cria horários padrão para um motorista (segunda a sexta, 8h às 17h)
  Future<List<DriverSchedule>> createDefaultSchedule(String driverId) async {
    final schedules = <DriverSchedule>[];

    // Segunda a sexta-feira (1-5), das 8h às 17h
    for (int day = 1; day <= 5; day++) {
      try {
        final schedule = await createSchedule(
          driverId: driverId,
          dayOfWeek: day,
          startTime: const TimeOfDay(hour: 8, minute: 0),
          endTime: const TimeOfDay(hour: 17, minute: 0),
        );
        schedules.add(schedule);
      } catch (e) {
        // Se falhar em criar algum horário, continua com os outros
        print('Erro ao criar horário padrão para dia $day: $e');
      }
    }

    return schedules;
  }

  /// Obtém estatísticas dos horários de trabalho
  Future<Map<String, dynamic>> getScheduleStats(String driverId) async {
    try {
      final schedules = await getDriverSchedules(driverId);
      final activeSchedules = schedules.where((s) => s.isActive).toList();

      int totalHoursPerWeek = 0;
      final daysWithSchedule = <int>{};

      for (final schedule in activeSchedules) {
        daysWithSchedule.add(schedule.dayOfWeek);
        
        final startMinutes = schedule.startTime.hour * 60 + schedule.startTime.minute;
        final endMinutes = schedule.endTime.hour * 60 + schedule.endTime.minute;
        
        int workingMinutes;
        if (endMinutes >= startMinutes) {
          workingMinutes = endMinutes - startMinutes;
        } else {
          // Horário que cruza a meia-noite
          workingMinutes = (24 * 60) - startMinutes + endMinutes;
        }
        
        totalHoursPerWeek += workingMinutes;
      }

      return {
        'totalSchedules': schedules.length,
        'activeSchedules': activeSchedules.length,
        'daysWithSchedule': daysWithSchedule.length,
        'totalHoursPerWeek': (totalHoursPerWeek / 60).round(),
        'averageHoursPerDay': daysWithSchedule.isNotEmpty 
            ? ((totalHoursPerWeek / 60) / daysWithSchedule.length).round() 
            : 0,
        'isWorkingNow': await isDriverWorkingNow(driverId),
      };
    } catch (e) {
      return {
        'totalSchedules': 0,
        'activeSchedules': 0,
        'daysWithSchedule': 0,
        'totalHoursPerWeek': 0,
        'averageHoursPerDay': 0,
        'isWorkingNow': false,
        'error': e.toString(),
      };
    }
  }
}