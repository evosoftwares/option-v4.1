import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/supabase/driver_excluded_zone.dart';
import '../exceptions/app_exceptions.dart';
import 'zone_validation_service.dart';

/// Secure service for managing driver excluded zones
/// Addresses all critical security issues identified in the analysis
class SecureDriverExcludedZonesService {
  SecureDriverExcludedZonesService(this._supabase);
  final SupabaseClient _supabase;

  /// Gets the current user ID for audit purposes
  String? get _currentUserId => _supabase.auth.currentUser?.id;

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

  /// Adiciona uma nova zona excluída para o motorista com validação completa
  /// Fixes race condition using upsert and implements all validations
  Future<DriverExcludedZone> addExcludedZone({
    required String driverId,
    required String neighborhoodName,
    required String city,
    required String state,
  }) async {
    try {
      // 1. Validate and normalize data
      final normalizedData = await ZoneValidationService.validateAndNormalizeZoneData(
        neighborhood: neighborhoodName,
        city: city,
        state: state,
      );

      // 2. Check current zone count to enforce limit
      final currentCount = await getExcludedZonesCount(driverId);
      if (ZoneValidationService.hasReachedZoneLimit(currentCount)) {
        throw ValidationException(
          'Limite máximo de zonas excluídas atingido (${ZoneValidationService.maxZonesPerDriver}). '
          'Você tem $currentCount zonas cadastradas.',
        );
      }

      // 3. Use upsert to prevent race conditions
      // The database will handle duplicate prevention via unique constraint
      final insertData = {
        'driver_id': driverId,
        'neighborhood_name': normalizedData['neighborhood_name']!,
        'city': normalizedData['city']!,
        'state': normalizedData['state']!,
        'updated_by': _currentUserId,
      };

      final response = await _supabase
          .from('driver_excluded_zones')
          .upsert(
            insertData,
            onConflict: 'driver_id,neighborhood_name,city,state',
          )
          .select()
          .single();

      final zone = DriverExcludedZone.fromJson(response);
      
      // 4. Log the action for audit
      await _logZoneAction(
        action: 'CREATE',
        driverId: driverId,
        zoneData: insertData,
      );

      return zone;
    } on PostgrestException catch (e) {
      if (e.code == '23505') {
        throw const ValidationException(
          'Esta zona já está na sua lista de exclusões.',
        );
      }
      if (e.code == 'P0001') {
        // Custom validation error from database triggers
        throw ValidationException(e.message);
      }
      throw DatabaseException(
        'Erro ao adicionar zona excluída. Por favor, tente novamente mais tarde.',
        e.code,
      );
    } on ValidationException {
      rethrow;
    } catch (e) {
      throw const DatabaseException(
        'Erro inesperado ao adicionar zona excluída. Por favor, tente novamente mais tarde.',
      );
    }
  }

  /// Adiciona múltiplas zonas excluídas com validação e transação
  Future<List<DriverExcludedZone>> addMultipleExcludedZones({
    required String driverId,
    required List<Map<String, String>> zones,
  }) async {
    if (zones.isEmpty) {
      throw const ValidationException('Lista de zonas não pode estar vazia');
    }

    try {
      // 1. Check total limit before processing
      final currentCount = await getExcludedZonesCount(driverId);
      final totalAfterAdd = currentCount + zones.length;
      
      if (totalAfterAdd > ZoneValidationService.maxZonesPerDriver) {
        final remaining = ZoneValidationService.getRemainingZoneSlots(currentCount);
        throw ValidationException(
          'Adição excederia o limite máximo de ${ZoneValidationService.maxZonesPerDriver} zonas. '
          'Você pode adicionar no máximo $remaining zonas.',
        );
      }

      // 2. Validate and normalize all zones
      final validatedZones = <Map<String, String>>[];
      for (final zone in zones) {
        final normalizedData = await ZoneValidationService.validateAndNormalizeZoneData(
          neighborhood: zone['neighborhoodName'] ?? '',
          city: zone['city'] ?? '',
          state: zone['state'] ?? '',
        );
        
        validatedZones.add({
          'driver_id': driverId,
          'neighborhood_name': normalizedData['neighborhood_name']!,
          'city': normalizedData['city']!,
          'state': normalizedData['state']!,
          'updated_by': _currentUserId ?? '',
        });
      }

      // 3. Insert with upsert to handle duplicates
      final response = await _supabase
          .from('driver_excluded_zones')
          .upsert(
            validatedZones,
            onConflict: 'driver_id,neighborhood_name,city,state',
          )
          .select();

      final addedZones = (response as List<dynamic>)
          .map((json) => DriverExcludedZone.fromJson(json as Map<String, dynamic>))
          .toList();

      // 4. Log the action
      await _logZoneAction(
        action: 'CREATE_MULTIPLE',
        driverId: driverId,
        zoneData: {'zones': validatedZones, 'count': addedZones.length},
      );

      return addedZones;
    } on PostgrestException catch (e) {
      if (e.code == 'P0001') {
        throw ValidationException(e.message);
      }
      throw DatabaseException(
        'Erro ao adicionar zonas excluídas. Por favor, tente novamente mais tarde.',
        e.code,
      );
    } on ValidationException {
      rethrow;
    } catch (e) {
      throw const DatabaseException(
        'Erro inesperado ao adicionar zonas excluídas. Por favor, tente novamente mais tarde.',
      );
    }
  }

