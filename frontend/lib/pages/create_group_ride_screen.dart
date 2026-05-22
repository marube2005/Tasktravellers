import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/offline_cache_service.dart';
import '../services/ride_service.dart';
import '../themes/app_colors.dart';
import '../widgets/custom_text_field.dart';
import 'group_invite_share_screen.dart';

class CreateGroupRideScreen extends StatefulWidget {
  const CreateGroupRideScreen({super.key});

  @override
  State<CreateGroupRideScreen> createState() => _CreateGroupRideScreenState();
}

class _CreateGroupRideScreenState extends State<CreateGroupRideScreen> {
  final _formKey = GlobalKey<FormState>();
  final _offlineCacheService = OfflineCacheService();
  final _originController = TextEditingController();
  final _destinationController = TextEditingController();
  final _groupSizeController = TextEditingController(text: '4');
  final _estimatedFareController = TextEditingController();
  final _groupNoteController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _originController.addListener(_saveDraft);
    _destinationController.addListener(_saveDraft);
    _groupSizeController.addListener(_saveDraft);
    _estimatedFareController.addListener(_saveDraft);
    _groupNoteController.addListener(_saveDraft);
    _restoreDraft();
  }

  Future<void> _restoreDraft() async {
    final draft = await _offlineCacheService.loadRideDraft();
    if (!mounted || draft == null) return;

    setState(() {
      _originController.text = draft['origin'] as String? ?? '';
      _destinationController.text = draft['destination'] as String? ?? '';
      _groupSizeController.text = draft['group_size']?.toString() ?? '4';
      _estimatedFareController.text = draft['estimated_fare']?.toString() ?? '';
      _groupNoteController.text = draft['group_note'] as String? ?? '';
    });
  }

  Future<void> _saveDraft() async {
    await _offlineCacheService.saveRideDraft({
      'origin': _originController.text.trim(),
      'destination': _destinationController.text.trim(),
      'group_size': _groupSizeController.text.trim(),
      'estimated_fare': _estimatedFareController.text.trim(),
      'group_note': _groupNoteController.text.trim(),
    });
  }

  @override
  void dispose() {
    _originController.dispose();
    _destinationController.dispose();
    _groupSizeController.dispose();
    _estimatedFareController.dispose();
    _groupNoteController.dispose();
    super.dispose();
  }

  Future<void> _createRide() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final ride = await RideService().createRidePool(
        origin: _originController.text.trim(),
        destination: _destinationController.text.trim(),
        groupSize: int.parse(_groupSizeController.text.trim()),
        estimatedFare: _estimatedFareController.text.trim().isEmpty
            ? null
            : double.tryParse(_estimatedFareController.text.trim()),
        groupNote: _groupNoteController.text.trim().isEmpty
            ? null
            : _groupNoteController.text.trim(),
      );

      if (!mounted) return;

      await _offlineCacheService.clearRideDraft();

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => GroupInviteShareScreen(ride: ride),
        ),
      );
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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Group Ride'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Plan the route',
                  style: GoogleFonts.manrope(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textLight,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Set the route and share an invite link instantly.',
                  style: GoogleFonts.manrope(
                    fontSize: 14,
                    color: AppColors.textGrey,
                  ),
                ),
                const SizedBox(height: 28),
                AppTextField(
                  controller: _originController,
                  label: 'Pickup point',
                  hint: 'e.g. Nairobi CBD',
                  prefixIcon: Icons.trip_origin,
                  validator: (value) =>
                      value == null || value.trim().isEmpty ? 'Pickup point is required' : null,
                ),
                const SizedBox(height: 16),
                AppTextField(
                  controller: _destinationController,
                  label: 'Destination',
                  hint: 'e.g. Thika Town',
                  prefixIcon: Icons.flag_outlined,
                  validator: (value) =>
                      value == null || value.trim().isEmpty ? 'Destination is required' : null,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: AppTextField(
                        controller: _groupSizeController,
                        label: 'Group size',
                        hint: '4',
                        prefixIcon: Icons.groups_outlined,
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          final size = int.tryParse(value ?? '');
                          if (size == null || size < 1) {
                            return 'Enter a valid group size';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: AppTextField(
                        controller: _estimatedFareController,
                        label: 'Fare (optional)',
                        hint: '1650',
                        prefixIcon: Icons.payments_outlined,
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                AppTextField(
                  controller: _groupNoteController,
                  label: 'Trip note (optional)',
                  hint: 'e.g. Leaving after the 5pm class',
                  prefixIcon: Icons.note_alt_outlined,
                  maxLines: 3,
                ),
                const SizedBox(height: 24),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                  ),
                  child: Text(
                    'Your ride will get a shareable invite link and a 6-character acceptance code for the sacco.',
                    style: GoogleFonts.manrope(
                      color: AppColors.primary,
                      fontSize: 13,
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _createRide,
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Create ride'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
