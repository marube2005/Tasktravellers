import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user.dart';
import '../models/user_role.dart'; // Assuming you have the UserRole enum defined

/// A service class to handle user profile data and related entities (like vehicles).
class UserService {
  final SupabaseClient _supabaseClient = Supabase.instance.client;

  /// Private constructor for Singleton pattern.
  UserService._internal();
  static final UserService _instance = UserService._internal();

  /// Factory constructor to return the single instance of UserService.
  factory UserService() => _instance;

  // Helper to get the current authenticated user's ID
  String? get _currentUserId => _supabaseClient.auth.currentUser?.id;

  // Helper to fetch the current user's role from the local session/state if available
  // For safety, the public profile fetch should confirm the role from the DB.
  Future<UserRole?> _getCurrentUserRole() async {
    final profile = await fetchCurrentUserProfileModel();
    if (profile != null) {
      return userRoleFromString(profile.role);
    }
    return null;
  }

  // =========================================================================
  // 1. PROFILE MANAGEMENT (Applies to all roles)
  // =========================================================================

  /// Fetches the current authenticated user's profile from the 'users' table.
  Future<AppUser?> fetchCurrentUserProfileModel() async {
    final userId = _currentUserId;
    if (userId == null) {
      return null;
    }

    try {
      final Map<String, dynamic> profile = await _supabaseClient
          .from('users')
          .select('*')
          .eq('id', userId)
          .single();

      return AppUser.fromMap(profile);
    } on PostgrestException catch (e) {
      // PGRST116 means 'No rows found', which should only happen if the
      // profile creation step after sign-up failed.
      if (e.code == 'PGRST116') {
        return null; 
      }
      throw Exception('Unable to load profile right now.');
    } catch (e) {
      throw Exception('Unable to load profile right now.');
    }
  }

  /// Backward-compatible map-based profile fetch for older callers.
  Future<Map<String, dynamic>?> fetchCurrentUserProfile() async {
    final profile = await fetchCurrentUserProfileModel();
    return profile?.toMap();
  }

  /// Updates specific fields on the current user's profile.
  Future<void> updateCurrentUserProfile({
    String? name,
    String? phone,
  }) async {
    final userId = _currentUserId;
    if (userId == null) {
      throw Exception('Authentication required. User not logged in.');
    }

    // Build map with non-null values
    final updates = <String, dynamic>{};
    if (name != null) updates['name'] = name;
    if (phone != null) updates['phone'] = phone;

    if (updates.isEmpty) return;

    try {
      await _supabaseClient
          .from('users')
          .update(updates)
          .eq('id', userId);
          
    } on PostgrestException {
      throw Exception('Unable to update profile right now.');
    } catch (e) {
      throw Exception('Unable to update profile right now.');
    }
  }

  // =========================================================================
  // 2. SACCO VEHICLE MANAGEMENT
  // =========================================================================

  /// Adds a new vehicle to the Sacco's fleet.
  /// Only callable by users with the 'sacco' role.
  Future<void> addVehicle({
    required String plateNumber,
    required int capacity,
    required String route,
  }) async {
    final saccoId = _currentUserId;
    if (saccoId == null) {
      throw Exception('Authentication required. User not logged in.');
    }
    
    // RLS should enforce that only a Sacco can insert into the vehicles table
    // where sacco_id = auth.uid(), but checking the role here adds a layer of safety.
    final role = await _getCurrentUserRole();
    if (role != UserRole.sacco) {
      throw Exception('Unauthorized access. Only Sacco operators can add vehicles.');
    }

    try {
      await _supabaseClient.from('vehicles').insert({
        'sacco_id': saccoId,
        'plate_number': plateNumber,
        'capacity': capacity,
        'route': route,
      });
    } on PostgrestException catch (e) {
      if (e.code == '23505') { // Unique violation for plate_number
        throw Exception('A vehicle with this plate number already exists.');
      }
      throw Exception('Unable to add vehicle right now.');
    } catch (e) {
      throw Exception('Unable to add vehicle right now.');
    }
  }
  
  /// Fetches all vehicles registered under the current Sacco operator.
  Future<List<Map<String, dynamic>>> fetchMySaccoVehicles() async {
    final saccoId = _currentUserId;
    if (saccoId == null) {
      return [];
    }
    
    final role = await _getCurrentUserRole();
    if (role != UserRole.sacco) {
      return []; // Non-sacco users see no vehicles
    }

    try {
      final List<Map<String, dynamic>> vehicles = await _supabaseClient
          .from('vehicles')
          .select('*')
          .eq('sacco_id', saccoId)
          .order('plate_number', ascending: true);
          
      return vehicles;
    } on PostgrestException {
      throw Exception('Unable to load vehicles right now.');
    } catch (e) {
      throw Exception('Unable to load vehicles right now.');
    }
  }
  
  /// Toggles the availability status of a specific vehicle.
  Future<void> toggleVehicleAvailability({
    required String vehicleId,
    required bool isAvailable,
  }) async {
    final saccoId = _currentUserId;
    if (saccoId == null) {
      throw Exception('Authentication required. User not logged in.');
    }
    
    try {
      // Update the vehicle, ensuring it belongs to the current Sacco
      await _supabaseClient
          .from('vehicles')
          .update({'is_available': isAvailable})
          .eq('id', vehicleId)
          .eq('sacco_id', saccoId);

    } on PostgrestException {
      throw Exception('Unable to update vehicle availability right now.');
    } catch (e) {
      throw Exception('Unable to update vehicle availability right now.');
    }
  }
}
