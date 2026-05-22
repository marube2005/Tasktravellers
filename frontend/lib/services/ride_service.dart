import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

/// Maps directly to the 'ride_status' ENUM in the Supabase database.
enum RideStatus {
  open,
  accepted,
  inProgress,
  completed,
  cancelled,
}

// Extension to convert the enum to a database string
extension RideStatusExtension on RideStatus {
  String toShortString() {
    return toString().split('.').last.replaceAllMapped(
      RegExp(r'([A-Z])'),
      (match) => '_${match.group(0)!.toLowerCase()}',
    );
  }
}

/// A service class to handle all ride creation, discovery, and management logic.
class RideService {
  final SupabaseClient _supabaseClient = Supabase.instance.client;

  /// Private constructor for Singleton pattern.
  RideService._internal();
  static final RideService _instance = RideService._internal();

  /// Factory constructor to return the single instance of RideService.
  factory RideService() => _instance;

  // Helper to get the current authenticated user's ID
  String? get _currentUserId => _supabaseClient.auth.currentUser?.id;
  
  // Helper to generate a universal HTTPS invite link that works across all
  // platforms (Android, iOS, and web). Configure universal-link / app-link
  // handling in your server or Firebase Dynamic Links to deep-link into the app.
  String _generateInviteLink() {
    final token = const Uuid().v4().substring(0, 8);
    return 'https://travelersapp.co.ke/join/$token';
  }

  String _generateAcceptanceCode() {
    final token = const Uuid().v4().replaceAll('-', '').toUpperCase();
    return token.substring(0, 6);
  }

  /// =========================================================================
  /// 1. PASSENGER ACTIONS: RIDE CREATION (GROUP POOL)
  /// =========================================================================

  /// Creates a new ride request, setting its status to 'open'.
  /// This serves as the start of the "Group Ride Pool".
  Future<Map<String, dynamic>> createRidePool({
    required String origin,
    required String destination,
    required int groupSize,
    double? estimatedFare,
    String? groupNote,
  }) async {
    final passengerId = _currentUserId;
    if (passengerId == null) {
      throw Exception('Authentication required. User not logged in.');
    }

    try {
      final inviteLink = _generateInviteLink();
      final acceptanceCode = _generateAcceptanceCode();
      final acceptanceCodeExpiresAt = DateTime.now()
          .add(const Duration(minutes: 15))
          .toUtc()
          .toIso8601String();
      
      // 1. Insert the new ride request into the 'rides' table
      final Map<String, dynamic> ride = await _supabaseClient
          .from('rides')
          .insert({
            'origin': origin,
            'destination': destination,
            'group_size': groupSize,
            'estimated_fare': estimatedFare,
            'invite_link': inviteLink,
            'acceptance_code': acceptanceCode,
            'acceptance_code_expires_at': acceptanceCodeExpiresAt,
            'group_note': groupNote,
            'status': RideStatus.open.toShortString(),
            'creator_id': passengerId,
          })
          .select()
          .single();

      final String rideId = ride['id'] as String;

      // 2. Automatically book the ride creator (passenger) onto the ride
      await _supabaseClient.from('bookings').insert({
        'ride_id': rideId,
        // For the passenger-created ride, the initial 'passenger_id' is the creator's ID
        'passenger_id': passengerId, 
      });

      return ride;
    } on PostgrestException catch (e) {
      throw Exception('Database Error creating ride: ${e.message}');
    } catch (e) {
      throw Exception('An unexpected error occurred while creating the ride: $e');
    }
  }

  /// =========================================================================
  /// 2. SACCO ACTIONS: RIDE MANAGEMENT
  /// =========================================================================

  /// Fetches a list of all currently open ride requests for Sacco operators to view.
  Future<List<Map<String, dynamic>>> fetchOpenRideRequests() async {
    try {
      // Fetch open rides, ordered by creation time
  final List<dynamic> rides = await _supabaseClient
          .from('rides')
          .select('*')
          .eq('status', RideStatus.open.toShortString())
          .order('created_at', ascending: true);

  return rides.cast<Map<String, dynamic>>();
    } on PostgrestException catch (e) {
      throw Exception('Database Error fetching open rides: ${e.message}');
    } catch (e) {
      throw Exception('An unexpected error occurred while fetching open rides: $e');
    }
  }

