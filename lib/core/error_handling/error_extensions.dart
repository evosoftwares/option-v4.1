/// Extensões úteis para o sistema de tratamento de erros
/// Facilita o uso do sistema de erros em toda a aplicação
library;

import 'dart:async';

import 'package:flutter/material.dart';

import 'app_error.dart';
import 'error_notifier.dart';
import 'global_error_handler.dart';

/// Extensão para Future com tratamento de erro automático
extension FutureErrorHandling<T> on Future<T> {
  /// Executa o Future com tratamento automático de erro
  Future<T?> withErrorHandling({
    String? operationName,
    AppErrorType? defaultErrorType,
    String? userMessage,
    Map<String, dynamic>? context,
    bool showUserNotification = true,
  }) async {
    try {
      return await this;
    } catch (error, stackTrace) {
      final appError = error is AppError 
          ? error 
          : AppError(
              type: defaultErrorType ?? AppErrorType.unknownError,
              message: error.toString(),
              userMessage: userMessage,
              technicalDetails: error.toString(),
              context: {
                'operation': operationName,
                ...?context,
              },
              stackTrace: stackTrace,
            );

      await GlobalErrorHandler.instance.handleError(
        appError,
        stackTrace: stackTrace,
      );

      if (showUserNotification) {
        ErrorNotificationService.instance.showError(appError);
      }

      return null;
    }
  }

  /// Executa o Future com fallback em caso de erro
  Future<T> withFallback(T fallbackValue, {
    String? operationName,
    bool logError = true,
  }) async {
    try {
      return await this;
    } catch (error, stackTrace) {
      if (logError) {
        await GlobalErrorHandler.instance.handleError(
          error,
          stackTrace: stackTrace,
          context: {'operation': operationName},
        );
      }
      return fallbackValue;
    }
  }

  /// Executa o Future com retry automático
  Future<T> withRetry({
    int maxRetries = 3,
    Duration delay = const Duration(seconds: 1),
    String? operationName,
    bool Function(Object error)? shouldRetry,
  }) async {
    var attempts = 0;
    
    while (attempts < maxRetries) {
      try {
        return await this;
      } catch (error, stackTrace) {
        attempts++;
        
        // Verifica se deve tentar novamente
        if (attempts >= maxRetries || 
            (shouldRetry != null && !shouldRetry(error))) {
          await GlobalErrorHandler.instance.handleError(
            error,
            stackTrace: stackTrace,
            context: {
              'operation': operationName,
              'attempts': attempts,
              'maxRetries': maxRetries,
            },
          );
          rethrow;
        }
        
        // Aguarda antes de tentar novamente
        await Future.delayed(delay * attempts);
      }
    }
    
    throw StateError('Não deveria chegar aqui');
  }
}

/// Extensão para BuildContext com utilitários de erro
extension BuildContextErrorHandling on BuildContext {
  /// Mostra um erro usando o contexto atual
  void showError(AppError error) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                error.displayMessage,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        action: SnackBarAction(
          label: 'Fechar',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(this).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  /// Mostra uma mensagem de sucesso
  void showSuccess(String message) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  /// Mostra uma mensagem de aviso
  void showWarning(String message) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.warning_outlined, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.orange.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  /// Mostra um dialog de erro
  Future<void> showErrorDialog(AppError error) async => showDialog(
      context: this,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red),
            SizedBox(width: 8),
            Text('Erro'),
          ],
        ),
        content: Text(error.displayMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
          if (error.severity == ErrorSeverity.critical)
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                // TODO: Implementar envio de relatório de erro
              },
              child: const Text('Reportar'),
            ),
        ],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
}

/// Extensão para Exception com conversão para AppError
extension ExceptionToAppError on Exception {
  /// Converte a exceção para AppError
  AppError toAppError({
    AppErrorType? type,
    String? userMessage,
    Map<String, dynamic>? context,
    ErrorSeverity severity = ErrorSeverity.medium,
  }) => AppError.fromException(
      this,
      type: type,
      userMessage: userMessage,
      context: context,
      severity: severity,
    );
}

/// Extensão para String com validações comuns
extension StringValidation on String {
  /// Valida se é um email válido
  AppError? validateEmail() {
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(this)) {
      return AppError(
        type: AppErrorType.validationFailed,
        message: 'Email inválido: $this',
        userMessage: 'Por favor, insira um email válido.',
      );
    }
    return null;
  }

  /// Valida se não está vazio
  AppError? validateNotEmpty(String fieldName) {
    if (trim().isEmpty) {
      return AppError(
        type: AppErrorType.missingRequiredField,
        message: 'Campo obrigatório vazio: $fieldName',
        userMessage: '$fieldName é obrigatório.',
      );
    }
    return null;
  }

  /// Valida comprimento mínimo
  AppError? validateMinLength(int minLength, String fieldName) {
    if (length < minLength) {
      return AppError(
        type: AppErrorType.validationFailed,
        message: 'Campo $fieldName muito curto: $length < $minLength',
        userMessage: '$fieldName deve ter pelo menos $minLength caracteres.',
      );
    }
    return null;
  }

  /// Valida se é um telefone válido (formato brasileiro)
  AppError? validatePhone() {
    final phoneRegex = RegExp(r'^\(?[1-9]{2}\)?\s?9?[0-9]{4}-?[0-9]{4}$');
    if (!phoneRegex.hasMatch(replaceAll(RegExp('[^0-9]'), ''))) {
      return AppError(
        type: AppErrorType.validationFailed,
        message: 'Telefone inválido: $this',
        userMessage: 'Por favor, insira um telefone válido.',
      );
    }
    return null;
  }
}

/// Mixin para widgets com tratamento de erro
mixin ErrorHandlingMixin<T extends StatefulWidget> on State<T> {
  /// Executa uma operação assíncrona com tratamento de erro
  Future<R?> executeWithErrorHandling<R>(
    Future<R> Function() operation, {
    String? operationName,
    AppErrorType? defaultErrorType,
    String? userMessage,
    bool showLoading = false,
    bool showUserNotification = true,
  }) async {
    if (showLoading) {
      // TODO: Implementar indicador de loading
    }

    try {
      final result = await operation();
      return result;
    } catch (error, stackTrace) {
      final appError = error is AppError 
          ? error 
          : AppError(
              type: defaultErrorType ?? AppErrorType.unknownError,
              message: error.toString(),
              userMessage: userMessage,
              technicalDetails: error.toString(),
              context: {
                'widget': widget.runtimeType.toString(),
                'operation': operationName,
              },
              stackTrace: stackTrace,
            );

      await GlobalErrorHandler.instance.handleError(
        appError,
        stackTrace: stackTrace,
      );

      if (showUserNotification && mounted) {
        context.showError(appError);
      }

      return null;
    } finally {
      if (showLoading) {
        // TODO: Esconder indicador de loading
      }
    }
  }

  /// Valida uma lista de campos
  List<AppError> validateFields(Map<String, String?> fields) {
    final errors = <AppError>[];
    
    for (final entry in fields.entries) {
      final fieldName = entry.key;
      final value = entry.value;
      
      if (value == null || value.trim().isEmpty) {
        errors.add(AppError(
          type: AppErrorType.missingRequiredField,
          message: 'Campo obrigatório vazio: $fieldName',
          userMessage: '$fieldName é obrigatório.',
        ));
      }
    }
    
    return errors;
  }

  /// Mostra erros de validação
  void showValidationErrors(List<AppError> errors) {
    if (errors.isNotEmpty && mounted) {
      final message = errors.map((e) => e.displayMessage).join('\n');
      context.showWarning(message);
    }
  }
}