import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../services/location_service.dart';

class RoutePreviewMap extends StatefulWidget {
  const RoutePreviewMap({
    super.key,
    this.originLat,
    this.originLng,
    this.destLat,
    this.destLng,
    this.originAddress,
    this.destAddress,
    this.height = 180,
  });

  final double? originLat;
  final double? originLng;
  final double? destLat;
  final double? destLng;
  final String? originAddress;
  final String? destAddress;
  final double height;

  @override
  State<RoutePreviewMap> createState() => _RoutePreviewMapState();
}

class _RoutePreviewMapState extends State<RoutePreviewMap> {
  GoogleMapController? _mapController;
  
  double? _originLat;
  double? _originLng;
  double? _destLat;
  double? _destLng;

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initCoordinates();
  }

  @override
  void didUpdateWidget(covariant RoutePreviewMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.originLat != widget.originLat ||
        oldWidget.originLng != widget.originLng ||
        oldWidget.destLat != widget.destLat ||
        oldWidget.destLng != widget.destLng ||
        oldWidget.originAddress != widget.originAddress ||
        oldWidget.destAddress != widget.destAddress) {
      _initCoordinates();
    }
  }

  Future<void> _initCoordinates() async {
    setState(() => _isLoading = true);

    double? oLat = widget.originLat;
    double? oLng = widget.originLng;
    double? dLat = widget.destLat;
    double? dLng = widget.destLng;

    final locService = LocationService();

    // Resolve Origin coordinates if missing
    if ((oLat == null || oLng == null) && widget.originAddress != null && widget.originAddress!.isNotEmpty) {
      final loc = await locService.getCoordinatesFromAddress(widget.originAddress!);
      if (loc != null) {
        oLat = loc.latitude;
        oLng = loc.longitude;
      }
    }

    // Resolve Destination coordinates if missing
    if ((dLat == null || dLng == null) && widget.destAddress != null && widget.destAddress!.isNotEmpty) {
      final loc = await locService.getCoordinatesFromAddress(widget.destAddress!);
      if (loc != null) {
        dLat = loc.latitude;
        dLng = loc.longitude;
      }
    }

    if (mounted) {
      setState(() {
        _originLat = oLat;
        _originLng = oLng;
        _destLat = dLat;
        _destLng = dLng;
        _isLoading = false;
      });
      if (oLat != null && oLng != null && dLat != null && dLng != null) {
        _fitMapBounds();
      }
    }
  }

  void _fitMapBounds() {
    if (_mapController == null || _originLat == null || _originLng == null || _destLat == null || _destLng == null) {
      return;
    }

    final southWestLat = _originLat! < _destLat! ? _originLat! : _destLat!;
    final southWestLng = _originLng! < _destLng! ? _originLng! : _destLng!;
    final northEastLat = _originLat! > _destLat! ? _originLat! : _destLat!;
    final northEastLng = _originLng! > _destLng! ? _originLng! : _destLng!;

    final bounds = LatLngBounds(
      southwest: LatLng(southWestLat, southWestLng),
      northeast: LatLng(northEastLat, northEastLng),
    );

    _mapController?.animateCamera(CameraUpdate.newLatLngBounds(bounds, 40));
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        height: widget.height,
        width: double.infinity,
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    if (_originLat == null || _originLng == null || _destLat == null || _destLng == null) {
      return Container(
        height: widget.height,
        width: double.infinity,
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: const Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.map_outlined, color: Color(0xFF94A3B8), size: 20),
              SizedBox(width: 8),
              Text(
                'Map route preview loading...',
                style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
              ),
            ],
          ),
        ),
      );
    }

    final originLatLng = LatLng(_originLat!, _originLng!);
    final destLatLng = LatLng(_destLat!, _destLng!);

    final Set<Marker> markers = {
      Marker(
        markerId: const MarkerId('origin'),
        position: originLatLng,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        infoWindow: InfoWindow(title: 'Pickup', snippet: widget.originAddress ?? 'Origin'),
      ),
      Marker(
        markerId: const MarkerId('dest'),
        position: destLatLng,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        infoWindow: InfoWindow(title: 'Destination', snippet: widget.destAddress ?? 'Destination'),
      ),
    };

    final Set<Polyline> polylines = {
      Polyline(
        polylineId: const PolylineId('route'),
        points: [originLatLng, destLatLng],
        color: const Color(0xFF006E27),
        width: 4,
      ),
    };

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        height: widget.height,
        width: double.infinity,
        child: GoogleMap(
          initialCameraPosition: CameraPosition(
            target: originLatLng,
            zoom: 12,
          ),
          markers: markers,
          polylines: polylines,
          myLocationButtonEnabled: false,
          zoomControlsEnabled: false,
          mapToolbarEnabled: false,
          onMapCreated: (controller) {
            _mapController = controller;
            _fitMapBounds();
          },
        ),
      ),
    );
  }
}
