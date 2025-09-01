/// Sistema de logging de erros para monitoramento e debugging
/// Integrado com o sistema de tratamento de erros da aplicação

import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app_error.dart';

/// Interface para diferentes tipos de logger
abstract class ErrorLogger {
  Future<void> logError(AppError error);
  Future<void> logInfo(String message, {Map<String, dynamic>? context});
  Future<void> logWarning(String message, {Map<String, dynamic>? context});
}

/// Logger que escreve no console/debug
class ConsoleErrorLogger implements ErrorLogger {
  @override
  Future<void> logError(AppError error) async {
    if (kDebugMode) {
      developer.log(
        error.message,
        name: 'AppError',
        error: error,
        stackTrace: error.stackTrace,
        level: _getSeverityLevel(error.severity),
      );
    }
  }

  @override
  Future<void> logInfo(String message, {Map<String, dynamic>? context}) async {
    if (kDebugMode) {
      developer.log(
        message,
        name: 'AppInfo',
        level: 800, // Info level
      );
      if (context != null) {
        developer.log(
          'Context: $context',
          name: 'AppInfo',
          level: 800,
        );
      }
    }
  }

  @override
  Future<void> logWarning(String message, {Map<String, dynamic>? context}) async {
    if (kDebugMode) {
      developer.log(
        message,
        name: 'AppWarning',
        level: 900, // Warning level
      );
      if (context != null) {
        developer.log(
          'Context: $context',
          name: 'AppWarning',
          level: 900,
        );
      }
    }
  }

  int _getSeverityLevel(ErrorSeverity severity) {
    switch (severity) {
      case ErrorSeverity.low:
        return 800; // Info
      case ErrorSeverity.medium:
        return 900; // Warning
      case ErrorSeverity.high:
        return 1000; // Error
      case ErrorSeverity.critical:
        return 1200; // Severe
    }
  }
}

/// Logger que envia erros para o Supabase para monitoramento
class SupabaseErrorLogger implements ErrorLogger {
  final SupabaseClient _supabase;
  final String _tableName;

  SupabaseErrorLogger({
    required SupabaseClient supabase,
    String tableName = 'error_logs',
  }) : _supabase = supabase,
       _tableName = tableName;

  @override
  Future<void> logError(AppError error) async {
    try {
      // Só loga erros de severidade média ou superior em produção
      if (!kDebugMode && error.severity == ErrorSeverity.low) {
        return;
      }

      final logData = {
        'error_type': error.type.name,
        'message': error.message,
        'user_message': error.userMessage,
        'technical_details': error.technicalDetails,
        'severity': error.severity.name,
        'context': error.context,
        'timestamp': error.timestamp.toIso8601String(),
        'stack_trace': error.stackTrace?.toString(),
        'app_version': await _getAppVersion(),
        'platform': _getPlatform(),
      };

      await _supabase.from(_tableName).insert(logData);
    } catch (e) {
      // Se falhar ao logar no Supabase, loga no console
      if (kDebugMode) {
        developer.log(
          'Failed to log error to Supabase: $e',
          name: 'SupabaseErrorLogger',
          level: 1000,
        );
      }
    }
  }

  @override
  Future<void> logInfo(String message, {Map<String, dynamic>? context}) async {
    try {
      final logData = {
        'level': 'info',
        'message': message,
        'context': context,
        'timestamp': DateTime.now().toIso8601String(),
        'app_version': await _getAppVersion(),
        'platform': _getPlatform(),
      };

      await _supabase.from('app_logs').insert(logData);
    } catch (e) {
      if (kDebugMode) {
        developer.log(
          'Failed to log info to Supabase: $e',
          name: 'SupabaseErrorLogger',
          level: 900,
        );
      }
    }
  }

  @override
  Future<void> logWarning(String message, {Map<String, dynamic>? context}) async {
    try {
      final logData = {
        'level': 'warning',
        'message': message,
        'context': context,
        'timestamp': DateTime.now().toIso8601String(),
        'app_version': await _getAppVersion(),
        'platform': _getPlatform(),
      };

      await _supabase.from('app_logs').insert(logData);
    } catch (e) {
      if (kDebugMode) {
        developer.log(
          'Failed to log warning to Supabase: $e',
          name: 'SupabaseErrorLogger',
          level: 900,
        );
      }
    }
  }

  Future<String> _getAppVersion() async {
    // TODO: Implementar obtenção da versão do app
    return '1.0.0';
  }

  String _getPlatform() {
    if (kIsWeb) return 'web';
    return defaultTargetPlatform.name;
  }
}

/// Logger composto que pode usar múltiplos loggers
class CompositeErrorLogger implements ErrorLogger {
  final List<ErrorLogger> _loggers;

  CompositeErrorLogger(this._loggers);

  @override
  Future<void> logError(AppError error) async {
    await Future.wait(
      _loggers.map((logger) => logger.logError(error)),
    );
  }

  @override
  Future<void> logInfo(String message, {Map<String, dynamic>? context}) async {
    await Future.wait(
      _loggers.map((logger) => logger.logInfo(message, context: context)),
    );
  }

  @override
  Future<void> logWarning(String message, {Map<String, dynamic>? context}) async {
    await Future.wait(
      _loggers.map((logger) => logger.logWarning(message, context: context)),
    );
  }
}

/// Singleton para gerenciar o sistema de logging
class ErrorLoggingService {
  static ErrorLoggingService? _instance;
  static ErrorLoggingService get instance {
    _instance ??= ErrorLoggingService._internal();
    return _instance!;
  }

  ErrorLoggingService._internal();

  ErrorLogger? _logger;

  /// Inicializa o sistema de logging
  void initialize({
    required SupabaseClient supabaseClient,
    bool enableConsoleLogging = true,
    bool enableSupabaseLogging = true,
  }) {
    final loggers = <ErrorLogger>[];

    if (enableConsoleLogging) {
      loggers.add(ConsoleErrorLogger());
    }

    if (enableSupabaseLogging) {
      loggers.add(SupabaseErrorLogger(supabase: supabaseClient));
    }

    _logger = loggers.length == 1 
        ? loggers.first 
        : CompositeErrorLogger(loggers);
  }

  /// Loga um erro
  Future<void> logError(AppError error) async {
    await _logger?.logError(error);
  }

  /// Loga informação
  Future<void> logInfo(String message, {Map<String, dynamic>? context}) async {
    await _logger?.logInfo(message, context: context);
  }

  /// Loga aviso
  Future<void> logWarning(String message, {Map<String, dynamic>? context}) async {
    await _logger?.logWarning(message, context: context);
  }

  /// Loga uma exceção genérica convertendo para AppError
  Future<void> logException(
    Exception exception, {
    AppErrorType? type,
    String? userMessage,
    Map<String, dynamic>? context,
    ErrorSeverity severity = ErrorSeverity.medium,
  }) async {
    final appError = AppError.fromException(
      exception,
      type: type,
      userMessage: userMessage,
      context: context,
      severity: severity,
    );
    await logError(appError);
  }
}