/// Widgets de feedback visual para operações de carteira
/// 
/// Este arquivo contém componentes visuais que fornecem feedback imediato
/// ao usuário sobre operações de carteira, como adição de crédito,
/// saques e transações.
library;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../utils/wallet_constants.dart';

/// Feedback visual para operações de carteira
/// 
/// Exibe animações e mensagens de sucesso/erro para operações de carteira
class WalletOperationFeedback extends StatelessWidget {
  const WalletOperationFeedback({
    super.key,
    required this.type,
    required this.title,
    required this.message,
    this.onRetry,
    this.onClose,
  });

  final WalletOperationType type;
  final String title;
  final String message;
  final VoidCallback? onRetry;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Container(
      margin: const EdgeInsets.all(AppSpacing.md),
      padding: AppSpacing.paddingLg,
      decoration: BoxDecoration(
        color: _getBackgroundColor(colorScheme),
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        border: Border.all(color: _getBorderColor(colorScheme)),
        boxShadow: [
          BoxShadow(
            color: _getShadowColor(colorScheme),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(
                _getIcon(),
                color: _getIconColor(colorScheme),
                size: AppSpacing.iconLg,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  title,
                  style: AppTypography.titleMedium.copyWith(
                    color: _getTitleColor(colorScheme),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (onClose != null)
                IconButton(
                  onPressed: onClose,
                  icon: Icon(
                    Icons.close,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            message,
            style: AppTypography.bodyMedium.copyWith(
              color: _getMessageColor(colorScheme),
            ),
            textAlign: TextAlign.left,
          ),
          if (onRetry != null) ...[
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: onRetry,
                style: FilledButton.styleFrom(
                  backgroundColor: _getButtonColor(colorScheme),
                  foregroundColor: _getButtonTextColor(colorScheme),
                ),
                child: const Text('Tentar novamente'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Color _getBackgroundColor(ColorScheme colorScheme) {
    switch (type) {
      case WalletOperationType.success:
        return colorScheme.primaryContainer;
      case WalletOperationType.error:
        return colorScheme.errorContainer;
      case WalletOperationType.warning:
        return colorScheme.secondaryContainer;
      case WalletOperationType.info:
        return colorScheme.surfaceContainerHighest;
    }
  }

  Color _getBorderColor(ColorScheme colorScheme) {
    switch (type) {
      case WalletOperationType.success:
        return colorScheme.primary.withValues(alpha: 0.3);
      case WalletOperationType.error:
        return colorScheme.error.withValues(alpha: 0.3);
      case WalletOperationType.warning:
        return colorScheme.secondary.withValues(alpha: 0.3);
      case WalletOperationType.info:
        return colorScheme.outlineVariant;
    }
  }

  Color _getShadowColor(ColorScheme colorScheme) {
    switch (type) {
      case WalletOperationType.success:
        return colorScheme.primary.withValues(alpha: 0.2);
      case WalletOperationType.error:
        return colorScheme.error.withValues(alpha: 0.2);
      case WalletOperationType.warning:
        return colorScheme.secondary.withValues(alpha: 0.2);
      case WalletOperationType.info:
        return AppColors.black.withValues(alpha: 0.1);
    }
  }

  IconData _getIcon() {
    switch (type) {
      case WalletOperationType.success:
        return Icons.check_circle;
      case WalletOperationType.error:
        return Icons.error_outline;
      case WalletOperationType.warning:
        return Icons.warning_amber_outlined;
      case WalletOperationType.info:
        return Icons.info_outline;
    }
  }

  Color _getIconColor(ColorScheme colorScheme) {
    switch (type) {
      case WalletOperationType.success:
        return colorScheme.primary;
      case WalletOperationType.error:
        return colorScheme.error;
      case WalletOperationType.warning:
        return colorScheme.secondary;
      case WalletOperationType.info:
        return colorScheme.onSurfaceVariant;
    }
  }

  Color _getTitleColor(ColorScheme colorScheme) {
    switch (type) {
      case WalletOperationType.success:
        return colorScheme.onPrimaryContainer;
      case WalletOperationType.error:
        return colorScheme.onErrorContainer;
      case WalletOperationType.warning:
        return colorScheme.onSecondaryContainer;
      case WalletOperationType.info:
        return colorScheme.onSurface;
    }
  }

  Color _getMessageColor(ColorScheme colorScheme) {
    switch (type) {
      case WalletOperationType.success:
        return colorScheme.onPrimaryContainer;
      case WalletOperationType.error:
        return colorScheme.onErrorContainer;
      case WalletOperationType.warning:
        return colorScheme.onSecondaryContainer;
      case WalletOperationType.info:
        return colorScheme.onSurfaceVariant;
    }
  }

  Color _getButtonColor(ColorScheme colorScheme) {
    switch (type) {
      case WalletOperationType.success:
        return colorScheme.primary;
      case WalletOperationType.error:
        return colorScheme.error;
      case WalletOperationType.warning:
        return colorScheme.secondary;
      case WalletOperationType.info:
        return colorScheme.primary;
    }
  }

  Color _getButtonTextColor(ColorScheme colorScheme) {
    switch (type) {
      case WalletOperationType.success:
        return colorScheme.onPrimary;
      case WalletOperationType.error:
        return colorScheme.onError;
      case WalletOperationType.warning:
        return colorScheme.onSecondary;
      case WalletOperationType.info:
        return colorScheme.onPrimary;
    }
  }
}

/// Tipos de operações de carteira para feedback visual
enum WalletOperationType {
  success,
  error,
  warning,
  info,
}

/// Indicador de progresso para operações de carteira
/// 
/// Exibe um indicador visual de que uma operação está em andamento
class WalletProgressIndicator extends StatelessWidget {
  const WalletProgressIndicator({
    super.key,
    this.message = 'Processando...',
  });

  final String message;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Container(
      padding: AppSpacing.paddingLg,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: AppSpacing.iconLg,
            height: AppSpacing.iconLg,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Text(
            message,
            style: AppTypography.bodyLarge.copyWith(
              color: colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

/// Componente de notificação em tempo real para transações
/// 
/// Exibe notificações sutis no topo da tela para transações recentes
class TransactionNotification extends StatefulWidget {
  const TransactionNotification({
    super.key,
    required this.amount,
    required this.description,
    required this.isCredit,
    this.duration = const Duration(seconds: 5),
    this.onDismiss,
  });

  final double amount;
  final String description;
  final bool isCredit;
  final Duration duration;
  final VoidCallback? onDismiss;

  @override
  State<TransactionNotification> createState() => _TransactionNotificationState();
}

class _TransactionNotificationState extends State<TransactionNotification>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _offsetAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _offsetAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _controller.forward();

    // Auto-dismiss after duration
    Future.delayed(widget.duration, () {
      if (mounted) {
        _dismiss();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _dismiss() {
    _controller.reverse().then((_) {
      if (mounted) {
        widget.onDismiss?.call();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isCredit = widget.isCredit;
    
    return SlideTransition(
      position: _offsetAnimation,
      child: Container(
        margin: const EdgeInsets.all(AppSpacing.md),
        padding: AppSpacing.paddingMd,
        decoration: BoxDecoration(
          color: isCredit ? colorScheme.primaryContainer : colorScheme.secondaryContainer,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          border: Border.all(
            color: isCredit 
                ? colorScheme.primary.withValues(alpha: 0.3) 
                : colorScheme.secondary.withValues(alpha: 0.3),
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.black.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: isCredit ? colorScheme.primary : colorScheme.secondary,
              foregroundColor: isCredit ? colorScheme.onPrimary : colorScheme.onSecondary,
              radius: AppSpacing.iconXs,
              child: Icon(
                isCredit ? Icons.add : Icons.remove,
                size: AppSpacing.iconXs,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.description,
                    style: AppTypography.bodyMedium.copyWith(
                      color: isCredit ? colorScheme.onPrimaryContainer : colorScheme.onSecondaryContainer,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '${isCredit ? '+' : '-'} ${WalletConstants.currencySymbol}${widget.amount.toStringAsFixed(2)}',
                    style: AppTypography.bodySmall.copyWith(
                      color: isCredit ? colorScheme.onPrimaryContainer : colorScheme.onSecondaryContainer,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: _dismiss,
              icon: Icon(
                Icons.close,
                size: AppSpacing.iconXs,
                color: isCredit ? colorScheme.onPrimaryContainer : colorScheme.onSecondaryContainer,
              ),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
      ),
    );
  }
}

/// Componente de confirmação visual para transações
/// 
/// Exibe uma animação de confirmação quando uma transação é concluída
class TransactionConfirmation extends StatefulWidget {
  const TransactionConfirmation({
    super.key,
    required this.amount,
    required this.description,
    required this.isSuccess,
    this.onComplete,
  });

  final double amount;
  final String description;
  final bool isSuccess;
  final VoidCallback? onComplete;

  @override
  State<TransactionConfirmation> createState() => _TransactionConfirmationState();
}

class _TransactionConfirmationState extends State<TransactionConfirmation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.3, 1.0)),
    );

    _controller.forward().then((_) {
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          widget.onComplete?.call();
        }
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isSuccess = widget.isSuccess;
    
    return ScaleTransition(
      scale: _scaleAnimation,
      child: FadeTransition(
        opacity: _opacityAnimation,
        child: Container(
          padding: AppSpacing.paddingXl,
          decoration: BoxDecoration(
            color: isSuccess ? colorScheme.primaryContainer : colorScheme.errorContainer,
            borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
            border: Border.all(
              color: isSuccess 
                  ? colorScheme.primary.withValues(alpha: 0.3) 
                  : colorScheme.error.withValues(alpha: 0.3),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isSuccess ? Icons.check_circle : Icons.error_outline,
                size: AppSpacing.iconXxl,
                color: isSuccess ? colorScheme.primary : colorScheme.error,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                isSuccess ? 'Transação Concluída' : 'Erro na Transação',
                style: AppTypography.titleLarge.copyWith(
                  color: isSuccess ? colorScheme.onPrimaryContainer : colorScheme.onErrorContainer,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                widget.description,
                style: AppTypography.bodyMedium.copyWith(
                  color: isSuccess ? colorScheme.onPrimaryContainer : colorScheme.onErrorContainer,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                '${isSuccess ? '+' : ''}${WalletConstants.currencySymbol}${widget.amount.toStringAsFixed(2)}',
                style: AppTypography.displayMedium.copyWith(
                  color: isSuccess ? colorScheme.primary : colorScheme.error,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}