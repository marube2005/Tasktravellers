import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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

  /// Registers a new user with an email and password, and inserts their profile
  /// into the 'users' table with the specified role.
  ///
  /// *NOTE: The MVP specifies Phone/OTP. Supabase supports this via
  /// 'signUp(phone: ..., password: ...)' or 'signInWithOtp(phone: ...)'
  /// depending on your flow. For simplicity and standard practice, Email/Password
  /// is shown, as the phone flow requires a separate package or backend logic
  /// for OTP verification in the client-side unless using 'signInWithOtp'.
  Future<void> signUpUser({
    required String name,
    required String email,
    required String phone,
    required String password,
    BuildContext? context, // optional, only if you want snackbars
  }) async {
    try {
      final supabase = Supabase.instance.client;

      final authResponse = await supabase.auth.signUp(
        email: email.trim(),
        password: password.trim(),
        data: {'name': name.trim(), 'phone': phone.trim()},
      );

      final user = authResponse.user;
      if (user == null) throw Exception("Signup failed.");

      // Optionally insert into 'users' table if you don't use RLS triggers
      // await supabase.from('users').insert({
      //   'id': user.id,
      //   'name': name,
      //   'email': email,
      //   'phone': phone,
      //   'role': 'passenger',
      // });

      if (context != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Signup successful! Check your email to verify.'),
          ),
        );
        Navigator.pushReplacementNamed(context, '/email_verification');
      }
    } on AuthException catch (e) {
      if (context != null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.message)));
      }
      throw Exception('Supabase Auth Error: ${e.message}');
    } catch (e) {
      if (context != null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
      throw Exception('Unexpected signup error: $e');
    }
  }

  /// Logs in a user using email and password.
  Future<void> loginUser(
    String email,
    String password,
    BuildContext context,
  ) async {
    try {
      final supabase = Supabase.instance.client;

      final response = await supabase.auth.signInWithPassword(
        email: email.trim(),
        password: password.trim(),
      );

      final user = response.user;
      if (user == null) throw Exception('User not found.');

      // 🔍 Check if verified
      if (user.emailConfirmedAt == null) {
        // Sign them out immediately
        await supabase.auth.signOut();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please verify your email before logging in.'),
          ),
        );

        // Redirect to verification screen
        Navigator.pushReplacementNamed(context, '/email_verification');
        return;
      }

      // ✅ Continue to home if verified
      Navigator.pushReplacementNamed(context, '/home');
    } on AuthException catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
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
}
