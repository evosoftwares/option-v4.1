import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../exceptions/app_exceptions.dart';
import '../models/supabase/working_hours.dart';

/// Serviço para gerenciar horários de trabalho dos motoristas
/// Substitui o DriverScheduleService com funcionalidade simplificada
class WorkingHoursService {
  WorkingHoursService(this._supabase);
  final SupabaseClient _supabase;

  /// Busca todos os horários de trabalho de um motorista
  Future<List<WorkingHours>> getWorkingHours(String driverId) async {
    try {
      final response = await _supabase
          .from('working_hours')
          .select()
          .eq('driver_id', driverId)
          .eq('is_active', true)
          .order('day_of_week', ascending: true)
          .order('start_time', ascending: true);

      return (response as List<dynamic>)
          .map((json) => WorkingHours.fromJson(json as Map<String, dynamic>))
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

  /// Busca horários de trabalho de um dia específico
  Future<List<WorkingHours>> getWorkingHoursByDay(
    String driverId,
    int dayOfWeek,
  ) async {
    try {
      final response = await _supabase
          .from('working_hours')
          .select()
          .eq('driver_id', driverId)
          .eq('day_of_week', dayOfWeek)
          .eq('is_active', true)
          .order('start_time', ascending: true);

      return (response as List<dynamic>)
          .map((json) => WorkingHours.fromJson(json as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      throw DatabaseException(
        'Erro ao buscar horários do dia. Por favor, tente novamente mais tarde.',
        e.code,
      );
    } catch (e) {
      throw const DatabaseException(
        'Erro inesperado ao buscar horários do dia. Por favor, tente novamente mais tarde.',
      );
    }
  }

  /// Cria um novo horário de trabalho
  Future<WorkingHours> createWorkingHours({
    required String driverId,
    required int dayOfWeek,
    required TimeOfDay startTime,
    required TimeOfDay endTime,
  }) async {
    try {
      // Valida se o dia da semana está no range correto (0-6)
      if (dayOfWeek < 0 || dayOfWeek > 6) {
        throw const ValidationException(
          'Dia da semana deve estar entre 0 (domingo) e 6 (sábado).',
        );
      }

      // Valida se não existe conflito de horários
      await _validateTimeConflict(driverId, dayOfWeek, startTime, endTime);

      final insertData = {
        'driver_id': driverId,
        'day_of_week': dayOfWeek,
        'start_time': WorkingHours.formatTimeOfDay(startTime),
        'end_time': WorkingHours.formatTimeOfDay(endTime),
        'is_active': true,
      };

      final response = await _supabase
          .from('working_hours')
          .insert(insertData)
          .select()
          .single();

      return WorkingHours.fromJson(response);
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

  /// Atualiza um horário de trabalho existente
  Future<WorkingHours> updateWorkingHours(
    String id, {
    int? dayOfWeek,
    TimeOfDay? startTime,
    TimeOfDay? endTime,
  }) async {
    try {
      final updates = <String, dynamic>{};

      if (dayOfWeek != null) {
        if (dayOfWeek < 0 || dayOfWeek > 6) {
          throw const ValidationException(
            'Dia da semana deve estar entre 0 (domingo) e 6 (sábado).',
          );
        }
        updates['day_of_week'] = dayOfWeek;
      }

      if (startTime != null) {
        updates['start_time'] = WorkingHours.formatTimeOfDay(startTime);
      }

      if (endTime != null) {
        updates['end_time'] = WorkingHours.formatTimeOfDay(endTime);
      }

      if (updates.isEmpty) {
        throw const ValidationException('Nenhum campo para atualizar foi fornecido.');
      }

      // Se está atualizando horários, valida conflitos
      if (dayOfWeek != null || startTime != null || endTime != null) {
        // Busca o registro atual para validação
        final current = await _getWorkingHoursById(id);
        final finalDayOfWeek = dayOfWeek ?? current.dayOfWeek;
        final finalStartTime = startTime ?? current.parseStartTime();
        final finalEndTime = endTime ?? current.parseEndTime();

        await _validateTimeConflict(
          current.driverId,
          finalDayOfWeek,
          finalStartTime,
          finalEndTime,
          excludeId: id,
        );
      }

      final response = await _supabase
          .from('working_hours')
          .update(updates)
          .eq('id', id)
          .select()
          .single();

      return WorkingHours.fromJson(response);
    } on PostgrestException catch (e) {
      throw DatabaseException(
        'Erro ao atualizar horário de trabalho. Por favor, tente novamente mais tarde.',
        e.code,
      );
    } catch (e) {
      if (e is ValidationException) rethrow;
      throw const DatabaseException(
        'Erro inesperado ao atualizar horário de trabalho. Por favor, tente novamente mais tarde.',
      );
    }
  }

  /// Remove um horário de trabalho
  Future<void> deleteWorkingHours(String id) async {
    try {
      await _supabase.from('working_hours').delete().eq('id', id);
    } on PostgrestException catch (e) {
      throw DatabaseException(
        'Erro ao remover horário de trabalho. Por favor, tente novamente mais tarde.',
        e.code,
      );
    } catch (e) {
      throw const DatabaseException(
        'Erro inesperado ao remover horário de trabalho. Por favor, tente novamente mais tarde.',
      );
    }
  }

  /// Desativa todos os horários de trabalho de um motorista
  Future<void> deactivateAllWorkingHours(String driverId) async {
    try {
      await _supabase
          .from('working_hours')
          .update({'is_active': false})
          .eq('driver_id', driverId)
          .eq('is_active', true);
    } on PostgrestException catch (e) {
      throw DatabaseException(
        'Erro ao desativar horários de trabalho. Por favor, tente novamente mais tarde.',
        e.code,
      );
    } catch (e) {
      throw const DatabaseException(
        'Erro inesperado ao desativar horários de trabalho. Por favor, tente novamente mais tarde.',
      );
    }
  }

  /// Remove todos os horários de trabalho de um motorista (método mantido para compatibilidade)
  Future<void> deleteAllWorkingHours(String driverId) async {
    await deactivateAllWorkingHours(driverId);
  }

  /// Verifica se o motorista está trabalhando agora baseado nos horários cadastrados
  Future<bool> isDriverWorkingNow(String driverId) async {
    try {
      final now = DateTime.now();
      final dayOfWeek = now.weekday % 7; // Converte para 0=domingo
      final currentTime = TimeOfDay.fromDateTime(now);

      final todayHours = await getWorkingHoursByDay(driverId, dayOfWeek);

      // Se não tem horários definidos, considera sempre disponível
      if (todayHours.isEmpty) {
        return true;
      }

      // Verifica se está dentro de algum intervalo
      for (final hours in todayHours) {
        if (hours.isWorkingNow()) {
          return true;
        }
      }

      return false;
    } catch (e) {
      // Em caso de erro, assume que está trabalhando para não bloquear
      return true;
    }
  }

  /// Busca um horário de trabalho por ID (método privado)
  Future<WorkingHours> _getWorkingHoursById(String id) async {
    final response = await _supabase
        .from('working_hours')
        .select()
        .eq('id', id)
        .single();

    return WorkingHours.fromJson(response);
  }

  /// Converte TimeOfDay para minutos desde meia-noite
  int _timeOfDayToMinutes(TimeOfDay time) {
    return time.hour * 60 + time.minute;
  }

  /// Verifica se dois intervalos de tempo se sobrepõem
  bool _hasTimeOverlap(
    TimeOfDay start1,
    TimeOfDay end1,
    TimeOfDay start2,
    TimeOfDay end2,
  ) {
    final start1Minutes = _timeOfDayToMinutes(start1);
    final end1Minutes = _timeOfDayToMinutes(end1);
    final start2Minutes = _timeOfDayToMinutes(start2);
    final end2Minutes = _timeOfDayToMinutes(end2);

    // Verifica sobreposição simples (sem cruzar meia-noite)
    // Dois intervalos se sobrepõem se:
    // - O início de um está antes do fim do outro E
    // - O início do outro está antes do fim do primeiro
    return (start1Minutes < end2Minutes) && (start2Minutes < end1Minutes);
  }

  /// Valida se há conflito de horários para o mesmo motorista e dia
  Future<void> _validateTimeConflict(
    String driverId,
    int dayOfWeek,
    TimeOfDay startTime,
    TimeOfDay endTime, {
    String? excludeId,
  }) async {
    // Validação básica: horário de início deve ser menor que horário de fim
    if (_timeOfDayToMinutes(startTime) >= _timeOfDayToMinutes(endTime)) {
      throw ValidationException(
        'Horário de início deve ser anterior ao horário de fim.',
      );
    }

    // Busca horários existentes para o mesmo dia
    final existingHours = await getWorkingHoursByDay(driverId, dayOfWeek);

    // Remove o horário atual da validação se estiver atualizando
    final hoursToCheck = excludeId != null
        ? existingHours.where((h) => h.id != excludeId).toList()
        : existingHours;

    for (final existing in hoursToCheck) {
      final existingStart = existing.parseStartTime();
      final existingEnd = existing.parseEndTime();

      // Verifica sobreposição de horários
      if (_hasTimeOverlap(
        startTime,
        endTime,
        existingStart,
        existingEnd,
      )) {
        throw ValidationException(
          'Conflito de horários detectado. O horário ${WorkingHours.formatTimeOfDay(startTime)} - ${WorkingHours.formatTimeOfDay(endTime)} '
          'sobrepõe com o horário existente ${existing.startTime} - ${existing.endTime}.',
        );
      }
    }
  }
}