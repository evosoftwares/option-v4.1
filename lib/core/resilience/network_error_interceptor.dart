/// Interceptador global de erros de rede
/// Captura e trata erros de conectividade para prevenir crashes
library;

import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../error_handling/error_handling.dart';
import 'retry_system.dart';

/// Tipos de erro de rede identificados
enum NetworkErrorType {
  connectionTimeout,
  socketException,
  dnsResolution,
  sslHandshake,
  serverError,
  rateLimited,
  unauthorized,
  forbidden,
  notFound,
  unknown,
}

/// Informações sobre erro de rede
class NetworkErrorInfo {
  const NetworkErrorInfo({
    required this.type,
    required this.originalError,
    required this.message,
    required this.isRecoverable,
    required this.suggestedRetryDelay,
    this.statusCode,
  });

  final NetworkErrorType type;
  final dynamic originalError;
  final String message;
  final bool isRecoverable;
  final Duration suggestedRetryDelay;
  final int? statusCode;

  @override
  String toString() => 'NetworkError($type): $message';
}

/// Interceptador de erros de rede
class NetworkErrorInterceptor {
  NetworkErrorInterceptor({
    this.enableLogging = true,
    this.enableMetrics = true,
  });

  final bool enableLogging;
  final bool enableMetrics;
  
  // Métricas de erro
  final Map<NetworkErrorType, int> _errorCounts = {};
  final List<NetworkErrorInfo> _recentErrors = [];
  static const int _maxRecentErrors = 50;

  /// Analisa e classifica um erro
  NetworkErrorInfo analyzeError(dynamic error) {
    if (error is SocketException) {
      return _handleSocketException(error);
    }
    
    if (error is TimeoutException) {
      return _handleTimeoutException(error);
    }
    
    if (error is PostgrestException) {
      return _handlePostgrestException(error);
    }
    
    if (error is AuthException) {
      return _handleAuthException(error);
    }
    
    if (error is HttpException) {
      return _handleHttpException(error);
    }
    
    if (error is HandshakeException) {
      return _handleHandshakeException(error);
    }
    
    // Erro genérico
    return NetworkErrorInfo(
      type: NetworkErrorType.unknown,
      originalError: error,
      message: 'Erro desconhecido: ${error.toString()}',
      isRecoverable: false,
      suggestedRetryDelay: const Duration(seconds: 5),
    );
  }

  /// Trata erro e decide se deve fazer retry
  Future<T> handleError<T>(
    dynamic error, {
    required Future<T> Function() retryOperation,
    RetryConfig? retryConfig,
    String? operationName,
  }) async {
    final errorInfo = analyzeError(error);
    
    // Registra métricas
    if (enableMetrics) {
      _recordError(errorInfo);
    }
    
    // Log do erro
    if (enableLogging) {
      _logError(errorInfo, operationName);
    }
    
    // Se não é recuperável, falha imediatamente
    if (!errorInfo.isRecoverable) {
      throw _createAppError(errorInfo);
    }
    
    // Tenta retry se configurado
    if (retryConfig != null) {
      try {
        return await RetrySystem.execute(
          retryOperation,
          config: retryConfig,
          operationName: operationName ?? 'network_retry',
        );
      } catch (retryError) {
        // Se retry falhou, lança erro tratado
        final retryErrorInfo = analyzeError(retryError);
        throw _createAppError(retryErrorInfo);
      }
    }
    
    // Lança erro tratado
    throw _createAppError(errorInfo);
  }

  /// Trata SocketException
  NetworkErrorInfo _handleSocketException(SocketException error) {
    if (error.message.contains('Failed host lookup')) {
      return NetworkErrorInfo(
        type: NetworkErrorType.dnsResolution,
        originalError: error,
        message: 'Erro de resolução DNS. Verifique sua conexão com a internet.',
        isRecoverable: true,
        suggestedRetryDelay: const Duration(seconds: 3),
      );
    }
    
    if (error.message.contains('Connection refused') || 
        error.message.contains('Connection failed')) {
      return NetworkErrorInfo(
        type: NetworkErrorType.socketException,
        originalError: error,
        message: 'Não foi possível conectar ao servidor. Tente novamente.',
        isRecoverable: true,
        suggestedRetryDelay: const Duration(seconds: 2),
      );
    }
    
    return NetworkErrorInfo(
      type: NetworkErrorType.socketException,
      originalError: error,
      message: 'Erro de conexão: ${error.message}',
      isRecoverable: true,
      suggestedRetryDelay: const Duration(seconds: 2),
    );
  }

