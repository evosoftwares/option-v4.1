/// Wrapper resiliente para SupabaseClient com cache offline e fallbacks
/// Previne crashes por instabilidade de rede
library;

import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'retry_system.dart';
import 'circuit_breaker.dart';
import 'local_cache_system.dart';
import 'connectivity_monitor.dart';

/// Configuração para o cliente resiliente
class ResilientClientConfig {
  const ResilientClientConfig({
    this.enableCache = true,
    this.cacheExpiration = const Duration(minutes: 5),
    this.enableOfflineMode = true,
    this.retryConfig = const RetryConfig(),
    this.maxCacheSize = 100,
    this.enableFallback = true,
    this.localCacheConfig = const LocalCacheConfig(),
  });

  final bool enableCache;
  final Duration cacheExpiration;
  final bool enableOfflineMode;
  final RetryConfig retryConfig;
  final int maxCacheSize;
  final bool enableFallback;
  final LocalCacheConfig localCacheConfig;
}

/// Item do cache com timestamp
class CacheItem {
  const CacheItem({
    required this.data,
    required this.timestamp,
    required this.key,
  });

  final Map<String, dynamic> data;
  final DateTime timestamp;
  final String key;

  bool isExpired(Duration expiration) {
    return DateTime.now().difference(timestamp) > expiration;
  }

  Map<String, dynamic> toJson() => {
        'data': data,
        'timestamp': timestamp.toIso8601String(),
        'key': key,
      };

  factory CacheItem.fromJson(Map<String, dynamic> json) => CacheItem(
        data: Map<String, dynamic>.from(json['data']),
        timestamp: DateTime.parse(json['timestamp']),
        key: json['key'],
      );
}

/// Cliente Supabase resiliente com cache e fallbacks
class ResilientSupabaseClient {
  ResilientSupabaseClient({
    required SupabaseClient client,
    ResilientClientConfig config = const ResilientClientConfig(),
  })  : _client = client,
        _config = config,
        _cache = <String, CacheItem>{},
        _circuitBreakerManager = CircuitBreakerManager(),
        _localCache = LocalCacheSystem.instance,
        _connectivityMonitor = ConnectivityMonitor.instance;

  final SupabaseClient _client;
  final ResilientClientConfig _config;
  final Map<String, CacheItem> _cache;
  final CircuitBreakerManager _circuitBreakerManager;
  final LocalCacheSystem _localCache;
  final ConnectivityMonitor _connectivityMonitor;
  SharedPreferences? _prefs;
  bool _isOnline = true;

  /// Inicializa o cliente resiliente
  Future<void> initialize() async {
    if (_config.enableCache) {
      _prefs = await SharedPreferences.getInstance();
      await _localCache.initialize();
    }
    
    // Inicializa monitor de conectividade
    await _connectivityMonitor.initialize();
    
    // Monitora mudanças de conectividade
     _connectivityMonitor.onConnectivityChanged.listen((event) {
       _isOnline = event.status == ConnectivityStatus.online;
       if (kDebugMode) {
         debugPrint('🌐 Status de conectividade: ${event.status.name}');
       }
     });
   }

  /// Getter para o cliente Supabase original
  SupabaseClient get client => _client;

  /// Status de conectividade
  bool get isOnline => _isOnline;

  /// Atualiza status de conectividade
  void updateConnectivityStatus(bool isOnline) {
    _isOnline = isOnline;
    if (kDebugMode) {
      debugPrint('🌐 Status de conectividade: ${isOnline ? "Online" : "Offline"}');
    }
  }

