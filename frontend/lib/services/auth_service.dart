import 'dart:async';
import 'package:flutter/foundation.dart';
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

  /// Registers a new user with an email and password.
  ///
  /// Throws an [Exception] on failure. On success the caller should show a
  /// confirmation message and navigate to '/email_verification'.
  ///
  /// NOTE: The MVP specifies Phone/OTP. Supabase supports this via
  /// 'signInWithOtp(phone: ...)'. Email/Password is used here for simplicity;
  /// the phone flow requires additional backend OTP handling.
  Future<void> signUpUser({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {
    try {
      final authResponse = await _supabaseClient.auth.signUp(
        email: email.trim(),
        password: password.trim(),
        data: {'name': name.trim(), 'phone': phone.trim()},
      );

      final user = authResponse.user;
      if (user == null) throw Exception('Signup failed.');
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
        email: email.trim(),
        password: password.trim(),
      );

      final user = response.user;
      if (user == null) throw Exception('User not found.');

      if (user.emailConfirmedAt == null) {
        // Sign the user out immediately so the session is not kept.
        await _supabaseClient.auth.signOut();
        return LoginResult.emailNotVerified;
      }

      return LoginResult.success;
    } on AuthException catch (e) {
      throw Exception(e.message);
    } catch (e) {
      throw Exception('Login error: $e');
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
}
