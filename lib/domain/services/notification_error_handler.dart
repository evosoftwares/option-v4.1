import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:logger/logger.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Tipos de erro de notificação
enum NotificationErrorType {
  networkError,
  authenticationError,
  invalidToken,
  quotaExceeded,
  serverError,
  timeoutError,
  unknownError,
}

/// Severidade do erro
enum ErrorSeverity {
  low,
  medium,
  high,
  critical,
}

/// Estratégia de retry
enum RetryStrategy {
  exponentialBackoff,
  linearBackoff,
  fixedDelay,
  noRetry,
}

/// Classe para representar um erro de notificação
class NotificationError {

  NotificationError({
    required this.id,
    required this.type,
    required this.severity,
    required this.message,
    this.code,
    this.details,
    required this.timestamp,
    this.userId,
    this.notificationId,
    this.retryCount = 0,
    this.stackTrace,
  });
  final String id;
  final NotificationErrorType type;
  final ErrorSeverity severity;
  final String message;
  final String? code;
  final Map<String, dynamic>? details;
  final DateTime timestamp;
  final String? userId;
  final String? notificationId;
  final int retryCount;
  final String? stackTrace;

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.name,
    'severity': severity.name,
    'message': message,
    'code': code,
    'details': details,
    'timestamp': timestamp.toIso8601String(),
    'user_id': userId,
    'notification_id': notificationId,
    'retry_count': retryCount,
    'stack_trace': stackTrace,
  };

  NotificationError copyWith({
    int? retryCount,
    String? message,
    Map<String, dynamic>? details,
  }) => NotificationError(
      id: id,
      type: type,
      severity: severity,
      message: message ?? this.message,
      code: code,
      details: details ?? this.details,
      timestamp: timestamp,
      userId: userId,
      notificationId: notificationId,
      retryCount: retryCount ?? this.retryCount,
      stackTrace: stackTrace,
    );
}

/// Configuração de retry
class RetryConfig {

  const RetryConfig({
    this.strategy = RetryStrategy.exponentialBackoff,
    this.maxRetries = 3,
    this.initialDelay = const Duration(seconds: 1),
    this.maxDelay = const Duration(minutes: 5),
    this.backoffMultiplier = 2.0,
    this.retryableErrors = const [
      NotificationErrorType.networkError,
      NotificationErrorType.serverError,
      NotificationErrorType.timeoutError,
    ],
  });
  final RetryStrategy strategy;
  final int maxRetries;
  final Duration initialDelay;
  final Duration maxDelay;
  final double backoffMultiplier;
  final List<NotificationErrorType> retryableErrors;
}

/// Serviço para tratamento de erros e retry logic de notificações
class NotificationErrorHandler {
  factory NotificationErrorHandler() => _instance;
  NotificationErrorHandler._internal();
  static final NotificationErrorHandler _instance = NotificationErrorHandler._internal();

  final Logger _logger = Logger();
  final Map<String, Timer> _retryTimers = {};
  final Map<String, int> _errorCounts = {};
  final List<NotificationError> _errorQueue = [];
  
  RetryConfig _retryConfig = const RetryConfig();
  
  /// Configura as opções de retry
  void configure(RetryConfig config) {
    _retryConfig = config;
    _logger.i('Configuração de retry atualizada: ${config.strategy.name}');
  }
  
  /// Processa um erro de notificação
  Future<bool> handleError({
    required NotificationError error,
    required Future<bool> Function() retryFunction,
    Function(NotificationError)? onMaxRetriesReached,
    Function(NotificationError, int)? onRetryAttempt,
  }) async {
    try {
      // Registrar erro
      await _logError(error);
      
      // Verificar se deve fazer retry
      if (!_shouldRetry(error)) {
        _logger.w('Erro não é elegível para retry: ${error.type.name}');
        onMaxRetriesReached?.call(error);
        return false;
      }
      
      // Verificar limite de retries
      if (error.retryCount >= _retryConfig.maxRetries) {
        _logger.e('Máximo de retries atingido para erro ${error.id}');
        await _handleMaxRetriesReached(error);
        onMaxRetriesReached?.call(error);
        return false;
      }
      
      // Calcular delay para próximo retry
      final delay = _calculateRetryDelay(error.retryCount);
      
      _logger.i('Agendando retry ${error.retryCount + 1}/${_retryConfig.maxRetries} para erro ${error.id} em ${delay.inSeconds}s');
      
      // Agendar retry
      return await _scheduleRetry(
        error: error,
        delay: delay,
        retryFunction: retryFunction,
        onMaxRetriesReached: onMaxRetriesReached,
        onRetryAttempt: onRetryAttempt,
      );
      
    } catch (e, stackTrace) {
      _logger.e('Erro ao processar erro de notificação', error: e, stackTrace: stackTrace);
      return false;
    }
  }
  
