import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../themes/app_colors.dart';

class OtpVerificationScreen extends StatefulWidget {
  const OtpVerificationScreen({super.key});

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final List<TextEditingController> _otpControllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _otpFocusNodes = List.generate(6, (_) => FocusNode());

  bool _isLoading = false;
  String? _errorMessage;
  String _phoneNumber = '';
  
  // Timer state
  int _secondsRemaining = 45;
  Timer? _timer;
  bool _canResend = false;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Retrieve phone number passed from sign-up screen
    final args = ModalRoute.of(context)?.settings.arguments as String?;
    if (args != null && args.isNotEmpty) {
      // Normalize format for display
      String displayPhone = args.trim();
      if (displayPhone.startsWith('0') && displayPhone.length == 10) {
        displayPhone = '+254 ${displayPhone.substring(1, 4)} ${displayPhone.substring(4, 7)} ${displayPhone.substring(7)}';
      }
      setState(() {
        _phoneNumber = displayPhone;
      });
      
      // Trigger OTP send automatically on load (Supabase auth.signUp already triggers it automatically,
      // but in case it needs to be sent again or initialized)
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _sendOtpSilent();
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (final c in _otpControllers) {
      c.dispose();
    }
    for (final f in _otpFocusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  void _startTimer() {
    setState(() {
      _secondsRemaining = 45;
      _canResend = false;
    });
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining == 0) {
        setState(() {
          _canResend = true;
          _timer?.cancel();
        });
      } else {
        setState(() {
          _secondsRemaining--;
        });
      }
    });
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  Future<void> _sendOtpSilent() async {
    final rawPhone = ModalRoute.of(context)?.settings.arguments as String?;
    if (rawPhone == null || rawPhone.isEmpty) return;

    final phone = rawPhone.replaceAll(RegExp(r'\s+'), '').trim();
    String formattedPhone = phone;
    if (phone.startsWith('0')) {
      formattedPhone = '+254${phone.substring(1)}';
    } else if (!phone.startsWith('+')) {
      formattedPhone = '+254$phone';
    }

    try {
      final client = Supabase.instance.client;
      final isLoggedIn = client.auth.currentSession != null;

      if (isLoggedIn) {
        await client.auth.updateUser(
          UserAttributes(phone: formattedPhone),
        );
      } else {
        await client.auth.signInWithOtp(
          phone: formattedPhone,
        );
      }
    } catch (_) {
      // Fail silently on initial load since Supabase already triggers OTP on signUp
    }
  }

  Future<void> _resendOtp() async {
    if (!_canResend) return;
    
    final rawPhone = ModalRoute.of(context)?.settings.arguments as String?;
    if (rawPhone == null || rawPhone.isEmpty) {
      setState(() => _errorMessage = 'Phone number missing');
      return;
    }

    final phone = rawPhone.replaceAll(RegExp(r'\s+'), '').trim();
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
        await client.auth.updateUser(
          UserAttributes(phone: formattedPhone),
        );
      } else {
        await client.auth.signInWithOtp(
          phone: formattedPhone,
        );
      }

