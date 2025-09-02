/// Serviço de cache para transações da carteira
/// 
/// Implementa cache em memória com TTL (Time To Live) para otimizar
/// o carregamento de transações e reduzir chamadas desnecessárias ao banco.
/// 
/// Funcionalidades:
/// - Cache em memória com expiração automática
/// - Invalidação seletiva por usuário
/// - Paginação inteligente
/// - Prevenção de vazamentos de memória
library;

import 'dart:async';
import '../models/passenger_wallet_transaction.dart';
import '../utils/wallet_constants.dart';

/// Entrada do cache com timestamp para controle de TTL
class _CacheEntry {
  
  _CacheEntry({
    required this.transactions,
    required this.timestamp,
    required this.totalCount,
  });
  final List<PassengerWalletTransaction> transactions;
  final DateTime timestamp;
  final int totalCount;
  
  /// Verifica se a entrada do cache ainda é válida
  bool get isValid {
    final now = DateTime.now();
    return now.difference(timestamp) < WalletConstants.cacheExpiration;
  }
}

/// Chave do cache baseada no usuário e página
class _CacheKey {
  
  _CacheKey({
    required this.passengerId,
    required this.page,
    required this.limit,
  });
  final String passengerId;
  final int page;
  final int limit;
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is _CacheKey &&
        other.passengerId == passengerId &&
        other.page == page &&
        other.limit == limit;
  }
  
  @override
  int get hashCode => Object.hash(passengerId, page, limit);
  
  @override
  String toString() => 'CacheKey($passengerId:$page:$limit)';
}

/// Serviço de cache para transações da carteira
class TransactionCacheService {
  factory TransactionCacheService() => _instance;
  TransactionCacheService._internal();
  static final TransactionCacheService _instance = TransactionCacheService._internal();
  
  /// Cache em memória das transações
  final Map<_CacheKey, _CacheEntry> _cache = {};
  
  /// Timer para limpeza periódica do cache
  Timer? _cleanupTimer;
  
  /// Inicializa o serviço de cache
  void initialize() {
    // Configura limpeza automática do cache a cada 5 minutos
    _cleanupTimer?.cancel();
    _cleanupTimer = Timer.periodic(
      WalletConstants.cacheCleanupInterval,
      (_) => _cleanupExpiredEntries(),
    );
  }
  
  /// Finaliza o serviço e limpa recursos
  void dispose() {
    _cleanupTimer?.cancel();
    _cleanupTimer = null;
    _cache.clear();
  }
  
  /// Obtém transações do cache se disponíveis e válidas
  List<PassengerWalletTransaction>? getCachedTransactions({
    required String passengerId,
    required int page,
    required int limit,
  }) {
    final key = _CacheKey(
      passengerId: passengerId,
      page: page,
      limit: limit,
    );
    
    final entry = _cache[key];
    if (entry != null && entry.isValid) {
      return List.from(entry.transactions); // Retorna cópia para evitar modificações
    }
    
    // Remove entrada expirada
    if (entry != null) {
      _cache.remove(key);
    }
    
    return null;
  }
  
  /// Armazena transações no cache
  void cacheTransactions({
    required String passengerId,
    required int page,
    required int limit,
    required List<PassengerWalletTransaction> transactions,
    required int totalCount,
  }) {
    final key = _CacheKey(
      passengerId: passengerId,
      page: page,
      limit: limit,
    );
    
    final entry = _CacheEntry(
      transactions: List.from(transactions), // Armazena cópia
      timestamp: DateTime.now(),
      totalCount: totalCount,
    );
    
    _cache[key] = entry;
    
    // Limita o tamanho do cache para evitar vazamentos de memória
    if (_cache.length > WalletConstants.maxCacheEntries) {
      _removeOldestEntries();
    }
  }
  
  /// Invalida cache para um usuário específico
  void invalidateUserCache(String passengerId) {
    _cache.removeWhere((key, _) => key.passengerId == passengerId);
  }
  
  /// Invalida todo o cache
  void invalidateAllCache() {
    _cache.clear();
  }
  
  /// Verifica se existe cache válido para uma página específica
  bool hasCachedPage({
    required String passengerId,
    required int page,
    required int limit,
  }) {
    final key = _CacheKey(
      passengerId: passengerId,
      page: page,
      limit: limit,
    );
    
    final entry = _cache[key];
    return entry != null && entry.isValid;
  }
  
  /// Obtém estatísticas do cache para monitoramento
  Map<String, dynamic> getCacheStats() {
    final validEntries = _cache.values.where((entry) => entry.isValid).length;
    final expiredEntries = _cache.length - validEntries;
    
    return {
      'total_entries': _cache.length,
      'valid_entries': validEntries,
      'expired_entries': expiredEntries,
      'cache_hit_ratio': _calculateHitRatio(),
      'memory_usage_kb': _estimateMemoryUsage(),
    };
  }
  
  /// Remove entradas expiradas do cache
  void _cleanupExpiredEntries() {
    _cache.removeWhere((_, entry) => !entry.isValid);
  }
  
  /// Remove as entradas mais antigas quando o cache atinge o limite
  void _removeOldestEntries() {
    final entries = _cache.entries.toList()
      ..sort((a, b) => a.value.timestamp.compareTo(b.value.timestamp));
    
    // Remove 25% das entradas mais antigas
    final removeCount = (WalletConstants.maxCacheEntries * 0.25).round();
    for (var i = 0; i < removeCount && entries.isNotEmpty; i++) {
      _cache.remove(entries[i].key);
    }
  }
  
  /// Calcula a taxa de acerto do cache (implementação simplificada)
  double _calculateHitRatio() {
    // Em uma implementação real, seria necessário rastrear hits e misses
    // Por simplicidade, retornamos uma estimativa baseada na validade das entradas
    if (_cache.isEmpty) return 0;
    
    final validEntries = _cache.values.where((entry) => entry.isValid).length;
    return validEntries / _cache.length;
  }
  
  /// Estima o uso de memória do cache em KB
  int _estimateMemoryUsage() {
    // Estimativa aproximada: cada transação ~1KB + overhead
    var totalTransactions = 0;
    for (final entry in _cache.values) {
      totalTransactions += entry.transactions.length;
    }
    
    return totalTransactions; // Aproximação em KB
  }
}