import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../repositories/group_repository.dart';

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
      // 1. Check if the ride exists in 'group_rides' first
      final Map<String, dynamic>? groupRide = await _supabaseClient
          .from('group_rides')
          .select('creator_id, status, max_passengers, current_passengers')
          .eq('id', rideId)
          .maybeSingle();

      if (groupRide != null) {
        final String? creatorId = groupRide['creator_id'] as String?;
        if (creatorId == userId) {
          throw Exception('You are already the creator of this group ride.');
        }

        final String status = groupRide['status'] as String? ?? 'forming';
        if (status == 'completed' || status == 'cancelled') {
          throw Exception('Group ride is no longer active.');
        }

        final int maxPassengers = (groupRide['max_passengers'] as int?) ?? 4;
        final int currentCount = (groupRide['current_passengers'] as int?) ?? 1;

        if (currentCount >= maxPassengers) {
          throw Exception('Group ride is full (max $maxPassengers passengers reached).');
        }

        // Check if user has already joined group_members
        final Map<String, dynamic>? existingMember = await _supabaseClient
            .from('group_members')
            .select('id')
            .eq('group_id', rideId)
            .eq('user_id', userId)
            .maybeSingle();

        if (existingMember != null) {
          throw Exception('You have already joined this group ride.');
        }

        // Insert into group_members
        try {
          await _supabaseClient.from('group_members').insert({
            'group_id': rideId,
            'user_id': userId,
            'joined_via': 'invite_link',
            'confirmed': true,
            'joined_at': DateTime.now().toIso8601String(),
          });
        } on PostgrestException catch (e) {
          if (e.code == '23505') {
            throw Exception('You have already joined this group ride.');
          }
          // Do NOT fall back to 'bookings' table because bookings.ride_id has a foreign key to 'rides' table (not group_rides)
          throw Exception('Could not join group ride: ${e.message}');
        }

        // Update current passenger count on group_rides
        final int newCount = currentCount + 1;
        final int minPassengers = (groupRide['min_passengers'] as int?) ?? 3;
        final bool isReady = newCount >= minPassengers && status == 'forming';

        await _supabaseClient
            .from('group_rides')
            .update({
              'current_passengers': newCount,
              if (isReady) 'status': 'ready',
            })
            .eq('id', rideId);

        if (isReady) {
          try {
            await GroupRepository().notifyDrivers(rideId);
          } catch (e) {
            debugPrint('Note: Driver notification triggered on auto-dispatch: $e');
          }
        }

        return;
      }

      // 2. Fallback check for standard 'rides' table
      final Map<String, dynamic>? ride = await _supabaseClient
          .from('rides')
          .select('status, group_size')
          .eq('id', rideId)
          .maybeSingle();

      if (ride == null) {
        throw Exception('Ride not found.');
      }

      if (ride['status'] != 'open') {
        throw Exception('Ride is not open for new bookings.');
      }

      final int groupSize = (ride['group_size'] as int?) ?? 0;
      final int currentCount = await getRidePassengerCount(rideId: rideId);
      if (groupSize > 0 && currentCount >= groupSize) {
        throw Exception('Ride is full. Maximum capacity of $groupSize passengers reached.');
      }

      // Insert booking record
      await _supabaseClient.from('bookings').insert({
        'ride_id': rideId,
        'passenger_id': userId,
      });

    } on PostgrestException catch (e) {
      if (e.code == '23505') {
        throw Exception('You have already joined this ride.');
      }
      throw Exception('Database Error during booking: ${e.message}');
    } catch (e) {
      throw Exception(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  /// Allows a passenger to leave a ride before it is accepted/in_progress.
  Future<void> leaveRide({required String rideId}) async {
    final userId = _currentUserId;
    if (userId == null) {
      throw Exception('Authentication required. User not logged in.');
    }

    try {
      await _supabaseClient
          .from('group_members')
          .delete()
          .eq('group_id', rideId)
          .eq('user_id', userId);

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
      final List<dynamic> bookings = await _supabaseClient
          .from('bookings')
          .select('*, rides(*)')
          .eq('passenger_id', userId);

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
      final List<dynamic> groupMembers = await _supabaseClient
          .from('group_members')
          .select('id')
          .eq('group_id', rideId);

      if (groupMembers.isNotEmpty) {
        return groupMembers.length;
      }

      final List<dynamic> rows = await _supabaseClient
          .from('bookings')
          .select('id')
          .eq('ride_id', rideId);

      return rows.length;
      
    } catch (_) {
      return 1;
    }
  }

  /// =========================================================================
  /// 3. REALTIME/GROUP POOL METHODS
  /// =========================================================================

  /// Listens to real-time changes in the number of passengers for a specific ride.
  Stream<List<Map<String, dynamic>>> rideBookingsStream({required String rideId}) {
    return _supabaseClient
        .from('bookings')
        .stream(primaryKey: ['id'])
        .eq('ride_id', rideId)
        .order('joined_at', ascending: true);
  }

  /// Listens to real-time changes in group_rides record (status, current_passengers).
  Stream<Map<String, dynamic>?> groupRideStream({required String rideId}) {
    return _supabaseClient
        .from('group_rides')
        .stream(primaryKey: ['id'])
        .eq('id', rideId)
        .map((list) => list.isNotEmpty ? list.first : null);
  }
}
