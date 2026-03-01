import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../themes/app_colors.dart';
import '../services/auth_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkSession();
  }

  Future<void> _checkSession() async {
    // Brief delay to show splash branding
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    final session = Supabase.instance.client.auth.currentSession;

    if (session == null) {
      // No session → go to welcome
      Navigator.pushReplacementNamed(context, '/welcome');
      return;
    }

    // Session exists → check profile for role-based routing
    try {
      final profile = await AuthService().getCurrentUserProfile();

      if (!mounted) return;

      if (profile == null) {
        // Profile missing → send to role selection
        Navigator.pushReplacementNamed(context, '/role-selection');
        return;
      }

      final role = profile['role'] as String?;

      if (role == 'admin') {
        Navigator.pushReplacementNamed(context, '/admin-verification-review');
      } else if (role == 'sacco') {
        Navigator.pushReplacementNamed(context, '/sacco-dashboard');
      } else {
        // Default to passenger dashboard
        Navigator.pushReplacementNamed(context, '/dashboard');
      }
    } catch (e) {
      // On error, fall back to welcome
      Navigator.pushReplacementNamed(context, '/welcome');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // App icon
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(
                Icons.directions_bus,
                size: 56,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Nenda',
              style: GoogleFonts.manrope(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Travel together, save together',
              style: GoogleFonts.manrope(
                fontSize: 16,
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 48),
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}
