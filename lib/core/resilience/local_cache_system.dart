import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Configuração do sistema de cache local
class LocalCacheConfig {
  const LocalCacheConfig({
    this.defaultTtl = const Duration(minutes: 15),
    this.maxCacheSize = 100,
    this.enablePersistence = true,
    this.enableCompression = false,
  });

  final Duration defaultTtl;
  final int maxCacheSize;
  final bool enablePersistence;
  final bool enableCompression;
}

/// Item do cache com metadados
class CacheItem {
  const CacheItem({
    required this.data,
    required this.timestamp,
    required this.ttl,
    this.priority = CachePriority.normal,
    this.tags = const [],
  });

  final dynamic data;
  final DateTime timestamp;
  final Duration ttl;
  final CachePriority priority;
  final List<String> tags;

  bool get isExpired => DateTime.now().difference(timestamp) > ttl;

  Map<String, dynamic> toJson() => {
        'data': data,
        'timestamp': timestamp.millisecondsSinceEpoch,
        'ttl': ttl.inMilliseconds,
        'priority': priority.index,
        'tags': tags,
      };

  factory CacheItem.fromJson(Map<String, dynamic> json) => CacheItem(
        data: json['data'],
        timestamp: DateTime.fromMillisecondsSinceEpoch(json['timestamp']),
        ttl: Duration(milliseconds: json['ttl']),
        priority: CachePriority.values[json['priority'] ?? 0],
        tags: List<String>.from(json['tags'] ?? []),
      );
}

/// Prioridade do cache
enum CachePriority {
  low,
  normal,
  high,
  critical,
}

/// Estatísticas do cache
class CacheStats {
  CacheStats({
    this.hits = 0,
    this.misses = 0,
    this.evictions = 0,
    this.size = 0,
  });

  int hits;
  int misses;
  int evictions;
  int size;

  double get hitRate => (hits + misses) > 0 ? hits / (hits + misses) : 0.0;

  Map<String, dynamic> toJson() => {
        'hits': hits,
        'misses': misses,
        'evictions': evictions,
        'size': size,
        'hitRate': hitRate,
      };
}

/// Sistema de cache local com persistência e TTL
class LocalCacheSystem {
  LocalCacheSystem({
    LocalCacheConfig config = const LocalCacheConfig(),
  }) : _config = config,
       _memoryCache = <String, CacheItem>{},
       _stats = CacheStats();

  final LocalCacheConfig _config;
  final Map<String, CacheItem> _memoryCache;
  final CacheStats _stats;
  SharedPreferences? _prefs;
  Timer? _cleanupTimer;

  static LocalCacheSystem? _instance;
  static LocalCacheSystem get instance {
    _instance ??= LocalCacheSystem();
    return _instance!;
  }

  /// Inicializa o sistema de cache
  Future<void> initialize() async {
    if (_config.enablePersistence) {
      _prefs = await SharedPreferences.getInstance();
      await _loadFromPersistence();
    }

    // Inicia limpeza automática
    _startCleanupTimer();
  }

  /// Armazena um item no cache
  Future<void> set(
    String key,
    dynamic data, {
    Duration? ttl,
    CachePriority priority = CachePriority.normal,
    List<String> tags = const [],
  }) async {
    final item = CacheItem(
      data: data,
      timestamp: DateTime.now(),
      ttl: ttl ?? _config.defaultTtl,
      priority: priority,
      tags: tags,
    );

    _memoryCache[key] = item;
    _stats.size = _memoryCache.length;

    // Verifica limite de tamanho
    if (_memoryCache.length > _config.maxCacheSize) {
      await _evictLeastImportant();
    }

    // Persiste se habilitado
    if (_config.enablePersistence && _prefs != null) {
      await _persistItem(key, item);
    }
  }

  /// Recupera um item do cache
  T? get<T>(String key) {
    final item = _memoryCache[key];
    
    if (item == null) {
      _stats.misses++;
      return null;
    }

    if (item.isExpired) {
      _memoryCache.remove(key);
      _stats.misses++;
      _stats.size = _memoryCache.length;
      
      // Remove da persistência
      if (_config.enablePersistence && _prefs != null) {
        _prefs!.remove('cache_$key');
      }
      
      return null;
    }

    _stats.hits++;
    return item.data as T?;
  }

  /// Verifica se uma chave existe no cache
  bool contains(String key) {
    final item = _memoryCache[key];
    return item != null && !item.isExpired;
  }

