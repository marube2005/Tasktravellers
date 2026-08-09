import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../themes/app_colors.dart';

/// PSV Driver Profile Setup Screen.
/// If the user is NOT authenticated (coming from role selection),
/// this screen acts as a combined Sign Up + Profile Setup.
/// If the user IS authenticated, it pre-fills and allows updating profile.
class PsvDriverProfileSetupScreen extends StatefulWidget {
  const PsvDriverProfileSetupScreen({super.key});

  @override
  State<PsvDriverProfileSetupScreen> createState() =>
      _PsvDriverProfileSetupScreenState();
}

class _PsvDriverProfileSetupScreenState
    extends State<PsvDriverProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _vehicleRegController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _acceptedTerms = false;

  bool get _isAuthenticated =>
      Supabase.instance.client.auth.currentUser != null;

  @override
  void initState() {
    super.initState();
    _prefillFromSession();
  }

  Future<void> _prefillFromSession() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    if (user.email != null && !user.email!.startsWith('user-')) {
      _emailController.text = user.email!;
    }
    final metaName = (user.userMetadata?['name'] ??
        user.userMetadata?['full_name'] ??
        user.userMetadata?['display_name']) as String? ??
        '';
    if (metaName.isNotEmpty) _fullNameController.text = metaName;

    final metaPhone =
        user.phone ?? user.userMetadata?['phone'] as String? ?? '';
    if (metaPhone.isNotEmpty) _phoneController.text = metaPhone;

    // Pre-fill vehicle reg from metadata stored during initial signup
    final metaVehicleReg =
        user.userMetadata?['vehicle_reg_number'] as String? ?? '';
    if (metaVehicleReg.isNotEmpty) _vehicleRegController.text = metaVehicleReg;


    try {
      final driverProfile = await Supabase.instance.client
          .from('psv_driver_profiles')
          .select()
          .eq('user_id', user.id)
          .maybeSingle();

      if (driverProfile != null && mounted) {
        if (driverProfile['full_name'] != null) {
          _fullNameController.text = driverProfile['full_name'];
        }
        if (driverProfile['phone'] != null) {
          _phoneController.text = driverProfile['phone'];
        }
        if (driverProfile['email'] != null) {
          _emailController.text = driverProfile['email'];
        }
        if (driverProfile['vehicle_reg_number'] != null) {
          _vehicleRegController.text = driverProfile['vehicle_reg_number'];
        }
      }
    } catch (e) {
      debugPrint('Error pre-filling PSV profile: $e');
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_isAuthenticated && !_acceptedTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please accept the Terms & Conditions')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final fullName = _fullNameController.text.trim();
      final email = _emailController.text.trim().toLowerCase();
      final phone = _phoneController.text.trim();
      final vehicleReg = _vehicleRegController.text.trim().toUpperCase();

      if (!_isAuthenticated) {
        // ── NEW USER PATH ─────────────────────────────────────────────────
        // 1. Create the auth account. The handle_new_user DB trigger
        //    (SECURITY DEFINER) will insert into public.users automatically,
        //    reading 'role' from signup metadata.
        //    We must NOT try to upsert public.users or psv_driver_profiles
        //    here — there is no session yet (email confirmation is required),
        //    so any client-side insert would be blocked by RLS (code 42501).
        final authResponse = await Supabase.instance.client.auth.signUp(
          email: email,
          password: _passwordController.text.trim(),
          data: {
            'name': fullName,
            'full_name': fullName,
            'phone': phone,
            'role': 'psv',
            // Store vehicle reg in metadata so it can be pre-filled later
            'vehicle_reg_number': vehicleReg,
          },
        );

        if (authResponse.user == null) {
          throw Exception('Account creation failed. Please try again.');
        }

        // 2. Navigate to email verification. After confirming + logging in,
        //    handlePostLoginNavigation will route them back to
        //    /psv-driver-profile-setup (already authenticated) to save the
        //    psv_driver_profiles row.
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Account created! Please verify your email.'),
              duration: Duration(seconds: 3),
            ),
          );
          Navigator.pushReplacementNamed(
            context,
            '/email-verification',
            arguments: {'email': email},
          );
        }
        return;
      }

      // ── AUTHENTICATED USER PATH (returning after email confirmation) ────
      final String userId = Supabase.instance.client.auth.currentUser!.id;

      // Upsert public.users — session exists, so RLS is satisfied.
      // Try with role='psv'; fall back without role if enum not yet patched.
      try {
        await Supabase.instance.client.from('users').upsert(<String, dynamic>{
          'id': userId,
          'name': fullName,
          'phone': phone,
          'role': 'psv',
          'email': email,
        });
      } catch (roleErr) {
        debugPrint('PSV role upsert (enum?), retrying without role: $roleErr');
        await Supabase.instance.client.from('users').upsert(<String, dynamic>{
          'id': userId,
          'name': fullName,
          'phone': phone,
          'email': email,
        });
      }

      // Upsert psv_driver_profiles
      await Supabase.instance.client.from('psv_driver_profiles').upsert(
        <String, dynamic>{
          'user_id': userId,
          'full_name': fullName,
          'phone': phone,
          'email': email,
          'vehicle_reg_number': vehicleReg,
          'verification_status': 'pending',
          'updated_at': DateTime.now().toIso8601String(),
        },
        onConflict: 'user_id',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Driver profile saved!')),
        );
        Navigator.pushReplacementNamed(context, '/psv-driver-verification');
      }

    } on AuthException catch (e) {
      if (mounted) {
        final msg = e.message.toLowerCase();
        final friendly = msg.contains('rate limit') || msg.contains('email rate')
            ? 'Too many signup attempts for this email.\n'
              'Please wait a few minutes or use a different email address.'
            : e.message;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(friendly),
            duration: const Duration(seconds: 6),
          ),
        );
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _vehicleRegController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool newUser = !_isAuthenticated;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundLight,
        elevation: 0,
        centerTitle: false,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.directions_bus, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 8),
            Text(
              'SafariFlow',
              style: GoogleFonts.poppins(
                color: AppColors.primary,
                fontWeight: FontWeight.w800,
                fontSize: 18,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none, color: AppColors.textLight),
            onPressed: () {},
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Step header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Driver Profile',
                      style: GoogleFonts.poppins(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textLight,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Step 1 of 3',
                        style: GoogleFonts.poppins(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  newUser
                      ? 'Create your PSV driver account to get started.'
                      : 'Update your PSV driver details.',
                  style: GoogleFonts.poppins(
                    color: AppColors.textGrey,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 24),

                // Full Name
                _buildLabel('Full Name'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _fullNameController,
                  decoration: _inputDecoration('e.g. John Kamau', Icons.person_outline),
                  validator: (val) =>
                      val == null || val.trim().isEmpty ? 'Full name is required' : null,
                ),
                const SizedBox(height: 20),

                // Phone
                _buildLabel('Phone Number'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: _inputDecoration('+254 7XX XXX XXX', Icons.phone_outlined),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) return 'Phone number is required';
                    if (val.trim().replaceAll(RegExp(r'\s+'), '').length < 9) {
                      return 'Enter a valid phone number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // Email
                _buildLabel('Email Address'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: _inputDecoration('driver@safariflow.com', Icons.email_outlined),
                  validator: (val) => val == null || !val.contains('@')
                      ? 'Valid email address required'
                      : null,
                ),
                const SizedBox(height: 20),

                // Password (only for new users)
                if (newUser) ...[
                  _buildLabel('Password'),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: _inputDecoration(
                      'Minimum 6 characters',
                      Icons.lock_outline,
                    ).copyWith(
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility_off : Icons.visibility,
                          color: AppColors.textGrey,
                        ),
                        onPressed: () =>
                            setState(() => _obscurePassword = !_obscurePassword),
                      ),
                    ),
                    validator: (val) => val == null || val.length < 6
                        ? 'Minimum 6 characters'
                        : null,
                  ),
                  const SizedBox(height: 20),
                ],

                // Vehicle Registration Number
                _buildLabel('Vehicle Registration Number'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _vehicleRegController,
                  textCapitalization: TextCapitalization.characters,
                  decoration: _inputDecoration('E.G. KCA 123X', Icons.directions_bus_outlined),
                  validator: (val) => val == null || val.trim().isEmpty
                      ? 'Vehicle registration number required'
                      : null,
                ),
                const SizedBox(height: 24),

                // Info Banner
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.info_outline, color: AppColors.primary, size: 22),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Your data is stored securely. We use these details to verify your PSV driver status and manage your performance scoreboard.',
                          style: GoogleFonts.poppins(
                            color: AppColors.textGrey,
                            fontSize: 13,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Terms checkbox (only for new users)
                if (newUser) ...[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Checkbox(
                        value: _acceptedTerms,
                        activeColor: AppColors.primary,
                        onChanged: (val) =>
                            setState(() => _acceptedTerms = val ?? false),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () =>
                              setState(() => _acceptedTerms = !_acceptedTerms),
                          child: Text(
                            'I accept the Terms & Conditions.',
                            style: GoogleFonts.poppins(
                              color: AppColors.textGrey,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],

                // Save & Continue Button
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
                      elevation: 2,
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Save & Continue',
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontSize: 17,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(Icons.arrow_forward,
                                  color: Colors.white, size: 20),
                            ],
                          ),
                  ),
                ),

                // Already have account link (new users only)
                if (newUser) ...[
                  const SizedBox(height: 16),
                  Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Already have an account? ',
                          style: GoogleFonts.poppins(
                            color: AppColors.textGrey,
                            fontSize: 13,
                          ),
                        ),
                        GestureDetector(
                          onTap: () =>
                              Navigator.pushReplacementNamed(context, '/login'),
                          child: Text(
                            'Log in',
                            style: GoogleFonts.poppins(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 24),
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
      hintStyle: GoogleFonts.poppins(color: Colors.grey.shade400, fontSize: 14),
      prefixIcon: Icon(icon, color: AppColors.primary),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide:
            BorderSide(color: AppColors.borderLight.withValues(alpha: 0.85)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide:
            BorderSide(color: AppColors.borderLight.withValues(alpha: 0.85)),
      ),
      focusedBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(14)),
        borderSide: BorderSide(color: AppColors.primary, width: 1.8),
      ),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }
}
