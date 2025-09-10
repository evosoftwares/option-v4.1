/// Sistema de retry automático com backoff exponencial
/// Previne crashes por instabilidade de rede
library;

import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Configuração para o sistema de retry
class RetryConfig {
  const RetryConfig({
    this.maxAttempts = 3,
    this.baseDelay = const Duration(milliseconds: 500),
    this.maxDelay = const Duration(seconds: 30),
    this.backoffMultiplier = 2.0,
    this.jitterFactor = 0.1,
    this.retryableErrors = const {
      'SocketException',
      'TimeoutException',
      'HttpException',
      'ClientException',
      'ConnectionException',
      'NetworkException',
    },
  });

  final int maxAttempts;
  final Duration baseDelay;
  final Duration maxDelay;
  final double backoffMultiplier;
  final double jitterFactor;
  final Set<String> retryableErrors;
}

/// Resultado de uma operação com retry
class RetryResult<T> {
  const RetryResult.success(this.data, this.attempts)
      : error = null,
        isSuccess = true;

  const RetryResult.failure(this.error, this.attempts)
      : data = null,
        isSuccess = false;

  final T? data;
  final Object? error;
  final int attempts;
  final bool isSuccess;
}

/// Sistema de retry automático para operações Supabase
class RetrySystem {
  static const RetryConfig _defaultConfig = RetryConfig();
  static final Random _random = Random();

  /// Executa uma operação com retry automático
  static Future<T> execute<T>(
    Future<T> Function() operation, {
    RetryConfig config = _defaultConfig,
    String? operationName,
    Map<String, dynamic>? context,
  }) async {
    final result = await executeWithResult(
      operation,
      config: config,
      operationName: operationName,
      context: context,
    );

    if (result.isSuccess) {
      return result.data!;
    } else {
      throw result.error!;
    }
  }

  /// Executa uma operação com retry e retorna resultado detalhado
  static Future<RetryResult<T>> executeWithResult<T>(
    Future<T> Function() operation, {
    RetryConfig config = _defaultConfig,
    String? operationName,
    Map<String, dynamic>? context,
  }) async {
    int attempts = 0;
    Object? lastError;

    while (attempts < config.maxAttempts) {
      attempts++;

      try {
        if (kDebugMode && operationName != null) {
          debugPrint('🔄 Tentativa $attempts/${
              config.maxAttempts} para $operationName');
        }

        final result = await operation();

        if (kDebugMode && operationName != null && attempts > 1) {
          debugPrint('✅ $operationName bem-sucedida na tentativa $attempts');
        }

        return RetryResult.success(result, attempts);
      } catch (error) {
        lastError = error;

        if (kDebugMode) {
          debugPrint('❌ Erro na tentativa $attempts: $error');
        }

        // Verifica se o erro é recuperável
        if (!_isRetryableError(error, config)) {
          if (kDebugMode) {
            debugPrint('🚫 Erro não recuperável: ${error.runtimeType}');
          }
          return RetryResult.failure(error, attempts);
        }

        // Se não é a última tentativa, aguarda antes de tentar novamente
        if (attempts < config.maxAttempts) {
          final delay = _calculateDelay(attempts, config);
          if (kDebugMode) {
            debugPrint('⏳ Aguardando ${delay.inMilliseconds}ms antes da próxima tentativa');
          }
          await Future.delayed(delay);
        }
      }
    }

    if (kDebugMode && operationName != null) {
      debugPrint('💥 $operationName falhou após $attempts tentativas');
    }

    return RetryResult.failure(lastError!, attempts);
  }

  /// Verifica se um erro é recuperável (pode ser tentado novamente)
  static bool _isRetryableError(Object error, RetryConfig config) {
    final errorType = error.runtimeType.toString();
    final errorMessage = error.toString().toLowerCase();

    // Verifica tipos de erro conhecidos
    if (config.retryableErrors.any((type) => errorType.contains(type))) {
      return true;
    }

    // Verifica erros específicos do Supabase
    if (error is PostgrestException) {
      // Erros de rede/timeout são recuperáveis
      if (error.code == null || error.code == '08000' || error.code == '08006') {
        return true;
      }
      // Erros de servidor (5xx) são recuperáveis
      if (error.message.contains('500') || error.message.contains('502') ||
          error.message.contains('503') || error.message.contains('504')) {
        return true;
      }
    }

    // Verifica mensagens de erro comuns
    final retryableMessages = [
      'network',
      'timeout',
      'connection',
      'socket',
      'dns',
      'resolve',
      'unreachable',
      'failed to connect',
      'connection refused',
      'connection reset',
      'no route to host',
    ];

    return retryableMessages.any((msg) => errorMessage.contains(msg));
  }

  /// Calcula o delay com backoff exponencial e jitter
  static Duration _calculateDelay(int attempt, RetryConfig config) {
    // Backoff exponencial
    final exponentialDelay = config.baseDelay.inMilliseconds *
        pow(config.backoffMultiplier, attempt - 1);

    // Adiciona jitter para evitar thundering herd
    final jitter = exponentialDelay * config.jitterFactor * _random.nextDouble();
    final totalDelay = (exponentialDelay + jitter).round();

    // Limita ao delay máximo
    final clampedDelay = totalDelay.clamp(0, config.maxDelay.inMilliseconds);

    return Duration(milliseconds: clampedDelay);
  }

  /// Configurações pré-definidas para diferentes cenários
  static const RetryConfig quickRetry = RetryConfig(
    maxAttempts: 2,
    baseDelay: Duration(milliseconds: 200),
    maxDelay: Duration(seconds: 2),
  );

  static const RetryConfig standardRetry = RetryConfig(
    maxAttempts: 3,
    baseDelay: Duration(milliseconds: 500),
    maxDelay: Duration(seconds: 10),
  );

  static const RetryConfig aggressiveRetry = RetryConfig(
    maxAttempts: 5,
    baseDelay: Duration(seconds: 1),
    maxDelay: Duration(seconds: 30),
    backoffMultiplier: 1.5,
  );

  static const RetryConfig criticalRetry = RetryConfig(
    maxAttempts: 7,
    baseDelay: Duration(milliseconds: 100),
    maxDelay: Duration(minutes: 1),
    backoffMultiplier: 1.8,
    jitterFactor: 0.2,
  );
}

/// Extensão para Future com retry automático
extension FutureRetry<T> on Future<T> {
  /// Executa o Future com retry automático
  Future<T> withRetry({
    RetryConfig config = const RetryConfig(),
    String? operationName,
    Map<String, dynamic>? context,
  }) {
    return RetrySystem.execute(
      () => this,
      config: config,
      operationName: operationName,
      context: context,
    );
  }

  /// Executa o Future com retry e retorna resultado detalhado
  Future<RetryResult<T>> withRetryResult({
    RetryConfig config = const RetryConfig(),
    String? operationName,
    Map<String, dynamic>? context,
  }) {
    return RetrySystem.executeWithResult(
      () => this,
      config: config,
      operationName: operationName,
      context: context,
    );
  }
}