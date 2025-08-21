import 'package:flutter/material.dart';

abstract class AppSpacing {
  // Base spacing units (4px grid system like Uber's BaseUI)
  static const double xs = 4;    // Extra small
  static const double sm = 8;    // Small
  static const double md = 16;   // Medium
  static const double lg = 24;   // Large
  static const double xl = 32;   // Extra large
  static const double xxl = 40;  // Double extra large
  static const double xxxl = 48; // Triple extra large
  
  // Component spacing
  static const double buttonPadding = md;
  static const double cardPadding = lg;
  static const double screenPadding = lg;
  static const double sectionSpacing = xl;
  static const double itemSpacing = md;
  static const double elementSpacing = sm;
  
  // Border radius (consistent with Uber's design)
  static const double radiusXs = 4;
  static const double radiusSm = 8;
  static const double radiusMd = 12;
  static const double radiusLg = 16;
  static const double radiusXl = 24;
  static const double radiusXxl = 28;
  
  // Layout spacing
  static const double headerHeight = 64;
  static const double bottomNavHeight = 80;
  static const double listItemHeight = 56;
  static const double buttonHeight = 48;
  static const double inputHeight = 52;
  
  // Safe areas
  static const EdgeInsets screenMargin = EdgeInsets.symmetric(horizontal: screenPadding);
  static const EdgeInsets cardMargin = EdgeInsets.all(sm);
  static const EdgeInsets buttonMargin = EdgeInsets.symmetric(horizontal: md, vertical: sm);
  
  // Common padding presets
  static const EdgeInsets paddingXs = EdgeInsets.all(xs);
  static const EdgeInsets paddingSm = EdgeInsets.all(sm);
  static const EdgeInsets paddingMd = EdgeInsets.all(md);
  static const EdgeInsets paddingLg = EdgeInsets.all(lg);
  static const EdgeInsets paddingXl = EdgeInsets.all(xl);
  
  // Asymmetric padding
  static const EdgeInsets paddingHorizontalMd = EdgeInsets.symmetric(horizontal: md);
  static const EdgeInsets paddingVerticalMd = EdgeInsets.symmetric(vertical: md);
  static const EdgeInsets paddingHorizontalLg = EdgeInsets.symmetric(horizontal: lg);
  static const EdgeInsets paddingVerticalLg = EdgeInsets.symmetric(vertical: lg);
  
  // Icon sizes
  static const double iconXs = 16;
  static const double iconSm = 20;
  static const double iconMd = 24;
  static const double iconLg = 32;
  static const double iconXl = 40;
  static const double iconXxl = 48;
  
  // Avatar sizes
  static const double avatarSm = 32;
  static const double avatarMd = 48;
  static const double avatarLg = 64;
  static const double avatarXl = 96;
  
  // Border widths
  static const double borderThin = 1;
  static const double borderMedium = 2;
  static const double borderThick = 4;
  
  // Shadow elevations (following Material Design)
  static const double elevation0 = 0;
  static const double elevation1 = 1;
  static const double elevation2 = 2;
  static const double elevation3 = 3;
  static const double elevation4 = 4;
  static const double elevation6 = 6;
  static const double elevation8 = 8;
  static const double elevation12 = 12;
}