  /// Executa uma query SELECT com cache e retry
  Future<List<Map<String, dynamic>>> select(
    String table, {
    String? select,
    Map<String, dynamic>? filters,
    String? orderBy,
    bool ascending = true,
    int? limit,
    bool useCache = true,
    String? operationName,
  }) async {
    final cacheKey = _generateCacheKey('select', table, {
      'select': select,
      'filters': filters,
      'orderBy': orderBy,
      'ascending': ascending,
      'limit': limit,
    });

    // Verifica cache local primeiro
    if (useCache && _config.enableCache) {
      final cached = _localCache.get<List<Map<String, dynamic>>>(cacheKey);
      if (cached != null) {
        if (kDebugMode) {
          debugPrint('📦 Dados obtidos do cache local: $table');
        }
        return cached;
      }
    }

    // Se offline e tem cache expirado, usa mesmo assim
    if (!_isOnline && _config.enableOfflineMode) {
      final expiredCache = _getExpiredCachedData(cacheKey);
      if (expiredCache != null) {
        if (kDebugMode) {
          debugPrint('📦 Usando cache expirado (modo offline): $table');
        }
        return List<Map<String, dynamic>>.from(expiredCache['data']);
      }
    }

    // Executa query com circuit breaker e retry
    try {
      final circuitBreaker = _circuitBreakerManager.getCircuitBreaker(
        'supabase_$table',
        config: const CircuitBreakerConfig(
          failureThreshold: 3,
          recoveryTimeout: Duration(seconds: 30),
        ),
      );
      
      final result = await circuitBreaker.execute(
        () => RetrySystem.execute(
          () async {
            var query = _client.from(table).select(select ?? '*');

            // Aplica filtros
            if (filters != null) {
              for (final entry in filters.entries) {
                query = query.eq(entry.key, entry.value);
              }
            }

            // Aplica ordenação e limite
            if (orderBy != null) {
              if (limit != null) {
                return await query.order(orderBy, ascending: ascending).limit(limit);
              } else {
                return await query.order(orderBy, ascending: ascending);
              }
            } else if (limit != null) {
              return await query.limit(limit);
            }

            return await query;
          },
          config: _config.retryConfig,
          operationName: operationName ?? 'select_$table',
        ),
        operationName: operationName ?? 'select_$table',
      );

      final data = List<Map<String, dynamic>>.from(result);

      // Salva no cache local se habilitado
      if (_config.enableCache) {
        await _localCache.set(
          cacheKey,
          data,
          ttl: _config.cacheExpiration,
          priority: CachePriority.normal,
          tags: [table, 'select'],
        );
        await _setCachedData(cacheKey, {'data': data});
      }

      return data;
    } catch (error) {
      if (kDebugMode) {
        debugPrint('❌ Erro na query $table: $error');
      }

      // Tenta fallback do cache local em caso de erro
      if (_config.enableFallback) {
        final fallback = _localCache.get<List<Map<String, dynamic>>>(cacheKey);
        if (fallback != null) {
          if (kDebugMode) {
            debugPrint('🔄 Usando fallback do cache local para $table');
          }
          return fallback;
        }
        
        final fallbackData = _getExpiredCachedData(cacheKey);
        if (fallbackData != null) {
          if (kDebugMode) {
            debugPrint('🔄 Usando fallback para $table');
          }
          return List<Map<String, dynamic>>.from(fallbackData['data']);
        }
      }

      rethrow;
    }
  }

  /// Executa uma operação INSERT com circuit breaker e retry
  Future<Map<String, dynamic>> insert(
    String table,
    Map<String, dynamic> data, {
    String? operationName,
  }) async {
    final circuitBreaker = _circuitBreakerManager.getCircuitBreaker(
      'supabase_$table',
      config: const CircuitBreakerConfig(
        failureThreshold: 3,
        recoveryTimeout: Duration(seconds: 30),
      ),
    );
    
    return await circuitBreaker.execute(
      () => RetrySystem.execute(
        () async {
          final result = await _client.from(table).insert(data).select().single();
          
          // Invalida cache relacionado
          _invalidateTableCache(table);
          await _localCache.removeByTags([table, 'insert']);
          
          return result;
        },
        config: _config.retryConfig,
        operationName: operationName ?? 'insert_$table',
      ),
      operationName: operationName ?? 'insert_$table',
    );
  }

  /// Executa uma operação UPDATE com retry
  Future<List<Map<String, dynamic>>> update(
    String table,
    Map<String, dynamic> data, {
    required Map<String, dynamic> filters,
    String? operationName,
  }) async {
    return await RetrySystem.execute(
      () async {
        var query = _client.from(table).update(data);
        
        // Aplica filtros
        for (final entry in filters.entries) {
          query = query.eq(entry.key, entry.value);
        }
        
        final result = await query.select();
        
        // Invalida cache relacionado
        _invalidateTableCache(table);
        
        return List<Map<String, dynamic>>.from(result);
      },
      config: _config.retryConfig,
      operationName: operationName ?? 'update_$table',
    );
  }

