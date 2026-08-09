import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Outcome of a successful [AuthService.loginUser] call.
/// The caller is responsible for navigating and showing feedback.
enum LoginResult {
  /// Authentication succeeded and email is verified.
  success,

  /// Authentication succeeded but the email address has not yet been confirmed.
  /// The user has been signed out automatically.
  emailNotVerified,
}

enum SignUpResult {
  /// User session created and active.
  sessionCreated,

  /// Account created but email verification link was sent.
  needsEmailVerification,
}

/// A service class to handle all Supabase Authentication logic.
class AuthService {
  final SupabaseClient _supabaseClient = Supabase.instance.client;

  /// Private constructor for Singleton pattern.
  AuthService._internal();
  static final AuthService _instance = AuthService._internal();

  /// Factory constructor to return the single instance of AuthService.
  factory AuthService() => _instance;
  Stream<AuthState> get authStateChanges =>
      _supabaseClient.auth.onAuthStateChange;

  /// Retrieves the current user session.
  Session? get currentSession => _supabaseClient.auth.currentSession;

  /// =========================================================================
  /// 2. PUBLIC METHODS
  /// =========================================================================

  /// Signs up a user using email and password.
  Future<SignUpResult> signUpUser({
    required String name,
    required String email,
    String? phone,
    required String password,
    String? role,
  }) async {
    try {
      final cleanEmail = email.trim().toLowerCase();
      final cleanName = name.trim();
      final cleanPhone = (phone != null && phone.trim().isNotEmpty) ? phone.trim() : null;
      final userRole = (role != null && role.isNotEmpty) ? role.toLowerCase() : 'passenger';

      final dataPayload = <String, dynamic>{
        'name': cleanName,
        'full_name': cleanName,
        'role': userRole,
      };
      if (cleanPhone != null) {
        dataPayload['phone'] = cleanPhone;
      }

      final authResponse = await _supabaseClient.auth.signUp(
        email: cleanEmail,
        password: password.trim(),
        data: dataPayload,
      );

      final user = authResponse.user;
      if (user == null) throw Exception('Signup failed.');

      if (authResponse.session != null) {
        try {
          final userMap = <String, dynamic>{
            'id': user.id,
            'email': cleanEmail,
            'name': cleanName,
            'role': userRole,
          };
          if (cleanPhone != null) {
            userMap['phone'] = cleanPhone;
          }
          await _supabaseClient.from('users').upsert(userMap);
        } catch (_) {}
        return SignUpResult.sessionCreated;
      } else {
        return SignUpResult.needsEmailVerification;
      }
    } on AuthException catch (e) {
      throw Exception('Supabase Auth Error: ${e.message}');
    } catch (e) {
      throw Exception('Unexpected signup error: $e');
    }
  }

  /// Logs in a user using email and password.
  ///
  /// Returns a [LoginResult] indicating what the caller should do next.
  /// Throws an [Exception] on authentication failure.
  Future<LoginResult> loginUser(String email, String password) async {
    try {
      final response = await _supabaseClient.auth.signInWithPassword(
        email: email.trim().toLowerCase(),
        password: password.trim(),
      );

      final user = response.user;
      if (user == null) throw Exception('User not found.');

      // Commented out mandatory email verification check for dev/testing:
      // if (user.emailConfirmedAt == null) {
      //   await _supabaseClient.auth.signOut();
      //   return LoginResult.emailNotVerified;
      // }

      return LoginResult.success;
    } on AuthException catch (e) {
      if (e.message.toLowerCase().contains('email not confirmed') ||
          e.message.toLowerCase().contains('email_not_confirmed')) {
        return LoginResult.emailNotVerified;
      }
      if (e.message.toLowerCase().contains('invalid login credentials')) {
        throw Exception(
          'Invalid credentials. If you recently signed up, please verify your email inbox or check your password.',
        );
      }
      throw Exception(e.message);
    } catch (e) {
      throw Exception('Login error: $e');
    }
  }

  /// Resends the signup confirmation email to the specified email address.
  Future<void> resendVerificationEmail(String email) async {
    try {
      await _supabaseClient.auth.resend(
        type: OtpType.signup,
        email: email.trim().toLowerCase(),
      );
    } on AuthException catch (e) {
      throw Exception('Failed to resend verification email: ${e.message}');
    } catch (e) {
      throw Exception('Unexpected error: $e');
    }
  }

