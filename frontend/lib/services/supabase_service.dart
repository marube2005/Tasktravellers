import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart'; // For kIsWeb

const String _supabaseUrl = String.fromEnvironment('SUPABASE_URL');
const String _supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

/// A central service class for initializing and providing access to the Supabase client.
/// Use this service before any other service (Auth, Ride, etc.) is instantiated.
class SupabaseService {
  late final SupabaseClient _supabaseClient;
  
  // Custom deep link redirect URL for mobile auth flows (e.g., magic links, password reset)
  // Ensure this is configured in your Supabase Auth settings and your Flutter app's manifest/plist.
  static const String _authRedirectUrl = kIsWeb
      ? '' // Not strictly needed for web/desktop unless using advanced flows
      : 'io.supabase.travelersapp://login-callback/'; 

  /// Private constructor for Singleton pattern.
  SupabaseService._internal();
  static final SupabaseService _instance = SupabaseService._internal();

  /// Factory constructor to return the single instance of SupabaseService.
  factory SupabaseService() => _instance;

  /// Getter for the SupabaseClient instance used across the application.
  SupabaseClient get client => _supabaseClient;

  // =========================================================================
  // INITIALIZATION
  // =========================================================================

  /// Initializes the Supabase client with compile-time `--dart-define` values.
  Future<void> initialize() async {
    if (_supabaseUrl.isEmpty) {
      throw Exception('SUPABASE_URL is not set via --dart-define.');
    }
    if (_supabaseAnonKey.isEmpty) {
      throw Exception('SUPABASE_ANON_KEY is not set via --dart-define.');
    }
    
    try {
      await Supabase.initialize(
        url: _supabaseUrl,
        anonKey: _supabaseAnonKey,
        debug: kDebugMode, // Enable Supabase logging in debug mode
        authOptions: const FlutterAuthClientOptions(
          authFlowType: AuthFlowType.pkce, // Recommended for mobile and web
        ),
      );
      
      _supabaseClient = Supabase.instance.client;
      debugPrint('Supabase client initialized successfully.');
      
    } catch (e) {
      debugPrint('Error initializing Supabase: $e');
      rethrow;
    }
  }
}