  /// Executa uma operação DELETE com retry
  Future<void> delete(
    String table, {
    required Map<String, dynamic> filters,
    String? operationName,
  }) async {
    await RetrySystem.execute(
      () async {
        var query = _client.from(table).delete();
        
        // Aplica filtros
        for (final entry in filters.entries) {
          query = query.eq(entry.key, entry.value);
        }
        
        await query;
        
        // Invalida cache relacionado
        _invalidateTableCache(table);
      },
      config: _config.retryConfig,
      operationName: operationName ?? 'delete_$table',
    );
  }

  /// Gera chave de cache baseada na operação
  String _generateCacheKey(String operation, String table, Map<String, dynamic> params) {
    final paramsJson = jsonEncode(params);
    return '${operation}_${table}_${paramsJson.hashCode}';
  }

  /// Obtém dados do cache se não expirados
  Map<String, dynamic>? _getCachedData(String key) {
    final item = _cache[key];
    if (item != null && !item.isExpired(_config.cacheExpiration)) {
      return item.data;
    }
    return null;
  }

  /// Obtém dados do cache mesmo se expirados (para fallback)
  Map<String, dynamic>? _getExpiredCachedData(String key) {
    final item = _cache[key];
    return item?.data;
  }

  /// Salva dados no cache
  Future<void> _setCachedData(String key, Map<String, dynamic> data) async {
    final item = CacheItem(
      data: data,
      timestamp: DateTime.now(),
      key: key,
    );

    _cache[key] = item;

    // Limita tamanho do cache
    if (_cache.length > _config.maxCacheSize) {
      _evictOldestCacheItems();
    }

    // Salva no disco se habilitado
    if (_config.enableOfflineMode && _prefs != null) {
      await _saveCacheToDisk();
    }
  }

  /// Remove itens mais antigos do cache
  void _evictOldestCacheItems() {
    final sortedItems = _cache.values.toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    final itemsToRemove = sortedItems.take(_cache.length - _config.maxCacheSize + 10);
    for (final item in itemsToRemove) {
      _cache.remove(item.key);
    }
  }

  /// Invalida cache de uma tabela específica
  void _invalidateTableCache(String table) {
    final keysToRemove = _cache.keys
        .where((key) => key.contains('_${table}_'))
        .toList();

    for (final key in keysToRemove) {
      _cache.remove(key);
    }
    
    // Invalida também no cache local
    _localCache.removeByTags([table]);
  }
  
  /// Verifica se é uma operação de carteira (alta prioridade)
  bool _isWalletOperation(String table) {
    return table.contains('wallet') || 
           table.contains('driver') || 
           table.contains('passenger') ||
           table.contains('transaction');
  }

  /// Carrega cache do disco
  Future<void> _loadCacheFromDisk() async {
    if (_prefs == null) return;

    try {
      final cacheJson = _prefs!.getString('supabase_cache');
      if (cacheJson != null) {
        final cacheData = jsonDecode(cacheJson) as Map<String, dynamic>;
        
        for (final entry in cacheData.entries) {
          try {
            final item = CacheItem.fromJson(entry.value);
            _cache[entry.key] = item;
          } catch (e) {
            if (kDebugMode) {
              debugPrint('Erro ao carregar item do cache: $e');
            }
          }
        }

        if (kDebugMode) {
          debugPrint('📦 Cache carregado do disco: ${_cache.length} itens');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Erro ao carregar cache do disco: $e');
      }
    }
  }

  /// Salva cache no disco
  Future<void> _saveCacheToDisk() async {
    if (_prefs == null) return;

    try {
      final cacheData = <String, dynamic>{};
      for (final entry in _cache.entries) {
        cacheData[entry.key] = entry.value.toJson();
      }

      await _prefs!.setString('supabase_cache', jsonEncode(cacheData));
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Erro ao salvar cache no disco: $e');
      }
    }
  }

  /// Limpa todo o cache
  Future<void> clearCache() async {
    _cache.clear();
    if (_prefs != null) {
      await _prefs!.remove('supabase_cache');
    }
    if (kDebugMode) {
      debugPrint('🗑️ Cache limpo');
    }
  }

  /// Obtém estatísticas do cache
  Map<String, dynamic> getCacheStats() {
    final now = DateTime.now();
    final validItems = _cache.values
        .where((item) => !item.isExpired(_config.cacheExpiration))
        .length;
    final expiredItems = _cache.length - validItems;

    return {
      'total_items': _cache.length,
      'valid_items': validItems,
      'expired_items': expiredItems,
      'cache_hit_ratio': validItems / (_cache.length > 0 ? _cache.length : 1),
      'is_online': _isOnline,
    };
  }
}