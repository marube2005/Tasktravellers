import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geolocator/geolocator.dart';
import '../themes/app_colors.dart';
import '../services/location_service.dart';

/// Permissions prompt screen — requests location access and notification
/// permissions before entering the main app.
class PermissionsScreen extends StatefulWidget {
  const PermissionsScreen({super.key});

  @override
  State<PermissionsScreen> createState() => _PermissionsScreenState();
}

class _PermissionsScreenState extends State<PermissionsScreen> {
  bool _locationGranted = false;
  bool _notificationsGranted = false;

  @override
  void initState() {
    super.initState();
    _checkExistingPermissions();
  }

  Future<void> _checkExistingPermissions() async {
    // Check if location is already granted
    final permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse) {
      setState(() => _locationGranted = true);
    } else if (permission == LocationPermission.deniedForever) {
      _showSettingsDialog();
    }
  }

  Future<void> _requestLocation() async {
    final permission = await LocationService().requestPermission();
    
    if (mounted) {
      if (permission == LocationPermission.always ||
          permission == LocationPermission.whileInUse) {
        setState(() {
          _locationGranted = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location access granted')),
        );
      } else if (permission == LocationPermission.deniedForever) {
        _showSettingsDialog();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location permission denied')),
        );
      }
    }
  }

  void _showSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Location Permission'),
        content: const Text(
          'Location permission is permanently denied. Please enable it in app settings to use ride tracking features.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              LocationService().openAppSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  Future<void> _requestNotifications() async {
    // In production: use permission_handler or firebase_messaging
    // final status = await Permission.notification.request();
    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) {
      setState(() => _notificationsGranted = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Notifications enabled')),
      );
    }
  }

  void _continue() {
    Navigator.pushReplacementNamed(context, '/dashboard');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            children: [
              const Spacer(flex: 1),

              // Icon
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Icon(
                  Icons.tune,
                  size: 50,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 28),

              Text(
                'Enable Permissions',
                style: GoogleFonts.manrope(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textLight,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'We need a few permissions to give you the best experience.',
                textAlign: TextAlign.center,
                style: GoogleFonts.manrope(
                  color: AppColors.textGrey,
                  fontSize: 15,
                ),
              ),

              const Spacer(flex: 1),

              // Location permission
              _PermissionTile(
                icon: Icons.location_on_outlined,
                title: 'Location Access',
                subtitle: 'Find nearby matatus and track your ride.',
                isGranted: _locationGranted,
                onTap: _locationGranted ? null : _requestLocation,
              ),
              const SizedBox(height: 16),

              // Notifications permission
              _PermissionTile(
                icon: Icons.notifications_outlined,
                title: 'Notifications',
                subtitle: 'Get ride updates and group alerts.',
                isGranted: _notificationsGranted,
                onTap: _notificationsGranted ? null : _requestNotifications,
              ),

              const Spacer(flex: 2),

              // Continue button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _continue,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    'Continue',
                    style: GoogleFonts.manrope(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Skip
              TextButton(
                onPressed: _continue,
                child: Text(
                  'Skip for now',
                  style: GoogleFonts.manrope(
                    color: AppColors.textGrey,
                    fontSize: 14,
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

class _PermissionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isGranted;
  final VoidCallback? onTap;

  const _PermissionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isGranted,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isGranted ? Colors.green.shade300 : Colors.grey.shade200,
            width: isGranted ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: isGranted
                  ? Colors.green.shade50
                  : AppColors.primary.withValues(alpha: 0.1),
              child: Icon(
                isGranted ? Icons.check_circle : icon,
                color: isGranted ? Colors.green : AppColors.primary,
                size: 28,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.manrope(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.manrope(
                      fontSize: 13,
                      color: AppColors.textGrey,
                    ),
                  ),
                ],
              ),
            ),
            if (!isGranted)
              Icon(Icons.chevron_right, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }
}
