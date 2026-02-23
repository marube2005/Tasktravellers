import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart'; // For kIsWeb
import 'package:flutter_dotenv/flutter_dotenv.dart';

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

  /// Initializes the Supabase client with credentials from the .env file.
  /// This must be called once at the start of the application, after dotenv.load().
  Future<void> initialize() async {
    final supabaseUrl = dotenv.env['SUPABASE_URL'];
    final supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'];

    if (supabaseUrl == null || supabaseUrl.isEmpty) {
      throw Exception('SUPABASE_URL is not set in .env file.');
    }
    if (supabaseAnonKey == null || supabaseAnonKey.isEmpty) {
      throw Exception('SUPABASE_ANON_KEY is not set in .env file.');
    }
    
    try {
      await Supabase.initialize(
        url: supabaseUrl,
        anonKey: supabaseAnonKey,
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