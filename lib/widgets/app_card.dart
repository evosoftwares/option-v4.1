import 'package:flutter/material.dart';
import '../theme/app_spacing.dart';

/// Cartão padronizado seguindo o design system do app
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.borderRadius,
    this.elevation,
    this.backgroundColor,
    this.borderColor,
    this.onTap,
    this.width,
    this.height,
  });

  /// Conteúdo do cartão
  final Widget child;

  /// Padding interno do cartão
  final EdgeInsetsGeometry? padding;

  /// Margem externa do cartão
  final EdgeInsetsGeometry? margin;

  /// Border radius personalizado
  final BorderRadius? borderRadius;

  /// Elevação do cartão
  final double? elevation;

  /// Cor de fundo personalizada
  final Color? backgroundColor;

  /// Cor da borda personalizada
  final Color? borderColor;

  /// Callback para tap
  final VoidCallback? onTap;

  /// Largura fixa do cartão
  final double? width;

  /// Altura fixa do cartão
  final double? height;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final cardChild = Container(
      width: width,
      height: height,
      padding: padding ?? AppSpacing.paddingLg,
      decoration: BoxDecoration(
        color: backgroundColor ?? colorScheme.surface,
        borderRadius: borderRadius ?? BorderRadius.circular(AppSpacing.radiusLg),
        border: borderColor != null 
            ? Border.all(color: borderColor!)
            : Border.all(color: colorScheme.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.1),
            blurRadius: elevation ?? AppSpacing.elevation2,
            offset: Offset(0, (elevation ?? AppSpacing.elevation2) / 2),
          ),
        ],
      ),
      child: child,
    );

    if (onTap != null) {
      return Container(
        margin: margin ?? AppSpacing.cardMargin,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: borderRadius ?? BorderRadius.circular(AppSpacing.radiusLg),
            child: cardChild,
          ),
        ),
      );
    }

    return Container(
      margin: margin ?? AppSpacing.cardMargin,
      child: cardChild,
    );
  }
}

/// Card para lista de itens
class AppListCard extends StatelessWidget {
  const AppListCard({
    super.key,
    required this.child,
    this.onTap,
    this.selected = false,
    this.showBorder = true,
  });

  final Widget child;
  final VoidCallback? onTap;
  final bool selected;
  final bool showBorder;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AppCard(
      margin: const EdgeInsets.only(bottom: AppSpacing.itemSpacing),
      padding: AppSpacing.paddingMd,
      elevation: selected ? AppSpacing.elevation4 : AppSpacing.elevation1,
      backgroundColor: selected ? colorScheme.primaryContainer : colorScheme.surface,
      borderColor: selected 
          ? colorScheme.primary 
          : showBorder 
              ? colorScheme.outlineVariant 
              : Colors.transparent,
      onTap: onTap,
      child: child,
    );
  }
}

/// Card para informações estatísticas  
class AppStatsCard extends StatelessWidget {
  const AppStatsCard({
    super.key,
    required this.title,
    required this.value,
    this.subtitle,
    this.icon,
    this.color,
    this.onTap,
  });

  final String title;
  final String value;
  final String? subtitle;
  final IconData? icon;
  final Color? color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final effectiveColor = color ?? colorScheme.primary;

    return AppCard(
      onTap: onTap,
      backgroundColor: effectiveColor.withOpacity(0.1),
      borderColor: effectiveColor,
      child: Row(
        children: [
          if (icon != null) ...[
            CircleAvatar(
              backgroundColor: effectiveColor,
              foregroundColor: colorScheme.onPrimary,
              child: Icon(icon),
            ),
            const SizedBox(width: AppSpacing.md),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  value,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    subtitle!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Card para exibir erros
class AppErrorCard extends StatelessWidget {
  const AppErrorCard({
    super.key,
    required this.title,
    required this.message,
    this.onRetry,
    this.retryLabel = 'Tentar novamente',
  });

  final String title;
  final String message;
  final VoidCallback? onRetry;
  final String retryLabel;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AppCard(
      backgroundColor: colorScheme.errorContainer,
      borderColor: colorScheme.error,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.error_outline,
                color: colorScheme.error,
                size: AppSpacing.iconMd,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: colorScheme.error,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            message,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: colorScheme.onErrorContainer,
            ),
          ),
          if (onRetry != null) ...[
            const SizedBox(height: AppSpacing.md),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: Text(retryLabel),
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.error,
                foregroundColor: colorScheme.onError,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Card para empty states
class AppEmptyCard extends StatelessWidget {
  const AppEmptyCard({
    super.key,
    required this.title,
    required this.message,
    this.icon = Icons.inbox_outlined,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String message;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AppCard(
      backgroundColor: colorScheme.surfaceContainerHighest,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: AppSpacing.iconXl * 2,
            color: colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: colorScheme.onSurface,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            message,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          if (onAction != null && actionLabel != null) ...[
            const SizedBox(height: AppSpacing.lg),
            ElevatedButton(
              onPressed: onAction,
              child: Text(actionLabel!),
            ),
          ],
        ],
      ),
    );
  }
}