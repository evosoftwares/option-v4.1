import 'package:supabase_flutter/supabase_flutter.dart';

import '../exceptions/app_exceptions.dart';
import '../models/supabase/driver_status.dart';
import '../models/supabase/driver_effective_status.dart';

/// Serviço para gerenciar o status online dos motoristas
/// Separa a intenção (toggle) do status efetivo (calculado pela view)
class DriverStatusService {
  DriverStatusService(this._supabase);
  final SupabaseClient _supabase;

  /// Busca o status de intenção online do motorista
  Future<DriverStatus?> getDriverStatus(String driverId) async {
    try {
      final response = await _supabase
          .from('driver_status')
          .select()
          .eq('driver_id', driverId)
          .maybeSingle();

      if (response == null) return null;
      return DriverStatus.fromJson(response);
    } on PostgrestException catch (e) {
      throw DatabaseException(
        'Erro ao buscar status do motorista. Por favor, tente novamente mais tarde.',
        e.code,
      );
    } catch (e) {
      throw const DatabaseException(
        'Erro inesperado ao buscar status do motorista. Por favor, tente novamente mais tarde.',
      );
    }
  }

  /// Busca o status efetivo do motorista (da view)
  Future<DriverEffectiveStatus?> getDriverEffectiveStatus(String driverId) async {
    try {
      final response = await _supabase
          .from('driver_effective_status')
          .select()
          .eq('driver_id', driverId)
          .maybeSingle();

      if (response == null) return null;
      return DriverEffectiveStatus.fromJson(response);
    } on PostgrestException catch (e) {
      throw DatabaseException(
        'Erro ao buscar status efetivo do motorista. Por favor, tente novamente mais tarde.',
        e.code,
      );
    } catch (e) {
      throw const DatabaseException(
        'Erro inesperado ao buscar status efetivo do motorista. Por favor, tente novamente mais tarde.',
      );
    }
  }

  /// Atualiza a intenção online do motorista
  Future<DriverStatus> updateOnlineIntent(
    String driverId,
    bool onlineIntent,
  ) async {
    try {
      final data = {
        'driver_id': driverId,
        'online_intent': onlineIntent,
      };

      final response = await _supabase
          .from('driver_status')
          .upsert(data)
          .select()
          .single();

      return DriverStatus.fromJson(response);
    } on PostgrestException catch (e) {
      throw DatabaseException(
        'Erro ao atualizar status online. Por favor, tente novamente mais tarde.',
        e.code,
      );
    } catch (e) {
      throw const DatabaseException(
        'Erro inesperado ao atualizar status online. Por favor, tente novamente mais tarde.',
      );
    }
  }

  /// Cria ou atualiza o status do motorista
  Future<DriverStatus> createOrUpdateDriverStatus({
    required String driverId,
    required bool onlineIntent,
  }) async {
    return updateOnlineIntent(driverId, onlineIntent);
  }

  /// Liga o motorista (define intenção como true)
  Future<DriverStatus> setDriverOnline(String driverId) async {
    return updateOnlineIntent(driverId, true);
  }

  /// Desliga o motorista (define intenção como false)
  Future<DriverStatus> setDriverOffline(String driverId) async {
    return updateOnlineIntent(driverId, false);
  }

  /// Verifica se o motorista pode ficar online agora
  /// (está dentro dos horários de trabalho)
  Future<bool> canDriverGoOnlineNow(String driverId) async {
    try {
      final effectiveStatus = await getDriverEffectiveStatus(driverId);
      
      // Se não tem status, assume que pode (sem horários definidos)
      if (effectiveStatus == null) return true;
      
      // Retorna se está dentro dos horários de trabalho
      return effectiveStatus.isWithinWorkingHours;
    } catch (e) {
      // Em caso de erro, assume que pode para não bloquear
      return true;
    }
  }

  /// Busca todos os motoristas efetivamente online
  Future<List<DriverEffectiveStatus>> getOnlineDrivers() async {
    try {
      final response = await _supabase
          .from('driver_effective_status')
          .select()
          .eq('effective_online', true)
          .order('intent_updated_at', ascending: false);

      return (response as List<dynamic>)
          .map((json) => DriverEffectiveStatus.fromJson(json as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      throw DatabaseException(
        'Erro ao buscar motoristas online. Por favor, tente novamente mais tarde.',
        e.code,
      );
    } catch (e) {
      throw const DatabaseException(
        'Erro inesperado ao buscar motoristas online. Por favor, tente novamente mais tarde.',
      );
    }
  }

  /// Busca motoristas com intenção online mas fora do horário
  Future<List<DriverEffectiveStatus>> getDriversWithIntentButOffline() async {
    try {
      final response = await _supabase
          .from('driver_effective_status')
          .select()
          .eq('online_intent', true)
          .eq('effective_online', false)
          .order('intent_updated_at', ascending: false);

      return (response as List<dynamic>)
          .map((json) => DriverEffectiveStatus.fromJson(json as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      throw DatabaseException(
        'Erro ao buscar motoristas com intenção online. Por favor, tente novamente mais tarde.',
        e.code,
      );
    } catch (e) {
      throw const DatabaseException(
        'Erro inesperado ao buscar motoristas com intenção online. Por favor, tente novamente mais tarde.',
      );
    }
  }

  /// Remove o status do motorista (usado quando motorista é excluído)
  Future<void> deleteDriverStatus(String driverId) async {
    try {
      await _supabase
          .from('driver_status')
          .delete()
          .eq('driver_id', driverId);
    } on PostgrestException catch (e) {
      throw DatabaseException(
        'Erro ao remover status do motorista. Por favor, tente novamente mais tarde.',
        e.code,
      );
    } catch (e) {
      throw const DatabaseException(
        'Erro inesperado ao remover status do motorista. Por favor, tente novamente mais tarde.',
      );
    }
  }

  /// Inicializa o status do motorista (usado quando motorista é criado)
  Future<DriverStatus> initializeDriverStatus(
    String driverId, {
    bool initialOnlineIntent = false,
  }) async {
    return createOrUpdateDriverStatus(
      driverId: driverId,
      onlineIntent: initialOnlineIntent,
    );
  }

  /// Busca estatísticas de status dos motoristas
  Future<Map<String, int>> getDriverStatusStats() async {
    try {
      final response = await _supabase
          .from('driver_effective_status')
          .select('online_intent, effective_online');

      int totalDrivers = 0;
      int withIntent = 0;
      int effectivelyOnline = 0;
      int intentButOffline = 0;

      for (final row in response as List<dynamic>) {
        totalDrivers++;
        final intent = row['online_intent'] as bool;
        final effective = row['effective_online'] as bool;

        if (intent) withIntent++;
        if (effective) effectivelyOnline++;
        if (intent && !effective) intentButOffline++;
      }

      return {
        'total_drivers': totalDrivers,
        'with_intent': withIntent,
        'effectively_online': effectivelyOnline,
        'intent_but_offline': intentButOffline,
        'offline': totalDrivers - withIntent,
      };
    } on PostgrestException catch (e) {
      throw DatabaseException(
        'Erro ao buscar estatísticas de status. Por favor, tente novamente mais tarde.',
        e.code,
      );
    } catch (e) {
      throw const DatabaseException(
        'Erro inesperado ao buscar estatísticas de status. Por favor, tente novamente mais tarde.',
      );
    }
  }
}