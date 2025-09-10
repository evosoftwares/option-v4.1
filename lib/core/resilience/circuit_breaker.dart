/// Circuit Breaker para prevenir cascata de falhas
/// Monitora falhas consecutivas e bloqueia operações quando necessário
library;

import 'dart:async';
import 'package:flutter/foundation.dart';

/// Estados do Circuit Breaker
enum CircuitBreakerState {
  /// Funcionamento normal - permite todas as operações
  closed,
  
  /// Muitas falhas detectadas - bloqueia operações
  open,
  
  /// Teste limitado - permite algumas operações para verificar recuperação
  halfOpen,
}

/// Configuração do Circuit Breaker
class CircuitBreakerConfig {
  const CircuitBreakerConfig({
    this.failureThreshold = 5,
    this.recoveryTimeout = const Duration(seconds: 30),
    this.successThreshold = 3,
    this.monitoringWindow = const Duration(minutes: 2),
    this.enableLogging = true,
  });

  /// Número de falhas consecutivas para abrir o circuito
  final int failureThreshold;
  
  /// Tempo para tentar recuperação (estado half-open)
  final Duration recoveryTimeout;
  
  /// Sucessos necessários no estado half-open para fechar o circuito
  final int successThreshold;
  
  /// Janela de tempo para monitoramento de falhas
  final Duration monitoringWindow;
  
  /// Habilita logging de debug
  final bool enableLogging;
}

/// Informações sobre uma operação
class OperationResult {
  const OperationResult({
    required this.isSuccess,
    required this.timestamp,
    this.error,
    this.operationName,
  });

  final bool isSuccess;
  final DateTime timestamp;
  final dynamic error;
  final String? operationName;
}

/// Circuit Breaker para operações críticas
class CircuitBreaker {
  CircuitBreaker({
    required this.name,
    CircuitBreakerConfig config = const CircuitBreakerConfig(),
  }) : _config = config;

  final String name;
  final CircuitBreakerConfig _config;
  
  CircuitBreakerState _state = CircuitBreakerState.closed;
  int _failureCount = 0;
  int _successCount = 0;
  DateTime? _lastFailureTime;
  DateTime? _stateChangeTime;
  final List<OperationResult> _operationHistory = [];
  
  /// Estado atual do circuit breaker
  CircuitBreakerState get state => _state;
  
  /// Número de falhas consecutivas
  int get failureCount => _failureCount;
  
  /// Número de sucessos no estado half-open
  int get successCount => _successCount;
  
  /// Última vez que o estado mudou
  DateTime? get lastStateChange => _stateChangeTime;
  
  /// Verifica se uma operação pode ser executada
  bool canExecute() {
    switch (_state) {
      case CircuitBreakerState.closed:
        return true;
        
      case CircuitBreakerState.open:
        // Verifica se é hora de tentar recuperação
        if (_shouldAttemptRecovery()) {
          _transitionToHalfOpen();
          return true;
        }
        return false;
        
      case CircuitBreakerState.halfOpen:
        return true;
    }
  }
  
  /// Executa uma operação com proteção do circuit breaker
  Future<T> execute<T>(
    Future<T> Function() operation, {
    String? operationName,
  }) async {
    if (!canExecute()) {
      final error = CircuitBreakerOpenException(
        'Circuit breaker "$name" está aberto. Operação bloqueada.',
        circuitBreakerName: name,
        state: _state,
        failureCount: _failureCount,
      );
      
      _recordOperation(OperationResult(
        isSuccess: false,
        timestamp: DateTime.now(),
        error: error,
        operationName: operationName,
      ));
      
      throw error;
    }
    
    try {
      final result = await operation();
      _onSuccess(operationName);
      return result;
    } catch (error) {
      _onFailure(error, operationName);
      rethrow;
    }
  }
  
