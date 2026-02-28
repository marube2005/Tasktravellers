import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'themes/app_themes.dart';
import 'pages/splash_screen.dart';
import 'pages/welcome_screen.dart';
import 'pages/login_screen.dart';
import 'pages/register_screen.dart';
import 'pages/role_selection_screen.dart';
import 'pages/phone_login_screen.dart';
import 'pages/passenger_profile_setup_screen.dart';
import 'pages/sacco_profile_setup_screen.dart';
import 'pages/sacco_verification_screen.dart';
import 'pages/permissions_screen.dart';
import 'pages/passenger_dashboard_screen.dart';
import 'pages/search_matatus_screen.dart';
import 'pages/payment_checkout_screen.dart';
import 'pages/ride_completion_rating_screen.dart';
import 'pages/ride_tracking_screen.dart';
import 'pages/email_verification.dart';
import 'pages/sacco_dashboard_screen.dart';
import 'pages/reset_password_screen.dart';
import 'pages/update_password_screen.dart';

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  late final StreamSubscription<AuthState> _authSubscription;

  @override
  void initState() {
    super.initState();
    _authSubscription = Supabase.instance.client.auth.onAuthStateChange.listen(
      (AuthState data) {
        final event = data.event;
        if (event == AuthChangeEvent.passwordRecovery) {
          // User clicked the password reset link in email
          _navigatorKey.currentState?.pushNamedAndRemoveUntil(
            '/update_password',
            (route) => false,
          );
        }
      },
    );
  }

  @override
  void dispose() {
    _authSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: _navigatorKey,
      title: 'Travelers App',
      debugShowCheckedModeBanner: false,

      // ---------- THEME ----------
      theme: AppThemes.lightTheme,
      darkTheme: AppThemes.darkTheme,
      themeMode: ThemeMode.system,

      // ---------- ROUTING ----------
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/welcome': (context) => const WelcomeScreen(),
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const SignUpScreen(),
        '/email_verification': (context) => const EmailVerificationScreen(),
        '/phone-verification': (context) => const PhoneVerificationScreen(),
        '/role-selection': (context) => const RoleSelectionScreen(),
        '/passenger-profile-setup': (context) => const PassengerProfileSetupScreen(),
        '/sacco-profile-setup': (context) => const SaccoProfileSetupScreen(),
        '/sacco-verification': (context) => const SaccoVerificationScreen(),
        '/permissions': (context) => const PermissionsScreen(),
        '/dashboard': (context) => const PassengerDashboardScreen(),
        '/sacco-dashboard': (context) => const SaccoDashboardScreen(),
        '/matatu-list': (context) => const MatatuListScreen(),
        '/payment': (context) => const PaymentScreen(),
        '/ride-complete': (context) => const RideCompleteScreen(),
        '/live-tracking': (context) => const LiveTrackingScreen(),
        '/reset_password': (context) => const ResetPasswordScreen(),
        '/update_password': (context) => const UpdatePasswordScreen(),
      },
    );
  }
}
