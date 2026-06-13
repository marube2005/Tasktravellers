// lib/providers/auth_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_service.dart';

final supabaseClientProvider = Provider((ref) {
  return SupabaseService().client;
});

final currentUserProvider = Provider<User?>((ref) {
  final supabase = ref.watch(supabaseClientProvider);
  return supabase.auth.currentUser;
});

final userIdProvider = Provider<String?>((ref) {
  final user = ref.watch(currentUserProvider);
  return user?.id;
});

final isLoggedInProvider = Provider<bool>((ref) {
  final user = ref.watch(currentUserProvider);
  return user != null;
});