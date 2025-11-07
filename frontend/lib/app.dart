import 'package:flutter/material.dart';
import 'themes/app_themes.dart';
import 'pages/welcome_screen.dart';
import 'pages/login_screen.dart';
import 'pages/register_screen.dart';
import 'pages/role_selection_screen.dart';
import 'pages/passenger_dashboard_screen.dart';
import 'pages/search_matatus_screen.dart';
import 'pages/payment_checkout_screen.dart';
import 'pages/ride_completion_rating_screen.dart';
import 'pages/ride_tracking_screen.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Travelers App',
      debugShowCheckedModeBanner: false,

      // ---------- THEME ----------
      theme: AppThemes.lightTheme,
      darkTheme: AppThemes.darkTheme,
      themeMode: ThemeMode.system,

      // ---------- ROUTING ----------
      initialRoute: '/welcome',
      routes: {
        '/welcome': (context) => const WelcomeScreen(),
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const SignUpScreen(),
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
