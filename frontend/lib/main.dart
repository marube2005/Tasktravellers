// lib/main.dart
import 'package:flutter/material.dart';
import 'app.dart';
import 'services/supabase_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Supabase first
  final supabaseService = SupabaseService();
  await supabaseService.initialize();
  
  runApp(const MyApp());
}