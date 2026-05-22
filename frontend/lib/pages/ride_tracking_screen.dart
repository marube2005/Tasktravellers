// lib/pages/ride_tracking_screen.dart
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:frontend/services/engagement_service.dart';
import 'package:frontend/services/location_service.dart';
import 'package:frontend/services/user_service.dart';

class LiveTrackingScreen extends StatefulWidget {
  const LiveTrackingScreen({super.key, this.rideId});

  final String? rideId;

  @override
  State<LiveTrackingScreen> createState() => _LiveTrackingScreenState();
}

class _LiveTrackingScreenState extends State<LiveTrackingScreen> {
  late GoogleMapController _mapController;
  
  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};
  
  Position? _passengerLocation;
  Map<String, dynamic>? _vehicleLocation;
  
  final LocationService _locationService = LocationService();
  final EngagementService _engagementService = EngagementService();
  
  // Demo ride data - in production, fetch from Supabase
  static const String _vehicleId = 'vehicle_001';
  
  // Default Nairobi location for testing
  static const LatLng _defaultLocation = LatLng(-1.2921, 36.8219);

  @override
  void initState() {
    super.initState();
    _initializeTracking();
    _engagementService.syncQueuedActions();
  }

  Future<void> _initializeTracking() async {
    // Get passenger's current location
    _passengerLocation = await _locationService.getCurrentPosition();
    
    if (mounted) {
      setState(() {
        if (_passengerLocation != null) {
          _addPassengerMarker();
        }
      });
    }

    // Subscribe to vehicle real-time location updates
    _subscribeToVehicleLocation();
    
    // Start streaming passenger location (for driver to see)
    _locationService.startLocationStream(
      onLocationUpdate: (position) {
        if (mounted) {
          setState(() {
            _passengerLocation = position;
            _updatePassengerMarker();
            _updatePolylines();
          });
        }
      },
      distanceFilter: 5, // Update every 5 meters
    );
  }

  void _subscribeToVehicleLocation() {
    _locationService.subscribeToVehicleLocation(
      vehicleId: _vehicleId,
      onUpdate: (location) {
        if (mounted) {
          setState(() {
            _vehicleLocation = location;
            _updateVehicleMarker();
            _updatePolylines();
          });
        }
      },
    );
  }

  Future<void> _raiseEmergencyAlert() async {
    try {
      final profile = await UserService().fetchCurrentUserProfileModel();
      final locationLabel = _passengerLocation == null
          ? null
          : await _locationService.getAddressFromCoordinates(
              _passengerLocation!.latitude,
              _passengerLocation!.longitude,
            );

      final alertMessage = [
        'SOS alert from Travelers App',
        if (widget.rideId != null) 'Ride: ${widget.rideId}',
        if (locationLabel != null) 'Location: $locationLabel',
      ].join(' • ');

      await _engagementService.raiseEmergencyAlert(
        rideId: widget.rideId,
        message: alertMessage,
        emergencyContactName: profile?.emergencyContactName,
        emergencyContactPhone: profile?.emergencyContactPhone,
        latitude: _passengerLocation?.latitude,
        longitude: _passengerLocation?.longitude,
        locationLabel: locationLabel,
      );

      await Clipboard.setData(ClipboardData(text: alertMessage));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('SOS alert sent and copied to clipboard')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
        );
      }
    }
  }

  void _addPassengerMarker() {
    if (_passengerLocation == null) return;
    
    _markers.removeWhere((m) => m.markerId.value == 'passenger');
    _markers.add(
      Marker(
        markerId: const MarkerId('passenger'),
        position: LatLng(_passengerLocation!.latitude, _passengerLocation!.longitude),
        infoWindow: const InfoWindow(title: 'Your Location'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
      ),
    );
  }

  void _updatePassengerMarker() {
    _addPassengerMarker();
  }

  void _updateVehicleMarker() {
    if (_vehicleLocation == null) return;
    
    final lat = _vehicleLocation!['latitude'] as double?;
    final lng = _vehicleLocation!['longitude'] as double?;
    final heading = _vehicleLocation!['heading'] as double?;
    
    if (lat == null || lng == null) return;

    _markers.removeWhere((m) => m.markerId.value == 'vehicle');
    _markers.add(
      Marker(
        markerId: const MarkerId('vehicle'),
        position: LatLng(lat, lng),
        infoWindow: const InfoWindow(
          title: 'Vehicle Location',
          snippet: 'Your matatu is on the way',
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        rotation: heading ?? 0,
      ),
    );
  }

  void _updatePolylines() {
    if (_passengerLocation == null || _vehicleLocation == null) return;

    final vehicleLat = _vehicleLocation!['latitude'] as double?;
    final vehicleLng = _vehicleLocation!['longitude'] as double?;
    
    if (vehicleLat == null || vehicleLng == null) return;

    _polylines.clear();
    _polylines.add(
      Polyline(
        polylineId: const PolylineId('route'),
        points: [
          LatLng(_passengerLocation!.latitude, _passengerLocation!.longitude),
          LatLng(vehicleLat, vehicleLng),
        ],
        color: Colors.blue,
        width: 3,
      ),
    );
  }

  @override
  void dispose() {
    if (!kIsWeb) {
      _mapController.dispose();
    }
    _locationService.stopLocationStream();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final initialLocation = _vehicleLocation != null
        ? LatLng(
            _vehicleLocation!['latitude'] as double,
            _vehicleLocation!['longitude'] as double,
          )
        : (_passengerLocation != null
            ? LatLng(_passengerLocation!.latitude, _passengerLocation!.longitude)
            : _defaultLocation);

    return Scaffold(
      body: Stack(
        children: [
          // --- 1. Google Map (Mobile only) ---
          if (!kIsWeb)
            GoogleMap(
              onMapCreated: (controller) {
                _mapController = controller;
              },
              initialCameraPosition: CameraPosition(
                target: initialLocation,
                zoom: 15.0,
              ),
              markers: _markers,
              polylines: _polylines,
              myLocationEnabled: true,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
            )
          else
            // Web Fallback: Simple map placeholder
            Container(
              color: Colors.grey.shade300,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.location_on, size: 64, color: Colors.red),
                    const SizedBox(height: 16),
                    Text(
                      'Live Tracking',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Maps not yet available on web',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ),

          // --- 2. Map Control Buttons (Mobile only) ---
          if (!kIsWeb)
            const _MapControlButtons(),
          Positioned(
            left: 16,
            right: 16,
            bottom: 24,
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _raiseEmergencyAlert,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                      icon: const Icon(Icons.sos),
                      label: const Text('SOS'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// --- Reusable Component Widgets ---

class _MapControlButtons extends StatefulWidget {
  const _MapControlButtons();
  
  @override
  State<_MapControlButtons> createState() => _MapControlButtonsState();
}

class _MapControlButtonsState extends State<_MapControlButtons> {
  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 60,
      right: 16,
      child: Column(
        children: [
          _MapButton(
            icon: Icons.add,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            onPressed: () async {
              final state = context.findAncestorStateOfType<_LiveTrackingScreenState>();
              if (state != null) {
                state._mapController.animateCamera(
                  CameraUpdate.zoomIn(),
                );
              }
            },
          ),
          const SizedBox(height: 2),
          _MapButton(
            icon: Icons.remove,
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
            onPressed: () async {
              final state = context.findAncestorStateOfType<_LiveTrackingScreenState>();
              if (state != null) {
                state._mapController.animateCamera(
                  CameraUpdate.zoomOut(),
                );
              }
            },
          ),
          const SizedBox(height: 16),
          _MapButton(
            icon: Icons.my_location,
            borderRadius: BorderRadius.circular(12),
            onPressed: () async {
              final state = context.findAncestorStateOfType<_LiveTrackingScreenState>();
              if (state != null && state._passengerLocation != null) {
                state._mapController.animateCamera(
                  CameraUpdate.newLatLng(
                    LatLng(state._passengerLocation!.latitude, state._passengerLocation!.longitude),
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }
}

class _MapButton extends StatelessWidget {
  final IconData icon;
  final BorderRadius borderRadius;
  final VoidCallback? onPressed;
  
  const _MapButton({
    required this.icon,
    required this.borderRadius,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: borderRadius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
        child: Material(
          color: Colors.black.withValues(alpha: 0.5),
          child: InkWell(
            onTap: onPressed,
            child: Container(
              width: 52,
              height: 52,
              alignment: Alignment.center,
              child: Icon(icon, color: Colors.white, size: 28),
            ),
          ),
        ),
      ),
    );
  }
}
