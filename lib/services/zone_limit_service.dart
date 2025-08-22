import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../exceptions/app_exceptions.dart';
import 'transaction_service.dart';

/// Serviço para gerenciar limites de zonas de exclusão por motorista
class ZoneLimitService {
  final SupabaseClient _supabase = Supabase.instance.client;
  
  // Configurações padrão
  static const int _defaultMaxZonesPerDriver = 50;
  static const String _configTableName = 'driver_zone_limits';
  static const String _excludedZonesTableName = 'driver_excluded_zones';
  
  // Cache para limites personalizados
  final Map<String, int> _customLimitsCache = {};
  DateTime? _lastCacheUpdate;
  static const Duration _cacheValidityDuration = Duration(minutes: 15);
  
  /// Obtém o limite máximo de zonas para um motorista específico
  Future<int> getZoneLimitForDriver(String driverId) async {
    try {
      // Verifica cache primeiro
      if (_isCustomLimitCacheValid() && _customLimitsCache.containsKey(driverId)) {
        return _customLimitsCache[driverId]!;
      }
      
      // Busca limite personalizado no banco
      final customLimit = await _getCustomLimit(driverId);
      if (customLimit != null) {
        _customLimitsCache[driverId] = customLimit;
        _lastCacheUpdate = DateTime.now();
        return customLimit;
      }
      
      // Retorna limite padrão
      return _defaultMaxZonesPerDriver;
      
    } catch (e) {
      // Em caso de erro, retorna limite padrão
      return _defaultMaxZonesPerDriver;
    }
  }
  
  /// Define um limite personalizado para um motorista
  Future<void> setCustomZoneLimit(String driverId, int limit) async {
    if (limit < 0) {
      throw ValidationException('Limite não pode ser negativo');
    }
    
    if (limit > 200) {
      throw ValidationException('Limite máximo permitido é 200 zonas');
    }
    
    await TransactionService.executeWithRetry(
      () async {
        // Verifica se já existe um limite personalizado
        final existing = await _getCustomLimit(driverId);
        
        if (existing != null) {
          // Atualiza limite existente
          await _supabase
              .from(_configTableName)
              .update({
                'max_zones': limit,
                'updated_at': DateTime.now().toIso8601String(),
              })
              .eq('driver_id', driverId);
        } else {
          // Cria novo limite personalizado
          await _supabase
              .from(_configTableName)
              .insert({
                'driver_id': driverId,
                'max_zones': limit,
                'created_at': DateTime.now().toIso8601String(),
                'updated_at': DateTime.now().toIso8601String(),
              });
        }
        
        // Atualiza cache
        _customLimitsCache[driverId] = limit;
        _lastCacheUpdate = DateTime.now();
      },
      operationName: 'setCustomZoneLimit',
    );
  }
  
  /// Remove limite personalizado (volta ao padrão)
  Future<void> removeCustomZoneLimit(String driverId) async {
    await TransactionService.executeWithRetry(
      () async {
        await _supabase
            .from(_configTableName)
            .delete()
            .eq('driver_id', driverId);
        
        // Remove do cache
        _customLimitsCache.remove(driverId);
      },
      operationName: 'removeCustomZoneLimit',
    );
  }
  
  /// Verifica se um motorista pode adicionar mais zonas
  Future<ZoneLimitCheckResult> checkCanAddZones(
    String driverId, 
    int zonesToAdd,
  ) async {
    try {
      final currentCount = await getCurrentZoneCount(driverId);
      final maxLimit = await getZoneLimitForDriver(driverId);
      final availableSlots = maxLimit - currentCount;
      
      return ZoneLimitCheckResult(
        canAdd: zonesToAdd <= availableSlots,
        currentCount: currentCount,
        maxLimit: maxLimit,
        availableSlots: availableSlots,
        requestedToAdd: zonesToAdd,
      );
      
    } catch (e) {
      throw DatabaseException('Erro ao verificar limite de zonas: ${e.toString()}');
    }
  }
  
  /// Obtém contagem atual de zonas de um motorista
  Future<int> getCurrentZoneCount(String driverId) async {
    try {
      final response = await _supabase
          .from(_excludedZonesTableName)
          .select('id')
          .eq('driver_id', driverId)
          .count(CountOption.exact);
      
      return response.count;
      
    } catch (e) {
      throw DatabaseException('Erro ao contar zonas: ${e.toString()}');
    }
  }
  
