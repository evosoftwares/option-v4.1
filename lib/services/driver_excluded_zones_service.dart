import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/supabase/driver_excluded_zone.dart';
import '../exceptions/app_exceptions.dart';
import 'geographic_validation_service.dart';
import '../utils/data_normalization_utils.dart';
import 'transaction_service.dart';
import 'zone_limit_service.dart';

class DriverExcludedZonesService {
  DriverExcludedZonesService(this._supabase);
  final SupabaseClient _supabase;
  final GeographicValidationService _geoValidationService = GeographicValidationService();
  final ZoneLimitService _zoneLimitService = ZoneLimitService();

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
    String? reason,
  }) async {
    return await TransactionService.executeWithRetry(
      () async {
        // Normaliza os dados de entrada
        final normalizedNeighborhood = DataNormalizationUtils.normalizeNeighborhoodName(neighborhoodName);
        final normalizedCity = DataNormalizationUtils.normalizeCityName(city);
        final normalizedState = DataNormalizationUtils.normalizeStateName(state);
        final normalizedReason = reason != null ? DataNormalizationUtils.normalizeReason(reason) : null;
        
        // Valida os dados normalizados
        final locationValidation = DataNormalizationUtils.validateAddress(
          neighborhood: normalizedNeighborhood,
          city: normalizedCity,
          state: normalizedState,
          reason: normalizedReason,
        );
        
        if (!locationValidation.isValid) {
          throw ValidationException(
            'Dados de localização inválidos: ${locationValidation.errors.join(', ')}'
          );
        }
        
        // Valida geograficamente
        final geoValidation = await GeographicValidationService.validateCity(
          normalizedCity,
          normalizedState,
        );
        
        if (!geoValidation) {
          throw ValidationException(
            'Localização não encontrada: ${normalizedCity}, ${normalizedState}'
          );
        }
        
        // Verifica limite de zonas
        await _zoneLimitService.validateAndEnforceLimit(driverId, 1);
        
        // Verifica se a zona já existe para este motorista
        final existing = await _supabase
            .from('driver_excluded_zones')
            .select()
            .eq('driver_id', driverId)
            .eq('neighborhood_name', normalizedNeighborhood)
            .eq('city', normalizedCity)
            .eq('state', normalizedState)
            .maybeSingle();

        if (existing != null) {
          throw const ValidationException(
            'Esta zona já está na sua lista de exclusões.',
          );
        }

        final insertData = {
          'driver_id': driverId,
          'neighborhood_name': normalizedNeighborhood,
          'city': normalizedCity,
          'state': normalizedState,
          if (normalizedReason != null) 'reason': normalizedReason,
        };

        final response = await _supabase
            .from('driver_excluded_zones')
            .insert(insertData)
            .select()
            .single();

        return DriverExcludedZone.fromJson(response);
      },
      operationName: 'addExcludedZone',
    );
  }

  /// Adiciona múltiplas zonas excluídas para o motorista
  Future<List<DriverExcludedZone>> addMultipleExcludedZones({
    required String driverId,
    required List<Map<String, String>> zones,
  }) async {
    return await TransactionService.executeWithRetry(
      () async {
        // Verifica limite antes de processar
        await _zoneLimitService.validateAndEnforceLimit(driverId, zones.length);
        
        final normalizedZones = <Map<String, dynamic>>[];
        
        // Normaliza e valida cada zona
         for (final zone in zones) {
           final normalizedNeighborhood = DataNormalizationUtils.normalizeNeighborhoodName(zone['neighborhoodName']!);
           final normalizedCity = DataNormalizationUtils.normalizeCityName(zone['city']!);
           final normalizedState = DataNormalizationUtils.normalizeStateName(zone['state']!);
           final normalizedReason = zone['reason'] != null ? DataNormalizationUtils.normalizeReason(zone['reason']!) : null;
           
           // Valida dados
           final locationValidation = DataNormalizationUtils.validateAddress(
             neighborhood: normalizedNeighborhood,
             city: normalizedCity,
             state: normalizedState,
             reason: normalizedReason,
           );
           
           if (!locationValidation.isValid) {
             throw ValidationException(
               'Dados inválidos para ${zone['neighborhoodName']}: ${locationValidation.errors.join(', ')}'
             );
           }
           
           // Valida geograficamente
           final geoValidation = await GeographicValidationService.validateCity(
             normalizedCity,
             normalizedState,
           );
           
           if (!geoValidation) {
             throw ValidationException(
               'Localização não encontrada para ${zone['city']}, ${zone['state']}'
             );
           }
          
          normalizedZones.add({
            'driver_id': driverId,
            'neighborhood_name': normalizedNeighborhood,
            'city': normalizedCity,
            'state': normalizedState,
            if (normalizedReason != null) 'reason': normalizedReason,
          });
        }
        
        final response = await _supabase
            .from('driver_excluded_zones')
            .insert(normalizedZones)
            .select();

        return (response as List<dynamic>)
            .map((json) => DriverExcludedZone.fromJson(json as Map<String, dynamic>))
            .toList();
      },
      operationName: 'addMultipleExcludedZones',
    );
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