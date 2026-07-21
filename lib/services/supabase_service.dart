import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart'; // For kIsWeb
import 'package:flutter/services.dart' show rootBundle;

/// A central service class for initializing and providing access to the Supabase client.
/// Use this service before any other service (Auth, Ride, etc.) is instantiated.
class SupabaseService {
  late final SupabaseClient _supabaseClient;
  late String _supabaseUrl;
  late String _supabaseAnonKey;

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

  /// Loads credentials from the .env file asset.
  Future<void> _loadEnvCredentialsFromAsset() async {
    try {
      final envContent = await rootBundle.loadString('.env');
      final lines = envContent.split('\n');
      
      for (final line in lines) {
        final trimmedLine = line.trim();
        if (trimmedLine.isEmpty || trimmedLine.startsWith('#')) {
          continue; // Skip empty lines and comments
        }
        
        if (trimmedLine.startsWith('SUPABASE_URL=')) {
          _supabaseUrl = trimmedLine.split('=').last;
        } else if (trimmedLine.startsWith('SUPABASE_ANON_KEY=')) {
          _supabaseAnonKey = trimmedLine.split('=').last;
        }
      }
      
      debugPrint('Credentials loaded from .env asset successfully.');
    } catch (e) {
      debugPrint('Error loading .env credentials: $e');
      rethrow;
    }
  }

  /// Loads credentials from compile-time environment variables (web).
  void _loadEnvCredentialsFromDefines() {
    try {
      _supabaseUrl = const String.fromEnvironment('SUPABASE_URL');
      _supabaseAnonKey = const String.fromEnvironment('SUPABASE_ANON_KEY');
      
      debugPrint('Web credentials - URL: ${_supabaseUrl.isNotEmpty ? 'SET' : 'EMPTY'}, Key: ${_supabaseAnonKey.isNotEmpty ? 'SET' : 'EMPTY'}');
      debugPrint('Credentials loaded from compile-time defines.');
    } catch (e) {
      debugPrint('Error loading environment defines: $e');
      rethrow;
    }
  }

  /// Initializes the Supabase client with credentials from appropriate source.
  /// - Mobile/Desktop: Reads from .env asset at runtime
  /// - Web: Reads from compile-time --dart-define values
  Future<void> initialize() async {
    try {
      // Load credentials based on platform
      if (kIsWeb) {
        _loadEnvCredentialsFromDefines();
      } else {
        await _loadEnvCredentialsFromAsset();
      }
      
      if (_supabaseUrl.isEmpty) {
        throw Exception(
          'SUPABASE_URL is not set. For web, use:\n'
          '  flutter run -d chrome --dart-define=SUPABASE_URL=https://... --dart-define=SUPABASE_ANON_KEY=...\n'
          'Or ensure --dart-define-from-file=.env is passed correctly.'
        );
      }
      if (_supabaseAnonKey.isEmpty) {
        throw Exception(
          'SUPABASE_ANON_KEY is not set. For web, use:\n'
          '  flutter run -d chrome --dart-define=SUPABASE_URL=https://... --dart-define=SUPABASE_ANON_KEY=...\n'
          'Or ensure --dart-define-from-file=.env is passed correctly.'
        );
      }
      
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

/// Generate a unique invite code for group rides
String generateInviteCode() {
  const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ0123456789';
  final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
  // Take last 6 digits of timestamp
  final shortCode = timestamp.substring(timestamp.length - 6);
  // Add 2 random characters
  final random = String.fromCharCodes(
    List.generate(2, (_) => chars.codeUnitAt(
      DateTime.now().millisecondsSinceEpoch % chars.length
    ))
  );
  return '$shortCode$random';
}
}
