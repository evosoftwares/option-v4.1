/// Handler global de erros para capturar e tratar erros não tratados
/// Integrado com o sistema de logging e notificação de usuário
library;

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'app_error.dart';
import 'error_logger.dart';
import 'error_notifier.dart';

/// Configuração do handler global de erros
class GlobalErrorHandlerConfig {

  const GlobalErrorHandlerConfig({
    this.enableErrorReporting = true,
    this.showErrorDialog = true,
    this.enableCrashlytics = false,
    this.errorDisplayDuration = const Duration(seconds: 5),
    this.silentErrors = const [],
  });
  final bool enableErrorReporting;
  final bool showErrorDialog;
  final bool enableCrashlytics;
  final Duration errorDisplayDuration;
  final List<AppErrorType> silentErrors;
}

/// Handler global de erros da aplicação
class GlobalErrorHandler {

  GlobalErrorHandler._internal();
  static GlobalErrorHandler? _instance;
  static GlobalErrorHandler get instance {
    _instance ??= GlobalErrorHandler._internal();
    return _instance!;
  }

  GlobalErrorHandlerConfig _config = const GlobalErrorHandlerConfig();
  ErrorLoggingService get _logger => ErrorLoggingService.instance;
  ErrorNotificationService get _notifier => ErrorNotificationService.instance;

  /// Inicializa o handler global de erros
  void initialize({
    GlobalErrorHandlerConfig? config,
  }) {
    _config = config ?? const GlobalErrorHandlerConfig();
    
    // Configura o handler de erros do Flutter
    FlutterError.onError = _handleFlutterError;
    
    // Configura o handler de erros de zona
    PlatformDispatcher.instance.onError = _handlePlatformError;
    
    // Configura o handler de erros não tratados
    runZonedGuarded(
      () {
        // A aplicação principal será executada aqui
      },
      _handleZoneError,
    );
  }

  /// Trata erros do Flutter framework
  void _handleFlutterError(FlutterErrorDetails details) {
    final appError = AppError(
      type: AppErrorType.unknownError,
      message: details.exception.toString(),
      technicalDetails: details.toString(),
      severity: _getErrorSeverity(details),
      context: {
        'library': details.library,
        'context': details.context?.toString(),
        'stack': details.stack?.toString(),
      },
      stackTrace: details.stack,
    );

    _processError(appError);

    // Em debug, mostra o erro padrão do Flutter
    if (kDebugMode) {
      FlutterError.presentError(details);
    }
  }

  /// Trata erros da plataforma
  bool _handlePlatformError(Object error, StackTrace stack) {
    final appError = AppError(
      type: _detectErrorTypeFromObject(error),
      message: error.toString(),
      technicalDetails: 'Platform error: ${error.toString()}',
      severity: ErrorSeverity.high,
      context: {
        'source': 'platform',
        'errorType': error.runtimeType.toString(),
      },
      stackTrace: stack,
    );

    _processError(appError);
    return true; // Indica que o erro foi tratado
  }

  /// Trata erros de zona
  void _handleZoneError(Object error, StackTrace stack) {
    final appError = AppError(
      type: _detectErrorTypeFromObject(error),
      message: error.toString(),
      technicalDetails: 'Zone error: ${error.toString()}',
      severity: ErrorSeverity.high,
      context: {
        'source': 'zone',
        'errorType': error.runtimeType.toString(),
      },
      stackTrace: stack,
    );

    _processError(appError);
  }

  /// Processa um erro capturado
  Future<void> _processError(AppError error) async {
    try {
      // Loga o erro
      if (_config.enableErrorReporting) {
        await _logger.logError(error);
      }

      // Notifica o usuário se não for um erro silencioso
      if (!_config.silentErrors.contains(error.type)) {
        if (_config.showErrorDialog) {
          _notifier.showError(error);
        }
      }

      // Envia para crashlytics se habilitado
      if (_config.enableCrashlytics) {
        await _sendToCrashlytics(error);
      }
    } catch (e) {
      // Se falhar ao processar o erro, pelo menos loga no console
      if (kDebugMode) {
        debugPrint('Failed to process error: $e');
        debugPrint('Original error: ${error.message}');
      }
    }
  }

