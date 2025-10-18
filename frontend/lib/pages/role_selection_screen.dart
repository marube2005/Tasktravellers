// lib/role_selection_screen.dart
import 'package:flutter/material.dart';
import 'package:travelers_app/main.dart'; // Adjust import path

// Define an enum for the roles for type safety
enum AppRole { passenger, sacco }

class RoleSelectionScreen extends StatefulWidget {
  const RoleSelectionScreen({super.key});

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen> {
  // State variable to hold the selected role
  AppRole? _selectedRole;

  void _selectRole(AppRole role) {
    setState(() {
      _selectedRole = role;
    });
  }

  void _continue() {
    if (_selectedRole != null) {
      // Navigate to the next screen based on the role
      // Example: Navigator.of(context).push(...)
      print('Selected Role: $_selectedRole');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Continuing as ${_selectedRole!.name}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Choose Your Role'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 8.0, bottom: 24.0),
                child: Text(
                  'How will you use the app? Select your role to get started.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                ),
              ),
              RoleCard(
                icon: Icons.person_outline,
                title: 'Passenger',
                subtitle: 'Find and book your next trip.',
                isSelected: _selectedRole == AppRole.passenger,
                onTap: () => _selectRole(AppRole.passenger),
              ),
              const SizedBox(height: 16),
              RoleCard(
                icon: Icons.directions_bus_outlined,
                title: 'Sacco',
                subtitle: 'Manage your fleet and rides.',
                isSelected: _selectedRole == AppRole.sacco,
                onTap: () => _selectRole(AppRole.sacco),
              ),
              const Spacer(), // Pushes the button to the bottom
              ElevatedButton(
                // Button is disabled if no role is selected
                onPressed: _selectedRole == null ? null : _continue,
                child: const Text('Continue'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Reusable card widget to avoid code duplication
class RoleCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isSelected;
  final VoidCallback onTap;

  const RoleCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isSelected
        ? AppColors.primary
        : (isDarkMode ? AppColors.borderDark : AppColors.borderLight);
    final titleColor = isSelected ? AppColors.primary : null;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(24.0),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withOpacity(0.1) : null,
          border: Border.all(color: borderColor, width: isSelected ? 2.0 : 1.0),
          borderRadius: BorderRadius.circular(16.0), // rounded-xl
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24, // size-12 equivalent
              backgroundColor: isDarkMode ? AppColors.iconBgDark : AppColors.iconBgLight,
              child: Icon(
                icon,
                size: 28,
                color: isSelected ? AppColors.primary : (isDarkMode ? AppColors.borderDark : AppColors.borderLight),
              ),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: titleColor,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey.shade500,
                      ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}