  /// Cria um erro de notificação a partir de uma exceção
  NotificationError createError({
    required dynamic exception,
    String? notificationId,
    String? userId,
    StackTrace? stackTrace,
  }) {
    final errorId = _generateErrorId();
    final type = _classifyError(exception);
    final severity = _determineSeverity(type);
    
    return NotificationError(
      id: errorId,
      type: type,
      severity: severity,
      message: exception.toString(),
      code: _extractErrorCode(exception),
      details: _extractErrorDetails(exception),
      timestamp: DateTime.now(),
      userId: userId,
      notificationId: notificationId,
      stackTrace: stackTrace?.toString(),
    );
  }
  
  /// Obtém estatísticas de erros
  Future<Map<String, dynamic>> getErrorStats({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final start = startDate ?? DateTime.now().subtract(const Duration(days: 7));
      final end = endDate ?? DateTime.now();
      
      final errors = await Supabase.instance.client
          .from('notification_errors')
          .select()
          .gte('timestamp', start.toIso8601String())
          .lte('timestamp', end.toIso8601String());
      
      final totalErrors = errors.length;
      final errorsByType = <String, int>{};
      final errorsBySeverity = <String, int>{};
      final errorsByHour = <int, int>{};
      
      for (final error in errors) {
        final type = error['type'] as String;
        final severity = error['severity'] as String;
        final timestamp = DateTime.parse(error['timestamp'] as String);
        
        errorsByType[type] = (errorsByType[type] ?? 0) + 1;
        errorsBySeverity[severity] = (errorsBySeverity[severity] ?? 0) + 1;
        errorsByHour[timestamp.hour] = (errorsByHour[timestamp.hour] ?? 0) + 1;
      }
      
      return {
        'period': {
          'start': start.toIso8601String(),
          'end': end.toIso8601String(),
        },
        'total_errors': totalErrors,
        'errors_by_type': errorsByType,
        'errors_by_severity': errorsBySeverity,
        'errors_by_hour': errorsByHour,
        'error_rate': _calculateErrorRate(start, end, totalErrors),
      };
      
    } catch (e) {
      _logger.e('Erro ao obter estatísticas de erros', error: e);
      return {'error': e.toString()};
    }
  }
  
  /// Obtém erros recentes
  Future<List<NotificationError>> getRecentErrors({
    int limit = 50,
    NotificationErrorType? type,
    ErrorSeverity? severity,
  }) async {
    try {
      final query = Supabase.instance.client
          .from('notification_errors')
          .select();
      
      if (type != null) {
        query.eq('type', type.name);
      }
      
      if (severity != null) {
        query.eq('severity', severity.name);
      }
      
      final response = await query
          .order('timestamp', ascending: false)
          .limit(limit);
      
      return response.map(_errorFromJson).toList();
      
    } catch (e) {
      _logger.e('Erro ao obter erros recentes', error: e);
      return [];
    }
  }
  
  /// Limpa erros antigos
  Future<int> cleanupOldErrors({int daysToKeep = 30}) async {
    try {
      final cutoffDate = DateTime.now().subtract(Duration(days: daysToKeep));
      
      final deletedRows = await Supabase.instance.client
          .from('notification_errors')
          .delete()
          .lt('timestamp', cutoffDate.toIso8601String());
      
      _logger.i('Erros antigos limpos: ${deletedRows.length} registros removidos');
      return deletedRows.length;
      
    } catch (e) {
      _logger.e('Erro ao limpar erros antigos', error: e);
      return 0;
    }
  }
  
  /// Cancela retry pendente
  void cancelRetry(String errorId) {
    final timer = _retryTimers[errorId];
    if (timer != null) {
      timer.cancel();
      _retryTimers.remove(errorId);
      _logger.i('Retry cancelado para erro $errorId');
    }
  }
  
  /// Cancela todos os retries pendentes
  void cancelAllRetries() {
    for (final timer in _retryTimers.values) {
      timer.cancel();
    }
    _retryTimers.clear();
    _logger.i('Todos os retries cancelados');
  }
  
  /// Verifica se deve fazer retry
  bool _shouldRetry(NotificationError error) => _retryConfig.retryableErrors.contains(error.type) &&
           error.retryCount < _retryConfig.maxRetries;
  
  /// Calcula delay para retry
  Duration _calculateRetryDelay(int retryCount) {
    switch (_retryConfig.strategy) {
      case RetryStrategy.exponentialBackoff:
        final delay = _retryConfig.initialDelay.inMilliseconds *
                     pow(_retryConfig.backoffMultiplier, retryCount);
        return Duration(
          milliseconds: min(delay.toInt(), _retryConfig.maxDelay.inMilliseconds),
        );
        
      case RetryStrategy.linearBackoff:
        final delay = _retryConfig.initialDelay.inMilliseconds * (retryCount + 1);
        return Duration(
          milliseconds: min(delay, _retryConfig.maxDelay.inMilliseconds),
        );
        
      case RetryStrategy.fixedDelay:
        return _retryConfig.initialDelay;
        
      case RetryStrategy.noRetry:
        return Duration.zero;
    }
  }
  
