import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_role.dart'; // Assuming you'll create this enum

/// A service class to handle all Supabase Authentication logic.
class AuthService {
  final SupabaseClient _supabaseClient = Supabase.instance.client;

  /// Private constructor for Singleton pattern.
  AuthService._internal();
  static final AuthService _instance = AuthService._internal();

  /// Factory constructor to return the single instance of AuthService.
  factory AuthService() => _instance;

  /// =========================================================================
  /// 1. AUTH STATE STREAM
  /// =========================================================================

  /// Stream to listen for real-time changes in the user's authentication state.
  /// This is typically used to navigate between the Auth and Main screens.
  Stream<AuthState> get authStateChanges => _supabaseClient.auth.onAuthStateChange;

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
  Future<void> signUp({
    required String email,
    required String password,
    required String name,
    required String phone,
    required UserRole role,
  }) async {
    try {
      // 1. Sign up the user in auth.users table
      final AuthResponse response = await _supabaseClient.auth.signUp(
        email: email,
        password: password,
        data: {'name': name, 'phone': phone}, // Optional metadata
      );

      final User? user = response.user;

      if (user == null) {
        throw Exception('User registration failed. No user returned.');
      }

      // 2. Insert the profile into the public 'users' table
      // This step assumes you have RLS policies set up to allow this.
      await _supabaseClient.from('users').insert({
        'id': user.id,
        'email': email,
        'phone': phone,
        'name': name,
        'role': role.toShortString(), // Convert enum to string for DB
      });

      // Handle email verification if required (Supabase default)
      if (user.emailConfirmedAt == null) {
        // You might want to show a message to the user to check their email
        debugPrint('Sign up successful! Please check your email for a verification link.');
      }
    } on AuthException catch (e) {
      throw Exception('Supabase Auth Error: ${e.message}');
    } catch (e) {
      // Catch network errors, RLS errors, or general exceptions
      throw Exception('An unexpected error occurred during sign up: $e');
    }
  }

  /// Logs in a user using email and password.
  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    try {
      // Supabase automatically updates the session on successful sign-in
      await _supabaseClient.auth.signInWithPassword(
        email: email,
        password: password,
      );
    } on AuthException catch (e) {
      throw Exception('Supabase Auth Error: ${e.message}');
    } catch (e) {
      throw Exception('An unexpected error occurred during sign in: $e');
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
        redirectTo: kIsWeb ? null : 'io.supabase.travelersapp://login/reset-password',
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
      throw Exception('An unexpected error occurred while fetching profile: $e');
    }
  }
}