import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:frontend/app.dart';
import 'package:frontend/models/user.dart';
import 'package:frontend/services/user_service.dart';
import 'package:frontend/services/booking_service.dart';
import 'package:frontend/themes/app_colors.dart';
import 'group_invite_share_screen.dart';
import 'ride_chat_screen.dart';
import 'ride_tracking_screen.dart';

class PassengerDashboardScreen extends StatefulWidget {
  const PassengerDashboardScreen({super.key});

  @override
  State<PassengerDashboardScreen> createState() => _PassengerDashboardScreenState();
}

class _PassengerDashboardScreenState extends State<PassengerDashboardScreen> {
  int _selectedIndex = 0;

  void changeTab(int index) {
    setState(() => _selectedIndex = index);
  }

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      const _HomeTab(),
      const _MyTripsTab(),
      const _ProfileTab(),
    ];

    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: pages),
      floatingActionButton: _selectedIndex == 0
          ? FloatingActionButton(
              onPressed: () => Navigator.pushNamed(context, '/create-group-ride'),
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: const CircleBorder(),
              child: const Icon(Icons.add, size: 28),
            )
          : null,
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  Widget _buildBottomNavBar() {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    
    return Container(
      decoration: BoxDecoration(
        color: isDarkMode ? AppColors.cardDark : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDarkMode ? AppColors.borderDark.withValues(alpha: 0.5) : AppColors.borderLight,
            width: 1,
          ),
        ),
      ),
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(0, Icons.home_rounded, 'Home'),
          _buildNavItem(1, Icons.card_travel_rounded, 'My Trips'),
          _buildNavItem(2, Icons.person_rounded, 'Profile'),
        ],
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = _selectedIndex == index;
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: () => _onItemTapped(index),
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected 
                  ? AppColors.primary.withValues(alpha: 0.15) 
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              icon,
              color: isSelected 
                  ? AppColors.primary 
                  : (isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600),
              size: 24,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.manrope(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: isSelected 
                  ? AppColors.primary 
                  : (isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600),
            ),
          ),
        ],
      ),
    );
  }
}

// =========================================================================
// HOME TAB
// =========================================================================
class _HomeTab extends StatefulWidget {
  const _HomeTab();

  @override
  State<_HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<_HomeTab> {
  bool _isLoading = true;
  String _userName = 'Alex';
  String? _avatarUrl;
  Map<String, dynamic>? _activeGroup;
  
  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }
  
