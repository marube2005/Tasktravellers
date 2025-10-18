import 'package:supabase_flutter/supabase_flutter.dart';

/// A service class to handle ride booking and group management logic.
class BookingService {
  final SupabaseClient _supabaseClient = Supabase.instance.client;

  /// Private constructor for Singleton pattern.
  BookingService._internal();
  static final BookingService _instance = BookingService._internal();

  /// Factory constructor to return the single instance of BookingService.
  factory BookingService() => _instance;

  // Helper to get the current authenticated user's ID
  String? get _currentUserId => _supabaseClient.auth.currentUser?.id;

  /// =========================================================================
  /// 1. PASSENGER ACTIONS
  /// =========================================================================

  /// Allows a passenger to join an open ride (a 'Group Ride Pool').
  ///
  /// This creates a new record in the 'bookings' junction table.
  /// It enforces the UNIQUE constraint (ride_id, passenger_id) from the schema.
  Future<void> joinRide({required String rideId}) async {
    final userId = _currentUserId;
    if (userId == null) {
      throw Exception('Authentication required. User not logged in.');
    }

    try {
      // 1. Check if the ride is still 'open' (optional but good practice)
      final Map<String, dynamic> ride = await _supabaseClient
          .from('rides')
          .select('status')
          .eq('id', rideId)
          .single();

      if (ride['status'] != 'open') {
        throw Exception('Ride is not open for new bookings.');
      }

      // 2. Insert the booking record
      await _supabaseClient.from('bookings').insert({
        'ride_id': rideId,
        'passenger_id': userId,
      });

    } on PostgrestException catch (e) {
      // Handle the unique constraint violation specifically
      // Supabase returns 23505 for unique violation
      if (e.code == '23505') {
        throw Exception('You have already joined this ride.');
      }
      throw Exception('Database Error during booking: ${e.message}');
    } catch (e) {
      throw Exception('An unexpected error occurred while joining the ride: $e');
    }
  }

  /// Allows a passenger to leave a ride before it is accepted/in_progress.
  ///
  /// This deletes the record from the 'bookings' junction table.
  Future<void> leaveRide({required String rideId}) async {
    final userId = _currentUserId;
    if (userId == null) {
      throw Exception('Authentication required. User not logged in.');
    }

    try {
      // Delete the booking record for the specific ride and user
      await _supabaseClient
          .from('bookings')
          .delete()
          .eq('ride_id', rideId)
          .eq('passenger_id', userId);

    } on PostgrestException catch (e) {
      throw Exception('Database Error during leaving ride: ${e.message}');
    } catch (e) {
      throw Exception('An unexpected error occurred while leaving the ride: $e');
    }
  }

  /// =========================================================================
  /// 2. QUERY METHODS
  /// =========================================================================

  /// Fetches all rides the current user is currently booked on.
  Future<List<Map<String, dynamic>>> fetchMyBookedRides() async {
    final userId = _currentUserId;
    if (userId == null) {
      return [];
    }

    try {
      // Fetch bookings, and INNER JOIN/select the ride details
    final List<dynamic> bookings = await _supabaseClient
          .from('bookings')
          .select('*, rides(*)') // Select all booking fields and join the related ride details
          .eq('passenger_id', userId);

      // The structure will be: [{..., "rides": {ride details}}, ...]
      // You may need to further map this to a specific model in your presentation layer.
    return bookings.cast<Map<String, dynamic>>();

    } on PostgrestException catch (e) {
      throw Exception('Database Error fetching booked rides: ${e.message}');
    } catch (e) {
      throw Exception('An unexpected error occurred while fetching bookings: $e');
    }
  }
  
  /// Counts the number of passengers currently booked on a specific ride.
  Future<int> getRidePassengerCount({required String rideId}) async {
    try {
    // Simple count by selecting IDs and returning the list length
    final List<dynamic> rows = await _supabaseClient
      .from('bookings')
      .select('id')
      .eq('ride_id', rideId);

    return rows.length;
      
    } on PostgrestException catch (e) {
      throw Exception('Database Error counting passengers: ${e.message}');
    } catch (e) {
      throw Exception('An unexpected error occurred while counting passengers: $e');
    }
  }

  /// =========================================================================
  /// 3. REALTIME/GROUP POOL METHODS
  /// =========================================================================

  /// Listens to real-time changes in the number of passengers for a specific ride.
  /// This is essential for the "Create Group Ride Pool" feature.
  Stream<List<Map<String, dynamic>>> rideBookingsStream({required String rideId}) {
    // You subscribe to the 'bookings' table filtered by the specific ride_id.
    // This stream will emit whenever a passenger joins or leaves.
    return _supabaseClient
        .from('bookings')
        .stream(primaryKey: ['id'])
        .eq('ride_id', rideId)
        .order('joined_at', ascending: true);
  }
}
