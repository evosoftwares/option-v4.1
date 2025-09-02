import 'package:flutter/material.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../theme/app_colors.dart';
import 'app_loading.dart';

/// Tipos de botão
enum AppButtonType {
  primary,
  secondary,
  outline,
  text,
  danger,
  success,
  warning,
}

/// Tamanhos de botão
enum AppButtonSize {
  small,
  medium,
  large,
}

/// Widget de botão padronizado
class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.onPressed,
    required this.text,
    this.type = AppButtonType.primary,
    this.size = AppButtonSize.medium,
    this.icon,
    this.isLoading = false,
    this.isEnabled = true,
    this.width,
    this.height,
  });

  final VoidCallback? onPressed;
  final String text;
  final AppButtonType type;
  final AppButtonSize size;
  final IconData? icon;
  final bool isLoading;
  final bool isEnabled;
  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDisabled = !isEnabled || isLoading || onPressed == null;

    return SizedBox(
      width: width ?? _getButtonWidth(),
      height: height ?? _getButtonHeight(),
      child: _buildButton(context, colorScheme, isDisabled),
    );
  }

  Widget _buildButton(BuildContext context, ColorScheme colorScheme, bool isDisabled) {
    switch (type) {
      case AppButtonType.primary:
        return _buildElevatedButton(context, colorScheme, isDisabled);
      case AppButtonType.secondary:
        return _buildFilledButton(context, colorScheme, isDisabled);
      case AppButtonType.outline:
        return _buildOutlinedButton(context, colorScheme, isDisabled);
      case AppButtonType.text:
        return _buildTextButton(context, colorScheme, isDisabled);
      case AppButtonType.danger:
        return _buildDangerButton(context, colorScheme, isDisabled);
      case AppButtonType.success:
        return _buildSuccessButton(context, colorScheme, isDisabled);
      case AppButtonType.warning:
        return _buildWarningButton(context, colorScheme, isDisabled);
    }
  }

  Widget _buildElevatedButton(BuildContext context, ColorScheme colorScheme, bool isDisabled) {
    return ElevatedButton(
      onPressed: isDisabled ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        disabledBackgroundColor: colorScheme.onSurface.withOpacity(0.12),
        disabledForegroundColor: colorScheme.onSurface.withOpacity(0.38),
        elevation: isDisabled ? 0 : _getElevation(),
        padding: _getPadding(),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_getBorderRadius()),
        ),
      ),
      child: _buildButtonContent(colorScheme.onPrimary),
    );
  }

  Widget _buildFilledButton(BuildContext context, ColorScheme colorScheme, bool isDisabled) {
    return FilledButton(
      onPressed: isDisabled ? null : onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: colorScheme.secondary,
        foregroundColor: colorScheme.onSecondary,
        disabledBackgroundColor: colorScheme.onSurface.withOpacity(0.12),
        disabledForegroundColor: colorScheme.onSurface.withOpacity(0.38),
        padding: _getPadding(),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_getBorderRadius()),
        ),
      ),
      child: _buildButtonContent(colorScheme.onSecondary),
    );
  }

  Widget _buildOutlinedButton(BuildContext context, ColorScheme colorScheme, bool isDisabled) {
    return OutlinedButton(
      onPressed: isDisabled ? null : onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: colorScheme.primary,
        disabledForegroundColor: colorScheme.onSurface.withOpacity(0.38),
        side: BorderSide(
          color: isDisabled 
              ? colorScheme.onSurface.withOpacity(0.12)
              : colorScheme.outline,
          width: _getBorderWidth(),
        ),
        padding: _getPadding(),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_getBorderRadius()),
        ),
      ),
      child: _buildButtonContent(colorScheme.primary),
    );
  }

  Widget _buildTextButton(BuildContext context, ColorScheme colorScheme, bool isDisabled) {
    return TextButton(
      onPressed: isDisabled ? null : onPressed,
      style: TextButton.styleFrom(
        foregroundColor: colorScheme.primary,
        disabledForegroundColor: colorScheme.onSurface.withOpacity(0.38),
        padding: _getPadding(),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_getBorderRadius()),
        ),
      ),
      child: _buildButtonContent(colorScheme.primary),
    );
  }

  Widget _buildDangerButton(BuildContext context, ColorScheme colorScheme, bool isDisabled) {
    return ElevatedButton(
      onPressed: isDisabled ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.error,
        foregroundColor: AppColors.white,
        disabledBackgroundColor: colorScheme.onSurface.withOpacity(0.12),
        disabledForegroundColor: colorScheme.onSurface.withOpacity(0.38),
        elevation: isDisabled ? 0 : _getElevation(),
        padding: _getPadding(),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_getBorderRadius()),
        ),
      ),
      child: _buildButtonContent(AppColors.white),
    );
  }

  Widget _buildSuccessButton(BuildContext context, ColorScheme colorScheme, bool isDisabled) {
    return ElevatedButton(
      onPressed: isDisabled ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.success,
        foregroundColor: AppColors.white,
        disabledBackgroundColor: colorScheme.onSurface.withOpacity(0.12),
        disabledForegroundColor: colorScheme.onSurface.withOpacity(0.38),
        elevation: isDisabled ? 0 : _getElevation(),
        padding: _getPadding(),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_getBorderRadius()),
        ),
      ),
      child: _buildButtonContent(AppColors.white),
    );
  }

  Widget _buildWarningButton(BuildContext context, ColorScheme colorScheme, bool isDisabled) {
    return ElevatedButton(
      onPressed: isDisabled ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.warning,
        foregroundColor: AppColors.white,
        disabledBackgroundColor: colorScheme.onSurface.withOpacity(0.12),
        disabledForegroundColor: colorScheme.onSurface.withOpacity(0.38),
        elevation: isDisabled ? 0 : _getElevation(),
        padding: _getPadding(),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_getBorderRadius()),
        ),
      ),
      child: _buildButtonContent(AppColors.white),
    );
  }

  Widget _buildButtonContent(Color textColor) {
    if (isLoading) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppLoadingUtils.buttonLoading(
            color: textColor,
            size: _getLoadingSize(),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            text,
            style: _getTextStyle().copyWith(color: textColor),
          ),
        ],
      );
    }

    if (icon != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: _getIconSize(),
            color: textColor,
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            text,
            style: _getTextStyle().copyWith(color: textColor),
          ),
        ],
      );
    }

    return Text(
      text,
      style: _getTextStyle().copyWith(color: textColor),
    );
  }

  double? _getButtonWidth() {
    switch (size) {
      case AppButtonSize.small:
        return null; // Auto width
      case AppButtonSize.medium:
        return null; // Auto width
      case AppButtonSize.large:
        return double.infinity; // Full width
    }
  }

  double _getButtonHeight() {
    switch (size) {
      case AppButtonSize.small:
        return 32.0;
      case AppButtonSize.medium:
        return 40.0;
      case AppButtonSize.large:
        return 48.0;
    }
  }

  EdgeInsetsGeometry _getPadding() {
    switch (size) {
      case AppButtonSize.small:
        return const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        );
      case AppButtonSize.medium:
        return const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        );
      case AppButtonSize.large:
        return const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        );
    }
  }

  double _getBorderRadius() {
    switch (size) {
      case AppButtonSize.small:
        return AppSpacing.radiusSm;
      case AppButtonSize.medium:
        return AppSpacing.radiusMd;
      case AppButtonSize.large:
        return AppSpacing.radiusLg;
    }
  }

  double _getBorderWidth() {
    return AppSpacing.borderMedium;
  }

  double _getElevation() {
    switch (size) {
      case AppButtonSize.small:
        return AppSpacing.elevation1;
      case AppButtonSize.medium:
        return AppSpacing.elevation2;
      case AppButtonSize.large:
        return AppSpacing.elevation3;
    }
  }

  TextStyle _getTextStyle() {
    switch (size) {
      case AppButtonSize.small:
        return AppTypography.labelSmall;
      case AppButtonSize.medium:
        return AppTypography.labelMedium;
      case AppButtonSize.large:
        return AppTypography.labelLarge;
    }
  }

  double _getIconSize() {
    switch (size) {
      case AppButtonSize.small:
        return AppSpacing.iconSm;
      case AppButtonSize.medium:
        return AppSpacing.iconMd;
      case AppButtonSize.large:
        return AppSpacing.iconLg;
    }
  }

  double _getLoadingSize() {
    switch (size) {
      case AppButtonSize.small:
        return 12.0;
      case AppButtonSize.medium:
        return 16.0;
      case AppButtonSize.large:
        return 20.0;
    }
  }
}

