// lib/main.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// Import all the screen files you have created (updated to local package paths)
import 'package:frontend/pages/role_selection_screen.dart';
import 'package:frontend/pages/passenger_dashboard_screen.dart';
import 'package:frontend/pages/search_matatus_screen.dart';
import 'package:frontend/pages/payment_checkout_screen.dart';
import 'package:frontend/pages/ride_completion_rating_screen.dart';
import 'package:frontend/pages/ride_tracking_screen.dart';

void main() {
  runApp(const MyApp());
}

// ------------------- App Colors & Themes -------------------

/// A central place for all your app's colors.
class AppColors {
  // Primary & Accents
  static const Color primary = Color(0xFF4C85E6); // Consistent Blue
  static const Color accentYellow = Color(0xFFF59E0B);
  static const Color accentGreen = Color(0xFF4CAF50);
  static const Color accentRed = Color(0xFFE53E3E);

  // Backgrounds
  static const Color backgroundLight = Color(0xFFF6F7F8);
  static const Color backgroundDark = Color(0xFF111721);
  
  // Cards & Surfaces
  static const Color cardLight = Colors.white;
  static const Color cardDark = Color(0xFF1A202C);

  // Text & Icons
  static const Color textLight = Color(0xFF1A202C);
  static const Color textDark = Color(0xFFE5E7EB);
  static const Color textGrey = Color(0xFF6B7280);
}

/// A central place for your app's theme data.
class AppThemes {
  static final ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    scaffoldBackgroundColor: AppColors.backgroundLight,
    primaryColor: AppColors.primary,
    textTheme: GoogleFonts.manropeTextTheme().apply(bodyColor: AppColors.textLight),
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.backgroundLight,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: GoogleFonts.manrope(fontWeight: FontWeight.bold, color: AppColors.textLight, fontSize: 20),
      iconTheme: const IconThemeData(color: AppColors.textLight),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(56),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
        textStyle: GoogleFonts.manrope(fontWeight: FontWeight.bold, fontSize: 16),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.cardLight,
      hintStyle: const TextStyle(color: AppColors.textGrey),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: BorderSide.none,
      ),
    ),
  );

  static final ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.backgroundDark,
    primaryColor: AppColors.primary,
    textTheme: GoogleFonts.manropeTextTheme().apply(bodyColor: AppColors.textDark),
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.backgroundDark,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: GoogleFonts.manrope(fontWeight: FontWeight.bold, color: AppColors.textDark, fontSize: 20),
      iconTheme: const IconThemeData(color: AppColors.textDark),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(56),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
        textStyle: GoogleFonts.manrope(fontWeight: FontWeight.bold, fontSize: 16),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.cardDark,
      hintStyle: const TextStyle(color: AppColors.textGrey),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: BorderSide.none,
      ),
    ),
  );
}

// ------------------- Main Application Widget -------------------

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Travelers App',
      debugShowCheckedModeBanner: false,
      
      // --- Themes ---
      theme: AppThemes.lightTheme,
      darkTheme: AppThemes.darkTheme,
      themeMode: ThemeMode.system, // Automatically adapts to system settings

      // --- Routing ---
      // The first screen the user sees.
      initialRoute: '/dashboard', 
      
      // Defines all the possible screens in your app.
      routes: {
        '/role-selection': (context) => const RoleSelectionScreen(),
        '/dashboard': (context) => const PassengerDashboardScreen(),
        '/matatu-list': (context) => const MatatuListScreen(),
        '/payment': (context) => const PaymentScreen(),
        '/ride-complete': (context) => const RideCompleteScreen(),
        '/live-tracking': (context) => const LiveTrackingScreen(),
      },
    );
  }
}