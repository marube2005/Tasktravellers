import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/location_service.dart';
import '../../../services/supabase_service.dart';
import '../../../widgets/bottom_nav_bar.dart';
import '../../themes/app_colors.dart';
import '../../widgets/route_preview_map.dart';
import 'group_invite_share_screen.dart';

class CreateGroupRideScreen extends StatefulWidget {
  const CreateGroupRideScreen({super.key});

  @override
  State<CreateGroupRideScreen> createState() => _CreateGroupRideScreenState();
}

class _CreateGroupRideScreenState extends State<CreateGroupRideScreen> {
  final TextEditingController _originController = TextEditingController();
  final TextEditingController _destinationController = TextEditingController();
  
  String _scheduleType = 'Now';
  DateTime? _scheduledDateTime;
  int _maxPassengers = 3;
  bool _isCreating = false;
  bool _isFetchingLocation = false;

  double? _originLat;
  double? _originLng;
  double? _destLat;
  double? _destLng;

  List<UserLocationResult> _originSuggestions = [];
  List<UserLocationResult> _destinationSuggestions = [];
  bool _isSearchingOrigin = false;
  bool _isSearchingDestination = false;

  void _onOriginChanged(String text) {
    if (text.trim().length < 2) {
      if (_originSuggestions.isNotEmpty) {
        setState(() => _originSuggestions = []);
      }
      return;
    }
    setState(() => _isSearchingOrigin = true);
    LocationService().searchAddressSuggestions(text).then((results) {
      if (mounted) {
        setState(() {
          _originSuggestions = results;
          _isSearchingOrigin = false;
        });
      }
    }).catchError((_) {
      if (mounted) setState(() => _isSearchingOrigin = false);
    });
  }

  void _onDestinationChanged(String text) {
    if (text.trim().length < 2) {
      if (_destinationSuggestions.isNotEmpty) {
        setState(() => _destinationSuggestions = []);
      }
      return;
    }
    setState(() => _isSearchingDestination = true);
    LocationService().searchAddressSuggestions(text).then((results) {
      if (mounted) {
        setState(() {
          _destinationSuggestions = results;
          _isSearchingDestination = false;
        });
      }
    }).catchError((_) {
      if (mounted) setState(() => _isSearchingDestination = false);
    });
  }

  final List<String> _popularDestinations = const [
    'Nairobi CBD (Archives)',
    'Westlands Terminal',
    'JKUAT Gate',
    'Kikuyu Main Stage',
  ];

  void _swapLocations() {
    final tempText = _originController.text;
    final tempLat = _originLat;
    final tempLng = _originLng;

    setState(() {
      _originController.text = _destinationController.text;
      _originLat = _destLat;
      _originLng = _destLng;

      _destinationController.text = tempText;
      _destLat = tempLat;
      _destLng = tempLng;
    });
  }

  Future<void> _useCurrentLocation() async {
    setState(() => _isFetchingLocation = true);
    try {
      final result = await LocationService().fetchCurrentLocationDetails();
      if (result != null && mounted) {
        setState(() {
          _originController.text = result.address;
          _originLat = result.latitude;
          _originLng = result.longitude;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🎯 Current location set successfully!'),
            backgroundColor: AppColors.primary,
            duration: Duration(seconds: 2),
          ),
        );
      } else if (mounted) {
        _showError('Unable to access current location. Please check location permissions.');
      }
    } catch (e) {
      if (mounted) _showError('Location error: $e');
    } finally {
      if (mounted) setState(() => _isFetchingLocation = false);
    }
  }

