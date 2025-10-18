import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart'; // For kIsWeb

/// A central service class for initializing and providing access to the Supabase client.
/// Use this service before any other service (Auth, Ride, etc.) is instantiated.
class SupabaseService {
  late final SupabaseClient _supabaseClient;
  
  // NOTE: Replace these with your actual Supabase project credentials
  // For production, consider using environment variables (e.g., flutter_dotenv).
  static const String _supabaseUrl = 'YOUR_SUPABASE_URL';
  static const String _supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY';
  
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

  /// Initializes the Supabase client with the provided URL and Anon Key.
  /// This must be called once at the start of the application.
  Future<void> initialize() async {
    if (_supabaseUrl.startsWith('YOUR_')) {
      throw Exception('SupabaseService not configured! Please update _supabaseUrl and _supabaseAnonKey in supabase_service.dart.');
    }
    
    try {
      await Supabase.initialize(
        url: _supabaseUrl,
        anonKey: _supabaseAnonKey,
        debug: kDebugMode, // Enable Supabase logging in debug mode
        // Custom deep link for redirecting users back to the app after external auth (e.g., OAuth, email validation)
        authOptions: const FlutterAuthClientOptions(
          authFlowType: AuthFlowType.pkce, // Recommended for mobile and web
          // 'redirectUrl' is not a valid named parameter for FlutterAuthClientOptions;
          // configure deep links using platform-specific settings or by using supported Supabase options.
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