/// Botão de ação flutuante padronizado
class AppFloatingActionButton extends StatelessWidget {
  const AppFloatingActionButton({
    super.key,
    required this.onPressed,
    required this.icon,
    this.tooltip,
    this.backgroundColor,
    this.foregroundColor,
    this.size = AppButtonSize.medium,
    this.isLoading = false,
  });

  final VoidCallback? onPressed;
  final IconData icon;
  final String? tooltip;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final AppButtonSize size;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final effectiveBackgroundColor = backgroundColor ?? colorScheme.primary;
    final effectiveForegroundColor = foregroundColor ?? colorScheme.onPrimary;

    return FloatingActionButton(
      onPressed: isLoading ? null : onPressed,
      tooltip: tooltip,
      backgroundColor: effectiveBackgroundColor,
      foregroundColor: effectiveForegroundColor,
      elevation: _getElevation(),
      child: isLoading
          ? AppLoadingUtils.buttonLoading(
              color: effectiveForegroundColor,
              size: _getIconSize(),
            )
          : Icon(
              icon,
              size: _getIconSize(),
            ),
    );
  }

  double _getElevation() {
    switch (size) {
      case AppButtonSize.small:
        return AppSpacing.elevation1;
      case AppButtonSize.medium:
        return AppSpacing.elevation2;
      case AppButtonSize.large:
        return AppSpacing.elevation3;
    }
  }

  double _getIconSize() {
    switch (size) {
      case AppButtonSize.small:
        return AppSpacing.iconSm;
      case AppButtonSize.medium:
        return AppSpacing.iconMd;
      case AppButtonSize.large:
        return AppSpacing.iconLg;
    }
  }
}

