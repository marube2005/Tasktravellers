import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';  // ✅ ADD THIS
import 'package:supabase_flutter/supabase_flutter.dart';
import 'themes/app_themes.dart';
import 'pages/splash_screen.dart';
import 'pages/welcome_screen.dart';
import 'pages/login_screen.dart';
import 'pages/register_screen.dart';
import 'pages/psv/role_selection_screen.dart';
import 'pages/otp_verification_screen.dart';
import 'pages/passenger/passenger_profile_setup_screen.dart';
import 'pages/psv/sacco_profile_setup_screen.dart';
import 'pages/psv/sacco_verification_screen.dart';
import 'pages/psv/psv_driver_profile_setup_screen.dart';
import 'pages/psv/psv_driver_verification_screen.dart';
import 'pages/psv/psv_driver_dashboard_screen.dart';
import 'pages/admin/admin_verification_review_screen.dart';
import 'pages/passenger/permissions_screen.dart';
import 'pages/passenger/passenger_dashboard_screen.dart';
import 'pages/passenger/create_group_ride_screen.dart';
import 'pages/search_matatus_screen.dart';
import 'pages/passenger/payment_checkout_screen.dart';
import 'pages/passenger/ride_completion_rating_screen.dart';
import 'pages/passenger/ride_tracking_screen.dart';
import 'pages/passenger/ride_acceptance_screen.dart';
import 'pages/email_verification.dart';
import 'pages/psv/sacco_dashboard_screen.dart';
import 'pages/reset_password_screen.dart';
import 'pages/update_password_screen.dart';

final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.system);

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
    // ✅ WRAP WITH ProviderScope
    return ProviderScope(
      child: Consumer(
        builder: (context, ref, child) {
          final themeMode = ref.watch(themeModeProvider);
          return MaterialApp(
            navigatorKey: _navigatorKey,
            title: 'Travelers App',
            debugShowCheckedModeBanner: false,

            // ---------- THEME ----------
            theme: AppThemes.lightTheme,
            darkTheme: AppThemes.darkTheme,
            themeMode: themeMode,

        // ---------- ROUTING ----------
        initialRoute: '/',
        routes: {
          '/': (context) => const SplashScreen(),
          '/welcome': (context) => const WelcomeScreen(),
          '/login': (context) => const LoginScreen(),
          '/register': (context) => const SignUpScreen(),
          '/email_verification': (context) {
            final args = ModalRoute.of(context)?.settings.arguments;
            final email = (args is Map) ? args['email'] as String? : null;
            return EmailVerificationScreen(email: email);
          },
          '/email-verification': (context) {
            final args = ModalRoute.of(context)?.settings.arguments;
            final email = (args is Map) ? args['email'] as String? : null;
            return EmailVerificationScreen(email: email);
          },

          '/phone-verification': (context) => const OtpVerificationScreen(),
          '/role-selection': (context) => const RoleSelectionScreen(),
          '/passenger-profile-setup': (context) => const PassengerProfileSetupScreen(),
          '/sacco-profile-setup': (context) => const SaccoProfileSetupScreen(),
          '/sacco-verification': (context) => const SaccoVerificationScreen(),
          '/psv-driver-profile-setup': (context) => const PsvDriverProfileSetupScreen(),
          '/psv-driver-verification': (context) => const PsvDriverVerificationScreen(),
          '/psv-driver-dashboard': (context) => const PsvDriverDashboardScreen(),
          '/permissions': (context) => const PermissionsScreen(),
          '/dashboard': (context) => const PassengerDashboardScreen(),
          '/create-group-ride': (context) => const CreateGroupRideScreen(),
          '/sacco-dashboard': (context) => const SaccoDashboardScreen(),
          '/matatu-list': (context) => const MatatuListScreen(),
          '/payment': (context) => const PaymentScreen(),
          '/ride-complete': (context) => const RideCompleteScreen(),
          '/live-tracking': (context) => const LiveTrackingScreen(),
          '/ride-acceptance': (context) => const RideAcceptanceScreen(),
          '/reset_password': (context) => const ResetPasswordScreen(),
          '/update_password': (context) => const UpdatePasswordScreen(),
          '/admin-verification-review': (context) => const AdminVerificationReviewScreen(),
        },
          );
        },
      ),
    );
  }
}