  /// Registra sucesso de operação
  void _onSuccess(String? operationName) {
    _recordOperation(OperationResult(
      isSuccess: true,
      timestamp: DateTime.now(),
      operationName: operationName,
    ));
    
    switch (_state) {
      case CircuitBreakerState.closed:
        // Reset failure count on success
        if (_failureCount > 0) {
          _failureCount = 0;
          _log('Contador de falhas resetado após sucesso');
        }
        break;
        
      case CircuitBreakerState.halfOpen:
        _successCount++;
        _log('Sucesso no estado half-open: $_successCount/${_config.successThreshold}');
        
        if (_successCount >= _config.successThreshold) {
          _transitionToClosed();
        }
        break;
        
      case CircuitBreakerState.open:
        // Não deveria acontecer, mas reset se acontecer
        _transitionToClosed();
        break;
    }
  }
  
  /// Registra falha de operação
  void _onFailure(dynamic error, String? operationName) {
    _lastFailureTime = DateTime.now();
    
    _recordOperation(OperationResult(
      isSuccess: false,
      timestamp: DateTime.now(),
      error: error,
      operationName: operationName,
    ));
    
    switch (_state) {
      case CircuitBreakerState.closed:
        _failureCount++;
        _log('Falha registrada: $_failureCount/${_config.failureThreshold}');
        
        if (_failureCount >= _config.failureThreshold) {
          _transitionToOpen();
        }
        break;
        
      case CircuitBreakerState.halfOpen:
        // Uma falha no half-open volta para open
        _transitionToOpen();
        break;
        
      case CircuitBreakerState.open:
        // Já está aberto, apenas incrementa contador
        _failureCount++;
        break;
    }
  }
  
  /// Verifica se deve tentar recuperação
  bool _shouldAttemptRecovery() {
    if (_lastFailureTime == null) return false;
    
    final timeSinceLastFailure = DateTime.now().difference(_lastFailureTime!);
    return timeSinceLastFailure >= _config.recoveryTimeout;
  }
  
  /// Transição para estado fechado (normal)
  void _transitionToClosed() {
    final previousState = _state;
    _state = CircuitBreakerState.closed;
    _failureCount = 0;
    _successCount = 0;
    _stateChangeTime = DateTime.now();
    
    _log('Transição: $previousState -> closed');
  }
  
  /// Transição para estado aberto (bloqueado)
  void _transitionToOpen() {
    final previousState = _state;
    _state = CircuitBreakerState.open;
    _successCount = 0;
    _stateChangeTime = DateTime.now();
    
    _log('Transição: $previousState -> open ($_failureCount falhas)');
  }
  
  /// Transição para estado meio-aberto (teste)
  void _transitionToHalfOpen() {
    final previousState = _state;
    _state = CircuitBreakerState.halfOpen;
    _successCount = 0;
    _stateChangeTime = DateTime.now();
    
    _log('Transição: $previousState -> half-open (tentando recuperação)');
  }
  
  /// Registra operação no histórico
  void _recordOperation(OperationResult result) {
    _operationHistory.add(result);
    
    // Limita tamanho do histórico
    const maxHistorySize = 100;
    if (_operationHistory.length > maxHistorySize) {
      _operationHistory.removeAt(0);
    }
    
    // Remove operações antigas da janela de monitoramento
    final cutoff = DateTime.now().subtract(_config.monitoringWindow);
    _operationHistory.removeWhere((op) => op.timestamp.isBefore(cutoff));
  }
  
  /// Log interno
  void _log(String message) {
    if (_config.enableLogging && kDebugMode) {
      debugPrint('🔌 CircuitBreaker[$name]: $message');
    }
  }
  
  /// Reset manual do circuit breaker
  void reset() {
    _log('Reset manual executado');
    _transitionToClosed();
  }
  
  /// Força abertura do circuit breaker
  void forceOpen() {
    _log('Abertura forçada');
    _failureCount = _config.failureThreshold;
    _transitionToOpen();
  }
  