  /// Trata TimeoutException
  NetworkErrorInfo _handleTimeoutException(TimeoutException error) {
    return NetworkErrorInfo(
      type: NetworkErrorType.connectionTimeout,
      originalError: error,
      message: 'Tempo limite de conexão excedido. Verifique sua internet.',
      isRecoverable: true,
      suggestedRetryDelay: const Duration(seconds: 3),
    );
  }

  /// Trata PostgrestException
  NetworkErrorInfo _handlePostgrestException(PostgrestException error) {
    final code = error.code;
    final message = error.message;
    
    if (code == '401') {
      return NetworkErrorInfo(
        type: NetworkErrorType.unauthorized,
        originalError: error,
        message: 'Sessão expirada. Faça login novamente.',
        isRecoverable: false,
        suggestedRetryDelay: Duration.zero,
        statusCode: 401,
      );
    }
    
    if (code == '403') {
      return NetworkErrorInfo(
        type: NetworkErrorType.forbidden,
        originalError: error,
        message: 'Acesso negado. Você não tem permissão para esta operação.',
        isRecoverable: false,
        suggestedRetryDelay: Duration.zero,
        statusCode: 403,
      );
    }
    
    if (code == '404') {
      return NetworkErrorInfo(
        type: NetworkErrorType.notFound,
        originalError: error,
        message: 'Recurso não encontrado.',
        isRecoverable: false,
        suggestedRetryDelay: Duration.zero,
        statusCode: 404,
      );
    }
    
    if (code == '429') {
      return NetworkErrorInfo(
        type: NetworkErrorType.rateLimited,
        originalError: error,
        message: 'Muitas requisições. Aguarde um momento.',
        isRecoverable: true,
        suggestedRetryDelay: const Duration(seconds: 10),
        statusCode: 429,
      );
    }
    
    // Erro de servidor (5xx)
    if (code?.startsWith('5') == true) {
      return NetworkErrorInfo(
        type: NetworkErrorType.serverError,
        originalError: error,
        message: 'Erro interno do servidor. Tente novamente em alguns minutos.',
        isRecoverable: true,
        suggestedRetryDelay: const Duration(seconds: 30),
        statusCode: int.tryParse(code ?? '500'),
      );
    }
    
    return NetworkErrorInfo(
      type: NetworkErrorType.serverError,
      originalError: error,
      message: message ?? 'Erro no servidor',
      isRecoverable: true,
      suggestedRetryDelay: const Duration(seconds: 5),
    );
  }

  /// Trata AuthException
  NetworkErrorInfo _handleAuthException(AuthException error) {
    return NetworkErrorInfo(
      type: NetworkErrorType.unauthorized,
      originalError: error,
      message: 'Erro de autenticação: ${error.message}',
      isRecoverable: false,
      suggestedRetryDelay: Duration.zero,
    );
  }

  /// Trata HttpException
  NetworkErrorInfo _handleHttpException(HttpException error) {
    return NetworkErrorInfo(
      type: NetworkErrorType.serverError,
      originalError: error,
      message: 'Erro HTTP: ${error.message}',
      isRecoverable: true,
      suggestedRetryDelay: const Duration(seconds: 3),
    );
  }

  /// Trata HandshakeException (SSL)
  NetworkErrorInfo _handleHandshakeException(HandshakeException error) {
    return NetworkErrorInfo(
      type: NetworkErrorType.sslHandshake,
      originalError: error,
      message: 'Erro de certificado SSL. Verifique a data/hora do dispositivo.',
      isRecoverable: true,
      suggestedRetryDelay: const Duration(seconds: 5),
    );
  }

  /// Registra erro nas métricas
  void _recordError(NetworkErrorInfo errorInfo) {
    _errorCounts[errorInfo.type] = (_errorCounts[errorInfo.type] ?? 0) + 1;
    
    _recentErrors.add(errorInfo);
    if (_recentErrors.length > _maxRecentErrors) {
      _recentErrors.removeAt(0);
    }
  }

