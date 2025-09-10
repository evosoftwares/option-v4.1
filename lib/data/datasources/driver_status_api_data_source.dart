import 'package:supabase_flutter/supabase_flutter.dart';

/// Data Source responsável apenas pelo acesso aos dados de status do motorista
/// Não contém lógica de negócio, apenas operações de acesso aos dados
class DriverStatusApiDataSource {
  final SupabaseClient _supabase;

  DriverStatusApiDataSource(this._supabase);

  /// Busca o status de intenção online do motorista
  Future<Map<String, dynamic>?> getDriverStatus(String driverId) async {
    final response = await _supabase
        .from('driver_status')
        .select()
        .eq('driver_id', driverId)
        .maybeSingle();

    return response;
  }

  /// Busca o status efetivo do motorista (da view)
  Future<Map<String, dynamic>?> getDriverEffectiveStatus(String driverId) async {
    final response = await _supabase
        .from('driver_effective_status')
        .select()
        .eq('driver_id', driverId)
        .maybeSingle();

    return response;
  }

  /// Atualiza a intenção online do motorista
  Future<Map<String, dynamic>> updateOnlineIntent(
    String driverId,
    bool onlineIntent,
  ) async {
    final data = {
      'driver_id': driverId,
      'online_intent': onlineIntent,
    };

    final response = await _supabase
        .from('driver_status')
        .upsert(data)
        .select()
        .single();

    return response;
  }

  /// Busca dados do motorista para verificação de aprovação
  Future<Map<String, dynamic>?> getDriverApprovalStatus(String driverId) async {
    final response = await _supabase
        .from('drivers')
        .select('approval_status')
        .eq('id', driverId)
        .maybeSingle();

    return response;
  }

  /// Busca documentos do motorista
  Future<List<Map<String, dynamic>>> getDriverDocuments(String driverId) async {
    final response = await _supabase
        .from('driver_documents')
        .select('document_type, status')
        .eq('driver_id', driverId)
        .eq('is_current', true);

    return List<Map<String, dynamic>>.from(response);
  }

  /// Busca todos os motoristas efetivamente online
  Future<List<Map<String, dynamic>>> getOnlineDrivers() async {
    final response = await _supabase
        .from('driver_effective_status')
        .select()
        .eq('effective_online', true)
        .order('intent_updated_at', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }

  /// Busca motoristas com intenção online mas fora do horário
  Future<List<Map<String, dynamic>>> getDriversWithIntentButOffline() async {
    final response = await _supabase
        .from('driver_effective_status')
        .select()
        .eq('online_intent', true)
        .eq('effective_online', false)
        .order('intent_updated_at', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }

  /// Remove o status do motorista
  Future<void> deleteDriverStatus(String driverId) async {
    await _supabase
        .from('driver_status')
        .delete()
        .eq('driver_id', driverId);
  }

  /// Busca estatísticas de status dos motoristas
  Future<List<Map<String, dynamic>>> getDriverStatusStats() async {
    final response = await _supabase
        .from('driver_effective_status')
        .select('online_intent, effective_online');

    return List<Map<String, dynamic>>.from(response);
  }

  /// Atualiza timestamp da última notificação do motorista
  Future<void> updateLastNotificationAt(String driverId) async {
    await _supabase
        .from('drivers')
        .update({'last_notification_at': DateTime.now().toIso8601String()})
        .eq('id', driverId);
  }
}