  /// Obtém estatísticas do circuit breaker
  Map<String, dynamic> getStats() {
    final now = DateTime.now();
    final recentOperations = _operationHistory
        .where((op) => now.difference(op.timestamp) <= _config.monitoringWindow)
        .toList();
    
    final recentFailures = recentOperations.where((op) => !op.isSuccess).length;
    final recentSuccesses = recentOperations.where((op) => op.isSuccess).length;
    final totalRecent = recentOperations.length;
    
    return {
      'name': name,
      'state': _state.name,
      'failure_count': _failureCount,
      'success_count': _successCount,
      'last_failure_time': _lastFailureTime?.toIso8601String(),
      'last_state_change': _stateChangeTime?.toIso8601String(),
      'recent_operations': totalRecent,
      'recent_failures': recentFailures,
      'recent_successes': recentSuccesses,
      'recent_failure_rate': totalRecent > 0 ? recentFailures / totalRecent : 0.0,
      'config': {
        'failure_threshold': _config.failureThreshold,
        'recovery_timeout_seconds': _config.recoveryTimeout.inSeconds,
        'success_threshold': _config.successThreshold,
        'monitoring_window_minutes': _config.monitoringWindow.inMinutes,
      },
    };
  }
  
  /// Obtém histórico de operações recentes
  List<Map<String, dynamic>> getRecentOperations({int limit = 20}) {
    final recent = _operationHistory
        .reversed
        .take(limit)
        .map((op) => {
              'success': op.isSuccess,
              'timestamp': op.timestamp.toIso8601String(),
              'operation_name': op.operationName,
              'error': op.error?.toString(),
            })
        .toList();
    
    return recent;
  }
}

/// Exceção lançada quando circuit breaker está aberto
class CircuitBreakerOpenException implements Exception {
  const CircuitBreakerOpenException(
    this.message, {
    required this.circuitBreakerName,
    required this.state,
    required this.failureCount,
  });

  final String message;
  final String circuitBreakerName;
  final CircuitBreakerState state;
  final int failureCount;

  @override
  String toString() => 'CircuitBreakerOpenException: $message';
}

/// Gerenciador global de circuit breakers
class CircuitBreakerManager {
  static final CircuitBreakerManager _instance = CircuitBreakerManager._internal();
  factory CircuitBreakerManager() => _instance;
  CircuitBreakerManager._internal();

  final Map<String, CircuitBreaker> _circuitBreakers = {};

  /// Obtém ou cria um circuit breaker
  CircuitBreaker getCircuitBreaker(
    String name, {
    CircuitBreakerConfig config = const CircuitBreakerConfig(),
  }) {
    return _circuitBreakers.putIfAbsent(
      name,
      () => CircuitBreaker(name: name, config: config),
    );
  }

  /// Lista todos os circuit breakers
  List<CircuitBreaker> getAllCircuitBreakers() {
    return _circuitBreakers.values.toList();
  }

  /// Obtém estatísticas de todos os circuit breakers
  Map<String, dynamic> getAllStats() {
    return {
      'circuit_breakers': _circuitBreakers.map(
        (name, cb) => MapEntry(name, cb.getStats()),
      ),
      'total_count': _circuitBreakers.length,
      'open_count': _circuitBreakers.values
          .where((cb) => cb.state == CircuitBreakerState.open)
          .length,
      'half_open_count': _circuitBreakers.values
          .where((cb) => cb.state == CircuitBreakerState.halfOpen)
          .length,
    };
  }

  /// Reset de todos os circuit breakers
  void resetAll() {
    for (final cb in _circuitBreakers.values) {
      cb.reset();
    }
  }

  /// Remove um circuit breaker
  void removeCircuitBreaker(String name) {
    _circuitBreakers.remove(name);
  }

  /// Limpa todos os circuit breakers
  void clear() {
    _circuitBreakers.clear();
  }
}

/// Extensão para facilitar uso de circuit breakers
extension CircuitBreakerExtension<T> on Future<T> {
  /// Executa com proteção de circuit breaker
  Future<T> withCircuitBreaker(
    String circuitBreakerName, {
    CircuitBreakerConfig config = const CircuitBreakerConfig(),
    String? operationName,
  }) async {
    final circuitBreaker = CircuitBreakerManager()
        .getCircuitBreaker(circuitBreakerName, config: config);
    
    return await circuitBreaker.execute<T>(
      () => this,
      operationName: operationName,
    );
  }
}