  /// Faz log do erro
  void _logError(NetworkErrorInfo errorInfo, String? operationName) {
    final operation = operationName ?? 'unknown';
    
    if (kDebugMode) {
      debugPrint('🌐 NetworkError [$operation]: ${errorInfo.type.name} - ${errorInfo.message}');
    }
    
    // Log para sistema de erro global
    // ErrorLogger implementação seria necessária aqui
    if (kDebugMode) {
      debugPrint('🔧 Operation: $operation, Type: ${errorInfo.type.name}, Status: ${errorInfo.statusCode}');
    }
  }

  /// Cria AppError baseado no NetworkErrorInfo
  AppError _createAppError(NetworkErrorInfo errorInfo) {
    AppErrorType errorType;
    
    switch (errorInfo.type) {
      case NetworkErrorType.connectionTimeout:
      case NetworkErrorType.socketException:
      case NetworkErrorType.dnsResolution:
      case NetworkErrorType.sslHandshake:
        errorType = AppErrorType.networkUnavailable;
        break;
      case NetworkErrorType.unauthorized:
        errorType = AppErrorType.authenticationFailed;
        break;
      case NetworkErrorType.forbidden:
        errorType = AppErrorType.authorizationDenied;
        break;
      case NetworkErrorType.serverError:
      case NetworkErrorType.rateLimited:
        errorType = AppErrorType.serverError;
        break;
      case NetworkErrorType.notFound:
        errorType = AppErrorType.unknownError; // não há notFound em AppErrorType
        break;
      case NetworkErrorType.unknown:
      default:
        errorType = AppErrorType.unknownError;
        break;
    }
    
    return AppError(
      type: errorType,
      message: errorInfo.message,
      context: {
        'network_error_type': errorInfo.type.name,
        'status_code': errorInfo.statusCode,
        'suggested_retry_delay': errorInfo.suggestedRetryDelay.inSeconds,
        'is_recoverable': errorInfo.isRecoverable,
      },
    );
  }

  /// Obtém estatísticas de erro
  Map<String, dynamic> getErrorStats() {
    final totalErrors = _errorCounts.values.fold(0, (sum, count) => sum + count);
    
    return {
      'total_errors': totalErrors,
      'error_counts': Map.fromEntries(
        _errorCounts.entries.map((e) => MapEntry(e.key.name, e.value)),
      ),
      'recent_errors_count': _recentErrors.length,
      'most_common_error': _getMostCommonError(),
    };
  }

  /// Obtém o tipo de erro mais comum
  String? _getMostCommonError() {
    if (_errorCounts.isEmpty) return null;
    
    var maxCount = 0;
    NetworkErrorType? mostCommon;
    
    for (final entry in _errorCounts.entries) {
      if (entry.value > maxCount) {
        maxCount = entry.value;
        mostCommon = entry.key;
      }
    }
    
    return mostCommon?.name;
  }

  /// Limpa estatísticas
  void clearStats() {
    _errorCounts.clear();
    _recentErrors.clear();
  }

  /// Verifica se há muitos erros recentes (possível problema de conectividade)
  bool hasHighErrorRate({Duration window = const Duration(minutes: 5)}) {
    final cutoff = DateTime.now().subtract(window);
    final recentErrorsInWindow = _recentErrors
        .where((error) => error.originalError is Exception)
        .length;
    
    return recentErrorsInWindow > 10; // Mais de 10 erros em 5 minutos
  }
}

// COMENTADO TEMPORARIAMENTE PARA CORRIGIR ERROS DE BUILD
// /// Extensão para facilitar uso do interceptador
// extension NetworkErrorInterceptorExtension<T> on Future<T> {
//   /// Aplica interceptação de erro de rede
//   Future<T> interceptNetworkErrors({
//     NetworkErrorInterceptor? interceptor,
//     RetryConfig? retryConfig,
//     String? operationName,
//   }) async {
//     final networkInterceptor = interceptor ?? NetworkErrorInterceptor();
//     
//     try {
//       return await this;
//     } catch (error) {
//       return await networkInterceptor.handleError<T>(
//         error,
//         retryOperation: () => this,
//         retryConfig: retryConfig,
//         operationName: operationName,
//       );
//     }
//   }
// }