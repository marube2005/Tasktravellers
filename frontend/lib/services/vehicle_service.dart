import 'package:supabase_flutter/supabase_flutter.dart';

/// A service class dedicated to managing vehicle records and availability for Saccos.
class VehicleService {
  final SupabaseClient _supabaseClient = Supabase.instance.client;

  /// Private constructor for Singleton pattern.
  VehicleService._internal();
  static final VehicleService _instance = VehicleService._internal();

  /// Factory constructor to return the single instance of VehicleService.
  factory VehicleService() => _instance;

  // Helper to get the current authenticated user's ID
  String? get _currentUserId => _supabaseClient.auth.currentUser?.id;

// =========================================================================
// 1. SACCO VEHICLE MANAGEMENT (CRUD)
// =========================================================================

  /// Adds a new vehicle to the Sacco's fleet.
  /// RLS must ensure only a Sacco can insert records where sacco_id = auth.uid().
  Future<void> addVehicle({
    required String plateNumber,
    required int capacity,
    required String route,
  }) async {
    final saccoId = _currentUserId;
    if (saccoId == null) {
      throw Exception('Authentication required. Sacco not logged in.');
    }

    try {
      await _supabaseClient.from('vehicles').insert({
        'sacco_id': saccoId,
        'plate_number': plateNumber,
        'capacity': capacity,
        'route': route,
        'is_available': true, // Default to available upon creation
      });
    } on PostgrestException catch (e) {
      if (e.code == '23505') {
        throw Exception('A vehicle with this plate number already exists.');
      }
      throw Exception('Database Error adding vehicle: ${e.message}');
    } catch (e) {
      throw Exception('An unexpected error occurred while adding the vehicle: $e');
    }
  }

  /// Fetches all vehicles registered under the current Sacco operator.
  Future<List<Map<String, dynamic>>> fetchMySaccoVehicles() async {
    final saccoId = _currentUserId;
    if (saccoId == null) {
      return [];
    }
    
    try {
      final List<dynamic> vehicles = await _supabaseClient
          .from('vehicles')
          .select('*')
          .eq('sacco_id', saccoId)
          .order('plate_number', ascending: true);
          
      return vehicles.cast<Map<String, dynamic>>();
    } on PostgrestException catch (e) {
      throw Exception('Database Error fetching vehicles: ${e.message}');
    } catch (e) {
      throw Exception('An unexpected error occurred while fetching vehicles: $e');
    }
  }

  /// Updates the details of a specific vehicle.
  Future<void> updateVehicle({
    required String vehicleId,
    String? plateNumber,
    int? capacity,
    String? route,
  }) async {
    final saccoId = _currentUserId;
    if (saccoId == null) {
      throw Exception('Authentication required. Sacco not logged in.');
    }
    
    final updates = <String, dynamic>{};
    if (plateNumber != null) updates['plate_number'] = plateNumber;
    if (capacity != null) updates['capacity'] = capacity;
    if (route != null) updates['route'] = route;

    if (updates.isEmpty) return;
    
    try {
      // Ensure the Sacco can only update their own vehicle
      await _supabaseClient
          .from('vehicles')
          .update(updates)
          .eq('id', vehicleId)
          .eq('sacco_id', saccoId);

    } on PostgrestException catch (e) {
      if (e.code == '23505') {
        throw Exception('This plate number is already in use.');
      }
      throw Exception('Database Error updating vehicle: ${e.message}');
    } catch (e) {
      throw Exception('An unexpected error occurred while updating vehicle: $e');
    }
  }

  /// Toggles the availability status of a specific vehicle.
  Future<void> toggleVehicleAvailability({
    required String vehicleId,
    required bool isAvailable,
  }) async {
    final saccoId = _currentUserId;
    if (saccoId == null) {
      throw Exception('Authentication required. Sacco not logged in.');
    }
    
    try {
      await _supabaseClient
          .from('vehicles')
          .update({'is_available': isAvailable})
          .eq('id', vehicleId)
          .eq('sacco_id', saccoId); // RLS redundancy check

    } on PostgrestException catch (e) {
      throw Exception('Database Error updating vehicle availability: ${e.message}');
    } catch (e) {
      throw Exception('An unexpected error occurred while updating availability: $e');
    }
  }
  
// =========================================================================
// 2. PASSENGER/RIDE DISCOVERY
// =========================================================================

  /// Fetches a list of available vehicles based on route or destination.
  /// This is used for the "Matatu Discovery" feature.
  Future<List<Map<String, dynamic>>> fetchAvailableVehicles({
    String? route,
    int? minCapacity,
  }) async {
    try {
  var builder = _supabaseClient
          .from('vehicles')
          .select('*, sacco:sacco_id(name, is_verified)') // Join Sacco profile details
          .eq('is_available', true); // Only fetch available vehicles

      if (route != null && route.isNotEmpty) {
        // You might use 'ilike' for partial route matching in a real scenario
        builder = builder.ilike('route', '%$route%');
      }

      if (minCapacity != null) {
        builder = builder.gte('capacity', minCapacity);
      }

  final List<dynamic> vehicles = await builder.order('capacity', ascending: false);
          
  return vehicles.cast<Map<String, dynamic>>();
    } on PostgrestException catch (e) {
      throw Exception('Database Error fetching available vehicles: ${e.message}');
    } catch (e) {
      throw Exception('An unexpected error occurred during vehicle discovery: $e');
    }
  }
}