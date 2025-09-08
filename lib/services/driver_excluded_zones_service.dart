import 'package:supabase_flutter/supabase_flutter.dart';

import '../exceptions/app_exceptions.dart';
import '../models/supabase/driver_excluded_zone.dart';
import '../utils/data_normalization_utils.dart';
import 'geographic_validation_service.dart';
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

  /// Adiciona uma nova zona excluída com palavra-chave flexível
  Future<DriverExcludedZone> addExcludedZoneByKeyword({
    required String driverId,
    required String keyword,
    required String zoneType, // 'rua', 'bairro', 'cidade', 'estado', 'regiao'
    String? city,
    String? state,
    String? reason,
  }) async => TransactionService.executeWithRetry(
      () async {
        // Valida palavra-chave
        if (keyword.trim().length < 2) {
          throw const ValidationException(
            'Palavra-chave deve ter pelo menos 2 caracteres.',
          );
        }
        
        // Valida tipo de zona
        const validTypes = ['rua', 'bairro', 'cidade', 'estado', 'regiao'];
        if (!validTypes.contains(zoneType.toLowerCase())) {
          throw ValidationException(
            'Tipo de zona inválido. Use: ${validTypes.join(', ')}',
          );
        }

        // Normaliza a palavra-chave
        final normalizedKeyword = DataNormalizationUtils.normalizeNeighborhoodName(keyword);
        final normalizedCity = city != null ? DataNormalizationUtils.normalizeCityName(city) : null;
        final normalizedState = state != null ? DataNormalizationUtils.normalizeStateName(state) : null;
        final normalizedReason = reason != null ? DataNormalizationUtils.normalizeReason(reason) : null;
        
        // Verifica se o motorista existe
        final driverExists = await _supabase
            .from('drivers')
            .select('id')
            .eq('id', driverId)
            .maybeSingle();
        
        if (driverExists == null) {
          throw const ValidationException(
            'Não foi possível adicionar zona excluída: motorista não encontrado.',
          );
        }
        
        // Verifica limite de zonas
        await _zoneLimitService.validateAndEnforceLimit(driverId, 1);
        
        // Verifica se a palavra-chave já existe para este motorista
        final existing = await _supabase
            .from('driver_excluded_zones')
            .select()
            .eq('driver_id', driverId)
            .eq('keyword', normalizedKeyword)
            .maybeSingle();

        if (existing != null) {
          throw ValidationException(
            'Palavra-chave "$normalizedKeyword" já está na sua lista de exclusões.',
          );
        }

        final insertData = {
          'driver_id': driverId,
          'keyword': normalizedKeyword,
          'zone_type': zoneType.toLowerCase(),
          'neighborhood_name': normalizedKeyword, // Manter compatibilidade
          'city': normalizedCity ?? 'N/A',
          'state': normalizedState ?? 'N/A',
          if (normalizedReason != null) 'reason': normalizedReason,
        };

        final response = await _supabase
            .from('driver_excluded_zones')
            .insert(insertData)
            .select()
            .single();

        return DriverExcludedZone.fromJson(response);
      },
      operationName: 'addExcludedZoneByKeyword',
    );

  /// Método legado: Adiciona zona por bairro exato (mantido para compatibilidade)
  Future<DriverExcludedZone> addExcludedZone({
    required String driverId,
    required String neighborhoodName,
    required String city,
    required String state,
    String? reason,
    bool fromGooglePlaces = false,
  }) async => TransactionService.executeWithRetry(
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
            'Dados de localização inválidos: ${locationValidation.errors.join(', ')}',
          );
        }
        
        // Valida geograficamente
        final geoValidation = await GeographicValidationService.validateCity(
          normalizedCity,
          normalizedState,
        );
        
        if (!geoValidation) {
          throw ValidationException(
            'Localização não encontrada: $normalizedCity, $normalizedState',
          );
        }
        
        // Verifica se o motorista existe
        final driverExists = await _supabase
            .from('drivers')
            .select('id')
            .eq('id', driverId)
            .maybeSingle();
        
        if (driverExists == null) {
          throw const ValidationException(
            'Não foi possível adicionar zona excluída: motorista não encontrado. '
            'Por favor, verifique se você está logado como motorista.',
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
          'keyword': normalizedNeighborhood, // Migrar para sistema de palavra-chave
          'zone_type': 'bairro', // Tipo padrão para sistema legado
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

  /// Método melhorado: Adiciona zona com tipo específico escolhido pelo usuário
  Future<DriverExcludedZone> addExcludedZoneWithType({
    required String driverId,
    required String keyword,
    required String zoneType,
    String? city,
    String? state,
    String? reason,
  }) async {
    return addExcludedZoneByKeyword(
      driverId: driverId,
      keyword: keyword,
      zoneType: zoneType,
      city: city,
      state: state,
      reason: reason,
    );
  }

  /// Adiciona múltiplas zonas excluídas para o motorista
  Future<List<DriverExcludedZone>> addMultipleExcludedZones({
    required String driverId,
    required List<Map<String, String>> zones,
  }) async => TransactionService.executeWithRetry(
      () async {
        // Verifica se o motorista existe
        final driverExists = await _supabase
            .from('drivers')
            .select('id')
            .eq('id', driverId)
            .maybeSingle();
        
        if (driverExists == null) {
          throw const ValidationException(
            'Não foi possível adicionar zonas excluídas: motorista não encontrado. '
            'Por favor, verifique se você está logado como motorista.',
          );
        }
        
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
               'Dados inválidos para ${zone['neighborhoodName']}: ${locationValidation.errors.join(', ')}',
             );
           }
           
           // Valida geograficamente
           final geoValidation = await GeographicValidationService.validateCity(
             normalizedCity,
             normalizedState,
           );
           
           if (!geoValidation) {
             throw ValidationException(
               'Localização não encontrada para ${zone['city']}, ${zone['state']}',
             );
           }
          
          normalizedZones.add({
            'driver_id': driverId,
            'keyword': normalizedNeighborhood, // Sistema de palavra-chave
            'zone_type': 'bairro', // Tipo padrão para lote legado
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

  /// Verifica se um endereço está excluído pelo motorista (sistema flexível)
  Future<bool> isAddressExcluded({
    required String driverId,
    required String fullAddress,
  }) async {
    try {
      // Usar função SQL para verificação flexível
      final response = await _supabase
          .rpc('check_address_exclusion', params: {
            'driver_id_param': driverId,
            'full_address': fullAddress,
          });

      return response as bool? ?? false;
    } on PostgrestException catch (e) {
      throw DatabaseException(
        'Erro ao verificar zona excluída. Por favor, tente novamente mais tarde.',
        e.code,
      );
    } catch (e) {
      // Fallback para sistema legado
      return await _isZoneExcludedLegacy(
        driverId: driverId,
        fullAddress: fullAddress,
      );
    }
  }

  /// Verifica se um bairro específico está na lista de exclusões do motorista (legado)
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

  /// Fallback para sistema legado (busca por palavras-chave manualmente)
  Future<bool> _isZoneExcludedLegacy({
    required String driverId,
    required String fullAddress,
  }) async {
    try {
      final zones = await getDriverExcludedZones(driverId);
      final lowerAddress = fullAddress.toLowerCase();
      
      // Verifica se alguma palavra-chave ou bairro está contido no endereço
      for (final zone in zones) {
        // Verifica palavra-chave (sistema novo)
        if (zone.keyword != null && 
            lowerAddress.contains(zone.keyword!.toLowerCase())) {
          return true;
        }
        
        // Verifica bairro (sistema legado)
        if (lowerAddress.contains(zone.neighborhoodName.toLowerCase())) {
          return true;
        }
      }
      
      return false;
    } catch (e) {
      // Em caso de erro, assume que não está excluído
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