  /// Remove uma zona excluída específica com auditoria
  Future<void> removeExcludedZone(String excludedZoneId) async {
    try {
      // First get the zone for logging
      final zoneResponse = await _supabase
          .from('driver_excluded_zones')
          .select()
          .eq('id', excludedZoneId)
          .maybeSingle();

      if (zoneResponse == null) {
        throw const ValidationException('Zona excluída não encontrada');
      }

      await _supabase
          .from('driver_excluded_zones')
          .delete()
          .eq('id', excludedZoneId);

      // Log the deletion
      await _logZoneAction(
        action: 'DELETE',
        driverId: zoneResponse['driver_id'] as String,
        zoneData: zoneResponse,
      );
    } on PostgrestException catch (e) {
      throw DatabaseException(
        'Erro ao remover zona excluída. Por favor, tente novamente mais tarde.',
        e.code,
      );
    } on ValidationException {
      rethrow;
    } catch (e) {
      throw const DatabaseException(
        'Erro inesperado ao remover zona excluída. Por favor, tente novamente mais tarde.',
      );
    }
  }

  /// Remove múltiplas zonas excluídas com validação
  Future<void> removeMultipleExcludedZones(List<String> excludedZoneIds) async {
    if (excludedZoneIds.isEmpty) {
      throw const ValidationException('Lista de zonas não pode estar vazia');
    }

    try {
      // Get zones for logging before deletion
      final zonesResponse = await _supabase
          .from('driver_excluded_zones')
          .select()
          .inFilter('id', excludedZoneIds);

      await _supabase
          .from('driver_excluded_zones')
          .delete()
          .inFilter('id', excludedZoneIds);

      // Log the bulk deletion
      for (final zone in zonesResponse) {
        await _logZoneAction(
          action: 'DELETE',
          driverId: zone['driver_id'] as String,
          zoneData: zone,
        );
      }
    } on PostgrestException catch (e) {
      throw DatabaseException(
        'Erro ao remover zonas excluídas. Por favor, tente novamente mais tarde.',
        e.code,
      );
    } on ValidationException {
      rethrow;
    } catch (e) {
      throw const DatabaseException(
        'Erro inesperado ao remover zonas excluídas. Por favor, tente novamente mais tarde.',
      );
    }
  }

  /// Remove todas as zonas excluídas de um motorista
  Future<void> removeAllExcludedZones(String driverId) async {
    try {
      // Get current zones for logging
      final currentZones = await getDriverExcludedZones(driverId);
      
      await _supabase
          .from('driver_excluded_zones')
          .delete()
          .eq('driver_id', driverId);

      // Log the action
      await _logZoneAction(
        action: 'DELETE_ALL',
        driverId: driverId,
        zoneData: {'removed_count': currentZones.length},
      );
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
  /// Uses normalized comparison for accurate results
  Future<bool> isZoneExcluded({
    required String driverId,
    required String neighborhoodName,
    required String city,
    required String state,
  }) async {
    try {
      // Normalize input for comparison
      final normalizedData = await ZoneValidationService.validateAndNormalizeZoneData(
        neighborhood: neighborhoodName,
        city: city,
        state: state,
      );

      final response = await _supabase
          .from('driver_excluded_zones')
          .select('id')
          .eq('driver_id', driverId)
          .eq('neighborhood_name', normalizedData['neighborhood_name']!)
          .eq('city', normalizedData['city']!)
          .eq('state', normalizedData['state']!)
          .maybeSingle();

      return response != null;
    } on PostgrestException catch (e) {
      throw DatabaseException(
        'Erro ao verificar zona excluída. Por favor, tente novamente mais tarde.',
        e.code,
      );
    } catch (e) {
      // If validation fails, assume zone is not excluded
      return false;
    }
  }

  /// Busca zonas excluídas por cidade
  Future<List<DriverExcludedZone>> getExcludedZonesByCity({
    required String driverId,
    required String city,
    required String state,
  }) async {
    try {
      // Normalize city and state for search
      final normalizedCity = ZoneValidationService.normalizeText(city);
      final normalizedState = ZoneValidationService.validateAndNormalizeState(state);

      final response = await _supabase
          .from('driver_excluded_zones')
          .select()
          .eq('driver_id', driverId)
          .eq('city', normalizedCity)
          .eq('state', normalizedState)
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

      return (response as List).length;
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

  /// Gets zone statistics for a driver
  Future<Map<String, dynamic>> getDriverZoneStats(String driverId) async {
    try {
      final response = await _supabase
          .from('driver_excluded_zones_stats')
          .select()
          .eq('driver_id', driverId)
          .maybeSingle();

      if (response == null) {
        return {
          'total_zones': 0,
          'cities_count': 0,
          'remaining_slots': ZoneValidationService.maxZonesPerDriver,
          'last_zone_added': null,
          'last_modification': null,
        };
      }

      final totalZones = response['total_zones'] as int;
      return {
        ...response,
        'remaining_slots': ZoneValidationService.getRemainingZoneSlots(totalZones),
      };
    } on PostgrestException catch (e) {
      throw DatabaseException(
        'Erro ao buscar estatísticas das zonas. Por favor, tente novamente mais tarde.',
        e.code,
      );
    } catch (e) {
      throw const DatabaseException(
        'Erro inesperado ao buscar estatísticas das zonas. Por favor, tente novamente mais tarde.',
      );
    }
  }

  /// Private method to log zone actions for audit trail
  Future<void> _logZoneAction({
    required String action,
    required String driverId,
    required Map<String, dynamic> zoneData,
    Map<String, dynamic>? oldData,
  }) async {
    try {
      if (_currentUserId == null) return; // Skip logging if no user

      await _supabase.from('activity_logs').insert({
        'user_id': _currentUserId,
        'action': action,
        'entity_type': 'driver_excluded_zone',
        'new_values': zoneData,
        'old_values': oldData,
        'metadata': {
          'timestamp': DateTime.now().toIso8601String(),
          'source': 'mobile_app',
          'driver_id': driverId,
        },
      });
    } catch (e) {
      // Don't throw on logging errors, just continue
      // In production, you might want to log this to a monitoring service
    }
  }
}