  Future<void> _loadDashboardData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    
    try {
      final user = await UserService().fetchCurrentUserProfileModel();
      if (user != null) {
        if (mounted) {
          setState(() {
            if (user.name != null && user.name!.isNotEmpty) {
              _userName = user.name!.split(' ').first;
            }
            _avatarUrl = user.avatarUrl;
          });
        }
      }
      
      final client = Supabase.instance.client;
      final userId = client.auth.currentUser?.id;
      if (userId != null) {
        final response = await client
            .from('group_rides')
            .select()
            .eq('creator_id', userId)
            .order('created_at', ascending: false)
            .limit(1)
            .maybeSingle();
        
        if (mounted && response != null) {
          setState(() {
            _activeGroup = response;
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading dashboard data: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _loadDashboardData,
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  children: [
                    // Custom App Bar Header Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.directions_bus_rounded, color: AppColors.primary, size: 20),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Travelers',
                              style: GoogleFonts.manrope(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            Stack(
                              children: [
                                IconButton(
                                  icon: Icon(
                                    Icons.notifications_none_rounded,
                                    color: theme.colorScheme.onSurface,
                                  ),
                                  onPressed: () {},
                                ),
                                Positioned(
                                  right: 8,
                                  top: 8,
                                  child: Container(
                                    width: 8,
                                    height: 8,
                                    decoration: const BoxDecoration(
                                      color: Colors.red,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(width: 8),
                            CircleAvatar(
                              radius: 18,
                              backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                              backgroundImage: _avatarUrl != null && _avatarUrl!.isNotEmpty
                                  ? NetworkImage(_avatarUrl!)
                                  : null,
                              child: _avatarUrl != null && _avatarUrl!.isNotEmpty
                                  ? null
                                  : const Icon(Icons.person, size: 20, color: AppColors.primary),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    
                    // Greetings
                    Text(
                      'Hujambo, $_userName!',
                      style: GoogleFonts.manrope(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Where are we headed today?',
                      style: GoogleFonts.manrope(
                        fontSize: 14,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // "Create Group Ride" Banner Card
                    Container(
                      height: 185,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        image: const DecorationImage(
                          image: AssetImage('assets/matatu.png'),
                          fit: BoxFit.cover,
                        ),
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(24),
                          gradient: LinearGradient(
                            begin: Alignment.bottomRight,
                            end: Alignment.topLeft,
                            colors: [
                              Colors.black.withValues(alpha: 0.85),
                              Colors.black.withValues(alpha: 0.3),
                            ],
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(
                              'Create Group Ride',
                              style: GoogleFonts.manrope(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Coordinate with friends and split the\nfare seamlessly.',
                              style: GoogleFonts.manrope(
                                color: Colors.white.withValues(alpha: 0.85),
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 12),
                            ElevatedButton.icon(
                              onPressed: () => Navigator.pushNamed(context, '/create-group-ride'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              ),
                              icon: const Icon(Icons.group_add_rounded, size: 18),
                              label: const Text(
                                'Start New Group',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Active Groups header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'My Active Groups',
                          style: GoogleFonts.manrope(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        TextButton(
                          onPressed: () {},
                          child: Text(
                            'See all',
                            style: GoogleFonts.manrope(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _buildActiveGroupCard(),
                    const SizedBox(height: 28),

                    // Recent Trips
                    Text(
                      'Recent Trips',
                      style: GoogleFonts.manrope(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildRecentTripItem(
                      title: 'Mombasa Getaway',
                      subtitle: 'Luxury Coach • KSH 1,500',
                      timeAgo: '2 days ago',
                    ),
                    const SizedBox(height: 12),
                    _buildRecentTripItem(
                      title: 'Daily Commute',
                      subtitle: 'Matatu • KSH 180',
                      timeAgo: 'Oct 26',
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildActiveGroupCard() {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    
    final origin = _activeGroup?['origin'] as String? ?? 'Nairobi CBD';
    final destination = _activeGroup?['destination'] as String? ?? 'Nakuru';
    final currentPassengers = _activeGroup?['current_passengers'] as int? ?? 1;
    final maxPassengers = _activeGroup?['max_passengers'] as int? ?? 3;
    final status = _activeGroup?['status'] as String? ?? 'forming';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDarkMode ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDarkMode ? AppColors.borderDark.withValues(alpha: 0.5) : AppColors.borderLight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDarkMode ? 0.2 : 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // On Track / Status Capsule
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'ON TRACK',
                    style: GoogleFonts.manrope(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                      letterSpacing: 1.1,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 5,
                      height: 5,
                      decoration: const BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      status.toUpperCase(),
                      style: GoogleFonts.manrope(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          // Route Title
          Text(
            '$origin to $destination',
            style: GoogleFonts.manrope(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          
          const SizedBox(height: 16),
          // Passengers joined Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  _buildAvatarStack(),
                  const SizedBox(width: 8),
                  Text(
                    '+$currentPassengers',
                    style: GoogleFonts.manrope(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Confirmed',
                    style: GoogleFonts.manrope(
                      fontSize: 11,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$currentPassengers/$maxPassengers',
                    style: GoogleFonts.manrope(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: currentPassengers / maxPassengers,
              backgroundColor: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade100,
              color: AppColors.primary,
              minHeight: 4,
            ),
          ),
          
          const SizedBox(height: 20),
          // Actions: Chat and View Details (emerald outlined CTA)
          Row(
            children: [
              Expanded(
                child: TextButton.icon(
                  onPressed: () {
                    final rideMap = _activeGroup ?? {
                      'id': 'mock_ride_id',
                      'origin': origin,
                      'destination': destination,
                    };
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => RideChatScreen(
                          rideId: rideMap['id'] as String,
                          title: '$origin → $destination',
                        ),
                      ),
                    );
                  },
                  style: TextButton.styleFrom(
                    backgroundColor: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade100,
                    foregroundColor: theme.colorScheme.onSurface,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  icon: const Icon(Icons.chat_bubble_outline_rounded, size: 16),
                  label: const Text('Chat', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    final rideMap = _activeGroup ?? {
                      'id': 'mock_ride_id',
                      'origin': origin,
                      'destination': destination,
                      'invite_link': 'https://travelersapp.co.ke/join/mock',
                      'acceptance_code': 'MOCK12',
                      'group_size': maxPassengers,
                      'group_note': 'Trip to Nakuru',
                    };
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => GroupInviteShareScreen(ride: rideMap),
                      ),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary, width: 1.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text('View Details', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarStack() {
    final theme = Theme.of(context);
    final borderCol = theme.cardTheme.color ?? theme.scaffoldBackgroundColor;
    
    return SizedBox(
      width: 48,
      height: 24,
      child: Stack(
        children: [
          Positioned(
            left: 0,
            child: CircleAvatar(
              radius: 12,
              backgroundColor: borderCol,
              child: const CircleAvatar(
                radius: 10,
                child: Icon(Icons.person, size: 12),
              ),
            ),
          ),
          Positioned(
            left: 12,
            child: CircleAvatar(
              radius: 12,
              backgroundColor: borderCol,
              child: const CircleAvatar(
                radius: 10,
                backgroundColor: AppColors.primary,
                child: Icon(Icons.person, size: 12, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentTripItem({
    required String title,
    required String subtitle,
    required String timeAgo,
  }) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: isDarkMode ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDarkMode ? AppColors.borderDark.withValues(alpha: 0.5) : AppColors.borderLight,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.directions_bus_rounded,
              color: AppColors.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.manrope(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: GoogleFonts.manrope(
                    fontSize: 12,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                timeAgo,
                style: GoogleFonts.manrope(
                  fontSize: 11,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 4),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 12,
                color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// =========================================================================
// MY TRIPS TAB
// =========================================================================
class _MyTripsTab extends StatefulWidget {
  const _MyTripsTab();

  @override
  State<_MyTripsTab> createState() => _MyTripsTabState();
}

class _MyTripsTabState extends State<_MyTripsTab> {
  final BookingService _bookingService = BookingService();
  bool _isLoading = true;
  List<Map<String, dynamic>> _trips = [];

  @override
  void initState() {
    super.initState();
    _loadTrips();
  }

  Future<void> _loadTrips() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final trips = await _bookingService.fetchMyBookedRides();
      if (mounted) {
        setState(() {
          _trips = trips;
        });
      }
    } catch (e) {
      debugPrint('Error loading trips: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'My Trips',
          style: GoogleFonts.manrope(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _trips.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _loadTrips,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _trips.length,
                    itemBuilder: (context, index) {
                      final trip = _trips[index];
                      final ride = trip['rides'] as Map<String, dynamic>? ?? {};
                      return _buildTripCard(ride);
                    },
                  ),
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.card_travel_rounded, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'No upcoming trips',
              style: GoogleFonts.manrope(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Join a ride pool or create a new group to start your journey.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, '/create-group-ride'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              child: const Text('Book a Ride'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTripCard(Map<String, dynamic> ride) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final origin = ride['origin'] as String? ?? 'Unknown';
    final destination = ride['destination'] as String? ?? 'Unknown';
    final status = ride['status'] as String? ?? 'open';
    final fare = ride['estimated_fare']?.toString() ?? 'TBD';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDarkMode ? AppColors.borderDark.withValues(alpha: 0.5) : AppColors.borderLight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  status.toUpperCase(),
                  style: GoogleFonts.manrope(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
              Text(
                'Ksh $fare',
                style: GoogleFonts.manrope(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.location_on_outlined, size: 16, color: Colors.grey),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '$origin → $destination',
                  style: GoogleFonts.manrope(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => LiveTrackingScreen(rideId: ride['id'] as String?),
                      ),
                    );
                  },
                  child: const Text('Track Ride'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => GroupInviteShareScreen(ride: ride),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Invite Details'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// =========================================================================
// PROFILE TAB
// =========================================================================
class _ProfileTab extends ConsumerWidget {
  const _ProfileTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    
    // Watch current theme mode
    final themeMode = ref.watch(themeModeProvider);
    final isDarkSwitchActive = themeMode == ThemeMode.dark || 
        (themeMode == ThemeMode.system && MediaQuery.of(context).platformBrightness == Brightness.dark);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: FutureBuilder<AppUser?>(
          future: UserService().fetchCurrentUserProfileModel(),
          builder: (context, snapshot) {
            final user = snapshot.data;
            final name = user?.name ?? 'Alex Maina';
            
            final memberYear = user?.createdAt != null 
                ? user!.createdAt!.year.toString() 
                : '2022';
            final subtext = 'Premium Traveler • Member since $memberYear';

            return ListView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              children: [
                // Custom App Bar Header Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        IconButton(
                          icon: Icon(Icons.arrow_back, color: theme.colorScheme.onSurface),
                          onPressed: () {
                            final dashboardState = context.findAncestorStateOfType<_PassengerDashboardScreenState>();
                            dashboardState?.changeTab(0);
                          },
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'SafariSync',
                          style: GoogleFonts.manrope(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: Icon(Icons.notifications_none_rounded, color: theme.colorScheme.onSurface),
                      onPressed: () {},
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // User Avatar Profile Area
                Center(
                  child: Column(
                    children: [
                      // Ring avatar
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: 104,
                            height: 104,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: AppColors.primary, width: 2),
                            ),
                            child: CircleAvatar(
                              radius: 48,
                              backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                              backgroundImage: user?.avatarUrl != null && user!.avatarUrl!.isNotEmpty
                                  ? NetworkImage(user.avatarUrl!)
                                  : null,
                              child: user?.avatarUrl != null && user!.avatarUrl!.isNotEmpty
                                  ? null
                                  : const Icon(Icons.person, size: 52, color: AppColors.primary),
                            ),
                          ),
                          // Rating Badge Overlay
                          Positioned(
                            bottom: 0,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.orange.shade800,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Colors.black26,
                                    blurRadius: 4,
                                    offset: Offset(0, 2),
                                  )
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '4.9',
                                    style: GoogleFonts.manrope(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(width: 2),
                                  const Icon(Icons.star_rounded, size: 12, color: Colors.white),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Full name
                      Text(
                        name,
                        style: GoogleFonts.manrope(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      // Sub-info
                      Text(
                        subtext,
                        style: GoogleFonts.manrope(
                          fontSize: 13,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Settings Cards list
                _buildSettingsOptionCard(
                  title: 'Personal Info',
                  subtitle: 'Manage identity and documents',
                  icon: Icons.person_outline_rounded,
                  iconColor: const Color(0xFF2E7D32),
                  iconBgColor: const Color(0xFFE8F5E9),
                  theme: theme,
                  onTap: () {
                    Navigator.pushNamed(context, '/passenger-profile-setup');
                  },
                ),
                const SizedBox(height: 12),
                _buildSettingsOptionCard(
                  title: 'Emergency Contact',
                  subtitle: 'Safety and SOS settings',
                  icon: Icons.emergency_outlined,
                  iconColor: const Color(0xFFC62828),
                  iconBgColor: const Color(0xFFFFEBEE),
                  theme: theme,
                  onTap: () {
                    Navigator.pushNamed(context, '/passenger-profile-setup');
                  },
                ),
                const SizedBox(height: 12),
                _buildSettingsOptionCard(
                  title: 'Payment History',
                  subtitle: 'Transactions and receipts',
                  icon: Icons.account_balance_wallet_outlined,
                  iconColor: const Color(0xFFEF6C00),
                  iconBgColor: const Color(0xFFFFF3E0),
                  theme: theme,
                  onTap: () {
                    Navigator.pushNamed(context, '/payment');
                  },
                ),
                const SizedBox(height: 12),
                _buildSettingsOptionCard(
                  title: 'Legal & FAQ',
                  subtitle: 'Privacy, Terms, and Help',
                  icon: Icons.gavel_rounded,
                  iconColor: const Color(0xFF37474F),
                  iconBgColor: const Color(0xFFECEFF1),
                  theme: theme,
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Travelers Terms & FAQ loaded.')),
                    );
                  },
                ),
                const SizedBox(height: 20),

                // Appearance Toggle Card
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: isDarkMode ? AppColors.cardDark : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isDarkMode ? AppColors.borderDark.withValues(alpha: 0.5) : AppColors.borderLight,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.dark_mode_outlined,
                          color: AppColors.primary,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          'Appearance',
                          style: GoogleFonts.manrope(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                      ),
                      Switch(
                        value: isDarkSwitchActive,
                        activeThumbColor: AppColors.primary,
                        onChanged: (value) {
                          ref.read(themeModeProvider.notifier).state = 
                              value ? ThemeMode.dark : ThemeMode.light;
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Sign Out row button
                Center(
                  child: TextButton.icon(
                    onPressed: () async {
                      await Supabase.instance.client.auth.signOut();
                      if (context.mounted) {
                        Navigator.pushReplacementNamed(context, '/login');
                      }
                    },
                    icon: const Icon(Icons.logout_rounded, color: Colors.red, size: 20),
                    label: Text(
                      'Sign Out',
                      style: GoogleFonts.manrope(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildSettingsOptionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required ThemeData theme,
    required VoidCallback onTap,
  }) {
    final isDarkMode = theme.brightness == Brightness.dark;
    
    return Container(
      decoration: BoxDecoration(
        color: isDarkMode ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDarkMode ? AppColors.borderDark.withValues(alpha: 0.5) : AppColors.borderLight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDarkMode ? 0.2 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isDarkMode ? iconColor.withValues(alpha: 0.2) : iconBgColor,
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: isDarkMode ? iconColor.withValues(alpha: 0.9) : iconColor,
            size: 22,
          ),
        ),
        title: Text(
          title,
          style: GoogleFonts.manrope(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: theme.colorScheme.onSurface,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: GoogleFonts.manrope(
            fontSize: 12,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios_rounded,
          size: 14,
          color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
        ),
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }
}
