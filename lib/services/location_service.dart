import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Structured result containing user GPS position and reverse-geocoded address.
class UserLocationResult {
  final double latitude;
  final double longitude;
  final String address;

  UserLocationResult({
    required this.latitude,
    required this.longitude,
    required this.address,
  });
}

/// A service class to handle location tracking, permissions, and real-time updates.
/// Used for vehicle tracking, passenger pickup, and ride progress.
class LocationService {
  final SupabaseClient _supabaseClient = Supabase.instance.client;
  
  StreamSubscription<Position>? _positionSubscription;
  Position? _currentPosition;
  
  /// Private constructor for Singleton pattern.
  LocationService._internal();
  static final LocationService _instance = LocationService._internal();

  /// Factory constructor to return the single instance of LocationService.
  factory LocationService() => _instance;

  /// Get the last known position.
  Position? get currentPosition => _currentPosition;

  // =========================================================================
  // 1. PERMISSION HANDLING
  // =========================================================================

  /// Check if location services are enabled and permissions granted.
  /// Returns true if ready to use location, false otherwise.
  Future<bool> checkLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Check if location services are enabled
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return false;
    }

    // Check permission status
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // Permissions are permanently denied
      return false;
    }

    return true;
  }

  /// Request location permission from the user.
  Future<LocationPermission> requestPermission() async {
    return await Geolocator.requestPermission();
  }

  /// Open device location settings (for when permission is denied forever).
  Future<bool> openLocationSettings() async {
    return await Geolocator.openLocationSettings();
  }

  /// Open app settings (for when permission is denied forever).
  Future<bool> openAppSettings() async {
    return await Geolocator.openAppSettings();
  }

  // =========================================================================
  // 2. LOCATION RETRIEVAL
  // =========================================================================

  /// Get the current position once.
  /// Returns null if permission denied or location unavailable.
  Future<Position?> getCurrentPosition({
    LocationAccuracy accuracy = LocationAccuracy.high,
  }) async {
    final hasPermission = await checkLocationPermission();
    if (!hasPermission) return null;

    try {
      _currentPosition = await Geolocator.getCurrentPosition(
        locationSettings: LocationSettings(
          accuracy: accuracy,
          distanceFilter: 10, // Minimum distance (meters) before update
        ),
      );
      return _currentPosition;
    } catch (e) {
      return null;
    }
  }

  /// Get the last known position (faster, but may be stale).
  Future<Position?> getLastKnownPosition() async {
    try {
      return await Geolocator.getLastKnownPosition();
    } catch (e) {
      return null;
    }
  }

  /// Helper to get current location with formatted address details.
  Future<UserLocationResult?> fetchCurrentLocationDetails() async {
    final pos = await getCurrentPosition();
    if (pos == null) return null;

    final address = await getAddressFromCoordinates(pos.latitude, pos.longitude);
    return UserLocationResult(
      latitude: pos.latitude,
      longitude: pos.longitude,
      address: address ?? '${pos.latitude.toStringAsFixed(4)}, ${pos.longitude.toStringAsFixed(4)}',
    );
  }

  /// Convert coordinates to a human-readable address.
  Future<String?> getAddressFromCoordinates(double lat, double lng) async {
    try {
      final placemarks = await placemarkFromCoordinates(lat, lng);
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        final parts = <String>[];
        if (place.street != null && place.street!.isNotEmpty) {
          parts.add(place.street!);
        }
        if (place.subLocality != null && place.subLocality!.isNotEmpty) {
          parts.add(place.subLocality!);
        }
        if (place.locality != null && place.locality!.isNotEmpty) {
          parts.add(place.locality!);
        }
        return parts.isNotEmpty ? parts.join(', ') : null;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Convert an address string to coordinates.
  Future<Location?> getCoordinatesFromAddress(String address) async {
    try {
      final locations = await locationFromAddress(address);
      return locations.isNotEmpty ? locations.first : null;
    } catch (e) {
      return null;
    }
  }

  /// Search for street/road/location suggestions as the user types.
  Future<List<UserLocationResult>> searchAddressSuggestions(String query) async {
    final cleanQuery = query.trim();
    if (cleanQuery.length < 2) return [];

    try {
      final locations = await locationFromAddress(cleanQuery);
      final results = <UserLocationResult>[];
      final seenAddresses = <String>{};

      for (final loc in locations.take(6)) {
        final address = await getAddressFromCoordinates(loc.latitude, loc.longitude);
        if (address != null && address.isNotEmpty && !seenAddresses.contains(address)) {
          seenAddresses.add(address);
          results.add(UserLocationResult(
            latitude: loc.latitude,
            longitude: loc.longitude,
            address: address,
          ));
        }
      }

      if (results.isEmpty && locations.isNotEmpty) {
        final firstLoc = locations.first;
        results.add(UserLocationResult(
          latitude: firstLoc.latitude,
          longitude: firstLoc.longitude,
          address: cleanQuery,
        ));
      }

      return results;
    } catch (e) {
      return [];
    }
  }

  // =========================================================================
  // 3. REAL-TIME TRACKING
  // =========================================================================

  /// Start streaming location updates.
  /// [onLocationUpdate] is called each time location changes.
  /// [distanceFilter] is minimum movement in meters to trigger update.
  void startLocationStream({
    required Function(Position) onLocationUpdate,
    int distanceFilter = 10,
    LocationAccuracy accuracy = LocationAccuracy.high,
  }) {
    _positionSubscription?.cancel();
    
    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: LocationSettings(
        accuracy: accuracy,
        distanceFilter: distanceFilter,
      ),
    ).listen((Position position) {
      _currentPosition = position;
      onLocationUpdate(position);
    });
  }

  /// Stop streaming location updates.
  void stopLocationStream() {
    _positionSubscription?.cancel();
    _positionSubscription = null;
  }

  /// Check if currently streaming location.
  bool get isStreaming => _positionSubscription != null;

  // =========================================================================
  // 4. DATABASE INTEGRATION (Real-time vehicle/ride tracking)
  // =========================================================================

  /// Update the current vehicle's location in the database.
  /// Used by Sacco operators/drivers to broadcast their position.
  Future<void> updateVehicleLocation({
    required String vehicleId,
    required double latitude,
    required double longitude,
    double? heading,
    double? speed,
  }) async {
    try {
      await _supabaseClient.from('vehicle_locations').upsert({
        'vehicle_id': vehicleId,
        'latitude': latitude,
        'longitude': longitude,
        'heading': heading,
        'speed': speed,
        'updated_at': DateTime.now().toIso8601String(),
      }, onConflict: 'vehicle_id');
    } catch (e) {
      throw Exception('Failed to update vehicle location: $e');
    }
  }

  /// Get the current location of a specific vehicle.
  Future<Map<String, dynamic>?> getVehicleLocation(String vehicleId) async {
    try {
      final result = await _supabaseClient
          .from('vehicle_locations')
          .select()
          .eq('vehicle_id', vehicleId)
          .maybeSingle();
      return result;
    } catch (e) {
      return null;
    }
  }

  /// Subscribe to real-time location updates for a vehicle.
  /// Returns a RealtimeChannel that can be unsubscribed later.
  RealtimeChannel subscribeToVehicleLocation({
    required String vehicleId,
    required Function(Map<String, dynamic>) onUpdate,
  }) {
    return _supabaseClient
        .channel('vehicle_location_$vehicleId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'vehicle_locations',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'vehicle_id',
            value: vehicleId,
          ),
          callback: (payload) {
            if (payload.newRecord.isNotEmpty) {
              onUpdate(payload.newRecord);
            }
          },
        )
        .subscribe();
  }

  /// Update the ride's current location (for live tracking).
  Future<void> updateRideLocation({
    required String rideId,
    required double latitude,
    required double longitude,
  }) async {
    try {
      await _supabaseClient.from('rides').update({
        'current_lat': latitude,
        'current_lng': longitude,
        'location_updated_at': DateTime.now().toIso8601String(),
      }).eq('id', rideId);
    } catch (e) {
      throw Exception('Failed to update ride location: $e');
    }
  }

  // =========================================================================
  // 5. DISTANCE & CALCULATIONS
  // =========================================================================

  /// Calculate distance between two points in meters.
  double calculateDistance({
    required double startLat,
    required double startLng,
    required double endLat,
    required double endLng,
  }) {
    return Geolocator.distanceBetween(startLat, startLng, endLat, endLng);
  }

  /// Calculate distance in kilometers (formatted string).
  String formatDistance(double meters) {
    if (meters < 1000) {
      return '${meters.round()} m';
    } else {
      return '${(meters / 1000).toStringAsFixed(1)} km';
    }
  }

  /// Calculate bearing between two points (direction in degrees).
  double calculateBearing({
    required double startLat,
    required double startLng,
    required double endLat,
    required double endLng,
  }) {
    return Geolocator.bearingBetween(startLat, startLng, endLat, endLng);
  }

  /// Estimate travel time based on distance and average speed.
  /// [averageSpeedKmh] defaults to 30 km/h for urban traffic.
  Duration estimateTravelTime(double distanceMeters, {double averageSpeedKmh = 30}) {
    final hours = (distanceMeters / 1000) / averageSpeedKmh;
    return Duration(minutes: (hours * 60).round());
  }

  /// Format duration to human-readable string.
  String formatDuration(Duration duration) {
    if (duration.inMinutes < 60) {
      return '${duration.inMinutes} min';
    } else {
      final hours = duration.inHours;
      final minutes = duration.inMinutes % 60;
      return minutes > 0 ? '$hours hr $minutes min' : '$hours hr';
    }
  }

  // =========================================================================
  // 6. CLEANUP
  // =========================================================================

  /// Dispose of all resources.
  void dispose() {
    stopLocationStream();
  }
}