  /// Trata um erro manualmente
  Future<void> handleError(
    Object error, {
    StackTrace? stackTrace,
    AppErrorType? type,
    String? userMessage,
    Map<String, dynamic>? context,
    ErrorSeverity severity = ErrorSeverity.medium,
  }) async {
    AppError appError;
    
    if (error is AppError) {
      appError = error;
    } else if (error is Exception) {
      appError = AppError.fromException(
        error,
        type: type,
        userMessage: userMessage,
        context: context,
        severity: severity,
      );
    } else {
      appError = AppError(
        type: type ?? AppErrorType.unknownError,
        message: error.toString(),
        userMessage: userMessage,
        technicalDetails: error.toString(),
        severity: severity,
        context: context,
        stackTrace: stackTrace ?? StackTrace.current,
      );
    }

    await _processError(appError);
  }

  /// Detecta o tipo de erro baseado no objeto
  AppErrorType _detectErrorTypeFromObject(Object error) {
    final errorString = error.toString().toLowerCase();
    
    if (error is PlatformException) {
      if (error.code.contains('permission')) {
        return AppErrorType.authorizationDenied;
      }
      if (error.code.contains('network')) {
        return AppErrorType.networkUnavailable;
      }
    }
    
    if (errorString.contains('socket') || 
        errorString.contains('network') ||
        errorString.contains('connection')) {
      return AppErrorType.networkUnavailable;
    }
    
    if (errorString.contains('timeout')) {
      return AppErrorType.connectionTimeout;
    }
    
    if (errorString.contains('permission') || 
        errorString.contains('unauthorized')) {
      return AppErrorType.authorizationDenied;
    }
    
    if (errorString.contains('validation') || 
        errorString.contains('invalid')) {
      return AppErrorType.validationFailed;
    }
    
    return AppErrorType.unknownError;
  }

  /// Determina a severidade do erro baseado nos detalhes
  ErrorSeverity _getErrorSeverity(FlutterErrorDetails details) {
    final errorString = details.exception.toString().toLowerCase();
    
    // Erros críticos
    if (errorString.contains('assertion') ||
        errorString.contains('null check') ||
        errorString.contains('range error')) {
      return ErrorSeverity.critical;
    }
    
    // Erros altos
    if (errorString.contains('state error') ||
        errorString.contains('format exception') ||
        errorString.contains('type error')) {
      return ErrorSeverity.high;
    }
    
    // Erros médios
    if (errorString.contains('timeout') ||
        errorString.contains('network')) {
      return ErrorSeverity.medium;
    }
    
    return ErrorSeverity.medium;
  }

  /// Envia erro para crashlytics (placeholder)
  Future<void> _sendToCrashlytics(AppError error) async {
    // TODO: Implementar integração com Firebase Crashlytics
    // FirebaseCrashlytics.instance.recordError(
    //   error.message,
    //   error.stackTrace,
    //   fatal: error.severity == ErrorSeverity.critical,
    // );
  }

  /// Executa uma função com tratamento de erro
  Future<T?> runWithErrorHandling<T>(
    Future<T> Function() function, {
    String? operationName,
    AppErrorType? defaultErrorType,
    String? userMessage,
    Map<String, dynamic>? context,
  }) async {
    try {
      return await function();
    } catch (error, stackTrace) {
      await handleError(
        error,
        stackTrace: stackTrace,
        type: defaultErrorType,
        userMessage: userMessage,
        context: {
          'operation': operationName,
          ...?context,
        },
      );
      return null;
    }
  }

  /// Executa uma função síncrona com tratamento de erro
  T? runSyncWithErrorHandling<T>(
    T Function() function, {
    String? operationName,
    AppErrorType? defaultErrorType,
    String? userMessage,
    Map<String, dynamic>? context,
  }) {
    try {
      return function();
    } catch (error, stackTrace) {
      handleError(
        error,
        stackTrace: stackTrace,
        type: defaultErrorType,
        userMessage: userMessage,
        context: {
          'operation': operationName,
          ...?context,
        },
      );
      return null;
    }
  }
}