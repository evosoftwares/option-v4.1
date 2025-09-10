import 'package:flutter/material.dart';
import 'app_spacing.dart';
import 'app_typography.dart';

abstract class AppButtonStyles {
  // Button heights - consistent sizes
  static const double heightSm = 40;
  static const double heightMd = AppSpacing.buttonHeight; // 48
  static const double heightLg = 56;
  
  // Button padding - consistent internal spacing
  static const EdgeInsets paddingMd = EdgeInsets.symmetric(
    horizontal: AppSpacing.lg, // 24
    vertical: AppSpacing.md,   // 16
  );
  
  static const EdgeInsets paddingSm = EdgeInsets.symmetric(
    horizontal: AppSpacing.md, // 16
    vertical: AppSpacing.sm,   // 8
  );

  // Border radius - consistent roundness
  static BorderRadius get borderRadius => BorderRadius.circular(AppSpacing.radiusMd); // 12
  static BorderRadius get borderRadiusLg => BorderRadius.circular(AppSpacing.radiusLg); // 16
  static BorderRadius get borderRadiusSm => BorderRadius.circular(AppSpacing.radiusSm); // 8

  // Primary button style
  static ButtonStyle primary(ColorScheme colorScheme) => FilledButton.styleFrom(
    backgroundColor: colorScheme.primary,
    foregroundColor: colorScheme.onPrimary,
    minimumSize: const Size.fromHeight(heightMd),
    padding: paddingMd,
    shape: RoundedRectangleBorder(borderRadius: borderRadius),
    textStyle: AppTypography.buttonText,
  );

  // Secondary button style  
  static ButtonStyle secondary(ColorScheme colorScheme) => OutlinedButton.styleFrom(
    foregroundColor: colorScheme.primary,
    side: BorderSide(color: colorScheme.primary),
    minimumSize: const Size.fromHeight(heightMd),
    padding: paddingMd,
    shape: RoundedRectangleBorder(borderRadius: borderRadius),
    textStyle: AppTypography.buttonText,
  );

  // Tertiary button style
  static ButtonStyle tertiary(ColorScheme colorScheme) => TextButton.styleFrom(
    foregroundColor: colorScheme.primary,
    minimumSize: const Size.fromHeight(heightMd),
    padding: paddingMd,
    shape: RoundedRectangleBorder(borderRadius: borderRadius),
    textStyle: AppTypography.buttonText,
  );

  // Success button style
  static ButtonStyle success(ColorScheme colorScheme) => FilledButton.styleFrom(
    backgroundColor: colorScheme.tertiary,
    foregroundColor: colorScheme.onTertiary,
    minimumSize: const Size.fromHeight(heightMd),
    padding: paddingMd,
    shape: RoundedRectangleBorder(borderRadius: borderRadius),
    textStyle: AppTypography.buttonText,
  );

  // Error/Destructive button style
  static ButtonStyle error(ColorScheme colorScheme) => FilledButton.styleFrom(
    backgroundColor: colorScheme.error,
    foregroundColor: colorScheme.onError,
    minimumSize: const Size.fromHeight(heightMd),
    padding: paddingMd,
    shape: RoundedRectangleBorder(borderRadius: borderRadius),
    textStyle: AppTypography.buttonText,
  );

  // Small button variants
  static ButtonStyle primarySm(ColorScheme colorScheme) => FilledButton.styleFrom(
    backgroundColor: colorScheme.primary,
    foregroundColor: colorScheme.onPrimary,
    minimumSize: const Size.fromHeight(heightSm),
    padding: paddingSm,
    shape: RoundedRectangleBorder(borderRadius: borderRadiusSm),
    textStyle: AppTypography.labelLarge,
  );

  static ButtonStyle secondarySm(ColorScheme colorScheme) => OutlinedButton.styleFrom(
    foregroundColor: colorScheme.primary,
    side: BorderSide(color: colorScheme.primary),
    minimumSize: const Size.fromHeight(heightSm),
    padding: paddingSm,
    shape: RoundedRectangleBorder(borderRadius: borderRadiusSm),
    textStyle: AppTypography.labelLarge,
  );

  // Large button variants
  static ButtonStyle primaryLg(ColorScheme colorScheme) => FilledButton.styleFrom(
    backgroundColor: colorScheme.primary,
    foregroundColor: colorScheme.onPrimary,
    minimumSize: const Size.fromHeight(heightLg),
    padding: paddingMd,
    shape: RoundedRectangleBorder(borderRadius: borderRadiusLg),
    textStyle: AppTypography.buttonText.copyWith(fontSize: 18),
  );

