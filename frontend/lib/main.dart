import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Credentials are injected at build time via:
  //   flutter run --dart-define-from-file=.env
  // or per-key:
  //   flutter run --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...
  //
  // NEVER bundle the .env file as a Flutter asset — doing so embeds the file
  // contents in the compiled binary where it can be extracted by anyone.
  const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  if (supabaseUrl.isEmpty || supabaseAnonKey.isEmpty) {
    throw Exception(
      'Missing required build config: SUPABASE_URL and SUPABASE_ANON_KEY '
      'must be set via --dart-define or --dart-define-from-file.',
    );
  }

  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseAnonKey,
    authOptions: FlutterAuthClientOptions(
      authFlowType: kIsWeb ? AuthFlowType.implicit : AuthFlowType.pkce,
    ),
  );

  runApp(const MyApp());
}
