import 'package:flutter/material.dart';

abstract class AppColors {
  // Base colors inspired by Uber's BaseUI
  static const Color black = Color(0xFF000000);
  static const Color white = Color(0xFFFFFFFF);
  
  // Gray scale
  static const Color gray50 = Color(0xFFF6F6F6);
  static const Color gray100 = Color(0xFFEBEBEB);
  static const Color gray200 = Color(0xFFD6D6D6);
  static const Color gray300 = Color(0xFFC2C2C2);
  static const Color gray400 = Color(0xFF9E9E9E);
  static const Color gray500 = Color(0xFF757575);
  static const Color gray600 = Color(0xFF545454);
  static const Color gray700 = Color(0xFF3D3D3D);
  static const Color gray800 = Color(0xFF1A1A1A);
  static const Color gray900 = Color(0xFF0D0D0D);
  
  // Accent colors
  static const Color blue = Color(0xFF276EF1);
  static const Color blueDark = Color(0xFF1E5BC7);
  static const Color blueLight = Color(0xFF4285F4);
  
  // Status colors
  static const Color success = Color(0xFF00A86B);
  static const Color warning = Color(0xFFFFB020);
  static const Color error = Color(0xFFD32F2F);
  static const Color info = Color(0xFF0288D1);
  
  // Light theme colors
  static const Color lightPrimary = black;
  static const Color lightOnPrimary = white;
  static const Color lightSurface = white;
  static const Color lightOnSurface = black;
  static const Color lightBackground = gray50;
  static const Color lightOnBackground = black;
  static const Color lightSurfaceVariant = gray100;
  static const Color lightOnSurfaceVariant = gray600;
  static const Color lightOutline = gray300;
  static const Color lightOutlineVariant = gray200;
  
  // Dark theme colors
  static const Color darkPrimary = white;
  static const Color darkOnPrimary = black;
  static const Color darkSurface = gray900;
  static const Color darkOnSurface = white;
  static const Color darkBackground = black;
  static const Color darkOnBackground = white;
  static const Color darkSurfaceVariant = gray800;
  static const Color darkOnSurfaceVariant = gray400;
  static const Color darkOutline = gray600;
  static const Color darkOutlineVariant = gray700;
  
  // Secondary colors
  static const Color secondary = gray800;
  static const Color onSecondary = white;
  static const Color secondaryContainer = gray600;
  static const Color onSecondaryContainer = white;
  
  // Tertiary colors
  static const Color tertiary = gray400;
  static const Color onTertiary = black;
  static const Color tertiaryContainer = gray200;
  static const Color onTertiaryContainer = black;
}