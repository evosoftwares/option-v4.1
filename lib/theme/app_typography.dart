import 'package:flutter/material.dart';
import 'app_colors.dart';

abstract class AppTypography {
  // Font families inspired by Uber's BaseUI
  static const String _primaryFont = 'SF Pro Display';
  static const String _secondaryFont = 'SF Pro Text';
  
  // Font weights
  static const FontWeight light = FontWeight.w300;
  static const FontWeight regular = FontWeight.w400;
  static const FontWeight medium = FontWeight.w500;
  static const FontWeight semiBold = FontWeight.w600;
  static const FontWeight bold = FontWeight.w700;
  
  // Display styles (Large headings)
  static const TextStyle displayLarge = TextStyle(
    fontFamily: _primaryFont,
    fontSize: 57,
    fontWeight: regular,
    height: 1.12,
    letterSpacing: -0.25,
  );
  
  static const TextStyle displayMedium = TextStyle(
    fontFamily: _primaryFont,
    fontSize: 45,
    fontWeight: regular,
    height: 1.16,
  );
  
  static const TextStyle displaySmall = TextStyle(
    fontFamily: _primaryFont,
    fontSize: 36,
    fontWeight: regular,
    height: 1.22,
  );
  
  // Headline styles
  static const TextStyle headlineLarge = TextStyle(
    fontFamily: _primaryFont,
    fontSize: 32,
    fontWeight: regular,
    height: 1.25,
  );
  
  static const TextStyle headlineMedium = TextStyle(
    fontFamily: _primaryFont,
    fontSize: 28,
    fontWeight: regular,
    height: 1.29,
  );
  
  static const TextStyle headlineSmall = TextStyle(
    fontFamily: _primaryFont,
    fontSize: 24,
    fontWeight: semiBold,
    height: 1.33,
  );
  
  // Title styles
  static const TextStyle titleLarge = TextStyle(
    fontFamily: _primaryFont,
    fontSize: 22,
    fontWeight: semiBold,
    height: 1.27,
  );
  
  static const TextStyle titleMedium = TextStyle(
    fontFamily: _primaryFont,
    fontSize: 16,
    fontWeight: semiBold,
    height: 1.50,
    letterSpacing: 0.15,
  );
  
  static const TextStyle titleSmall = TextStyle(
    fontFamily: _primaryFont,
    fontSize: 14,
    fontWeight: semiBold,
    height: 1.43,
    letterSpacing: 0.10,
  );
  
  // Body styles
  static const TextStyle bodyLarge = TextStyle(
    fontFamily: _secondaryFont,
    fontSize: 16,
    fontWeight: regular,
    height: 1.50,
    letterSpacing: 0.50,
  );
  
  static const TextStyle bodyMedium = TextStyle(
    fontFamily: _secondaryFont,
    fontSize: 14,
    fontWeight: regular,
    height: 1.43,
    letterSpacing: 0.25,
  );
  
  static const TextStyle bodySmall = TextStyle(
    fontFamily: _secondaryFont,
    fontSize: 12,
    fontWeight: regular,
    height: 1.33,
    letterSpacing: 0.40,
  );
  
  // Label styles
  static const TextStyle labelLarge = TextStyle(
    fontFamily: _secondaryFont,
    fontSize: 14,
    fontWeight: medium,
    height: 1.43,
    letterSpacing: 0.10,
  );
  
  static const TextStyle labelMedium = TextStyle(
    fontFamily: _secondaryFont,
    fontSize: 12,
    fontWeight: medium,
    height: 1.33,
    letterSpacing: 0.50,
  );
  
  static const TextStyle labelSmall = TextStyle(
    fontFamily: _secondaryFont,
    fontSize: 11,
    fontWeight: medium,
    height: 1.45,
    letterSpacing: 0.50,
  );
  
  // Custom styles inspired by Uber's design
  static const TextStyle heroTitle = TextStyle(
    fontFamily: _primaryFont,
    fontSize: 40,
    fontWeight: bold,
    height: 1.2,
    letterSpacing: -0.5,
  );
  
  static const TextStyle sectionTitle = TextStyle(
    fontFamily: _primaryFont,
    fontSize: 20,
    fontWeight: semiBold,
    height: 1.3,
    letterSpacing: 0.15,
  );
  
  static const TextStyle buttonText = TextStyle(
    fontFamily: _secondaryFont,
    fontSize: 16,
    fontWeight: semiBold,
    height: 1.25,
    letterSpacing: 0.5,
  );
  
  static const TextStyle captionText = TextStyle(
    fontFamily: _secondaryFont,
    fontSize: 13,
    fontWeight: regular,
    height: 1.38,
    letterSpacing: 0.25,
  );
  
  // Get text theme with colors
  static TextTheme getTextTheme({required bool isDark}) {
    final Color textColor = isDark ? AppColors.darkOnSurface : AppColors.lightOnSurface;
    final Color secondaryTextColor = isDark ? AppColors.darkOnSurfaceVariant : AppColors.lightOnSurfaceVariant;
    
    return TextTheme(
      displayLarge: displayLarge.copyWith(color: textColor),
      displayMedium: displayMedium.copyWith(color: textColor),
      displaySmall: displaySmall.copyWith(color: textColor),
      headlineLarge: headlineLarge.copyWith(color: textColor),
      headlineMedium: headlineMedium.copyWith(color: textColor),
      headlineSmall: headlineSmall.copyWith(color: textColor),
      titleLarge: titleLarge.copyWith(color: textColor),
      titleMedium: titleMedium.copyWith(color: textColor),
      titleSmall: titleSmall.copyWith(color: textColor),
      bodyLarge: bodyLarge.copyWith(color: textColor),
      bodyMedium: bodyMedium.copyWith(color: textColor),
      bodySmall: bodySmall.copyWith(color: secondaryTextColor),
      labelLarge: labelLarge.copyWith(color: textColor),
      labelMedium: labelMedium.copyWith(color: textColor),
      labelSmall: labelSmall.copyWith(color: secondaryTextColor),
    );
  }
}