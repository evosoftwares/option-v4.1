import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/supabase/driver_excluded_zone.dart';
import '../exceptions/app_exceptions.dart';
import '../utils/data_normalization_utils.dart';
import 'geographic_validation_service.dart';
import 'transaction_service.dart';
import 'zone_limit_service.dart';

/// Serviço aprimorado para gerenciar zonas excluídas de motoristas
/// Inclui validações geográficas, normalização de dados e controle de concorrência
class EnhancedDriverExcludedZonesService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final ZoneLimitService _zoneLimitService = ZoneLimitService();
  static const String _tableName = 'driver_excluded_zones';
  
  // Cache para otimizar consultas frequentes
  final Map<String, List<DriverExcludedZone>> _cache = {};
  final Map<String, DateTime> _cacheTimestamps = {};
  static const Duration _cacheTimeout = Duration(minutes: 5);
  
  /// Busca todas as zonas excluídas de um motorista
  Future<List<DriverExcludedZone>> getDriverExcludedZones(String driverId) async {
    try {
      // Verifica cache primeiro
      if (_isCacheValid(driverId)) {
        return _cache[driverId]!;
      }
      
      final response = await _supabase
          .from(_tableName)
          .select()
          .eq('driver_id', driverId)
          .order('created_at', ascending: false);
      
      final zones = (response as List)
          .map((json) => DriverExcludedZone.fromJson(json))
          .toList();
      
      // Atualiza cache
      _updateCache(driverId, zones);
      
      return zones;
    } catch (e) {
      throw DatabaseException('Erro ao buscar zonas excluídas: ${e.toString()}');
    }
  }
  
  /// Adiciona uma nova zona excluída com validações completas
  Future<DriverExcludedZone> addExcludedZone({
    required String driverId,
    required String neighborhoodName,
    required String city,
    required String state,
    String? reason,
  }) async {
    return await TransactionService.executeWithRetry(
      () async {
        // Validação de entrada
        _validateInputData(neighborhoodName, city, state);
        
        // Normalização de dados
        final normalizedData = DataNormalizationUtils.normalizeAddress(
          neighborhood: neighborhoodName,
          city: city,
          state: state,
          reason: reason,
        );
        
        final normalizedNeighborhood = normalizedData['neighborhood_name']!;
        final normalizedCity = normalizedData['city']!;
        final normalizedState = normalizedData['state']!;
        
        // Validação geográfica
        final validationResult = await GeographicValidationService.validateAddress(
          neighborhood: normalizedNeighborhood,
          city: normalizedCity,
          state: normalizedState,
        );
        
        if (!validationResult.isValid) {
          throw ValidationException(
            'Dados geográficos inválidos: ${validationResult.errors.join(', ')}'
          );
        }
        
        // Verifica limite de zonas
        await _zoneLimitService.validateAndEnforceLimit(driverId, 1);
        
        // Verifica duplicatas
        await _checkDuplicateZone(driverId, normalizedNeighborhood, normalizedCity, normalizedState);
        
        // Insere nova zona
        final response = await _supabase
            .from(_tableName)
            .insert({
              'driver_id': driverId,
              'neighborhood_name': normalizedNeighborhood,
              'city': normalizedCity,
              'state': normalizedState,
              'reason': reason?.trim(),
              'created_by': driverId,
            })
            .select()
            .single();
        
        final newZone = DriverExcludedZone.fromJson(response);
        
        // Invalida cache
        _invalidateCache(driverId);
        
        return newZone;
      },
      operationName: 'addExcludedZone',
    );
  }
  
  /// Adiciona múltiplas zonas excluídas em uma transação
  Future<List<DriverExcludedZone>> addMultipleExcludedZones({
    required String driverId,
    required List<Map<String, String>> zones,
  }) async {
    if (zones.isEmpty) {
      throw ValidationException('Lista de zonas não pode estar vazia');
    }
    
    if (zones.length > 20) {
      throw ValidationException('Máximo de 20 zonas podem ser adicionadas por vez');
    }
    
    // Validação e normalização de todas as zonas
    final normalizedZones = <Map<String, String>>[];
    
    for (final zone in zones) {
      final neighborhood = zone['neighborhood_name'] ?? '';
      final city = zone['city'] ?? '';
      final state = zone['state'] ?? '';
      
      _validateInputData(neighborhood, city, state);
      
      final normalizedData = DataNormalizationUtils.normalizeAddress(
        neighborhood: neighborhood,
        city: city,
        state: state,
        reason: zone['reason'],
      );
      
      final normalizedNeighborhood = normalizedData['neighborhood_name']!;
      final normalizedCity = normalizedData['city']!;
      final normalizedState = normalizedData['state']!;
      
      // Validação geográfica
      final validationResult = await GeographicValidationService.validateAddress(
        neighborhood: normalizedNeighborhood,
        city: normalizedCity,
        state: normalizedState,
      );
      
      if (!validationResult.isValid) {
        throw ValidationException(
          'Dados inválidos para $neighborhood, $city, $state: ${validationResult.errors.join(', ')}'
        );
      }
      
      normalizedZones.add({
        'driver_id': driverId,
        'neighborhood_name': normalizedNeighborhood,
        'city': normalizedCity,
        'state': normalizedState,
        'reason': normalizedData['reason']!,
        'created_by': driverId,
      });
    }
    
    return await TransactionService.executeWithRetry(
      () async {
        // Verifica limite total
        await _zoneLimitService.validateAndEnforceLimit(driverId, normalizedZones.length);
        
        // Verifica duplicatas
        for (final zone in normalizedZones) {
          await _checkDuplicateZone(
            driverId,
            zone['neighborhood_name']!,
            zone['city']!,
            zone['state']!,
          );
        }
        
        // Insere todas as zonas
        final response = await _supabase
            .from(_tableName)
            .insert(normalizedZones)
            .select();
        
        final newZones = (response as List)
            .map((json) => DriverExcludedZone.fromJson(json))
            .toList();
        
        // Invalida cache
        _invalidateCache(driverId);
        
        return newZones;
      },
      operationName: 'addMultipleExcludedZones',
    );
  }
  
  /// Remove uma zona excluída
  Future<void> removeExcludedZone(String zoneId, String driverId) async {
    return await TransactionService.executeWithRetry(
      () async {
        await _supabase
            .from(_tableName)
            .delete()
            .eq('id', zoneId)
            .eq('driver_id', driverId);
        
        // Invalida cache
        _invalidateCache(driverId);
      },
      operationName: 'removeExcludedZone',
    );
  }
  
  /// Remove múltiplas zonas excluídas
  Future<void> removeMultipleExcludedZones(List<String> zoneIds, String driverId) async {
    if (zoneIds.isEmpty) return;
    
    return await TransactionService.executeWithRetry(
      () async {
        await _supabase
            .from(_tableName)
            .delete()
            .inFilter('id', zoneIds)
            .eq('driver_id', driverId);
        
        // Invalida cache
        _invalidateCache(driverId);
      },
      operationName: 'removeMultipleExcludedZones',
    );
  }
  
  /// Remove todas as zonas excluídas de um motorista
  Future<void> removeAllExcludedZones(String driverId) async {
    return await TransactionService.executeWithRetry(
      () async {
        await _supabase
            .from(_tableName)
            .delete()
            .eq('driver_id', driverId);
        
        // Invalida cache
        _invalidateCache(driverId);
      },
      operationName: 'removeAllExcludedZones',
    );
  }
  
  /// Verifica se uma zona específica está excluída
  Future<bool> isZoneExcluded({
    required String driverId,
    required String neighborhoodName,
    required String city,
    required String state,
  }) async {
    try {
      final normalizedData = DataNormalizationUtils.normalizeAddress(
        neighborhood: neighborhoodName,
        city: city,
        state: state,
      );
      
      final normalizedNeighborhood = normalizedData['neighborhood_name']!;
      final normalizedCity = normalizedData['city']!;
      final normalizedState = normalizedData['state']!;
      
      final response = await _supabase
          .from(_tableName)
          .select('id')
          .eq('driver_id', driverId)
          .eq('neighborhood_name', normalizedNeighborhood)
          .eq('city', normalizedCity)
          .eq('state', normalizedState)
          .limit(1);
      
      return (response as List).isNotEmpty;
    } catch (e) {
      throw DatabaseException('Erro ao verificar zona excluída: ${e.toString()}');
    }
  }
  
  /// Busca zonas excluídas por cidade
  Future<List<DriverExcludedZone>> getExcludedZonesByCity(String city, String state) async {
    try {
      final normalizedData = DataNormalizationUtils.normalizeAddress(
        neighborhood: '',
        city: city,
        state: state,
      );
      
      final normalizedCity = normalizedData['city']!;
      final normalizedState = normalizedData['state']!;
      
      final response = await _supabase
          .from(_tableName)
          .select()
          .eq('city', normalizedCity)
          .eq('state', normalizedState)
          .order('created_at', ascending: false);
      
      return (response as List)
          .map((json) => DriverExcludedZone.fromJson(json))
          .toList();
    } catch (e) {
      throw DatabaseException('Erro ao buscar zonas por cidade: ${e.toString()}');
    }
  }
  
  /// Conta o número total de zonas excluídas de um motorista
  Future<int> getExcludedZonesCount(String driverId) async {
    return await _zoneLimitService.getCurrentZoneCount(driverId);
  }
  
  /// Busca estatísticas de zonas excluídas
  Future<Map<String, dynamic>> getZoneStatistics(String driverId) async {
    try {
      final zones = await getDriverExcludedZones(driverId);
      
      final cityStats = <String, int>{};
      final stateStats = <String, int>{};
      
      for (final zone in zones) {
        final cityKey = '${zone.city}, ${zone.state}';
        cityStats[cityKey] = (cityStats[cityKey] ?? 0) + 1;
        stateStats[zone.state] = (stateStats[zone.state] ?? 0) + 1;
      }
      
      final maxZones = await _zoneLimitService.getZoneLimitForDriver(driverId);
      
      return {
        'total_zones': zones.length,
        'max_zones': maxZones,
        'remaining_slots': maxZones - zones.length,
        'cities_count': cityStats.length,
        'states_count': stateStats.length,
        'zones_by_city': cityStats,
        'zones_by_state': stateStats,
        'most_excluded_city': cityStats.isNotEmpty 
            ? cityStats.entries.reduce((a, b) => a.value > b.value ? a : b).key
            : null,
      };
    } catch (e) {
      throw DatabaseException('Erro ao buscar estatísticas: ${e.toString()}');
    }
  }
  
  // Métodos privados de validação e utilitários
  
  void _validateInputData(String neighborhood, String city, String state) {
    final validationResult = DataNormalizationUtils.validateAddress(
      neighborhood: neighborhood,
      city: city,
      state: state,
    );
    
    if (!validationResult.isValid) {
      throw ValidationException(
        'Dados inválidos: ${validationResult.errors.join(', ')}'
      );
    }
  }
  
  /// Obtém contagem atual de zonas (delegado para ZoneLimitService)
  Future<int> getZoneCount(String driverId) async {
    return await _zoneLimitService.getCurrentZoneCount(driverId);
  }
  
  /// Obtém estatísticas de uso de zonas
  Future<ZoneUsageStats> getZoneUsageStats(String driverId) async {
    return await _zoneLimitService.getZoneUsageStats(driverId);
  }
  
  /// Obtém limite máximo para um motorista
  Future<int> getZoneLimitForDriver(String driverId) async {
    return await _zoneLimitService.getZoneLimitForDriver(driverId);
  }
  
  Future<void> _checkDuplicateZone(
    String driverId,
    String neighborhood,
    String city,
    String state,
  ) async {
    final exists = await isZoneExcluded(
      driverId: driverId,
      neighborhoodName: neighborhood,
      city: city,
      state: state,
    );
    
    if (exists) {
      throw ValidationException(
        'Zona "$neighborhood, $city, $state" já está excluída'
      );
    }
  }
  

  
  // Métodos de cache
  
  bool _isCacheValid(String driverId) {
    if (!_cache.containsKey(driverId) || !_cacheTimestamps.containsKey(driverId)) {
      return false;
    }
    
    final timestamp = _cacheTimestamps[driverId]!;
    return DateTime.now().difference(timestamp) < _cacheTimeout;
  }
  
  void _updateCache(String driverId, List<DriverExcludedZone> zones) {
    _cache[driverId] = zones;
    _cacheTimestamps[driverId] = DateTime.now();
  }
  
  void _invalidateCache(String driverId) {
    _cache.remove(driverId);
    _cacheTimestamps.remove(driverId);
  }
  
  /// Limpa todo o cache
  void clearCache() {
    _cache.clear();
    _cacheTimestamps.clear();
  }
}