  /// Agenda retry
  Future<bool> _scheduleRetry({
    required NotificationError error,
    required Duration delay,
    required Future<bool> Function() retryFunction,
    Function(NotificationError)? onMaxRetriesReached,
    Function(NotificationError, int)? onRetryAttempt,
  }) async {
    final completer = Completer<bool>();
    
    _retryTimers[error.id] = Timer(delay, () async {
      try {
        final updatedError = error.copyWith(retryCount: error.retryCount + 1);
        
        onRetryAttempt?.call(updatedError, updatedError.retryCount);
        
        _logger.i('Executando retry ${updatedError.retryCount} para erro ${error.id}');
        
        final success = await retryFunction();
        
        if (success) {
          _logger.i('Retry bem-sucedido para erro ${error.id}');
          await _logRetrySuccess(updatedError);
          completer.complete(true);
        } else {
          _logger.w('Retry falhou para erro ${error.id}');
          
          // Tentar novamente se ainda há retries disponíveis
          if (updatedError.retryCount < _retryConfig.maxRetries) {
            final nextSuccess = await handleError(
              error: updatedError,
              retryFunction: retryFunction,
              onMaxRetriesReached: onMaxRetriesReached,
              onRetryAttempt: onRetryAttempt,
            );
            completer.complete(nextSuccess);
          } else {
            await _handleMaxRetriesReached(updatedError);
            onMaxRetriesReached?.call(updatedError);
            completer.complete(false);
          }
        }
        
      } catch (e, stackTrace) {
        _logger.e('Erro durante retry', error: e, stackTrace: stackTrace);
        completer.complete(false);
      } finally {
        _retryTimers.remove(error.id);
      }
    });
    
    return completer.future;
  }
  
  /// Registra erro no banco de dados
  Future<void> _logError(NotificationError error) async {
    try {
      await Supabase.instance.client
          .from('notification_errors')
          .insert(error.toJson());
      
      // Incrementar contador de erros
      final key = '${error.type.name}_${DateTime.now().hour}';
      _errorCounts[key] = (_errorCounts[key] ?? 0) + 1;
      
      // Adicionar à fila de erros para processamento
      _errorQueue.add(error);
      
      // Processar alertas se necessário
      await _processErrorAlerts(error);
      
    } catch (e) {
      _logger.e('Erro ao registrar erro no banco', error: e);
    }
  }
  
  /// Registra sucesso de retry
  Future<void> _logRetrySuccess(NotificationError error) async {
    try {
      await Supabase.instance.client
          .from('notification_retry_success')
          .insert({
            'error_id': error.id,
            'retry_count': error.retryCount,
            'resolved_at': DateTime.now().toIso8601String(),
            'resolution_time_seconds': DateTime.now().difference(error.timestamp).inSeconds,
          });
      
    } catch (e) {
      _logger.e('Erro ao registrar sucesso de retry', error: e);
    }
  }
  
  /// Trata quando máximo de retries é atingido
  Future<void> _handleMaxRetriesReached(NotificationError error) async {
    try {
      await Supabase.instance.client
          .from('notification_errors')
          .update({
            'max_retries_reached': true,
            'final_retry_at': DateTime.now().toIso8601String(),
          })
          .eq('id', error.id);
      
      // Enviar alerta crítico se necessário
      if (error.severity == ErrorSeverity.critical) {
        await _sendCriticalErrorAlert(error);
      }
      
    } catch (e) {
      _logger.e('Erro ao marcar máximo de retries atingido', error: e);
    }
  }
  
  /// Processa alertas de erro
  Future<void> _processErrorAlerts(NotificationError error) async {
    try {
      // Verificar se deve enviar alerta baseado na severidade
      if (error.severity == ErrorSeverity.critical) {
        await _sendCriticalErrorAlert(error);
      } else if (error.severity == ErrorSeverity.high) {
        // Verificar frequência de erros
        final recentErrors = await _getRecentErrorCount(error.type, const Duration(minutes: 5));
        if (recentErrors > 10) {
          await _sendHighFrequencyErrorAlert(error.type, recentErrors);
        }
      }
      
    } catch (e) {
      _logger.e('Erro ao processar alertas', error: e);
    }
  }
  
