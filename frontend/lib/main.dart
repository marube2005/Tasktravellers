import 'package:flutter/material.dart';
import 'app.dart';
import 'services/supabase_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase using SupabaseService
  // Credentials are read from the .env file at runtime
  await SupabaseService().initialize();

  runApp(const MyApp());
}
