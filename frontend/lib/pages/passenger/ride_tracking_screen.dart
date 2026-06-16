// lib/pages/passenger/ride_tracking_screen.dart
import 'dart:async';
import 'dart:math';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:frontend/services/engagement_service.dart';
import 'package:frontend/services/location_service.dart';
import 'package:frontend/services/user_service.dart';
import 'package:frontend/themes/app_colors.dart';

class LiveTrackingScreen extends StatefulWidget {
  const LiveTrackingScreen({super.key, this.rideId});

  final String? rideId;

  @override
  State<LiveTrackingScreen> createState() => _LiveTrackingScreenState();
}

class _LiveTrackingScreenState extends State<LiveTrackingScreen> {
  GoogleMapController? _mapController;
  
  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};
  
  Position? _passengerLocation;
  Map<String, dynamic>? _vehicleLocation;
  
  final LocationService _locationService = LocationService();
  final EngagementService _engagementService = EngagementService();
  
  // Demo ride data
  static const String _vehicleId = 'vehicle_001';
  static const LatLng _defaultLocation = LatLng(-1.2921, 36.8219);

  // Simulation & Demo State
  Timer? _simulationTimer;
  int _simulationStep = 0;
  final List<LatLng> _simulatedPath = [];
  bool _isSimulating = false;
  String _rideStatus = 'Searching for Matatu...'; // 'Searching...', 'On the Way', 'Arrived', 'Simulation Paused'
  double _distanceRemaining = 0.0;
  String _etaText = '-- mins';
  bool _sosTriggered = false;

  @override
  void initState() {
    super.initState();
    _initializeTracking();
    _engagementService.syncQueuedActions();
  }

  Future<void> _initializeTracking() async {
    // Get passenger's current location
    _passengerLocation = await _locationService.getCurrentPosition();
    
    final LatLng startLocation = _passengerLocation != null
        ? LatLng(_passengerLocation!.latitude, _passengerLocation!.longitude)
        : _defaultLocation;

    if (mounted) {
      setState(() {
        _addPassengerMarker(startLocation);
      });
    }

    // Initialize simulated path
    _generateSimulatedPath(startLocation);

    // Start simulation automatically after a short delay for demo purposes
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        _startSimulation();
      }
    });

    // Also subscribe to vehicle real-time location updates (production database support)
    _subscribeToVehicleLocation();
    
    // Start streaming passenger location (for driver/sacco to see)
    _locationService.startLocationStream(
      onLocationUpdate: (position) {
        if (mounted) {
          setState(() {
            _passengerLocation = position;
            final userLoc = LatLng(position.latitude, position.longitude);
            _addPassengerMarker(userLoc);
            if (!_isSimulating) {
              _updatePolylines();
            }
          });
        }
      },
      distanceFilter: 5, // Update every 5 meters
    );
  }

  void _generateSimulatedPath(LatLng target) {
    _simulatedPath.clear();
    // Start vehicle ~1.3 km away with small offsets
    final double startLat = target.latitude + 0.008;
    final double startLng = target.longitude + 0.010;
    
    // Generate 15 points creating a smooth interpolation towards the target
    for (int i = 0; i <= 15; i++) {
      double t = i / 15.0;
      double lat = startLat + (target.latitude - startLat) * t;
      double lng = startLng + (target.longitude - startLng) * t;
      _simulatedPath.add(LatLng(lat, lng));
    }
  }

  void _startSimulation() {
    if (_simulatedPath.isEmpty) return;
    _simulationTimer?.cancel();
    
    setState(() {
      _isSimulating = true;
      _simulationStep = 0;
      _rideStatus = 'On the Way';
      
      // Place initial vehicle location
      _vehicleLocation = {
        'latitude': _simulatedPath[0].latitude,
        'longitude': _simulatedPath[0].longitude,
        'heading': 0.0,
      };
      _updateVehicleMarker();
      _updatePolylines();
    });

    _simulationTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      if (_simulationStep >= _simulatedPath.length - 1) {
        timer.cancel();
        setState(() {
          _isSimulating = false;
          _rideStatus = 'Arrived';
          _etaText = 'Arrived';
          _distanceRemaining = 0.0;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🎉 Your Matatu Rongai Express (KCA 789X) has arrived at your pickup spot!'),
            backgroundColor: AppColors.primary,
            duration: Duration(seconds: 5),
          ),
        );
        return;
      }

      setState(() {
        _simulationStep++;
        final currentPoint = _simulatedPath[_simulationStep];
        final prevPoint = _simulatedPath[_simulationStep - 1];
        
        // Calculate heading
        final heading = _locationService.calculateBearing(
          startLat: prevPoint.latitude,
          startLng: prevPoint.longitude,
          endLat: currentPoint.latitude,
          endLng: currentPoint.longitude,
        );

        _vehicleLocation = {
          'latitude': currentPoint.latitude,
          'longitude': currentPoint.longitude,
          'heading': heading,
        };

        _updateVehicleMarker();
        _updatePolylines();
        
        // Calculate remaining distance and time
        final passengerLat = _passengerLocation?.latitude ?? _defaultLocation.latitude;
        final passengerLng = _passengerLocation?.longitude ?? _defaultLocation.longitude;
        
        _distanceRemaining = _locationService.calculateDistance(
          startLat: currentPoint.latitude,
          startLng: currentPoint.longitude,
          endLat: passengerLat,
          endLng: passengerLng,
        );

        final duration = _locationService.estimateTravelTime(_distanceRemaining, averageSpeedKmh: 40);
        _etaText = _locationService.formatDuration(duration);
      });

      // Animate map camera to keep both markers in view
      if (!kIsWeb && _mapController != null) {
        _animateCameraToBounds();
      }
    });
  }

  void _animateCameraToBounds() {
    if (_passengerLocation == null || _vehicleLocation == null || _mapController == null) return;
    
    final pLat = _passengerLocation!.latitude;
    final pLng = _passengerLocation!.longitude;
    final vLat = _vehicleLocation!['latitude'] as double;
    final vLng = _vehicleLocation!['longitude'] as double;
    
    final southwest = LatLng(min(pLat, vLat), min(pLng, vLng));
    final northeast = LatLng(max(pLat, vLat), max(pLng, vLng));
    
    _mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(southwest: southwest, northeast: northeast),
        80.0, // padding in pixels
      ),
    );
  }

  void _subscribeToVehicleLocation() {
    _locationService.subscribeToVehicleLocation(
      vehicleId: _vehicleId,
      onUpdate: (location) {
        // Only update from DB if we're not currently running the simulation
        if (!_isSimulating && mounted) {
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
    setState(() {
      _sosTriggered = true;
    });

    try {
      final profile = await (() async {
        try {
          return await UserService().fetchCurrentUserProfileModel();
        } catch (_) {
          return null;
        }
      })();
      
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
          const SnackBar(
            content: Text('SOS alert sent and copied to clipboard'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _sosTriggered = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
        );
      }
    }
  }

  void _addPassengerMarker(LatLng position) {
    _markers.removeWhere((m) => m.markerId.value == 'passenger');
    _markers.add(
      Marker(
        markerId: const MarkerId('passenger'),
        position: position,
        infoWindow: const InfoWindow(title: 'Your Location'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
      ),
    );
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
    if (_vehicleLocation == null) return;

    final pLat = _passengerLocation?.latitude ?? _defaultLocation.latitude;
    final pLng = _passengerLocation?.longitude ?? _defaultLocation.longitude;
    final vLat = _vehicleLocation!['latitude'] as double?;
    final vLng = _vehicleLocation!['longitude'] as double?;
    
    if (vLat == null || vLng == null) return;

    _polylines.clear();
    _polylines.add(
      Polyline(
        polylineId: const PolylineId('route'),
        points: [
          LatLng(pLat, pLng),
          LatLng(vLat, vLng),
        ],
        color: AppColors.primary,
        width: 4,
      ),
    );
  }

  @override
  void dispose() {
    _simulationTimer?.cancel();
    if (!kIsWeb && _mapController != null) {
      _mapController!.dispose();
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
              color: Colors.grey.shade100,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.location_on_rounded, size: 64, color: AppColors.primary),
                    const SizedBox(height: 16),
                    Text(
                      'Live Tracking Screen',
                      style: GoogleFonts.poppins(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textLight,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Maps are simulated dynamically below on web platforms.',
                      style: GoogleFonts.poppins(
                        color: AppColors.textGrey,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // --- 2. Map Control Buttons (Mobile only) ---
          if (!kIsWeb)
            _buildMapControlButtons(),

          // --- 3. Premium Floating Bottom Card ---
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: SafeArea(
              child: _buildPremiumDashboardCard(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapControlButtons() {
    return Positioned(
      top: 60,
      right: 16,
      child: Column(
        children: [
          _MapButton(
            icon: Icons.add,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            onPressed: () {
              _mapController?.animateCamera(CameraUpdate.zoomIn());
            },
          ),
          const SizedBox(height: 2),
          _MapButton(
            icon: Icons.remove,
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
            onPressed: () {
              _mapController?.animateCamera(CameraUpdate.zoomOut());
            },
          ),
          const SizedBox(height: 16),
          _MapButton(
            icon: Icons.my_location,
            borderRadius: BorderRadius.circular(12),
            onPressed: () {
              final lat = _passengerLocation?.latitude ?? _defaultLocation.latitude;
              final lng = _passengerLocation?.longitude ?? _defaultLocation.longitude;
              _mapController?.animateCamera(
                CameraUpdate.newLatLng(LatLng(lat, lng)),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumDashboardCard() {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDarkMode ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDarkMode ? 0.3 : 0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(
          color: isDarkMode ? AppColors.borderDark.withValues(alpha: 0.5) : AppColors.borderLight,
          width: 1.5,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          
          // Ride Status & ETA Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _rideStatus.toUpperCase(),
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: _rideStatus == 'Arrived'
                          ? Colors.green.shade600
                          : theme.colorScheme.primary,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _rideStatus == 'Searching for Matatu...'
                        ? 'Finding your pool...'
                        : (_rideStatus == 'Arrived'
                            ? 'Your matatu has arrived!'
                            : 'ETA: $_etaText'),
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
              if (_isSimulating)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _locationService.formatDistance(_distanceRemaining),
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
            ],
          ),
          
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 16),
          
          // Driver & Vehicle Card
          Row(
            children: [
              // Driver Avatar
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.person,
                  color: theme.colorScheme.primary,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              // Driver & Sacco Names
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Peter Kamau (Sacco Driver)',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Rongai Express • 14-seater • KCA 789X',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              // Rating
              Row(
                children: [
                  Icon(Icons.star_rounded, color: Colors.amber.shade600, size: 20),
                  const SizedBox(width: 2),
                  Text(
                    '4.8',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // Row of Action buttons
          Row(
            children: [
              // SOS emergency button
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _sosTriggered ? null : _raiseEmergencyAlert,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade600,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  icon: const Icon(Icons.sos, size: 20),
                  label: Text(
                    _sosTriggered ? 'SOS Sent' : 'SOS',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              
              // Call Driver
              _buildActionButton(
                icon: Icons.phone_outlined,
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Calling driver: +254 712 345678...')),
                  );
                },
                tooltip: 'Call Driver',
              ),
              const SizedBox(width: 12),
              
              // Chat with Sacco
              _buildActionButton(
                icon: Icons.chat_bubble_outline_rounded,
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Opening chat with matatu group...')),
                  );
                },
                tooltip: 'Chat Pool',
              ),
              const SizedBox(width: 12),
              
              // Reset/Simulation control
              _buildActionButton(
                icon: _isSimulating ? Icons.pause_rounded : Icons.play_arrow_rounded,
                onPressed: () {
                  if (_isSimulating) {
                    _simulationTimer?.cancel();
                    setState(() {
                      _isSimulating = false;
                      _rideStatus = 'Simulation Paused';
                    });
                  } else {
                    if (_simulationStep >= _simulatedPath.length - 1) {
                      _initializeTracking();
                    } else {
                      _startSimulation();
                    }
                  }
                },
                tooltip: _isSimulating ? 'Pause Demo' : 'Play Demo',
                color: theme.colorScheme.primary,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required VoidCallback onPressed,
    required String tooltip,
    Color? color,
  }) {
    final theme = Theme.of(context);
    final accentColor = color ?? theme.colorScheme.primary;
    
    return Container(
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: accentColor.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: IconButton(
        icon: Icon(icon, color: accentColor),
        onPressed: onPressed,
        tooltip: tooltip,
        padding: const EdgeInsets.all(12),
        constraints: const BoxConstraints(),
      ),
    );
  }
}

// --- Map control button component widget ---
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
