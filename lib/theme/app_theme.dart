import 'package:flutter/material.dart';
import 'light_theme.dart';

class AppTheme {
  static ThemeData get lightTheme => LightTheme.theme;
  
  // TODO: Add proper dark theme when available. For now, reuse light theme to avoid missing file.
  static ThemeData get darkTheme => LightTheme.theme;
  
  static ThemeMode getThemeMode(String? themeModeString) {
    switch (themeModeString?.toLowerCase()) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'system':
      default:
        return ThemeMode.system;
    }
  }
  
  static bool isDarkMode(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return brightness == Brightness.dark;
  }
  
  static Color getAdaptiveColor(
    BuildContext context, {
    required Color lightColor,
    required Color darkColor,
  }) => isDarkMode(context) ? darkColor : lightColor;
  
  static TextStyle getAdaptiveTextStyle(
    BuildContext context, {
    required TextStyle lightStyle,
    required TextStyle darkStyle,
  }) => isDarkMode(context) ? darkStyle : lightStyle;
}