-// lib/matatu_list_screen.dart
import 'package:flutter/material.dart';
import 'package:travelers_app/main.dart'; // Adjust import path

// A simple data model for a Matatu
class Matatu {
  final String plate;
  final String capacity;
  final String route;
  final bool isAvailable;
  final int price;
  final String imageUrl;

  Matatu({
    required this.plate,
    required this.capacity,
    required this.route,
    required this.isAvailable,
    required this.price,
    required this.imageUrl,
  });
}

class MatatuListScreen extends StatelessWidget {
  const MatatuListScreen({super.key});

  // Dummy data for the list
  static final List<Matatu> _matatus = [
    Matatu(plate: 'KBC 123A', capacity: '14 Seater', route: 'Nairobi - Nakuru', isAvailable: true, price: 500, imageUrl: 'https://picsum.photos/seed/1/200'),
    Matatu(plate: 'KDE 456B', capacity: '33 Seater', route: 'Nairobi - Mombasa', isAvailable: true, price: 700, imageUrl: 'https://picsum.photos/seed/2/200'),
    Matatu(plate: 'KFG 789C', capacity: '14 Seater', route: 'Nairobi - Thika', isAvailable: true, price: 300, imageUrl: 'https://picsum.photos/seed/3/200'),
    Matatu(plate: 'KGH 012D', capacity: '25 Seater', route: 'Nairobi - Kisumu', isAvailable: false, price: 1200, imageUrl: 'https://picsum.photos/seed/4/200'),
    Matatu(plate: 'KJL 345E', capacity: '14 Seater', route: 'Nairobi - Machakos', isAvailable: true, price: 450, imageUrl: 'https://picsum.photos/seed/5/200'),
    Matatu(plate: 'KMN 678F', capacity: '11 Seater', route: 'Nakuru - Naivasha', isAvailable: true, price: 200, imageUrl: 'https://picsum.photos/seed/6/200'),
  ];


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // The top app bar
          SliverAppBar(
            title: const Text('Travelers App'),
            leading: const Icon(Icons.directions_bus),
            actions: [
              IconButton(icon: const Icon(Icons.search), onPressed: () {}),
            ],
            pinned: true,
            floating: true,
          ),
          // The sticky filter bar
          SliverPersistentHeader(
            pinned: true,
            delegate: _FilterBarDelegate(),
          ),
          // The main list of matatu cards
          SliverPadding(
            padding: const EdgeInsets.all(16.0),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: MatatuCard(matatu: _matatus[index]),
                  );
                },
                childCount: _matatus.length,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Delegate for creating the sticky filter bar
class _FilterBarDelegate extends SliverPersistentHeaderDelegate {
  @override
  double get minExtent => 68.0; // Height of the bar + padding
  @override
  double get maxExtent => 68.0;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    final theme = Theme.of(context);
    return Container(
      color: theme.scaffoldBackgroundColor,
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: const [
          FilterChipButton(icon: Icons.groups_outlined, label: 'Capacity'),
          SizedBox(width: 8),
          FilterChipButton(icon: Icons.route_outlined, label: 'Route'),
          SizedBox(width: 8),
          FilterChipButton(icon: Icons.payments_outlined, label: 'Price Range'),
        ],
      ),
    );
  }

  @override
  bool shouldRebuild(_FilterBarDelegate oldDelegate) => false;
}

// A reusable filter chip widget
class FilterChipButton extends StatelessWidget {
  final IconData icon;
  final String label;
  const FilterChipButton({super.key, required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(icon, size: 18, color: AppColors.primary),
      label: Row(
        children: [
          Text(label, style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w500)),
          const Icon(Icons.arrow_drop_down, color: AppColors.primary),
        ],
      ),
      backgroundColor: AppColors.primary.withOpacity(0.1),
      shape: const StadiumBorder(),
      padding: const EdgeInsets.symmetric(horizontal: 8),
    );
  }
}

// A reusable card widget for displaying matatu info
class MatatuCard extends StatelessWidget {
  final Matatu matatu;
  const MatatuCard({super.key, required this.matatu});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: isDarkMode ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(16.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12.0),
            child: Image.network(
              matatu.imageUrl,
              width: 80,
              height: 80,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(matatu.plate, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Text(matatu.capacity, style: TextStyle(color: Colors.grey.shade500, fontSize: 14)),
                Text(matatu.route, style: TextStyle(color: Colors.grey.shade500, fontSize: 14)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      width: 8, height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: matatu.isAvailable ? Colors.green.shade500 : Colors.red.shade500,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      matatu.isAvailable ? 'Available' : 'Unavailable',
                      style: TextStyle(
                        color: matatu.isAvailable ? Colors.green.shade600 : Colors.red.shade600,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Text(
            'Ksh ${matatu.price}',
            style: const TextStyle(
              color: AppColors.cornflowerBlue,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ],
      ),
    );
  }
}