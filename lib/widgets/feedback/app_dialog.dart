import 'package:flutter/material.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../theme/app_colors.dart';

/// Tipos de diálogo disponíveis
enum AppDialogType {
  confirmation,
  alert,
  info,
  warning,
  error,
  success,
}

/// Widget de diálogo padronizado para o aplicativo
class AppDialog extends StatelessWidget {
  const AppDialog({
    super.key,
    required this.title,
    required this.content,
    this.type = AppDialogType.info,
    this.primaryAction,
    this.secondaryAction,
    this.actions,
    this.dismissible = true,
    this.showIcon = true,
  });

  final String title;
  final String content;
  final AppDialogType type;
  final AppDialogAction? primaryAction;
  final AppDialogAction? secondaryAction;
  final List<AppDialogAction>? actions;
  final bool dismissible;
  final bool showIcon;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final dialogConfig = _getDialogConfig(colorScheme);

    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      titlePadding: EdgeInsets.zero,
      contentPadding: EdgeInsets.zero,
      actionsPadding: EdgeInsets.zero,
      title: _buildTitle(dialogConfig),
      content: _buildContent(dialogConfig),
      actions: _buildActions(context),
      backgroundColor: colorScheme.surface,
      elevation: AppSpacing.elevation8,
    );
  }

  Widget _buildTitle(_DialogConfig config) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.sm,
      ),
      child: Row(
        children: [
          if (showIcon) ...[
            Icon(
              config.icon,
              color: config.iconColor,
              size: AppSpacing.iconMd,
            ),
            const SizedBox(width: AppSpacing.sm),
          ],
          Expanded(
            child: Text(
              title,
              style: AppTypography.titleLarge.copyWith(
                color: config.titleColor,
                fontWeight: AppTypography.semiBold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(_DialogConfig config) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        AppSpacing.lg,
      ),
      child: Text(
        content,
        style: AppTypography.bodyMedium.copyWith(
          color: config.contentColor,
        ),
      ),
    );
  }

  List<Widget> _buildActions(BuildContext context) {
    final List<AppDialogAction> actionsList = actions ??
        [
          if (secondaryAction != null) secondaryAction!,
          if (primaryAction != null) primaryAction!,
        ].where((action) => action != null).toList();

    if (actionsList.isEmpty) return [];

    return [
      Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: actionsList
              .asMap()
              .entries
              .map((entry) {
                final index = entry.key;
                final action = entry.value;
                return Padding(
                  padding: EdgeInsets.only(
                    left: index > 0 ? AppSpacing.sm : 0,
                  ),
                  child: _buildActionButton(context, action),
                );
              })
              .toList(),
        ),
      ),
    ];
  }

  Widget _buildActionButton(BuildContext context, AppDialogAction action) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return action.isPrimary
        ? ElevatedButton(
            onPressed: () => action.onPressed?.call(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.primary,
              foregroundColor: colorScheme.onPrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.sm,
              ),
            ),
            child: Text(
              action.label,
              style: AppTypography.bodyMedium.copyWith(
                fontWeight: AppTypography.semiBold,
              ),
            ),
          )
        : TextButton(
            onPressed: () => action.onPressed?.call(context),
            style: TextButton.styleFrom(
              foregroundColor: colorScheme.onSurface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.sm,
              ),
            ),
            child: Text(
              action.label,
              style: AppTypography.bodyMedium,
            ),
          );
  }

  _DialogConfig _getDialogConfig(ColorScheme colorScheme) {
    switch (type) {
      case AppDialogType.confirmation:
        return _DialogConfig(
          icon: Icons.help_outline,
          iconColor: colorScheme.primary,
          titleColor: colorScheme.onSurface,
          contentColor: colorScheme.onSurfaceVariant,
        );
      case AppDialogType.alert:
        return _DialogConfig(
          icon: Icons.warning_outlined,
          iconColor: AppColors.warning,
          titleColor: colorScheme.onSurface,
          contentColor: colorScheme.onSurfaceVariant,
        );
      case AppDialogType.info:
        return _DialogConfig(
          icon: Icons.info_outline,
          iconColor: AppColors.info,
          titleColor: colorScheme.onSurface,
          contentColor: colorScheme.onSurfaceVariant,
        );
      case AppDialogType.warning:
        return _DialogConfig(
          icon: Icons.warning_outlined,
          iconColor: AppColors.warning,
          titleColor: colorScheme.onSurface,
          contentColor: colorScheme.onSurfaceVariant,
        );
      case AppDialogType.error:
        return _DialogConfig(
          icon: Icons.error_outline,
          iconColor: AppColors.error,
          titleColor: colorScheme.onSurface,
          contentColor: colorScheme.onSurfaceVariant,
        );
      case AppDialogType.success:
        return _DialogConfig(
          icon: Icons.check_circle_outline,
          iconColor: AppColors.success,
          titleColor: colorScheme.onSurface,
          contentColor: colorScheme.onSurfaceVariant,
        );
    }
  }
}

