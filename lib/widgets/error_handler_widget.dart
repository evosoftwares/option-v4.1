import 'package:flutter/material.dart';
import '../services/real_saved_places_service.dart';
import '../services/app_logger.dart';
import '../theme/app_spacing.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// Widget para exibir mensagens de erro de forma amigável ao usuário
class ErrorHandlerWidget {
  /// Exibe um SnackBar com mensagem de erro baseada no tipo de exceção
  static void showErrorSnackBar(BuildContext context, dynamic error) {
    String message;
    Color backgroundColor;
    IconData icon;

    if (error is ValidationException) {
      message = error.message;
      backgroundColor = AppColors.warning;
      icon = Icons.warning;
      AppLogger.warning('Erro de validação exibido ao usuário: ${error.message}');
    } else if (error is DatabaseException) {
      message = 'Erro no banco de dados. Tente novamente.';
      backgroundColor = AppColors.error;
      icon = Icons.error;
      AppLogger.error('Erro de banco exibido ao usuário: ${error.message}');
    } else if (error is NetworkException) {
      message = 'Erro de conexão. Verifique sua internet e tente novamente.';
      backgroundColor = AppColors.blue;
      icon = Icons.wifi_off;
      AppLogger.error('Erro de rede exibido ao usuário: ${error.message}');
    } else {
      message = 'Ocorreu um erro inesperado. Tente novamente.';
      backgroundColor = AppColors.gray400;
      icon = Icons.error_outline;
      AppLogger.error('Erro genérico exibido ao usuário: $error');
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: backgroundColor,
        action: SnackBarAction(
          label: 'OK',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  /// Exibe um dialog de erro para erros mais críticos
  static Future<void> showErrorDialog(BuildContext context, dynamic error) async {
    String title;
    String message;
    IconData icon;
    Color iconColor;

    if (error is ValidationException) {
      title = 'Dados Inválidos';
      message = error.message;
      icon = Icons.warning;
      iconColor = Colors.orange;
    } else if (error is DatabaseException) {
      title = 'Erro no Banco de Dados';
      message = 'Não foi possível salvar os dados. Tente novamente em alguns instantes.';
      icon = Icons.error;
      iconColor = Colors.red;
    } else if (error is NetworkException) {
      title = 'Erro de Conexão';
      message = 'Verifique sua conexão com a internet e tente novamente.';
      icon = Icons.wifi_off;
      iconColor = Colors.blue;
    } else {
      title = 'Erro Inesperado';
      message = 'Ocorreu um erro inesperado. Tente novamente ou entre em contato com o suporte.';
      icon = Icons.error_outline;
      iconColor = Colors.grey;
    }

    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
          title: Row(
            children: [
              Icon(icon, color: iconColor),
              const SizedBox(width: AppSpacing.sm),
              Text(title),
            ],
          ),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            ),
          ],
        ),
    );
  }

  /// Widget para exibir estado de carregamento com possibilidade de cancelamento
  static Widget buildLoadingWidget({
    required String message,
    VoidCallback? onCancel,
  }) => Center(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: AppSpacing.md),
              Text(
                message,
                style: AppTypography.bodyLarge,
                textAlign: TextAlign.center,
              ),
              if (onCancel != null) ...[
                const SizedBox(height: 16),
                TextButton(
                  onPressed: onCancel,
                  child: const Text('Cancelar'),
                ),
              ]
            ],
          ),
        ),
      ),
    );

  /// Widget para exibir estado de erro com opção de tentar novamente
  static Widget buildErrorWidget({
    required String message,
    VoidCallback? onRetry,
    IconData? icon,
  }) => Center(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon ?? Icons.error_outline,
                size: 48,
                color: AppColors.error,
              ),
              const SizedBox(height: 16),
              Text(
                message,
                style: const TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              if (onRetry != null) ...[
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: onRetry,
                  child: const Text('Tentar Novamente'),
                ),
              ]
            ],
          ),
        ),
      ),
    );
}