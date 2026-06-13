// lib/themes/app_themes.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';
// import 'app_spacing.dart';

class AppThemes {
  // Shadow constants
  static List<BoxShadow> get level1Shadow {
    return [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.05),
        blurRadius: 20,
        offset: const Offset(0, 4),
      ),
    ];
  }
  
  static List<BoxShadow> get level2Shadow {
    return [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.12),
        blurRadius: 30,
        offset: const Offset(0, 8),
      ),
    ];
  }

  static final ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    useMaterial3: true,
    
    // Colors
    scaffoldBackgroundColor: AppColors.background,
    primaryColor: AppColors.primary,
    colorScheme: const ColorScheme.light(
      primary: AppColors.primary,
      onPrimary: AppColors.onPrimary,
      primaryContainer: AppColors.primaryContainer,
      onPrimaryContainer: AppColors.onPrimaryContainer,
      secondary: AppColors.secondary,
      onSecondary: AppColors.onSecondary,
      secondaryContainer: AppColors.secondaryContainer,
      onSecondaryContainer: AppColors.onSecondaryContainer,
      tertiary: AppColors.tertiary,
      onTertiary: AppColors.onTertiary,
      tertiaryContainer: AppColors.tertiaryContainer,
      error: AppColors.error,
      onError: AppColors.onError,
      errorContainer: AppColors.errorContainer,
      surface: AppColors.surface,
      onSurface: AppColors.onSurface,
      surfaceContainerHighest: AppColors.surfaceVariant,
      outline: AppColors.outline,
    ),
    
    // Typography
    textTheme: _lightTextTheme,
    
    // AppBar
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.surfaceContainerLowest,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: GoogleFonts.lexend(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: AppColors.onSurface,
      ),
      iconTheme: const IconThemeData(color: AppColors.onSurface),
      surfaceTintColor: Colors.transparent,
    ),
    
    // Buttons
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        minimumSize: const Size.fromHeight(48),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        textStyle: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    
    // Input Fields
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surfaceContainerLowest,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.outlineVariant),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.outlineVariant),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
    ),
    
    // Card Theme
    cardTheme: CardThemeData(
      color: AppColors.surfaceContainerLowest,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),
  );

  static final TextTheme _lightTextTheme = TextTheme(
    displayLarge: GoogleFonts.lexend(
      fontSize: 40,
      fontWeight: FontWeight.w700,
      color: AppColors.onSurface,
    ),
    displayMedium: GoogleFonts.lexend(
      fontSize: 32,
      fontWeight: FontWeight.w600,
      color: AppColors.onSurface,
    ),
    displaySmall: GoogleFonts.lexend(
      fontSize: 28,
      fontWeight: FontWeight.w600,
      color: AppColors.onSurface,
    ),
    headlineLarge: GoogleFonts.lexend(
      fontSize: 24,
      fontWeight: FontWeight.w600,
      color: AppColors.onSurface,
    ),
    bodyLarge: GoogleFonts.inter(
      fontSize: 16,
      fontWeight: FontWeight.w400,
      color: AppColors.onSurface,
    ),
    bodyMedium: GoogleFonts.inter(
      fontSize: 14,
      fontWeight: FontWeight.w400,
      color: AppColors.onSurface,
    ),
    labelLarge: GoogleFonts.inter(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      color: AppColors.onSurface,
    ),
    labelMedium: GoogleFonts.inter(
      fontSize: 12,
      fontWeight: FontWeight.w500,
      color: AppColors.onSurfaceVariant,
    ),
  );

// lib/themes/app_themes.dart - Add this after lightTheme

static final ThemeData darkTheme = ThemeData(
  brightness: Brightness.dark,
  useMaterial3: true,
  
  // Colors
  scaffoldBackgroundColor: AppColors.inverseSurface,
  primaryColor: AppColors.primary,
  colorScheme: const ColorScheme.dark(
    primary: AppColors.primary,
    onPrimary: AppColors.onPrimary,
    primaryContainer: AppColors.primaryContainer,
    onPrimaryContainer: AppColors.onPrimaryContainer,
    secondary: AppColors.secondary,
    onSecondary: AppColors.onSecondary,
    secondaryContainer: AppColors.secondaryContainer,
    onSecondaryContainer: AppColors.onSecondaryContainer,
    tertiary: AppColors.tertiary,
    onTertiary: AppColors.onTertiary,
    tertiaryContainer: AppColors.tertiaryContainer,
    error: AppColors.error,
    onError: AppColors.onError,
    errorContainer: AppColors.errorContainer,
    surface: AppColors.inverseSurface,
    onSurface: AppColors.inverseOnSurface,
    surfaceContainerHighest: AppColors.surfaceVariant,
    outline: AppColors.outline,
  ),
  
  // Typography
  textTheme: _darkTextTheme,
  
  // AppBar
  appBarTheme: AppBarTheme(
    backgroundColor: AppColors.cardDark,
    elevation: 0,
    centerTitle: true,
    titleTextStyle: GoogleFonts.lexend(
      fontSize: 20,
      fontWeight: FontWeight.w600,
      color: AppColors.inverseOnSurface,
    ),
    iconTheme: const IconThemeData(color: AppColors.inverseOnSurface),
    surfaceTintColor: Colors.transparent,
  ),
  
  // Buttons
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: AppColors.primary,
      foregroundColor: AppColors.onPrimary,
      minimumSize: const Size.fromHeight(48),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
  ),
  
  // Input Fields
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: AppColors.cardDark,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.outline),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.outline),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
    ),
  ),
  
  // Card Theme
  cardTheme: CardThemeData(
    color: AppColors.cardDark,
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
    ),
  ),
);

static final TextTheme _darkTextTheme = TextTheme(
  displayLarge: GoogleFonts.lexend(
    fontSize: 40,
    fontWeight: FontWeight.w700,
    color: AppColors.inverseOnSurface,
  ),
  displayMedium: GoogleFonts.lexend(
    fontSize: 32,
    fontWeight: FontWeight.w600,
    color: AppColors.inverseOnSurface,
  ),
  displaySmall: GoogleFonts.lexend(
    fontSize: 28,
    fontWeight: FontWeight.w600,
    color: AppColors.inverseOnSurface,
  ),
  headlineLarge: GoogleFonts.lexend(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    color: AppColors.inverseOnSurface,
  ),
  bodyLarge: GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: AppColors.inverseOnSurface,
  ),
  bodyMedium: GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.inverseOnSurface,
  ),
  labelLarge: GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.inverseOnSurface,
  ),
  labelMedium: GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: AppColors.outlineVariant,
  ),
);
}