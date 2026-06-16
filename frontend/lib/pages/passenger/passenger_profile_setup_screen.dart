import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../themes/app_colors.dart';
import '../../widgets/avatar_picker.dart';

/// Profile setup screen for Passengers after role selection.
/// Collects: name (pre-filled), home area, preferred routes, emergency contact.
class PassengerProfileSetupScreen extends StatefulWidget {
  const PassengerProfileSetupScreen({super.key});

  @override
  State<PassengerProfileSetupScreen> createState() =>
      _PassengerProfileSetupScreenState();
}

class _PassengerProfileSetupScreenState
    extends State<PassengerProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _homeAreaController = TextEditingController();
  final _preferredRoutesController = TextEditingController();
  final _emergencyNameController = TextEditingController();
  final _emergencyPhoneController = TextEditingController();
  bool _isLoading = false;
  String? _avatarUrl;

  @override
  void initState() {
    super.initState();
    _loadExistingProfile();
  }

  Future<void> _loadExistingProfile() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      // Pre-fill name from auth metadata
      final name = user.userMetadata?['name'] as String? ?? '';
      _nameController.text = name;
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) throw Exception('Not authenticated');

      final updates = {
        'name': _nameController.text.trim(),
        'home_area': _homeAreaController.text.trim(),
        'preferred_routes': _preferredRoutesController.text.trim(),
        'emergency_contact_name': _emergencyNameController.text.trim(),
        'emergency_contact_phone': _emergencyPhoneController.text.trim(),
        'role': 'passenger',
      };
      if (_avatarUrl != null) {
        updates['avatar_url'] = _avatarUrl!;
      }
      final client = Supabase.instance.client;

      try {
        await client.from('users').update(updates).eq('id', userId);
      } on PostgrestException catch (e) {
        // If optional columns are missing in an older DB schema, save core profile fields.
        if (e.code == 'PGRST204') {
          final coreUpdates = <String, dynamic>{
            'name': _nameController.text.trim(),
            'role': 'passenger',
          };
          if (_avatarUrl != null) {
            coreUpdates['avatar_url'] = _avatarUrl!;
          }
          await client.from('users').update(coreUpdates).eq('id', userId);
        } else {
          rethrow;
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile saved!')),
        );
        Navigator.pushReplacementNamed(context, '/permissions');
      }
    } on PostgrestException catch (e) {
      if (mounted) {
        final message = e.code == 'PGRST204'
            ? 'Your profile was partially saved. Please apply the latest database migrations.'
            : 'Unable to save profile right now. Please try again.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to save profile right now.')),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _homeAreaController.dispose();
    _preferredRoutesController.dispose();
    _emergencyNameController.dispose();
    _emergencyPhoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundLight,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Set Up Profile',
          style: GoogleFonts.poppins(
            color: AppColors.textLight,
            fontWeight: FontWeight.w700,
            fontSize: 20,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Complete your profile',
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textLight,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Help us personalise your experience.',
                  style: GoogleFonts.poppins(
                    color: AppColors.textGrey,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 32),

                // Avatar picker
                Center(
                  child: AvatarPicker(
                    currentAvatarUrl: _avatarUrl,
                    storagePath: Supabase.instance.client.auth.currentUser?.id ?? 'unknown',
                    onUploaded: (url) {
                      setState(() => _avatarUrl = url);
                    },
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    'Tap to add profile photo',
                    style: GoogleFonts.poppins(
                      color: AppColors.textGrey,
                      fontSize: 13,
                    ),
                  ),
                ),
                const SizedBox(height: 28),

                // Name
                _buildLabel('Full Name'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _nameController,
                  decoration: _inputDecoration('Your full name', Icons.person_outline),
                  validator: (val) =>
                      val == null || val.isEmpty ? 'Name is required' : null,
                ),
                const SizedBox(height: 20),

                // Home Area
                _buildLabel('Home Area (optional)'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _homeAreaController,
                  decoration:
                      _inputDecoration('e.g. Westlands, Nairobi', Icons.home_outlined),
                ),
                const SizedBox(height: 20),

                // Preferred Routes
                _buildLabel('Preferred Routes (optional)'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _preferredRoutesController,
                  decoration: _inputDecoration(
                      'e.g. CBD → Thika, Ngong → CBD', Icons.route_outlined),
                ),
                const SizedBox(height: 28),

                // Emergency Contact section
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.emergency_outlined,
                              color: Colors.orange.shade700, size: 22),
                          const SizedBox(width: 8),
                          Text(
                            'Emergency Contact',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.orange.shade800,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Someone we can reach in case of an emergency.',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: Colors.orange.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _emergencyNameController,
                  decoration: _inputDecoration(
                      'Contact name', Icons.person_outline),
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _emergencyPhoneController,
                  keyboardType: TextInputType.phone,
                  decoration:
                      _inputDecoration('Contact phone', Icons.phone_outlined),
                ),
                const SizedBox(height: 36),

                // Save button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _saveProfile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(
                            'Continue',
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 16),

                // Skip
                Center(
                  child: TextButton(
                    onPressed: () {
                      Navigator.pushReplacementNamed(context, '/permissions');
                    },
                    child: Text(
                      'Skip for now',
                      style: GoogleFonts.poppins(
                        color: AppColors.textGrey,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.poppins(
        fontWeight: FontWeight.w600,
        fontSize: 14,
        color: AppColors.textLight,
      ),
    );
  }

  InputDecoration _inputDecoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: AppColors.borderLight.withValues(alpha: 0.85)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: AppColors.borderLight.withValues(alpha: 0.85)),
      ),
      focusedBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(14)),
        borderSide: BorderSide(color: AppColors.primary, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }
}
