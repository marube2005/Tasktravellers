import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/ride_service.dart';
import '../services/user_service.dart';
import '../themes/app_colors.dart';
import '../widgets/custom_text_field.dart';

class RideAcceptanceScreen extends StatefulWidget {
  const RideAcceptanceScreen({super.key});

  @override
  State<RideAcceptanceScreen> createState() => _RideAcceptanceScreenState();
}

class _RideAcceptanceScreenState extends State<RideAcceptanceScreen> {
  final _formKey = GlobalKey<FormState>();
  final _rideIdController = TextEditingController();
  final _codeController = TextEditingController();
  final _fareController = TextEditingController();
  String? _vehicleId;
  bool _isLoading = false;
  Map<String, dynamic>? _ride;
  List<Map<String, dynamic>> _vehicles = [];

  @override
  void initState() {
    super.initState();
    _loadVehicles();
  }

  Future<void> _loadVehicles() async {
    try {
      final vehicles = await UserService().fetchMySaccoVehicles();
      if (mounted) {
        setState(() {
          _vehicles = vehicles;
          _vehicleId = vehicles.isNotEmpty ? vehicles.first['id'] as String? : null;
        });
      }
    } catch (_) {
      // ignore load failure until submit
    }
  }

  Future<void> _loadRide() async {
    final rideId = _rideIdController.text.trim();
    if (rideId.isEmpty) return;

    try {
      final ride = await RideService().fetchRideById(rideId);
      if (mounted) setState(() => _ride = ride);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
        );
      }
    }
  }

  Future<void> _acceptRide() async {
    if (!_formKey.currentState!.validate()) return;
    if (_vehicleId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No sacco vehicle available')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final saccoId = Supabase.instance.client.auth.currentUser?.id;
      if (saccoId == null) {
        throw Exception('Authentication required. User not logged in.');
      }
      await RideService().acceptRideWithCode(
        rideId: _rideIdController.text.trim(),
        acceptanceCode: _codeController.text.trim(),
        vehicleId: _vehicleId!,
        saccoId: saccoId,
        confirmedFare: double.tryParse(_fareController.text.trim()) ?? 0,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ride accepted successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _rideIdController.dispose();
    _codeController.dispose();
    _fareController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Accept Ride'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'OTP ride acceptance',
                style: GoogleFonts.manrope(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textLight,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Enter the shared ride code before confirming the vehicle.',
                style: GoogleFonts.manrope(color: AppColors.textGrey),
              ),
              const SizedBox(height: 24),
              AppTextField(
                controller: _rideIdController,
                label: 'Ride ID',
                hint: 'Paste ride id here',
                prefixIcon: Icons.receipt_long,
                validator: (value) =>
                    value == null || value.trim().isEmpty ? 'Ride ID is required' : null,
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: _loadRide,
                child: const Text('Load ride details'),
              ),
              const SizedBox(height: 16),
              AppTextField(
                controller: _codeController,
                label: 'Acceptance code',
                hint: '6-character code',
                prefixIcon: Icons.pin,
                validator: (value) =>
                    value == null || value.trim().length < 4 ? 'Enter the ride code' : null,
              ),
              const SizedBox(height: 16),
              AppTextField(
                controller: _fareController,
                label: 'Confirmed fare',
                hint: '1650',
                prefixIcon: Icons.payments_outlined,
                keyboardType: TextInputType.number,
                validator: (value) =>
                    value == null || value.trim().isEmpty ? 'Fare is required' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _vehicleId,
                items: _vehicles
                    .map(
                      (vehicle) => DropdownMenuItem<String>(
                        value: vehicle['id'] as String?,
                        child: Text('${vehicle['plate_number'] ?? 'Vehicle'}'),
                      ),
                    )
                    .toList(),
                onChanged: (value) => setState(() => _vehicleId = value),
                decoration: const InputDecoration(
                  labelText: 'Vehicle',
                  prefixIcon: Icon(Icons.directions_bus),
                ),
                validator: (value) => value == null ? 'Choose a vehicle' : null,
              ),
              const SizedBox(height: 20),
              if (_ride != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.cardLight,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.borderLight),
                  ),
                  child: Text(
                    '${_ride!['origin'] ?? 'Origin'} → ${_ride!['destination'] ?? 'Destination'}',
                    style: GoogleFonts.manrope(fontWeight: FontWeight.w700),
                  ),
                ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _acceptRide,
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Accept ride'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