  /// Envia alerta de erro crítico
  Future<void> _sendCriticalErrorAlert(NotificationError error) async {
    try {
      // Implementar envio de alerta (email, Slack, etc.)
      _logger.e('ALERTA CRÍTICO: ${error.message}');
      
      // Registrar alerta enviado
      await Supabase.instance.client
          .from('notification_alerts')
          .insert({
            'error_id': error.id,
            'alert_type': 'critical_error',
            'message': 'Erro crítico de notificação: ${error.message}',
            'sent_at': DateTime.now().toIso8601String(),
          });
      
    } catch (e) {
      _logger.e('Erro ao enviar alerta crítico', error: e);
    }
  }
  
  /// Envia alerta de alta frequência de erros
  Future<void> _sendHighFrequencyErrorAlert(NotificationErrorType type, int count) async {
    try {
      _logger.w('ALERTA: Alta frequência de erros ${type.name}: $count erros em 5 minutos');
      
      await Supabase.instance.client
          .from('notification_alerts')
          .insert({
            'alert_type': 'high_frequency_error',
            'message': 'Alta frequência de erros ${type.name}: $count erros em 5 minutos',
            'error_type': type.name,
            'error_count': count,
            'sent_at': DateTime.now().toIso8601String(),
          });
      
    } catch (e) {
      _logger.e('Erro ao enviar alerta de alta frequência', error: e);
    }
  }
  
  /// Obtém contagem de erros recentes
  Future<int> _getRecentErrorCount(NotificationErrorType type, Duration period) async {
    try {
      final since = DateTime.now().subtract(period);
      
      final errors = await Supabase.instance.client
          .from('notification_errors')
          .select('id')
          .eq('type', type.name)
          .gte('timestamp', since.toIso8601String());
      
      return errors.length;
      
    } catch (e) {
      _logger.e('Erro ao obter contagem de erros recentes', error: e);
      return 0;
    }
  }
  
  /// Classifica tipo de erro
  NotificationErrorType _classifyError(dynamic exception) {
    final message = exception.toString().toLowerCase();
    
    if (message.contains('network') || message.contains('connection')) {
      return NotificationErrorType.networkError;
    } else if (message.contains('auth') || message.contains('unauthorized')) {
      return NotificationErrorType.authenticationError;
    } else if (message.contains('token') || message.contains('registration')) {
      return NotificationErrorType.invalidToken;
    } else if (message.contains('quota') || message.contains('limit')) {
      return NotificationErrorType.quotaExceeded;
    } else if (message.contains('server') || message.contains('500')) {
      return NotificationErrorType.serverError;
    } else if (message.contains('timeout')) {
      return NotificationErrorType.timeoutError;
    } else {
      return NotificationErrorType.unknownError;
    }
  }
  
  /// Determina severidade do erro
  ErrorSeverity _determineSeverity(NotificationErrorType type) {
    switch (type) {
      case NotificationErrorType.authenticationError:
      case NotificationErrorType.quotaExceeded:
        return ErrorSeverity.critical;
      case NotificationErrorType.serverError:
      case NotificationErrorType.invalidToken:
        return ErrorSeverity.high;
      case NotificationErrorType.networkError:
      case NotificationErrorType.timeoutError:
        return ErrorSeverity.medium;
      case NotificationErrorType.unknownError:
        return ErrorSeverity.low;
    }
  }
  
  /// Extrai código de erro
  String? _extractErrorCode(dynamic exception) {
    if (exception is HttpException) {
      return exception.message;
    } else if (exception is SocketException) {
      return exception.osError?.errorCode.toString();
    }
    return null;
  }
  
  /// Extrai detalhes do erro
  Map<String, dynamic>? _extractErrorDetails(dynamic exception) {
    final details = <String, dynamic>{};
    
    if (exception is HttpException) {
      details['uri'] = exception.uri?.toString();
    } else if (exception is SocketException) {
      details['address'] = exception.address?.toString();
      details['port'] = exception.port;
    }
    
    return details.isNotEmpty ? details : null;
  }
  
  /// Gera ID único para erro
  String _generateErrorId() => 'err_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(1000)}';
  
  /// Calcula taxa de erro
  double _calculateErrorRate(DateTime start, DateTime end, int errorCount) {
    final hours = end.difference(start).inHours;
    return hours > 0 ? errorCount / hours : 0.0;
  }
  
  /// Cria NotificationError a partir de JSON
  NotificationError _errorFromJson(Map<String, dynamic> json) => NotificationError(
      id: json['id'] as String,
      type: NotificationErrorType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => NotificationErrorType.unknownError,
      ),
      severity: ErrorSeverity.values.firstWhere(
        (e) => e.name == json['severity'],
        orElse: () => ErrorSeverity.low,
      ),
      message: json['message'] as String,
      code: json['code'] as String?,
      details: json['details'] as Map<String, dynamic>?,
      timestamp: DateTime.parse(json['timestamp'] as String),
      userId: json['user_id'] as String?,
      notificationId: json['notification_id'] as String?,
      retryCount: json['retry_count'] as int? ?? 0,
      stackTrace: json['stack_trace'] as String?,
    );
}