  /// Remove um item do cache
  Future<void> remove(String key) async {
    _memoryCache.remove(key);
    _stats.size = _memoryCache.length;
    
    if (_config.enablePersistence && _prefs != null) {
      await _prefs!.remove('cache_$key');
    }
  }

  /// Remove itens por tags
  Future<void> removeByTags(List<String> tags) async {
    final keysToRemove = <String>[];
    
    for (final entry in _memoryCache.entries) {
      if (entry.value.tags.any((tag) => tags.contains(tag))) {
        keysToRemove.add(entry.key);
      }
    }

    for (final key in keysToRemove) {
      await remove(key);
    }
  }

  /// Limpa todo o cache
  Future<void> clear() async {
    _memoryCache.clear();
    _stats.size = 0;
    
    if (_config.enablePersistence && _prefs != null) {
      final keys = _prefs!.getKeys()
          .where((key) => key.startsWith('cache_'))
          .toList();
      
      for (final key in keys) {
        await _prefs!.remove(key);
      }
    }
  }

  /// Obtém estatísticas do cache
  CacheStats getStats() => _stats;

  /// Obtém ou define um valor com função de fallback
  Future<T> getOrSet<T>(
    String key,
    Future<T> Function() fallback, {
    Duration? ttl,
    CachePriority priority = CachePriority.normal,
    List<String> tags = const [],
  }) async {
    final cached = get<T>(key);
    if (cached != null) {
      return cached;
    }

    final value = await fallback();
    await set(key, value, ttl: ttl, priority: priority, tags: tags);
    return value;
  }

  /// Carrega cache da persistência
  Future<void> _loadFromPersistence() async {
    if (_prefs == null) return;

    final keys = _prefs!.getKeys()
        .where((key) => key.startsWith('cache_'))
        .toList();

    for (final persistenceKey in keys) {
      try {
        final jsonString = _prefs!.getString(persistenceKey);
        if (jsonString != null) {
          final json = jsonDecode(jsonString);
          final item = CacheItem.fromJson(json);
          
          if (!item.isExpired) {
            final cacheKey = persistenceKey.substring(6); // Remove 'cache_'
            _memoryCache[cacheKey] = item;
          } else {
            // Remove item expirado da persistência
            await _prefs!.remove(persistenceKey);
          }
        }
      } catch (e) {
        debugPrint('Erro ao carregar item do cache: $e');
        await _prefs!.remove(persistenceKey);
      }
    }

    _stats.size = _memoryCache.length;
  }

  /// Persiste um item
  Future<void> _persistItem(String key, CacheItem item) async {
    if (_prefs == null) return;

    try {
      final json = jsonEncode(item.toJson());
      await _prefs!.setString('cache_$key', json);
    } catch (e) {
      debugPrint('Erro ao persistir item do cache: $e');
    }
  }

  /// Remove o item menos importante
  Future<void> _evictLeastImportant() async {
    if (_memoryCache.isEmpty) return;

    // Ordena por prioridade (menor primeiro) e depois por timestamp (mais antigo primeiro)
    final entries = _memoryCache.entries.toList()
      ..sort((a, b) {
        final priorityComparison = a.value.priority.index.compareTo(b.value.priority.index);
        if (priorityComparison != 0) return priorityComparison;
        return a.value.timestamp.compareTo(b.value.timestamp);
      });

    final keyToRemove = entries.first.key;
    await remove(keyToRemove);
    _stats.evictions++;
  }

  /// Inicia timer de limpeza automática
  void _startCleanupTimer() {
    _cleanupTimer?.cancel();
    _cleanupTimer = Timer.periodic(
      const Duration(minutes: 5),
      (_) => _cleanupExpired(),
    );
  }

  /// Remove itens expirados
  Future<void> _cleanupExpired() async {
    final expiredKeys = <String>[];
    
    for (final entry in _memoryCache.entries) {
      if (entry.value.isExpired) {
        expiredKeys.add(entry.key);
      }
    }

    for (final key in expiredKeys) {
      await remove(key);
    }
  }

  /// Libera recursos
  void dispose() {
    _cleanupTimer?.cancel();
    _memoryCache.clear();
  }
}

/// Extensão para facilitar uso do cache
extension CacheExtension<T> on Future<T> {
  /// Executa com cache automático
  Future<T> withCache(
    String key, {
    Duration? ttl,
    CachePriority priority = CachePriority.normal,
    List<String> tags = const [],
  }) async {
    return await LocalCacheSystem.instance.getOrSet(
      key,
      () => this,
      ttl: ttl,
      priority: priority,
      tags: tags,
    );
  }
}