/// Utilitários para botões
abstract class AppButtonUtils {
  /// Botão primário padrão
  static Widget primary({
    required VoidCallback? onPressed,
    required String text,
    IconData? icon,
    AppButtonSize size = AppButtonSize.medium,
    bool isLoading = false,
    double? width,
  }) {
    return AppButton(
      onPressed: onPressed,
      text: text,
      type: AppButtonType.primary,
      size: size,
      icon: icon,
      isLoading: isLoading,
      width: width,
    );
  }

  /// Botão secundário padrão
  static Widget secondary({
    required VoidCallback? onPressed,
    required String text,
    IconData? icon,
    AppButtonSize size = AppButtonSize.medium,
    bool isLoading = false,
    double? width,
  }) {
    return AppButton(
      onPressed: onPressed,
      text: text,
      type: AppButtonType.secondary,
      size: size,
      icon: icon,
      isLoading: isLoading,
      width: width,
    );
  }

  /// Botão de contorno padrão
  static Widget outline({
    required VoidCallback? onPressed,
    required String text,
    IconData? icon,
    AppButtonSize size = AppButtonSize.medium,
    bool isLoading = false,
    double? width,
  }) {
    return AppButton(
      onPressed: onPressed,
      text: text,
      type: AppButtonType.outline,
      size: size,
      icon: icon,
      isLoading: isLoading,
      width: width,
    );
  }

  /// Botão de texto padrão
  static Widget text({
    required VoidCallback? onPressed,
    required String text,
    IconData? icon,
    AppButtonSize size = AppButtonSize.medium,
    bool isLoading = false,
  }) {
    return AppButton(
      onPressed: onPressed,
      text: text,
      type: AppButtonType.text,
      size: size,
      icon: icon,
      isLoading: isLoading,
    );
  }

  /// Botão de perigo padrão
  static Widget danger({
    required VoidCallback? onPressed,
    required String text,
    IconData? icon,
    AppButtonSize size = AppButtonSize.medium,
    bool isLoading = false,
    double? width,
  }) {
    return AppButton(
      onPressed: onPressed,
      text: text,
      type: AppButtonType.danger,
      size: size,
      icon: icon,
      isLoading: isLoading,
      width: width,
    );
  }

  /// Botão de sucesso padrão
  static Widget success({
    required VoidCallback? onPressed,
    required String text,
    IconData? icon,
    AppButtonSize size = AppButtonSize.medium,
    bool isLoading = false,
    double? width,
  }) {
    return AppButton(
      onPressed: onPressed,
      text: text,
      type: AppButtonType.success,
      size: size,
      icon: icon,
      isLoading: isLoading,
      width: width,
    );
  }

  /// Botão de aviso padrão
  static Widget warning({
    required VoidCallback? onPressed,
    required String text,
    IconData? icon,
    AppButtonSize size = AppButtonSize.medium,
    bool isLoading = false,
    double? width,
  }) {
    return AppButton(
      onPressed: onPressed,
      text: text,
      type: AppButtonType.warning,
      size: size,
      icon: icon,
      isLoading: isLoading,
      width: width,
    );
  }
}