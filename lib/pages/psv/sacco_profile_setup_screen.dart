import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/user_service.dart';
import '../../themes/app_colors.dart';
import '../../widgets/avatar_picker.dart';

/// Profile setup screen for Sacco operators after role selection.
/// Collects: sacco name, NTSA license number, fleet size, contact details.
class SaccoProfileSetupScreen extends StatefulWidget {
  const SaccoProfileSetupScreen({super.key});

  @override
  State<SaccoProfileSetupScreen> createState() =>
      _SaccoProfileSetupScreenState();
}

class _SaccoProfileSetupScreenState extends State<SaccoProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _saccoNameController = TextEditingController();
  final _ntsaLicenseController = TextEditingController();
  final _fleetSizeController = TextEditingController();
  final _contactNameController = TextEditingController();
  final _contactPhoneController = TextEditingController();
  final _contactEmailController = TextEditingController();
  bool _isLoading = false;
  String? _logoUrl;

  @override
  void initState() {
    super.initState();
    _loadExisting();
  }

  Future<void> _loadExisting() async {
    User? user;
    try {
      final response = await Supabase.instance.client.auth.getUser();
      user = response.user ?? Supabase.instance.client.auth.currentUser;
    } catch (_) {
      user = Supabase.instance.client.auth.currentUser;
    }

    if (user != null) {
      if (user.email != null && !user.email!.startsWith('user-')) {
        _contactEmailController.text = user.email!;
      }
      final metaName = (user.userMetadata?['name'] ?? 
                   user.userMetadata?['full_name'] ?? 
                   user.userMetadata?['display_name']) as String? ?? '';
      if (metaName.isNotEmpty) {
        _contactNameController.text = metaName;
      }
      final metaPhone = user.phone ?? user.userMetadata?['phone'] as String? ?? '';
      if (metaPhone.isNotEmpty) {
        _contactPhoneController.text = metaPhone;
      }

      try {
        final profile = await UserService().fetchCurrentUserProfileModel();
        if (mounted && profile != null) {
          if (profile.name != null && profile.name!.isNotEmpty) {
            _contactNameController.text = profile.name!;
          }
          if (profile.email != null && profile.email!.isNotEmpty) {
            _contactEmailController.text = profile.email!;
          }
          if (profile.phone != null && profile.phone!.isNotEmpty) {
            _contactPhoneController.text = profile.phone!;
          }
        }
      } catch (e) {
        debugPrint('Error loading sacco existing profile: $e');
      }
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) throw Exception('Not authenticated');

      final contactName = _contactNameController.text.trim();
      final contactEmail = _contactEmailController.text.trim().toLowerCase();
      final contactPhone = _contactPhoneController.text.trim();

      // Upsert user profile record
      final userUpdates = <String, dynamic>{
        'id': userId,
        'name': contactName,
        'phone': contactPhone,
        'role': 'sacco',
      };
      if (contactEmail.isNotEmpty && !contactEmail.startsWith('user-')) {
        userUpdates['email'] = contactEmail;
      }
      if (_logoUrl != null) {
        userUpdates['avatar_url'] = _logoUrl!;
      }
      await Supabase.instance.client.from('users').upsert(userUpdates);

      // Insert sacco profile details
      final saccoData = <String, dynamic>{
        'user_id': userId,
        'sacco_name': _saccoNameController.text.trim(),
        'ntsa_license': _ntsaLicenseController.text.trim(),
        'fleet_size': int.tryParse(_fleetSizeController.text.trim()) ?? 0,
        'contact_name': _contactNameController.text.trim(),
        'contact_phone': _contactPhoneController.text.trim(),
        'contact_email': _contactEmailController.text.trim(),
        'verification_status': 'pending',
      };
      if (_logoUrl != null) {
        saccoData['logo_url'] = _logoUrl!;
      }
        await Supabase.instance.client
          .from('sacco_profiles')
          .upsert(saccoData, onConflict: 'user_id');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sacco profile saved!')),
        );
        Navigator.pushReplacementNamed(context, '/sacco-verification');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to save Sacco profile right now.')),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _saccoNameController.dispose();
    _ntsaLicenseController.dispose();
    _fleetSizeController.dispose();
    _contactNameController.dispose();
    _contactPhoneController.dispose();
    _contactEmailController.dispose();
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
          'Sacco Registration',
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
                  'Register your Sacco',
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textLight,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Provide your Sacco details to get started.',
                  style: GoogleFonts.poppins(
                    color: AppColors.textGrey,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 32),

                // Logo/Avatar picker
                Center(
                  child: AvatarPicker(
                    currentAvatarUrl: _logoUrl,
                    storagePath: 'sacco_${Supabase.instance.client.auth.currentUser?.id ?? "unknown"}',
                    onUploaded: (url) {
                      setState(() => _logoUrl = url);
                    },
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    'Tap to add Sacco logo',
                    style: GoogleFonts.poppins(
                      color: AppColors.textGrey,
                      fontSize: 13,
                    ),
                  ),
                ),
                const SizedBox(height: 28),

                // Sacco details section
                _sectionHeader('Sacco Information', Icons.business_outlined),
                const SizedBox(height: 16),

                _buildLabel('Sacco Name'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _saccoNameController,
                  decoration:
                      _inputDecoration('e.g. Safari Sacco', Icons.badge_outlined),
                  validator: (val) =>
                      val == null || val.isEmpty ? 'Sacco name is required' : null,
                ),
                const SizedBox(height: 20),

                _buildLabel('NTSA License Number'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _ntsaLicenseController,
                  decoration:
                      _inputDecoration('e.g. NTSA/PSV/2024/001', Icons.verified_outlined),
                  validator: (val) => val == null || val.isEmpty
                      ? 'NTSA license is required'
                      : null,
                ),
                const SizedBox(height: 20),

                _buildLabel('Fleet Size'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _fleetSizeController,
                  keyboardType: TextInputType.number,
                  decoration: _inputDecoration(
                      'Number of vehicles', Icons.directions_bus_outlined),
                  validator: (val) =>
                      val == null || val.isEmpty ? 'Fleet size is required' : null,
                ),
                const SizedBox(height: 28),

                // Contact details section
                _sectionHeader('Contact Details', Icons.contact_phone_outlined),
                const SizedBox(height: 16),

                _buildLabel('Contact Person Name'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _contactNameController,
                  decoration:
                      _inputDecoration('Full name', Icons.person_outline),
                  validator: (val) =>
                      val == null || val.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 20),

                _buildLabel('Contact Phone'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _contactPhoneController,
                  keyboardType: TextInputType.phone,
                  decoration:
                      _inputDecoration('0712345678', Icons.phone_outlined),
                  validator: (val) =>
                      val == null || val.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 20),

                _buildLabel('Contact Email'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _contactEmailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration:
                      _inputDecoration('email@example.com', Icons.email_outlined),
                ),
                const SizedBox(height: 36),

                // Continue button
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
                            'Continue to Verification',
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
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

  Widget _sectionHeader(String title, IconData icon) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 22),
          const SizedBox(width: 10),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: AppColors.primary,
            ),
          ),
        ],
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
