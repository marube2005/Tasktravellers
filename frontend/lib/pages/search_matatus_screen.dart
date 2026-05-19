// lib/pages/search_matatus_screen.dart
import 'package:flutter/material.dart';
import 'package:frontend/utils/constants.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// A simple data model for a Matatu
class Matatu {
  final String id;
  final String plate;
  final String capacity;
  final String route;
  final bool isAvailable;
  final int price;
  final String? imageUrl;
  final String? saccoName;

  Matatu({
    required this.id,
    required this.plate,
    required this.capacity,
    required this.route,
    required this.isAvailable,
    required this.price,
    this.imageUrl,
    this.saccoName,
  });

  factory Matatu.fromJson(Map<String, dynamic> json) {
    final sacco = json['sacco'] as Map<String, dynamic>?;
    return Matatu(
      id: json['id'] as String? ?? '',
      plate: json['plate_number'] as String? ?? 'Unknown',
      capacity: '${json['capacity'] ?? 0} Seater',
      route: json['route'] as String? ?? 'Unknown route',
      isAvailable: json['is_available'] as bool? ?? false,
      price: json['price'] as int? ?? 0,
      imageUrl: json['image_url'] as String?,
      saccoName: sacco?['name'] as String?,
    );
  }
}

class MatatuListScreen extends StatefulWidget {
  const MatatuListScreen({super.key});

  @override
  State<MatatuListScreen> createState() => _MatatuListScreenState();
}

class _MatatuListScreenState extends State<MatatuListScreen> {
  List<Matatu> _matatus = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadVehicles();
  }

  Future<void> _loadVehicles() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await Supabase.instance.client
          .from('vehicles')
          .select('*, sacco:sacco_id(name, is_verified)')
          .eq('is_available', true)
          .order('created_at', ascending: false);

      final List<dynamic> data = response as List<dynamic>;
      if (mounted) {
        setState(() {
          _matatus = data.map((json) => Matatu.fromJson(json as Map<String, dynamic>)).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _loadVehicles,
        child: CustomScrollView(
          slivers: [
            // The top app bar
            SliverAppBar(
              title: const Text('Travelers App'),
              leading: const Icon(Icons.directions_bus),
              actions: [
                IconButton(icon: const Icon(Icons.search), onPressed: () {}),
                IconButton(icon: const Icon(Icons.refresh), onPressed: _loadVehicles),
              ],
              pinned: true,
              floating: true,
            ),
            // The sticky filter bar
            SliverPersistentHeader(
              pinned: true,
              delegate: _FilterBarDelegate(),
            ),
            // Loading state
            if (_isLoading)
              const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              )
            // Error state
            else if (_error != null)
              SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 48, color: Colors.red),
                      const SizedBox(height: 16),
                      Text('Error: $_error'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadVehicles,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              )
            // Empty state
            else if (_matatus.isEmpty)
              const SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.directions_bus_outlined, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('No vehicles available', style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                ),
              )
            // The main list of matatu cards
            else
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
      backgroundColor: AppColors.primary.withValues(alpha: 0.1),
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
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12.0),
            child: matatu.imageUrl != null && matatu.imageUrl!.isNotEmpty
                ? Image.network(
                    matatu.imageUrl!,
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stack) => Container(
                      width: 80,
                      height: 80,
                      color: Colors.grey.shade200,
                      child: const Icon(Icons.directions_bus, size: 40, color: Colors.grey),
                    ),
                  )
                : Container(
                    width: 80,
                    height: 80,
                    color: Colors.grey.shade200,
                    child: const Icon(Icons.directions_bus, size: 40, color: Colors.grey),
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