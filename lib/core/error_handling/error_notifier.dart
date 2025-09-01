/// Sistema de notificação de erros para o usuário
/// Integrado com o sistema de tratamento de erros da aplicação

import 'package:flutter/material.dart';
import 'app_error.dart';

/// Interface para diferentes tipos de notificação de erro
abstract class ErrorNotifier {
  void showError(AppError error);
  void showSuccess(String message);
  void showWarning(String message);
  void showInfo(String message);
}

/// Notificador que usa SnackBar
class SnackBarErrorNotifier implements ErrorNotifier {
  final GlobalKey<ScaffoldMessengerState>? scaffoldMessengerKey;

  SnackBarErrorNotifier({this.scaffoldMessengerKey});

  @override
  void showError(AppError error) {
    _showSnackBar(
      message: error.displayMessage,
      backgroundColor: Colors.red.shade600,
      icon: Icons.error_outline,
      duration: _getDurationForSeverity(error.severity),
    );
  }

  @override
  void showSuccess(String message) {
    _showSnackBar(
      message: message,
      backgroundColor: Colors.green.shade600,
      icon: Icons.check_circle_outline,
    );
  }

  @override
  void showWarning(String message) {
    _showSnackBar(
      message: message,
      backgroundColor: Colors.orange.shade600,
      icon: Icons.warning_outlined,
    );
  }

  @override
  void showInfo(String message) {
    _showSnackBar(
      message: message,
      backgroundColor: Colors.blue.shade600,
      icon: Icons.info_outline,
    );
  }

  void _showSnackBar({
    required String message,
    required Color backgroundColor,
    required IconData icon,
    Duration duration = const Duration(seconds: 4),
  }) {
    final context = _getCurrentContext();
    final scaffoldMessenger = scaffoldMessengerKey?.currentState ?? 
        (context != null ? ScaffoldMessenger.maybeOf(context) : null);
    
    if (scaffoldMessenger != null) {
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(icon, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
          backgroundColor: backgroundColor,
          duration: duration,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          action: SnackBarAction(
            label: 'Fechar',
            textColor: Colors.white,
            onPressed: () {
              scaffoldMessenger.hideCurrentSnackBar();
            },
          ),
        ),
      );
    }
  }

  Duration _getDurationForSeverity(ErrorSeverity severity) {
    switch (severity) {
      case ErrorSeverity.low:
        return const Duration(seconds: 3);
      case ErrorSeverity.medium:
        return const Duration(seconds: 4);
      case ErrorSeverity.high:
        return const Duration(seconds: 6);
      case ErrorSeverity.critical:
        return const Duration(seconds: 8);
    }
  }

  BuildContext? _getCurrentContext() {
    // Tenta obter o contexto atual do navigator
    final element = WidgetsBinding.instance.rootElement;
    if (element != null) {
      return Navigator.maybeOf(element)?.context;
    }
    return null;
  }
}

/// Notificador que usa Dialog
class DialogErrorNotifier implements ErrorNotifier {
  final GlobalKey<NavigatorState>? navigatorKey;

  DialogErrorNotifier({this.navigatorKey});

  @override
  void showError(AppError error) {
    _showDialog(
      title: 'Erro',
      message: error.displayMessage,
      icon: Icons.error_outline,
      iconColor: Colors.red,
      actions: [
        TextButton(
          onPressed: () => _closeDialog(),
          child: const Text('OK'),
        ),
        if (error.severity == ErrorSeverity.critical)
          TextButton(
            onPressed: () {
              _closeDialog();
              // TODO: Implementar envio de relatório de erro
            },
            child: const Text('Reportar'),
          ),
      ],
    );
  }

  @override
  void showSuccess(String message) {
    _showDialog(
      title: 'Sucesso',
      message: message,
      icon: Icons.check_circle_outline,
      iconColor: Colors.green,
      actions: [
        TextButton(
          onPressed: () => _closeDialog(),
          child: const Text('OK'),
        ),
      ],
    );
  }

  @override
  void showWarning(String message) {
    _showDialog(
      title: 'Atenção',
      message: message,
      icon: Icons.warning_outlined,
      iconColor: Colors.orange,
      actions: [
        TextButton(
          onPressed: () => _closeDialog(),
          child: const Text('OK'),
        ),
      ],
    );
  }

  @override
  void showInfo(String message) {
    _showDialog(
      title: 'Informação',
      message: message,
      icon: Icons.info_outline,
      iconColor: Colors.blue,
      actions: [
        TextButton(
          onPressed: () => _closeDialog(),
          child: const Text('OK'),
        ),
      ],
    );
  }

  void _showDialog({
    required String title,
    required String message,
    required IconData icon,
    required Color iconColor,
    required List<Widget> actions,
  }) {
    final context = _getCurrentContext();
    if (context != null) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: Row(
            children: [
              Icon(icon, color: iconColor),
              const SizedBox(width: 8),
              Text(title),
            ],
          ),
          content: Text(message),
          actions: actions,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  void _closeDialog() {
    final context = _getCurrentContext();
    if (context != null) {
      Navigator.of(context).pop();
    }
  }

  BuildContext? _getCurrentContext() {
    if (navigatorKey?.currentContext != null) {
      return navigatorKey!.currentContext;
    }
    
    final element = WidgetsBinding.instance.rootElement;
    if (element != null) {
      return Navigator.maybeOf(element)?.context;
    }
    return null;
  }
}

/// Notificador composto que pode usar múltiplos notificadores
class CompositeErrorNotifier implements ErrorNotifier {
  final List<ErrorNotifier> _notifiers;

  CompositeErrorNotifier(this._notifiers);

  @override
  void showError(AppError error) {
    for (final notifier in _notifiers) {
      notifier.showError(error);
    }
  }

  @override
  void showSuccess(String message) {
    for (final notifier in _notifiers) {
      notifier.showSuccess(message);
    }
  }

  @override
  void showWarning(String message) {
    for (final notifier in _notifiers) {
      notifier.showWarning(message);
    }
  }

  @override
  void showInfo(String message) {
    for (final notifier in _notifiers) {
      notifier.showInfo(message);
    }
  }
}

/// Singleton para gerenciar o sistema de notificação de erros
class ErrorNotificationService {
  static ErrorNotificationService? _instance;
  static ErrorNotificationService get instance {
    _instance ??= ErrorNotificationService._internal();
    return _instance!;
  }

  ErrorNotificationService._internal();

  ErrorNotifier? _notifier;

  /// Inicializa o sistema de notificação
  void initialize({
    GlobalKey<ScaffoldMessengerState>? scaffoldMessengerKey,
    GlobalKey<NavigatorState>? navigatorKey,
    bool useSnackBar = true,
    bool useDialog = false,
  }) {
    final notifiers = <ErrorNotifier>[];

    if (useSnackBar) {
      notifiers.add(SnackBarErrorNotifier(
        scaffoldMessengerKey: scaffoldMessengerKey,
      ));
    }

    if (useDialog) {
      notifiers.add(DialogErrorNotifier(
        navigatorKey: navigatorKey,
      ));
    }

    _notifier = notifiers.length == 1 
        ? notifiers.first 
        : CompositeErrorNotifier(notifiers);
  }

  /// Mostra um erro
  void showError(AppError error) {
    _notifier?.showError(error);
  }

  /// Mostra uma mensagem de sucesso
  void showSuccess(String message) {
    _notifier?.showSuccess(message);
  }

  /// Mostra uma mensagem de aviso
  void showWarning(String message) {
    _notifier?.showWarning(message);
  }

  /// Mostra uma mensagem informativa
  void showInfo(String message) {
    _notifier?.showInfo(message);
  }
}