  Future<void> _selectDateTime() async {
    final now = DateTime.now();
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(days: 1)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 90)),
    );
    
    if (pickedDate != null && mounted) {
      final pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );
      
      if (pickedTime != null && mounted) {
        setState(() {
          _scheduledDateTime = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
        });
      }
    }
  }
  
  void _seedTestGroupRide() {
    setState(() {
      _originController.text = 'Nairobi CBD (Archives)';
      _destinationController.text = 'Westlands Terminal';
      _originLat = -1.286389;
      _originLng = 36.817223;
      _destLat = -1.268333;
      _destLng = 36.809444;
      _maxPassengers = 4;
      _scheduleType = 'Now';
    });
    _createGroup();
  }

  void _seedReadyGroupRide() {
    setState(() {
      _originController.text = 'Nairobi CBD (Archives)';
      _destinationController.text = 'Westlands Terminal';
      _originLat = -1.286389;
      _originLng = 36.817223;
      _destLat = -1.268333;
      _destLng = 36.809444;
      _maxPassengers = 4;
      _scheduleType = 'Now';
    });
    _createGroup(overrideStatus: 'ready', overridePassengers: 3);
  }

  Future<void> _createGroup({String? overrideStatus, int? overridePassengers}) async {
    // Validate inputs
    if (_originController.text.trim().isEmpty) {
      _showError('Please enter origin/pickup location');
      return;
    }
    if (_destinationController.text.trim().isEmpty) {
      _showError('Please enter destination');
      return;
    }
    
    setState(() => _isCreating = true);
    
    try {
      final supabaseService = SupabaseService();
      final supabaseClient = supabaseService.client;
      final session = supabaseClient.auth.currentSession;
      
      if (session == null) {
        _showError('Please log in first');
        return;
      }
      
      final userId = session.user.id;
      final inviteCode = supabaseService.generateInviteCode();
      
      final groupRideData = {
        'creator_id': userId,
        'origin': _originController.text.trim(),
        'destination': _destinationController.text.trim(),
        if (_originLat != null) 'origin_lat': _originLat,
        if (_originLng != null) 'origin_lng': _originLng,
        if (_destLat != null) 'dest_lat': _destLat,
        if (_destLng != null) 'dest_lng': _destLng,
        'schedule_type': _scheduleType,
        'scheduled_time': _scheduleType == 'Later' && _scheduledDateTime != null 
            ? _scheduledDateTime!.toIso8601String() 
            : null,
        'max_passengers': _maxPassengers,
        'min_passengers': 3,
        'current_passengers': overridePassengers ?? 1,
        'status': overrideStatus ?? 'forming',
        'invite_code': inviteCode,
        'created_at': DateTime.now().toIso8601String(),
        'is_locked': false,
      };
      
      Map<String, dynamic> response;
      try {
        response = await supabaseClient
            .from('group_rides')
            .insert(groupRideData)
            .select()
            .single();
      } on PostgrestException catch (e) {
        if (e.code == 'PGRST204' || e.message.contains('dest_lat')) {
          // Retry without dest_lat/dest_lng if columns have not been added to Supabase DB yet
          final fallbackData = Map<String, dynamic>.from(groupRideData)
            ..remove('dest_lat')
            ..remove('dest_lng');

          response = await supabaseClient
              .from('group_rides')
              .insert(fallbackData)
              .select()
              .single();
        } else {
          rethrow;
        }
      }
      
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => GroupInviteShareScreen(ride: response),
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ Error creating group: $e');
      _showError('Failed to create group: $e');
    } finally {
      if (mounted) {
        setState(() => _isCreating = false);
      }
    }
  }
  
  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }
  
  @override
  void dispose() {
    _originController.dispose();
    _destinationController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAF9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1E293B)),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: Text(
          'Travelers',
          style: GoogleFonts.poppins(
            color: AppColors.primary,
            fontWeight: FontWeight.w800,
            fontSize: 22,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none_outlined, color: AppColors.primary),
            onPressed: () {},
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. HERO BANNER CARD (From Design Image 1)
                    Container(
                      width: double.infinity,
                      height: 140,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        image: const DecorationImage(
                          image: AssetImage('assets/matatu.png'),
                          fit: BoxFit.cover,
                        ),
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withValues(alpha: 0.15),
                              Colors.black.withValues(alpha: 0.8),
                            ],
                          ),
                        ),
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Start a New Journey',
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Split costs, travel together, save more.',
                              style: GoogleFonts.poppins(
                                color: Colors.white.withValues(alpha: 0.9),
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // 2. ROUTE DETAILS SECTION (From Design Image 1)
                    Text(
                      'ROUTE DETAILS',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF64748B),
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.02),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Origin',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF64748B),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.gps_fixed_rounded, color: AppColors.primary, size: 20),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: TextField(
                                    controller: _originController,
                                    onChanged: _onOriginChanged,
                                    decoration: InputDecoration(
                                      hintText: 'Where from?',
                                      hintStyle: GoogleFonts.poppins(color: const Color(0xFF94A3B8), fontSize: 14),
                                      border: InputBorder.none,
                                    ),
                                  ),
                                ),
                                if (_isSearchingOrigin)
                                  const Padding(
                                    padding: EdgeInsets.only(right: 8),
                                    child: SizedBox(
                                      width: 14,
                                      height: 14,
                                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                                    ),
                                  ),
                                IconButton(
                                  icon: _isFetchingLocation
                                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                                      : Icon(Icons.my_location_rounded, color: AppColors.primary, size: 20),
                                  onPressed: _isFetchingLocation ? null : _useCurrentLocation,
                                ),
                              ],
                            ),
                          ),
                          if (_originSuggestions.isNotEmpty)
                            _buildSuggestionsList(
                              suggestions: _originSuggestions,
                              onSelect: (loc) {
                                setState(() {
                                  _originController.text = loc.address;
                                  _originLat = loc.latitude;
                                  _originLng = loc.longitude;
                                  _originSuggestions = [];
                                });
                              },
                            ),

                          // Swap Button in Center
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: GestureDetector(
                                onTap: _swapLocations,
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.swap_vert, color: Colors.white, size: 20),
                                ),
                              ),
                            ),
                          ),

                          Text(
                            'Destination',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF64748B),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.outlined_flag_rounded, color: AppColors.primary, size: 20),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: TextField(
                                    controller: _destinationController,
                                    onChanged: _onDestinationChanged,
                                    decoration: InputDecoration(
                                      hintText: 'Where to?',
                                      hintStyle: GoogleFonts.poppins(color: const Color(0xFF94A3B8), fontSize: 14),
                                      border: InputBorder.none,
                                    ),
                                  ),
                                ),
                                if (_isSearchingDestination)
                                  const Padding(
                                    padding: EdgeInsets.all(12),
                                    child: SizedBox(
                                      width: 14,
                                      height: 14,
                                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          if (_destinationSuggestions.isNotEmpty)
                            _buildSuggestionsList(
                              suggestions: _destinationSuggestions,
                              onSelect: (loc) {
                                setState(() {
                                  _destinationController.text = loc.address;
                                  _destLat = loc.latitude;
                                  _destLng = loc.longitude;
                                  _destinationSuggestions = [];
                                });
                              },
                            ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Popular Destination Chips (Restricted to 4 key stages)
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: _popularDestinations.map((dest) {
                        return ActionChip(
                          avatar: Icon(Icons.place, size: 14, color: AppColors.primary),
                          label: Text(
                            dest,
                            style: GoogleFonts.poppins(fontSize: 12, color: const Color(0xFF334155)),
                          ),
                          backgroundColor: Colors.white,
                          side: const BorderSide(color: Color(0xFFCBD5E1)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          onPressed: () async {
                            setState(() {
                              _destinationController.text = dest;
                            });
                            final loc = await LocationService().getCoordinatesFromAddress(dest);
                            if (loc != null && mounted) {
                              setState(() {
                                _destLat = loc.latitude;
                                _destLng = loc.longitude;
                              });
                            }
                          },
                        );
                      }).toList(),
                    ),

                    // ROUTE PREVIEW MAP
                    if (_originController.text.isNotEmpty && _destinationController.text.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Text(
                        'ROUTE PREVIEW',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF64748B),
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 8),
                      RoutePreviewMap(
                        originLat: _originLat,
                        originLng: _originLng,
                        destLat: _destLat,
                        destLng: _destLng,
                        originAddress: _originController.text,
                        destAddress: _destinationController.text,
                        height: 180,
                      ),
                    ],

                    const SizedBox(height: 24),

                    // 3. SCHEDULE SECTION (From Design Image 1)
                    Text(
                      'SCHEDULE',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF64748B),
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE2E8F0).withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                setState(() => _scheduleType = 'Now');
                                if (_originController.text.trim().isEmpty) {
                                  _useCurrentLocation();
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                decoration: BoxDecoration(
                                  color: _scheduleType == 'Now' ? AppColors.primary : Colors.transparent,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Center(
                                  child: Text(
                                    'Now',
                                    style: GoogleFonts.poppins(
                                      color: _scheduleType == 'Now' ? Colors.white : const Color(0xFF64748B),
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setState(() => _scheduleType = 'Later'),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                decoration: BoxDecoration(
                                  color: _scheduleType == 'Later' ? AppColors.primary : Colors.transparent,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Center(
                                  child: Text(
                                    'Later',
                                    style: GoogleFonts.poppins(
                                      color: _scheduleType == 'Later' ? Colors.white : const Color(0xFF64748B),
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    if (_scheduleType == 'Later') ...[
                      const SizedBox(height: 12),
                      GestureDetector(
                        onTap: _selectDateTime,
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.calendar_today, color: AppColors.primary, size: 20),
                              const SizedBox(width: 12),
                              Text(
                                _scheduledDateTime == null
                                    ? 'Select date and time'
                                    : '${_scheduledDateTime!.day}/${_scheduledDateTime!.month}/${_scheduledDateTime!.year} at ${_scheduledDateTime!.hour}:${_scheduledDateTime!.minute.toString().padLeft(2, '0')}',
                                style: GoogleFonts.poppins(
                                  color: _scheduledDateTime == null ? const Color(0xFF94A3B8) : const Color(0xFF0F172A),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: 24),

                    // 4. MAXIMUM PASSENGERS SECTION (From Design Image 1)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'MAXIMUM PASSENGERS',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF64748B),
                            letterSpacing: 1,
                          ),
                        ),
                        Text(
                          'Minimum of 3 required.',
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF94A3B8),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '$_maxPassengers',
                                style: GoogleFonts.poppins(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFF0F172A),
                                ),
                              ),
                              Text(
                                'Seats available',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: const Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              IconButton(
                                onPressed: _maxPassengers > 3
                                    ? () => setState(() => _maxPassengers--)
                                    : null,
                                icon: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: _maxPassengers > 3 ? const Color(0xFF64748B) : const Color(0xFFCBD5E1),
                                    ),
                                  ),
                                  child: Icon(
                                    Icons.remove,
                                    size: 18,
                                    color: _maxPassengers > 3 ? const Color(0xFF334155) : const Color(0xFF94A3B8),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 4),
                              IconButton(
                                onPressed: _maxPassengers < 14
                                    ? () => setState(() => _maxPassengers++)
                                    : null,
                                icon: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.add, size: 18, color: Colors.white),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    Center(
                      child: Column(
                        children: [
                          TextButton.icon(
                            onPressed: _isCreating ? null : _seedTestGroupRide,
                            icon: Icon(Icons.bolt_rounded, color: AppColors.primary, size: 18),
                            label: Text(
                              '⚡ Autofill & Create Sample Test Ride (Forming)',
                              style: GoogleFonts.poppins(
                                color: AppColors.primary,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          TextButton.icon(
                            onPressed: _isCreating ? null : _seedReadyGroupRide,
                            icon: const Icon(Icons.verified_rounded, color: Color(0xFF16A34A), size: 18),
                            label: Text(
                              '🚗 Create Ready Ride (3/4 Joined - Ready for Driver)',
                              style: GoogleFonts.poppins(
                                color: const Color(0xFF16A34A),
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),

                    // 5. CREATE GROUP BUTTON (From Design Image 1)
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: _isCreating ? null : _createGroup,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: _isCreating
                            ? const CircularProgressIndicator(color: Colors.white)
                            : Text(
                                'Create Group',
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    Center(
                      child: Text(
                        'By creating a group, you agree to our Travel Safety Guidelines.',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: const Color(0xFF94A3B8),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),

            // Bottom Navigation Bar
            const BottomNavBar(currentIndex: 0),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestionsList({
    required List<UserLocationResult> suggestions,
    required Function(UserLocationResult) onSelect,
  }) {
    if (suggestions.isEmpty) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.only(top: 4, bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: suggestions.map((loc) {
          return ListTile(
            dense: true,
            leading: Icon(Icons.location_on_outlined, color: AppColors.primary, size: 18),
            title: Text(
              loc.address,
              style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600),
            ),
            onTap: () => onSelect(loc),
          );
        }).toList(),
      ),
    );
  }
}