      _startTimer();
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('OTP code resent to $formattedPhone')),
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
          _errorMessage = 'Failed to resend OTP: $e';
        });
      }
    }
  }

  Future<void> _verifyOtp() async {
    final otp = _otpControllers.map((c) => c.text).join();
    if (otp.length < 6) {
      setState(() => _errorMessage = 'Enter the full 6-digit code');
      return;
    }

    final rawPhone = ModalRoute.of(context)?.settings.arguments as String?;
    if (rawPhone == null || rawPhone.isEmpty) {
      setState(() => _errorMessage = 'Phone number missing');
      return;
    }

    final phone = rawPhone.replaceAll(RegExp(r'\s+'), '').trim();
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
        await client.auth.verifyOTP(
          phone: formattedPhone,
          token: otp,
          type: OtpType.phoneChange,
        );

        // Sync verified phone to public.users table
        final userId = client.auth.currentUser?.id;
        if (userId != null) {
          await client.from('users').update({'phone': formattedPhone}).eq('id', userId);
        }
      } else {
        await client.auth.verifyOTP(
          phone: formattedPhone,
          token: otp,
          type: OtpType.sms,
        );
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
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: theme.colorScheme.onSurface),
          onPressed: () => Navigator.of(context).pop(),
        ),
        centerTitle: true,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: isDarkMode ? Colors.white.withValues(alpha: 0.1) : AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(
                Icons.directions_bus_rounded,
                color: isDarkMode ? Colors.white : AppColors.primary,
                size: 18,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Travelers',
              style: GoogleFonts.manrope(
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.w800,
                fontSize: 18,
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              
              // Shield and phone illustration container
              Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  color: isDarkMode ? theme.colorScheme.primary.withValues(alpha: 0.15) : const Color(0xFFF1F8F3),
                  borderRadius: BorderRadius.circular(28),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Phone mockup widget
                    Container(
                      width: 60,
                      height: 100,
                      decoration: BoxDecoration(
                        color: theme.cardTheme.color ?? (isDarkMode ? AppColors.cardDark : Colors.white),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: isDarkMode ? AppColors.borderDark : AppColors.borderLight, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: isDarkMode ? 0.2 : 0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          )
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const SizedBox(height: 8),
                          // Screen content lines
                          Column(
                            children: List.generate(4, (i) => Container(
                              height: 3,
                              width: 32,
                              margin: const EdgeInsets.symmetric(vertical: 2.5),
                              decoration: BoxDecoration(
                                color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            )),
                          ),
                          // Home button indicator
                          Container(
                            height: 3,
                            width: 20,
                            margin: const EdgeInsets.only(bottom: 6),
                            decoration: BoxDecoration(
                              color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade300,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Floating shield badge with checkmark
                    Positioned(
                      right: 32,
                      bottom: 32,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary,
                          shape: BoxShape.circle,
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 8,
                              offset: Offset(0, 2),
                            )
                          ],
                        ),
                        child: Icon(
                          Icons.check,
                          color: theme.colorScheme.onPrimary,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 32),
              
              Text(
                'Verify Phone',
                style: GoogleFonts.manrope(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Enter the 6-digit code sent to\n$_phoneNumber',
                textAlign: TextAlign.center,
                style: GoogleFonts.manrope(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontSize: 15,
                  height: 1.4,
                ),
              ),
              
              const SizedBox(height: 32),

              if (_errorMessage != null) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDarkMode ? const Color(0x33BA1A1A) : Colors.red.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: isDarkMode ? AppColors.error : Colors.red.shade200),
                  ),
                  child: Text(
                    _errorMessage!,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.manrope(
                      color: isDarkMode ? Colors.red.shade300 : Colors.red.shade700,
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // 6-digit OTP code inputs
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(6, (index) {
                  return SizedBox(
                    width: 46,
                    height: 56,
                    child: TextField(
                      controller: _otpControllers[index],
                      focusNode: _otpFocusNodes[index],
                      textAlign: TextAlign.center,
                      keyboardType: TextInputType.number,
                      maxLength: 1,
                      style: GoogleFonts.manrope(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                      decoration: InputDecoration(
                        counterText: '',
                        filled: true,
                        fillColor: theme.inputDecorationTheme.fillColor ??
                            (isDarkMode ? AppColors.cardDark : AppColors.cardLight),
                        contentPadding: EdgeInsets.zero,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: isDarkMode ? AppColors.borderDark : AppColors.borderLight,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: isDarkMode ? AppColors.borderDark : AppColors.borderLight,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: AppColors.primary,
                            width: 2,
                          ),
                        ),
                      ),
                      onChanged: (value) {
                        if (value.isNotEmpty && index < 5) {
                          _otpFocusNodes[index + 1].requestFocus();
                        } else if (value.isEmpty && index > 0) {
                          _otpFocusNodes[index - 1].requestFocus();
                        }
                        
                        // Try to auto-submit when the last box is filled
                        if (index == 5 && value.isNotEmpty) {
                          final fullOtp = _otpControllers.map((c) => c.text).join();
                          if (fullOtp.length == 6) {
                            _verifyOtp();
                          }
                        }
                      },
                    ),
                  );
                }),
              ),
              
              const SizedBox(height: 32),
              
              // Countdown & Resend
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Didn't receive code? ",
                    style: GoogleFonts.manrope(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontSize: 14,
                    ),
                  ),
                  _canResend
                      ? GestureDetector(
                          onTap: _isLoading ? null : _resendOtp,
                          child: Text(
                            'Resend code',
                            style: GoogleFonts.manrope(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                        )
                      : Text(
                          'Resend code in ${_formatTime(_secondsRemaining)}',
                          style: GoogleFonts.manrope(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                ],
              ),
              
              const SizedBox(height: 40),
              
              // Verify & Continue Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _verifyOtp,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? CircularProgressIndicator(color: theme.colorScheme.onPrimary)
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Verify & Continue',
                              style: GoogleFonts.manrope(
                                color: theme.colorScheme.onPrimary,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              Icons.arrow_forward,
                              color: theme.colorScheme.onPrimary,
                              size: 18,
                            ),
                          ],
                        ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Secure badge
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.lock_outline_rounded,
                    color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Secure end-to-end verification',
                    style: GoogleFonts.manrope(
                      color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