/// Ação de diálogo
class AppDialogAction {
  const AppDialogAction({
    required this.label,
    this.onPressed,
    this.isPrimary = false,
  });

  final String label;
  final void Function(BuildContext context)? onPressed;
  final bool isPrimary;
}

/// Configuração interna do diálogo
class _DialogConfig {
  const _DialogConfig({
    required this.icon,
    required this.iconColor,
    required this.titleColor,
    required this.contentColor,
  });

  final IconData icon;
  final Color iconColor;
  final Color titleColor;
  final Color contentColor;
}

/// Utilitários para exibir diálogos
abstract class AppDialogUtils {
  /// Exibe um diálogo de confirmação
  static Future<bool?> showConfirmation(
    BuildContext context, {
    required String title,
    required String content,
    String confirmLabel = 'Confirmar',
    String cancelLabel = 'Cancelar',
    bool dismissible = true,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: dismissible,
      builder: (context) => AppDialog(
        type: AppDialogType.confirmation,
        title: title,
        content: content,
        dismissible: dismissible,
        primaryAction: AppDialogAction(
          label: confirmLabel,
          isPrimary: true,
          onPressed: (context) => Navigator.of(context).pop(true),
        ),
        secondaryAction: AppDialogAction(
          label: cancelLabel,
          onPressed: (context) => Navigator.of(context).pop(false),
        ),
      ),
    );
  }

  /// Exibe um diálogo de alerta
  static Future<void> showAlert(
    BuildContext context, {
    required String title,
    required String content,
    String buttonLabel = 'OK',
    AppDialogType type = AppDialogType.alert,
    bool dismissible = true,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: dismissible,
      builder: (context) => AppDialog(
        type: type,
        title: title,
        content: content,
        dismissible: dismissible,
        primaryAction: AppDialogAction(
          label: buttonLabel,
          isPrimary: true,
          onPressed: (context) => Navigator.of(context).pop(),
        ),
      ),
    );
  }

  /// Exibe um diálogo de erro
  static Future<void> showError(
    BuildContext context, {
    required String title,
    required String content,
    String buttonLabel = 'OK',
    bool dismissible = true,
  }) {
    return showAlert(
      context,
      title: title,
      content: content,
      buttonLabel: buttonLabel,
      type: AppDialogType.error,
      dismissible: dismissible,
    );
  }

  /// Exibe um diálogo de sucesso
  static Future<void> showSuccess(
    BuildContext context, {
    required String title,
    required String content,
    String buttonLabel = 'OK',
    bool dismissible = true,
  }) {
    return showAlert(
      context,
      title: title,
      content: content,
      buttonLabel: buttonLabel,
      type: AppDialogType.success,
      dismissible: dismissible,
    );
  }

  /// Exibe um diálogo de informação
  static Future<void> showInfo(
    BuildContext context, {
    required String title,
    required String content,
    String buttonLabel = 'OK',
    bool dismissible = true,
  }) {
    return showAlert(
      context,
      title: title,
      content: content,
      buttonLabel: buttonLabel,
      type: AppDialogType.info,
      dismissible: dismissible,
    );
  }

  /// Exibe um diálogo de aviso
  static Future<void> showWarning(
    BuildContext context, {
    required String title,
    required String content,
    String buttonLabel = 'OK',
    bool dismissible = true,
  }) {
    return showAlert(
      context,
      title: title,
      content: content,
      buttonLabel: buttonLabel,
      type: AppDialogType.warning,
      dismissible: dismissible,
    );
  }

  /// Exibe um diálogo personalizado
  static Future<T?> showCustom<T>(
    BuildContext context, {
    required AppDialog dialog,
    bool dismissible = true,
  }) {
    return showDialog<T>(
      context: context,
      barrierDismissible: dismissible,
      builder: (context) => dialog,
    );
  }
}