  /// Obtém estatísticas de uso de zonas por motorista
  Future<ZoneUsageStats> getZoneUsageStats(String driverId) async {
    try {
      final currentCount = await getCurrentZoneCount(driverId);
      final maxLimit = await getZoneLimitForDriver(driverId);
      final usagePercentage = (currentCount / maxLimit * 100).round();
      
      return ZoneUsageStats(
        driverId: driverId,
        currentCount: currentCount,
        maxLimit: maxLimit,
        availableSlots: maxLimit - currentCount,
        usagePercentage: usagePercentage,
        isNearLimit: usagePercentage >= 80,
        isAtLimit: currentCount >= maxLimit,
      );
      
    } catch (e) {
      throw DatabaseException('Erro ao obter estatísticas: ${e.toString()}');
    }
  }
  
  /// Obtém todos os motoristas com limites personalizados
  Future<List<DriverZoneLimit>> getAllCustomLimits() async {
    try {
      final response = await _supabase
          .from(_configTableName)
          .select('driver_id, max_zones, created_at, updated_at')
          .order('updated_at', ascending: false);
      
      return (response as List)
          .map((json) => DriverZoneLimit.fromJson(json))
          .toList();
      
    } catch (e) {
      throw DatabaseException('Erro ao buscar limites personalizados: ${e.toString()}');
    }
  }
  
  /// Valida e aplica limite antes de adicionar zonas
  Future<void> validateAndEnforceLimit(
    String driverId, 
    int zonesToAdd,
  ) async {
    final checkResult = await checkCanAddZones(driverId, zonesToAdd);
    
    if (!checkResult.canAdd) {
      throw ValidationException(
        'Limite de zonas excedido. '
        'Atual: ${checkResult.currentCount}/${checkResult.maxLimit}, '
        'tentando adicionar: ${checkResult.requestedToAdd}, '
        'disponível: ${checkResult.availableSlots}'
      );
    }
  }
  
  /// Busca limite personalizado no banco
  Future<int?> _getCustomLimit(String driverId) async {
    try {
      final response = await _supabase
          .from(_configTableName)
          .select('max_zones')
          .eq('driver_id', driverId)
          .maybeSingle();
      
      return response?['max_zones'] as int?;
      
    } catch (e) {
      return null;
    }
  }
  
  /// Verifica se o cache de limites personalizados ainda é válido
  bool _isCustomLimitCacheValid() {
    if (_lastCacheUpdate == null) return false;
    
    return DateTime.now().difference(_lastCacheUpdate!) < _cacheValidityDuration;
  }
  
  /// Limpa cache de limites personalizados
  void clearCache() {
    _customLimitsCache.clear();
    _lastCacheUpdate = null;
  }
  
  /// Obtém limite padrão do sistema
  static int get defaultMaxZones => _defaultMaxZonesPerDriver;
}

/// Resultado da verificação de limite de zonas
class ZoneLimitCheckResult {
  final bool canAdd;
  final int currentCount;
  final int maxLimit;
  final int availableSlots;
  final int requestedToAdd;
  
  const ZoneLimitCheckResult({
    required this.canAdd,
    required this.currentCount,
    required this.maxLimit,
    required this.availableSlots,
    required this.requestedToAdd,
  });
  
  @override
  String toString() {
    return 'ZoneLimitCheckResult(canAdd: $canAdd, current: $currentCount/$maxLimit, '
           'available: $availableSlots, requested: $requestedToAdd)';
  }
}

/// Estatísticas de uso de zonas
class ZoneUsageStats {
  final String driverId;
  final int currentCount;
  final int maxLimit;
  final int availableSlots;
  final int usagePercentage;
  final bool isNearLimit;
  final bool isAtLimit;
  
  const ZoneUsageStats({
    required this.driverId,
    required this.currentCount,
    required this.maxLimit,
    required this.availableSlots,
    required this.usagePercentage,
    required this.isNearLimit,
    required this.isAtLimit,
  });
  
  Map<String, dynamic> toJson() {
    return {
      'driver_id': driverId,
      'current_count': currentCount,
      'max_limit': maxLimit,
      'available_slots': availableSlots,
      'usage_percentage': usagePercentage,
      'is_near_limit': isNearLimit,
      'is_at_limit': isAtLimit,
    };
  }
}

/// Modelo para limite personalizado de motorista
class DriverZoneLimit {
  final String driverId;
  final int maxZones;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  const DriverZoneLimit({
    required this.driverId,
    required this.maxZones,
    required this.createdAt,
    required this.updatedAt,
  });
  
  factory DriverZoneLimit.fromJson(Map<String, dynamic> json) {
    return DriverZoneLimit(
      driverId: json['driver_id'] as String,
      maxZones: json['max_zones'] as int,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'driver_id': driverId,
      'max_zones': maxZones,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}