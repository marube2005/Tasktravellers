import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../themes/app_colors.dart';
import '../widgets/custom_text_field.dart';

class PhoneVerificationScreen extends StatefulWidget {
  const PhoneVerificationScreen({super.key});

  @override
  State<PhoneVerificationScreen> createState() =>
      _PhoneVerificationScreenState();
}

class _PhoneVerificationScreenState extends State<PhoneVerificationScreen> {
  final _phoneController = TextEditingController();
  final List<TextEditingController> _otpControllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _otpFocusNodes = List.generate(6, (_) => FocusNode());

  bool _isLoading = false;
  bool _otpSent = false;
  String? _errorMessage;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      final args = ModalRoute.of(context)?.settings.arguments as String?;
      if (args != null && args.isNotEmpty) {
        _phoneController.text = args;
        // Automatically send OTP code on screen entry
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _sendOtp();
        });
      }
      _initialized = true;
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    for (final c in _otpControllers) {
      c.dispose();
    }
    for (final f in _otpFocusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  /// Send OTP to the entered phone number
  Future<void> _sendOtp() async {
    final phone = _phoneController.text.replaceAll(RegExp(r'\s+'), '').trim();
    if (phone.isEmpty) {
      setState(() => _errorMessage = 'Enter your phone number');
      return;
    }

    // Normalize: if starts with 0, replace with +254
    String formattedPhone = phone;
    if (phone.startsWith('0')) {
      formattedPhone = '+254${phone.substring(1)}';
    } else if (!phone.startsWith('+')) {
      formattedPhone = '+254$phone';
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final client = Supabase.instance.client;
      final isLoggedIn = client.auth.currentSession != null;

      if (isLoggedIn) {
        // If logged in, update the phone number attribute (sends verification SMS code)
        await client.auth.updateUser(
          UserAttributes(phone: formattedPhone),
        );
      } else {
        // If not logged in, request passwordless sign in OTP
        await client.auth.signInWithOtp(
          phone: formattedPhone,
        );
      }

      if (mounted) {
        setState(() {
          _otpSent = true;
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('OTP sent to $formattedPhone')),
        );
      }
    } on AuthException catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.message;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Failed to send OTP: $e';
        });
      }
    }
  }

  /// Verify the OTP code
  Future<void> _verifyOtp() async {
    final otp = _otpControllers.map((c) => c.text).join();
    if (otp.length < 6) {
      setState(() => _errorMessage = 'Enter the full 6-digit code');
      return;
    }

    String formattedPhone = _phoneController.text.replaceAll(RegExp(r'\s+'), '').trim();
    if (formattedPhone.startsWith('0')) {
      formattedPhone = '+254${formattedPhone.substring(1)}';
    } else if (!formattedPhone.startsWith('+')) {
      formattedPhone = '+254$formattedPhone';
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final client = Supabase.instance.client;
      final isLoggedIn = client.auth.currentSession != null;

      if (isLoggedIn) {
        // If logged in, verify OTP with phoneChange type
        await client.auth.verifyOTP(
          phone: formattedPhone,
          token: otp,
          type: OtpType.phoneChange,
        );

        // Sync profile in public.users database table
        final user = client.auth.currentUser;
        if (user != null) {
          final userEmail = user.email;
          final updates = <String, dynamic>{
            'id': user.id,
            'phone': formattedPhone,
          };
          if (userEmail != null && !userEmail.startsWith('user-')) {
            updates['email'] = userEmail;
          }
          await client.from('users').upsert(updates);
        }
      } else {
        // If not logged in, verify OTP with sms type (passwordless sign-in)
        await client.auth.verifyOTP(
          phone: formattedPhone,
          token: otp,
          type: OtpType.sms,
        );

        final user = client.auth.currentUser;
        if (user != null) {
          final userEmail = user.email;
          final updates = <String, dynamic>{
            'id': user.id,
            'phone': formattedPhone,
          };
          if (userEmail != null && !userEmail.startsWith('user-')) {
            updates['email'] = userEmail;
          }
          await client.from('users').upsert(updates);
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Phone verified successfully!')),
        );
        Navigator.pushReplacementNamed(context, '/role-selection');
      }
    } on AuthException catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.message;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Verification failed: $e';
        });
      }
    }
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
          'Phone Verification',
          style: GoogleFonts.poppins(
            color: AppColors.textLight,
            fontWeight: FontWeight.w700,
            fontSize: 20,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Center(
                child: Icon(
                  Icons.phone_android,
                  size: 80,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                _otpSent ? 'Enter verification code' : 'Verify your phone',
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textLight,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _otpSent
                    ? 'We sent a 6-digit code to your phone number.'
                    : 'Enter your phone number to receive an OTP code.',
                style: GoogleFonts.poppins(
                  color: AppColors.textGrey,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 32),

              // Error message
              if (_errorMessage != null) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Text(
                    _errorMessage!,
                    style: GoogleFonts.poppins(
                      color: Colors.red.shade700,
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              if (!_otpSent) ...[
                // Phone number input
                AppTextField(
                  controller: _phoneController,
                  label: 'Phone number',
                  hint: '0712345678',
                  prefixIcon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 24),

                // Send OTP button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _sendOtp,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(
                            'Send OTP',
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
              ] else ...[
                // OTP input fields
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(6, (index) {
                    return SizedBox(
                      width: 48,
                      height: 56,
                      child: TextField(
                        controller: _otpControllers[index],
                        focusNode: _otpFocusNodes[index],
                        textAlign: TextAlign.center,
                        keyboardType: TextInputType.number,
                        maxLength: 1,
                        style: GoogleFonts.poppins(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                        decoration: InputDecoration(
                          counterText: '',
                          filled: true,
                          fillColor: AppColors.cardLight,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(
                              color: AppColors.borderLight.withValues(alpha: 0.85),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(
                                color: AppColors.primary, width: 2),
                          ),
                        ),
                        onChanged: (value) {
                          if (value.isNotEmpty && index < 5) {
                            _otpFocusNodes[index + 1].requestFocus();
                          } else if (value.isEmpty && index > 0) {
                            _otpFocusNodes[index - 1].requestFocus();
                          }
                        },
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 24),

                // Verify button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _verifyOtp,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(
                            'Verify',
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 16),

                // Resend code
                Center(
                  child: TextButton(
                    onPressed: _isLoading ? null : _sendOtp,
                    child: Text(
                      'Resend code',
                      style: GoogleFonts.poppins(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 24),
              // Skip option (for email-verified users)
              Center(
                  child: TextButton(
                    onPressed: () {
                      Navigator.pushReplacementNamed(context, '/role-selection');
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
            ],
          ),
        ),
      ),
    );
  }
}
