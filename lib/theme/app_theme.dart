import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Cores principais do Uber
  static const Color uberBlack = Color(0xFF000000);
  static const Color uberDarkGray = Color(0xFF1A1A1A);
  static const Color uberMediumGray = Color(0xFF545454);
  static const Color uberLightGray = Color(0xFF9E9E9E);
  static const Color uberWhite = Color(0xFFFFFFFF);
  static const Color uberGreen = Color(0xFF06C167);
  static const Color uberGreenDark = Color(0xFF00514A);
  static const Color uberRed = Color(0xFFD32F2F);
  static const Color uberBackground = Color(0xFFF6F6F6);
  static const Color uberSurface = Color(0xFFFFFFFF);

  static ThemeData get theme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.light(
        primary: uberBlack,
        onPrimary: uberWhite,
        primaryContainer: uberDarkGray,
        onPrimaryContainer: uberWhite,
        secondary: uberDarkGray,
        onSecondary: uberWhite,
        secondaryContainer: uberMediumGray,
        onSecondaryContainer: uberWhite,
        tertiary: uberLightGray,
        onTertiary: uberBlack,
        error: uberRed,
        onError: uberWhite,
        surface: uberSurface,
        onSurface: uberBlack,
        surfaceContainerHighest: uberSurface,
        onSurfaceVariant: uberMediumGray,
        outline: uberLightGray,
        outlineVariant: uberLightGray.withOpacity(0.5),
        shadow: uberBlack.withOpacity(0.1),
        scrim: uberBlack.withOpacity(0.3),
      ),
      scaffoldBackgroundColor: uberBackground,
      appBarTheme: AppBarTheme(
        backgroundColor: uberWhite,
        foregroundColor: uberBlack,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.urbanist(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: uberBlack,
        ),
        iconTheme: const IconThemeData(color: uberBlack),
      ),
      textTheme: GoogleFonts.urbanistTextTheme(
        ThemeData.light().textTheme,
      ).copyWith(
        displayLarge: GoogleFonts.urbanist(
          fontSize: 57,
          fontWeight: FontWeight.w400,
          letterSpacing: -0.25,
        ),
        displayMedium: GoogleFonts.urbanist(
          fontSize: 45,
          fontWeight: FontWeight.w400,
        ),
        displaySmall: GoogleFonts.urbanist(
          fontSize: 36,
          fontWeight: FontWeight.w400,
        ),
        headlineLarge: GoogleFonts.urbanist(
          fontSize: 32,
          fontWeight: FontWeight.w400,
        ),
        headlineMedium: GoogleFonts.urbanist(
          fontSize: 28,
          fontWeight: FontWeight.w400,
        ),
        headlineSmall: GoogleFonts.urbanist(
          fontSize: 24,
          fontWeight: FontWeight.w400,
        ),
        titleLarge: GoogleFonts.urbanist(
          fontSize: 22,
          fontWeight: FontWeight.w400,
        ),
        titleMedium: GoogleFonts.urbanist(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.15,
        ),
        titleSmall: GoogleFonts.urbanist(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.1,
        ),
        bodyLarge: GoogleFonts.urbanist(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          letterSpacing: 0.5,
        ),
        bodyMedium: GoogleFonts.urbanist(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          letterSpacing: 0.25,
        ),
        bodySmall: GoogleFonts.urbanist(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          letterSpacing: 0.4,
        ),
        labelLarge: GoogleFonts.urbanist(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.1,
        ),
        labelMedium: GoogleFonts.urbanist(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.5,
        ),
        labelSmall: GoogleFonts.urbanist(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.5,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: uberBlack,
          foregroundColor: uberWhite,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          textStyle: GoogleFonts.urbanist(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: uberBlack,
          side: BorderSide(color: uberLightGray.withOpacity(0.5)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          textStyle: GoogleFonts.urbanist(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: uberBlack,
          textStyle: GoogleFonts.urbanist(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: uberWhite,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: uberLightGray.withOpacity(0.5)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: uberLightGray.withOpacity(0.5)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: uberBlack, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: uberRed),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        labelStyle: GoogleFonts.urbanist(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: uberMediumGray,
        ),
        hintStyle: GoogleFonts.urbanist(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: uberLightGray,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: uberLightGray.withOpacity(0.2),
            width: 1,
          ),
        ),
        margin: const EdgeInsets.all(0),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: uberWhite,
        elevation: 0,
        indicatorColor: uberBlack.withOpacity(0.1),
        indicatorShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        labelTextStyle: MaterialStateProperty.all(
          GoogleFonts.urbanist(
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: uberBlack,
        foregroundColor: uberWhite,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: uberLightGray.withOpacity(0.2),
        selectedColor: uberBlack.withOpacity(0.1),
        disabledColor: uberLightGray.withOpacity(0.1),
        labelStyle: GoogleFonts.urbanist(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: uberBlack,
        ),
        secondaryLabelStyle: GoogleFonts.urbanist(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: uberWhite,
        ),
        brightness: Brightness.light,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: uberLightGray.withOpacity(0.3)),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: uberLightGray.withOpacity(0.3),
        thickness: 1,
        space: 1,
      ),
    );
  }

  static ThemeData get uberBlackTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.dark(
        primary: uberWhite,
        onPrimary: uberBlack,
        primaryContainer: uberDarkGray,
        onPrimaryContainer: uberWhite,
        secondary: uberMediumGray,
        onSecondary: uberWhite,
        secondaryContainer: uberMediumGray,
        onSecondaryContainer: uberWhite,
        tertiary: uberLightGray,
        onTertiary: uberWhite,
        error: uberRed,
        onError: uberWhite,
        surface: uberBlack,
        onSurface: uberWhite,
        surfaceContainerHighest: uberDarkGray,
        onSurfaceVariant: uberLightGray,
        outline: uberMediumGray,
        outlineVariant: uberMediumGray.withOpacity(0.5),
        shadow: uberBlack.withOpacity(0.5),
        scrim: uberBlack.withOpacity(0.7),
      ),
      scaffoldBackgroundColor: uberBlack,
      appBarTheme: AppBarTheme(
        backgroundColor: uberBlack,
        foregroundColor: uberWhite,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.urbanist(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: uberWhite,
        ),
        iconTheme: const IconThemeData(color: uberWhite),
      ),
      textTheme: GoogleFonts.urbanistTextTheme(
        ThemeData.dark().textTheme,
      ).copyWith(
        displayLarge: GoogleFonts.urbanist(
          fontSize: 57,
          fontWeight: FontWeight.w400,
          letterSpacing: -0.25,
          color: uberWhite,
        ),
        displayMedium: GoogleFonts.urbanist(
          fontSize: 45,
          fontWeight: FontWeight.w400,
          color: uberWhite,
        ),
        displaySmall: GoogleFonts.urbanist(
          fontSize: 36,
          fontWeight: FontWeight.w400,
          color: uberWhite,
        ),
        headlineLarge: GoogleFonts.urbanist(
          fontSize: 32,
          fontWeight: FontWeight.w400,
          color: uberWhite,
        ),
        headlineMedium: GoogleFonts.urbanist(
          fontSize: 28,
          fontWeight: FontWeight.w400,
          color: uberWhite,
        ),
        headlineSmall: GoogleFonts.urbanist(
          fontSize: 24,
          fontWeight: FontWeight.w400,
          color: uberWhite,
        ),
        titleLarge: GoogleFonts.urbanist(
          fontSize: 22,
          fontWeight: FontWeight.w400,
          color: uberWhite,
        ),
        titleMedium: GoogleFonts.urbanist(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.15,
          color: uberWhite,
        ),
        titleSmall: GoogleFonts.urbanist(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.1,
          color: uberWhite,
        ),
        bodyLarge: GoogleFonts.urbanist(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          letterSpacing: 0.5,
          color: uberWhite,
        ),
        bodyMedium: GoogleFonts.urbanist(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          letterSpacing: 0.25,
          color: uberWhite,
        ),
        bodySmall: GoogleFonts.urbanist(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          letterSpacing: 0.4,
          color: uberWhite,
        ),
        labelLarge: GoogleFonts.urbanist(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.1,
          color: uberWhite,
        ),
        labelMedium: GoogleFonts.urbanist(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.5,
          color: uberWhite,
        ),
        labelSmall: GoogleFonts.urbanist(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.5,
          color: uberWhite,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: uberWhite,
          foregroundColor: uberBlack,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          textStyle: GoogleFonts.urbanist(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: uberWhite,
          side: BorderSide(color: uberMediumGray.withOpacity(0.5)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          textStyle: GoogleFonts.urbanist(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: uberWhite,
          textStyle: GoogleFonts.urbanist(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: uberDarkGray,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: uberMediumGray.withOpacity(0.5)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: uberMediumGray.withOpacity(0.5)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: uberWhite, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: uberRed),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        labelStyle: GoogleFonts.urbanist(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: uberLightGray,
        ),
        hintStyle: GoogleFonts.urbanist(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: uberMediumGray,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: uberDarkGray,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: uberMediumGray.withOpacity(0.3),
            width: 1,
          ),
        ),
        margin: const EdgeInsets.all(0),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: uberBlack,
        elevation: 0,
        indicatorColor: uberWhite.withOpacity(0.1),
        indicatorShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        labelTextStyle: MaterialStateProperty.all(
          GoogleFonts.urbanist(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: uberWhite,
          ),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: uberWhite,
        foregroundColor: uberBlack,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: uberMediumGray.withOpacity(0.2),
        selectedColor: uberWhite.withOpacity(0.1),
        disabledColor: uberMediumGray.withOpacity(0.1),
        labelStyle: GoogleFonts.urbanist(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: uberWhite,
        ),
        secondaryLabelStyle: GoogleFonts.urbanist(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: uberBlack,
        ),
        brightness: Brightness.dark,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: uberMediumGray.withOpacity(0.3)),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: uberMediumGray.withOpacity(0.3),
        thickness: 1,
        space: 1,
      ),
    );
  }
}