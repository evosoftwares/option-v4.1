import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/supabase/driver_excluded_zone.dart';
import '../exceptions/app_exceptions.dart';

class DriverExcludedZonesService {
  DriverExcludedZonesService(this._supabase);
  final SupabaseClient _supabase;

  /// Busca todas as zonas excluídas de um motorista
  Future<List<DriverExcludedZone>> getDriverExcludedZones(String driverId) async {
    try {
      final response = await _supabase
          .from('driver_excluded_zones')
          .select()
          .eq('driver_id', driverId)
          .order('created_at', ascending: false);

      return (response as List<dynamic>)
          .map((json) => DriverExcludedZone.fromJson(json as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      throw DatabaseException(
        'Erro ao buscar zonas excluídas. Por favor, tente novamente mais tarde.',
        e.code,
      );
    } catch (e) {
      throw const DatabaseException(
        'Erro inesperado ao buscar zonas excluídas. Por favor, tente novamente mais tarde.',
      );
    }
  }

  /// Adiciona uma nova zona excluída para o motorista
  Future<DriverExcludedZone> addExcludedZone({
    required String driverId,
    required String neighborhoodName,
    required String city,
    required String state,
  }) async {
    try {
      // Verifica se a zona já existe para este motorista
      final existing = await _supabase
          .from('driver_excluded_zones')
          .select()
          .eq('driver_id', driverId)
          .eq('neighborhood_name', neighborhoodName)
          .eq('city', city)
          .eq('state', state)
          .maybeSingle();

      if (existing != null) {
        throw const DatabaseException(
          'Esta zona já está na sua lista de exclusões.',
        );
      }

      final insertData = {
        'driver_id': driverId,
        'neighborhood_name': neighborhoodName,
        'city': city,
        'state': state,
      };

      final response = await _supabase
          .from('driver_excluded_zones')
          .insert(insertData)
          .select()
          .single();

      return DriverExcludedZone.fromJson(response);
    } on PostgrestException catch (e) {
      if (e.code == '23505') {
        throw const DatabaseException(
          'Esta zona já está na sua lista de exclusões.',
        );
      }
      throw DatabaseException(
        'Erro ao adicionar zona excluída. Por favor, tente novamente mais tarde.',
        e.code,
      );
    } catch (e) {
      if (e is DatabaseException) rethrow;
      throw const DatabaseException(
        'Erro inesperado ao adicionar zona excluída. Por favor, tente novamente mais tarde.',
      );
    }
  }

  /// Adiciona múltiplas zonas excluídas para o motorista
  Future<List<DriverExcludedZone>> addMultipleExcludedZones({
    required String driverId,
    required List<Map<String, String>> zones,
  }) async {
    try {
      final insertData = zones.map((zone) => {
        'driver_id': driverId,
        'neighborhood_name': zone['neighborhoodName']!,
        'city': zone['city']!,
        'state': zone['state']!,
      }).toList();

      final response = await _supabase
          .from('driver_excluded_zones')
          .insert(insertData)
          .select();

      return (response as List<dynamic>)
          .map((json) => DriverExcludedZone.fromJson(json as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      throw DatabaseException(
        'Erro ao adicionar zonas excluídas. Por favor, tente novamente mais tarde.',
        e.code,
      );
    } catch (e) {
      throw const DatabaseException(
        'Erro inesperado ao adicionar zonas excluídas. Por favor, tente novamente mais tarde.',
      );
    }
  }

  /// Remove uma zona excluída específica
  Future<void> removeExcludedZone(String excludedZoneId) async {
    try {
      await _supabase
          .from('driver_excluded_zones')
          .delete()
          .eq('id', excludedZoneId);
    } on PostgrestException catch (e) {
      throw DatabaseException(
        'Erro ao remover zona excluída. Por favor, tente novamente mais tarde.',
        e.code,
      );
    } catch (e) {
      throw const DatabaseException(
        'Erro inesperado ao remover zona excluída. Por favor, tente novamente mais tarde.',
      );
    }
  }

  /// Remove múltiplas zonas excluídas
  Future<void> removeMultipleExcludedZones(List<String> excludedZoneIds) async {
    try {
      await _supabase
          .from('driver_excluded_zones')
          .delete()
          .inFilter('id', excludedZoneIds);
    } on PostgrestException catch (e) {
      throw DatabaseException(
        'Erro ao remover zonas excluídas. Por favor, tente novamente mais tarde.',
        e.code,
      );
    } catch (e) {
      throw const DatabaseException(
        'Erro inesperado ao remover zonas excluídas. Por favor, tente novamente mais tarde.',
      );
    }
  }

  /// Remove todas as zonas excluídas de um motorista
  Future<void> removeAllExcludedZones(String driverId) async {
    try {
      await _supabase
          .from('driver_excluded_zones')
          .delete()
          .eq('driver_id', driverId);
    } on PostgrestException catch (e) {
      throw DatabaseException(
        'Erro ao remover todas as zonas excluídas. Por favor, tente novamente mais tarde.',
        e.code,
      );
    } catch (e) {
      throw const DatabaseException(
        'Erro inesperado ao remover todas as zonas excluídas. Por favor, tente novamente mais tarde.',
      );
    }
  }

  /// Verifica se um bairro específico está na lista de exclusões do motorista
  Future<bool> isZoneExcluded({
    required String driverId,
    required String neighborhoodName,
    required String city,
    required String state,
  }) async {
    try {
      final response = await _supabase
          .from('driver_excluded_zones')
          .select('id')
          .eq('driver_id', driverId)
          .eq('neighborhood_name', neighborhoodName)
          .eq('city', city)
          .eq('state', state)
          .maybeSingle();

      return response != null;
    } on PostgrestException catch (e) {
      throw DatabaseException(
        'Erro ao verificar zona excluída. Por favor, tente novamente mais tarde.',
        e.code,
      );
    } catch (e) {
      throw const DatabaseException(
        'Erro inesperado ao verificar zona excluída. Por favor, tente novamente mais tarde.',
      );
    }
  }

  /// Busca zonas excluídas por cidade
  Future<List<DriverExcludedZone>> getExcludedZonesByCity({
    required String driverId,
    required String city,
    required String state,
  }) async {
    try {
      final response = await _supabase
          .from('driver_excluded_zones')
          .select()
          .eq('driver_id', driverId)
          .eq('city', city)
          .eq('state', state)
          .order('neighborhood_name', ascending: true);

      return (response as List<dynamic>)
          .map((json) => DriverExcludedZone.fromJson(json as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      throw DatabaseException(
        'Erro ao buscar zonas excluídas por cidade. Por favor, tente novamente mais tarde.',
        e.code,
      );
    } catch (e) {
      throw const DatabaseException(
        'Erro inesperado ao buscar zonas excluídas por cidade. Por favor, tente novamente mais tarde.',
      );
    }
  }

  /// Conta o total de zonas excluídas de um motorista
  Future<int> getExcludedZonesCount(String driverId) async {
    try {
      final response = await _supabase
          .from('driver_excluded_zones')
          .select('id')
          .eq('driver_id', driverId);

      return (response as List<dynamic>).length;
    } on PostgrestException catch (e) {
      throw DatabaseException(
        'Erro ao contar zonas excluídas. Por favor, tente novamente mais tarde.',
        e.code,
      );
    } catch (e) {
      throw const DatabaseException(
        'Erro inesperado ao contar zonas excluídas. Por favor, tente novamente mais tarde.',
      );
    }
  }
}