import 'package:flutter/material.dart';

class AppColors {
  // =========================================================================
  // SURFACE COLORS
  // =========================================================================
  static const Color surface = Color(0xFFf8f9fa);
  static const Color surfaceDim = Color(0xFFd9dadb);
  static const Color surfaceBright = Color(0xFFf8f9fa);
  static const Color surfaceContainerLowest = Color(0xFFffffff);
  static const Color surfaceContainerLow = Color(0xFFf3f4f5);
  static const Color surfaceContainer = Color(0xFFedeeef);
  static const Color surfaceContainerHigh = Color(0xFFe7e8e9);
  static const Color surfaceContainerHighest = Color(0xFFe1e3e4);
  
  // =========================================================================
  // ON-SURFACE COLORS
  // =========================================================================
  static const Color onSurface = Color(0xFF191c1d);
  static const Color onSurfaceVariant = Color(0xFF3e4a3c);
  static const Color inverseSurface = Color(0xFF2e3132);
  static const Color inverseOnSurface = Color(0xFFf0f1f2);
  
  // =========================================================================
  // OUTLINE COLORS
  // =========================================================================
  static const Color outline = Color(0xFF6d7b6b);
  static const Color outlineVariant = Color(0xFFbdcab8);
  
  // =========================================================================
  // PRIMARY COLORS (Safaricom Green)
  // =========================================================================
  static const Color primary = Color(0xFF006e27);
  static const Color onPrimary = Color(0xFFffffff);
  static const Color primaryContainer = Color(0xFF26b24b);
  static const Color onPrimaryContainer = Color(0xFF003c12);
  static const Color inversePrimary = Color(0xFF5de072);
  static const Color surfaceTint = Color(0xFF006e27);
  static const Color primaryFixed = Color(0xFF7afd8b);
  static const Color primaryFixedDim = Color(0xFF5de072);
  static const Color onPrimaryFixed = Color(0xFF002107);
  static const Color onPrimaryFixedVariant = Color(0xFF00531b);
  
  // =========================================================================
  // SECONDARY COLORS (Deep Charcoal)
  // =========================================================================
  static const Color secondary = Color(0xFF5f5e5e);
  static const Color onSecondary = Color(0xFFffffff);
  static const Color secondaryContainer = Color(0xFFe4e2e1);
  static const Color onSecondaryContainer = Color(0xFF656464);
  static const Color secondaryFixed = Color(0xFFe4e2e1);
  static const Color secondaryFixedDim = Color(0xFFc8c6c6);
  static const Color onSecondaryFixed = Color(0xFF1b1c1c);
  static const Color onSecondaryFixedVariant = Color(0xFF474747);
  
  // =========================================================================
  // TERTIARY COLORS (Sunset Orange for CTAs)
  // =========================================================================
  static const Color tertiary = Color(0xFF904d00);
  static const Color onTertiary = Color(0xFFffffff);
  static const Color tertiaryContainer = Color(0xFFe98000);
  static const Color onTertiaryContainer = Color(0xFF512800);
  static const Color tertiaryFixed = Color(0xFFffdcc3);
  static const Color tertiaryFixedDim = Color(0xFFffb77d);
  static const Color onTertiaryFixed = Color(0xFF2f1500);
  static const Color onTertiaryFixedVariant = Color(0xFF6e3900);
  
  // =========================================================================
  // ERROR COLORS
  // =========================================================================
  static const Color error = Color(0xFFba1a1a);
  static const Color onError = Color(0xFFffffff);
  static const Color errorContainer = Color(0xFFffdad6);
  static const Color onErrorContainer = Color(0xFF93000a);
  
  // =========================================================================
  // BACKGROUND
  // =========================================================================
  static const Color background = Color(0xFFf8f9fa);
  static const Color onBackground = Color(0xFF191c1d);
  static const Color surfaceVariant = Color(0xFFe1e3e4);
  
  // =========================================================================
  // LEGACY ALIASES (for backward compatibility with existing code)
  // =========================================================================
  static const Color primaryLegacy = primary;
  static const Color accentYellow = tertiary; // Sunset Orange replaces yellow
  static const Color accentGreen = primary;
  static const Color accentRed = error;
  static const Color backgroundLight = surface;
  static const Color backgroundDark = inverseSurface;
  static const Color cardLight = surfaceContainerLowest;
  static const Color cardDark = Color(0xFF1e2021);
  static const Color iconBgLight = surfaceContainerLow;
  static const Color iconBgDark = Color(0xFF2a2c2d);
  static const Color textLight = onSurface;
  static const Color textDark = inverseOnSurface;
  static const Color textGrey = onSurfaceVariant;
  static const Color cornflowerBlue = tertiary;
  static const Color borderLight = outlineVariant;
  static const Color borderDark = outline;
  static const Color handleColor = surfaceDim;
  static const Color infoText = onSurfaceVariant;
}

// =========================================================================
// SPACING CONSTANTS (8px grid system)
// =========================================================================
class AppSpacing {
  static const double base = 4;
  static const double xs = 8;
  static const double sm = 16;
  static const double md = 24;
  static const double lg = 32;
  static const double xl = 48;
  static const double gutter = 16;
  static const double marginMobile = 20;
  
  // Edge padding helpers
  static const EdgeInsets pagePadding = EdgeInsets.all(marginMobile);
  static const EdgeInsets cardPadding = EdgeInsets.all(sm);
  static const EdgeInsets sectionPadding = EdgeInsets.symmetric(vertical: md, horizontal: marginMobile);
}

// =========================================================================
// RADIUS CONSTANTS
// =========================================================================
class AppRadius {
  static const double sm = 4;
  static const double medium = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double full = 9999;
  
  // BorderRadius helpers
  static final BorderRadius cardBorder = BorderRadius.circular(lg);
  static final BorderRadius buttonBorder = BorderRadius.circular(md);
  static final BorderRadius inputBorder = BorderRadius.circular(md);
  static final BorderRadius pillBorder = BorderRadius.circular(full);
}