  // Floating Action Button style
  static ButtonStyle fab(ColorScheme colorScheme) => ElevatedButton.styleFrom(
    backgroundColor: colorScheme.primary,
    foregroundColor: colorScheme.onPrimary,
    shape: const CircleBorder(),
    padding: const EdgeInsets.all(AppSpacing.md),
    elevation: AppSpacing.elevation6,
  );
}

// Pre-built button widgets for common use cases
class AppButton extends StatelessWidget {
  const AppButton.primary({
    super.key,
    required this.text,
    required this.onPressed,
    this.size = AppButtonSize.medium,
    this.fullWidth = false,
    this.icon,
  }) : _style = _AppButtonStyle.primary;

  const AppButton.secondary({
    super.key,
    required this.text,
    required this.onPressed,
    this.size = AppButtonSize.medium,
    this.fullWidth = false,
    this.icon,
  }) : _style = _AppButtonStyle.secondary;

  const AppButton.tertiary({
    super.key,
    required this.text,
    required this.onPressed,
    this.size = AppButtonSize.medium,
    this.fullWidth = false,
    this.icon,
  }) : _style = _AppButtonStyle.tertiary;

  const AppButton.success({
    super.key,
    required this.text,
    required this.onPressed,
    this.size = AppButtonSize.medium,
    this.fullWidth = false,
    this.icon,
  }) : _style = _AppButtonStyle.success;

  const AppButton.error({
    super.key,
    required this.text,
    required this.onPressed,
    this.size = AppButtonSize.medium,
    this.fullWidth = false,
    this.icon,
  }) : _style = _AppButtonStyle.error;

  final String text;
  final VoidCallback? onPressed;
  final AppButtonSize size;
  final bool fullWidth;
  final IconData? icon;
  final _AppButtonStyle _style;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    ButtonStyle style;

    switch (_style) {
      case _AppButtonStyle.primary:
        style = size == AppButtonSize.small 
            ? AppButtonStyles.primarySm(colorScheme)
            : size == AppButtonSize.large
                ? AppButtonStyles.primaryLg(colorScheme)
                : AppButtonStyles.primary(colorScheme);
        break;
      case _AppButtonStyle.secondary:
        style = size == AppButtonSize.small 
            ? AppButtonStyles.secondarySm(colorScheme)
            : AppButtonStyles.secondary(colorScheme);
        break;
      case _AppButtonStyle.tertiary:
        style = AppButtonStyles.tertiary(colorScheme);
        break;
      case _AppButtonStyle.success:
        style = AppButtonStyles.success(colorScheme);
        break;
      case _AppButtonStyle.error:
        style = AppButtonStyles.error(colorScheme);
        break;
    }

    if (fullWidth) {
      style = style.copyWith(
        minimumSize: WidgetStateProperty.all(Size.fromHeight(_getHeight())),
      );
    }

    final child = icon != null
        ? Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: _getIconSize()),
              const SizedBox(width: AppSpacing.sm),
              Text(text),
            ],
          )
        : Text(text);

    switch (_style) {
      case _AppButtonStyle.primary:
      case _AppButtonStyle.success:
      case _AppButtonStyle.error:
        return FilledButton(
          onPressed: onPressed,
          style: style,
          child: child,
        );
      case _AppButtonStyle.secondary:
        return OutlinedButton(
          onPressed: onPressed,
          style: style,
          child: child,
        );
      case _AppButtonStyle.tertiary:
        return TextButton(
          onPressed: onPressed,
          style: style,
          child: child,
        );
    }
  }

  double _getHeight() {
    switch (size) {
      case AppButtonSize.small:
        return AppButtonStyles.heightSm;
      case AppButtonSize.medium:
        return AppButtonStyles.heightMd;
      case AppButtonSize.large:
        return AppButtonStyles.heightLg;
    }
  }

  double _getIconSize() {
    switch (size) {
      case AppButtonSize.small:
        return AppSpacing.iconSm; // 20
      case AppButtonSize.medium:
        return AppSpacing.iconMd; // 24
      case AppButtonSize.large:
        return AppSpacing.iconLg; // 32
    }
  }
}

enum AppButtonSize {
  small,
  medium,
  large,
}

enum _AppButtonStyle {
  primary,
  secondary,
  tertiary,
  success,
  error,
}