  /// Signs out the current user and clears the session.
  Future<void> signOut() async {
    try {
      await _supabaseClient.auth.signOut();
    } on AuthException catch (e) {
      throw Exception('Supabase Auth Error during sign out: ${e.message}');
    } catch (e) {
      throw Exception('An unexpected error occurred during sign out: $e');
    }
  }

  /// Resets the user's password using an email.
  Future<void> resetPassword({required String email}) async {
    try {
      await _supabaseClient.auth.resetPasswordForEmail(
        email,
        redirectTo: kIsWeb
            ? null
            : 'io.supabase.travelersapp://login/reset-password',
      );
    } on AuthException catch (e) {
      throw Exception('Supabase Auth Error: ${e.message}');
    } catch (e) {
      throw Exception('An unexpected error occurred: $e');
    }
  }

  /// Updates the user's password after they click the reset link in email.
  Future<void> updatePassword({required String newPassword}) async {
    try {
      await _supabaseClient.auth.updateUser(
        UserAttributes(password: newPassword),
      );
    } on AuthException catch (e) {
      throw Exception('Supabase Auth Error: ${e.message}');
    } catch (e) {
      throw Exception('An unexpected error occurred: $e');
    }
  }

  /// =========================================================================
  /// 3. USER MANAGEMENT (Profile Retrieval)
  /// =========================================================================

  /// Fetches the current authenticated user's profile from the 'users' table.
  /// This is crucial for determining the user's role and verification status.
  Future<Map<String, dynamic>?> getCurrentUserProfile() async {
    final User? user = _supabaseClient.auth.currentUser;

    if (user == null) {
      return null;
    }

    try {
      // Fetch the profile using the user's ID
      final Map<String, dynamic> profile = await _supabaseClient
          .from('users')
          .select()
          .eq('id', user.id)
          .single();

      return profile;
    } on PostgrestException catch (e) {
      // Handle the case where no profile is found (e.g., initial setup failure)
      if (e.code == 'PGRST116') {
        return null;
      }
      throw Exception('Database Error fetching profile: ${e.message}');
    } catch (e) {
      throw Exception(
        'An unexpected error occurred while fetching profile: $e',
      );
    }
  }

  /// Navigates the user to their role-based homepage if a profile exists in DB,
  /// or to /role-selection if their profile/role is missing.
  Future<void> handlePostLoginNavigation(BuildContext context) async {
    try {
      final profile = await getCurrentUserProfile();

      if (!context.mounted) return;

      if (profile != null && profile['role'] != null && (profile['role'] as String).isNotEmpty) {
        final role = (profile['role'] as String).toLowerCase();
        if (role == 'admin') {
          Navigator.pushReplacementNamed(context, '/admin-verification-review');
        } else if (role == 'psv' || role == 'driver') {
          final userId = _supabaseClient.auth.currentUser?.id;
          if (userId != null) {
            try {
              final driverProfile = await _supabaseClient
                  .from('psv_driver_profiles')
                  .select()
                  .eq('user_id', userId)
                  .maybeSingle();

              if (!context.mounted) return;

              if (driverProfile == null || driverProfile['full_name'] == null) {
                Navigator.pushReplacementNamed(context, '/psv-driver-profile-setup');
                return;
              } else if (driverProfile['psv_badge_url'] == null ||
                  driverProfile['driving_license_url'] == null) {
                Navigator.pushReplacementNamed(context, '/psv-driver-verification');
                return;
              }
            } catch (_) {}
          }
          if (context.mounted) {
            Navigator.pushReplacementNamed(context, '/psv-driver-dashboard');
          }
        } else if (role == 'sacco') {
          Navigator.pushReplacementNamed(context, '/sacco-dashboard');
        } else {
          // Passenger dashboard
          Navigator.pushReplacementNamed(context, '/dashboard');
        }
      } else {
        Navigator.pushReplacementNamed(context, '/role-selection');
      }
    } catch (_) {
      if (context.mounted) {
        Navigator.pushReplacementNamed(context, '/role-selection');
      }
    }
  }
}