  /// Allows a Sacco to accept an open ride request.
  /// This links the ride to the Sacco and one of their vehicles.
  ///
  /// Throws [RideAlreadyAcceptedException] if another Sacco accepted first.
  Future<void> acceptRide({
    required String rideId,
    required String vehicleId,
    required String saccoId,
    required double confirmedFare,
  }) async {
    try {
      // Conditional update: only succeeds if the ride is still 'open'.
      // Selecting back the row lets us detect whether the update actually matched.
      final List<dynamic> updated = await _supabaseClient
          .from('rides')
          .update({
            'status': RideStatus.accepted.toShortString(),
            'provider_id': saccoId,
            'vehicle_id': vehicleId,
            'estimated_fare': confirmedFare,
          })
          .eq('id', rideId)
          .eq('status', RideStatus.open.toShortString())
          .select('id');

      if (updated.isEmpty) {
        throw Exception(
          'This ride is no longer available. Another sacco may have accepted it first.',
        );
      }
    } on PostgrestException catch (e) {
      throw Exception('Database Error accepting ride: ${e.message}');
    } catch (e) {
      rethrow;
    }
  }
  
  /// Allows a Sacco to update the ride status to 'in_progress', 'completed', or 'cancelled'.
  Future<void> updateRideStatus({
    required String rideId,
    required RideStatus newStatus,
  }) async {
    // You should add checks here (e.g., only sacco or admin can update status)
    // This is typically handled by RLS policies on the 'rides' table.
    
    try {
      await _supabaseClient
          .from('rides')
          .update({'status': newStatus.toShortString()})
          .eq('id', rideId);
          
    } on PostgrestException catch (e) {
      throw Exception('Database Error updating ride status: ${e.message}');
    } catch (e) {
      throw Exception('An unexpected error occurred while updating status: $e');
    }
  }

  /// OTP-style acceptance flow: verify the shared code before accepting the ride.
  Future<void> acceptRideWithCode({
    required String rideId,
    required String acceptanceCode,
    required String vehicleId,
    required String saccoId,
    required double confirmedFare,
  }) async {
    final ride = await _supabaseClient
        .from('rides')
        .select('acceptance_code, acceptance_code_expires_at')
        .eq('id', rideId)
        .single();

    final storedCode = (ride['acceptance_code'] as String?)?.trim().toUpperCase();
    final storedExpiryRaw = ride['acceptance_code_expires_at'];
    final storedExpiry = storedExpiryRaw == null
        ? null
        : DateTime.tryParse(storedExpiryRaw.toString())?.toUtc();
    final now = DateTime.now().toUtc();

    if (storedCode == null || storedCode.isEmpty) {
      throw Exception('No acceptance code is configured for this ride.');
    }
    if (storedExpiry != null && now.isAfter(storedExpiry)) {
      throw Exception('The ride acceptance code has expired.');
    }
    if (storedCode != acceptanceCode.trim().toUpperCase()) {
      throw Exception('Invalid ride acceptance code.');
    }

    await acceptRide(
      rideId: rideId,
      vehicleId: vehicleId,
      saccoId: saccoId,
      confirmedFare: confirmedFare,
    );
  }

  Future<Map<String, dynamic>?> fetchRideById(String rideId) async {
    try {
      return await _supabaseClient.from('rides').select('*').eq('id', rideId).maybeSingle();
    } on PostgrestException catch (e) {
      throw Exception('Database Error fetching ride: ${e.message}');
    } catch (e) {
      throw Exception('An unexpected error occurred while fetching the ride: $e');
    }
  }

  /// =========================================================================
  /// 3. DISCOVERY AND REALTIME
  /// =========================================================================

  /// Real-time stream for a single ride's details.
  /// Useful for passengers to track status changes (open -> accepted -> in_progress).
  Stream<Map<String, dynamic>> singleRideStream({required String rideId}) {
    // Select the ride and join vehicle details for driver tracking
    return _supabaseClient
        .from('rides')
        .stream(primaryKey: ['id'])
        .eq('id', rideId)
        .limit(1)
        .map((data) => data.first); // Stream of a single ride map
  }

  /// Fetches a list of vehicles managed by a specific Sacco.
  /// (This could also live in a dedicated VehicleService, but included here for context)
  Future<List<Map<String, dynamic>>> fetchSaccoVehicles({required String saccoId}) async {
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

  /// Fetches all rides provided by a specific Sacco (used for earnings/history view).
  Future<List<Map<String, dynamic>>> fetchSaccoRides({required String saccoId}) async {
    try {
  final List<dynamic> rides = await _supabaseClient
          .from('rides')
          .select('*, vehicles(plate_number)') // Join vehicle details
          .eq('provider_id', saccoId)
          .order('created_at', ascending: false);
          
  return rides.cast<Map<String, dynamic>>();
    } on PostgrestException catch (e) {
      throw Exception('Database Error fetching Sacco rides: ${e.message}');
    } catch (e) {
      throw Exception('An unexpected error occurred while fetching Sacco rides: $e');
    }
  }
}
