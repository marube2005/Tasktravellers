// lib/pages/ride_tracking_screen.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:frontend/utils/constants.dart';
// import 'package:travelers_app/main.dart'; // Adjust import path

class LiveTrackingScreen extends StatelessWidget {
  const LiveTrackingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // --- 1. Map Background ---
          // In a real app, this would be the GoogleMap widget
          Image.network(
            'https://i.imgur.com/p4Co3g7.png', // Placeholder map image
            fit: BoxFit.cover,
            height: double.infinity,
            width: double.infinity,
          ),

          // --- 2. Map Control Buttons ---
          const _MapControlButtons(),
          
          // --- 3. Draggable Bottom Sheet ---
          DraggableScrollableSheet(
            initialChildSize: 0.5, // Start at 50% height
            minChildSize: 0.3,   // Can be dragged down to 30%
            maxChildSize: 0.9,   // Can be dragged up to 90%
            builder: (context, scrollController) {
              return ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20.0)),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(20.0)),
                    ),
                    child: _BottomSheetContent(scrollController: scrollController),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

// --- Reusable Component Widgets ---

class _MapControlButtons extends StatelessWidget {
  const _MapControlButtons();
  
  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 60,
      right: 16,
      child: Column(
        children: [
          _MapButton(icon: Icons.add, borderRadius: const BorderRadius.vertical(top: Radius.circular(12))),
          const SizedBox(height: 2),
          _MapButton(icon: Icons.remove, borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12))),
          const SizedBox(height: 16),
          _MapButton(icon: Icons.navigation_outlined, borderRadius: BorderRadius.circular(12)),
        ],
      ),
    );
  }
}

class _MapButton extends StatelessWidget {
  final IconData icon;
  final BorderRadius borderRadius;
  const _MapButton({required this.icon, required this.borderRadius});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: borderRadius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
        child: Container(
          width: 52,
          height: 52,
          color: Colors.black.withOpacity(0.5),
          child: Icon(icon, color: Colors.white, size: 28),
        ),
      ),
    );
  }
}

class _BottomSheetContent extends StatelessWidget {
  final ScrollController scrollController;
  const _BottomSheetContent({required this.scrollController});
  
  @override
  Widget build(BuildContext context) {
    return ListView(
      controller: scrollController,
      padding: const EdgeInsets.all(0),
      children: [
        // Drag Handle
        Center(
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 12.0),
            width: 40,
            height: 5,
            decoration: BoxDecoration(
              color: AppColors.handleColor,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
        // Driver Info
        const _DriverInfoSection(),
        // Details Grid
        const _DetailsGrid(),
        // Action Buttons
        const _ActionButtons(),
      ],
    );
  }
}

class _DriverInfoSection extends StatelessWidget {
  const _DriverInfoSection();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 32,
            backgroundImage: NetworkImage('https://picsum.photos/seed/driver/200'),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('John Doe', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                Row(
                  children: [
                    const Icon(Icons.star, color: Colors.yellow, size: 18),
                    const SizedBox(width: 4),
                    Text('4.8', style: TextStyle(color: AppColors.infoText, fontSize: 16)),
                  ],
                ),
              ],
            ),
          ),
          OutlinedButton(
            onPressed: () {},
            style: OutlinedButton.styleFrom(
              shape: const CircleBorder(),
              side: BorderSide(color: AppColors.primary, width: 2),
              minimumSize: const Size(52, 52),
            ),
            child: const Icon(Icons.share, color: AppColors.primary),
          ),
        ],
      ),
    );
  }
}

class _DetailsGrid extends StatelessWidget {
  const _DetailsGrid();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        childAspectRatio: 2.5, // Adjust ratio for better spacing
        mainAxisSpacing: 0,
        crossAxisSpacing: 16,
        children: const [
          _InfoTile(label: 'ETA', value: '15 mins'),
          _InfoTile(label: 'Status', value: 'In Transit'),
          _InfoTile(label: 'License Plate', value: 'KDA 001A'),
          _InfoTile(label: 'Vehicle Model', value: 'Nissan Urvan'),
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final String label;
  final String value;
  const _InfoTile({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.handleColor)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label, style: const TextStyle(color: AppColors.infoText, fontSize: 14)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _ActionButtons extends StatelessWidget {
  const _ActionButtons();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.call),
              label: const Text('Contact Driver'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
                minimumSize: const Size.fromHeight(56),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                textStyle: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.sos),
              label: const Text('SOS'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade600,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(56),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                textStyle: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}