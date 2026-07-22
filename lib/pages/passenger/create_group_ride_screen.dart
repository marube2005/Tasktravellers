import 'package:flutter/material.dart';
import '../../services/location_service.dart';
import '../../../services/supabase_service.dart';
import '../../../widgets/bottom_nav_bar.dart';
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

  final List<String> _popularDestinations = const [
    'Nairobi CBD (Archives)',
    'Westlands Terminal',
    'Kikuyu Main Stage',
    'Thika Superhighway Stage',
    'Juja / JKUAT Gate',
    'Rongai Stage',
    'Nakuru Town Stage',
    'Eldoret Bus Park',
    'Kisumu Bus Park',
    'Mombasa Bus Stage',
  ];

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
            backgroundColor: Colors.green,
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
  
  Future<void> _createGroup() async {
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
      // Get Supabase client directly
      final supabaseService = SupabaseService();
      final supabaseClient = supabaseService.client;
      
      // Get current session directly (NO provider)
      final session = supabaseClient.auth.currentSession;
      
      if (session == null) {
        _showError('Please log in first');
        return;
      }
      
      final userId = session.user.id;
      debugPrint('✅ User ID: $userId');
      
      // Generate unique invite code
      final inviteCode = supabaseService.generateInviteCode();
      debugPrint('✅ Invite Code: $inviteCode');
      
      // Prepare group ride data
      final groupRideData = {
        'creator_id': userId,
        'origin': _originController.text.trim(),
        'destination': _destinationController.text.trim(),
        if (_originLat != null) 'origin_lat': _originLat,
        if (_originLng != null) 'origin_lng': _originLng,
        'schedule_type': _scheduleType,
        'scheduled_time': _scheduleType == 'Later' && _scheduledDateTime != null 
            ? _scheduledDateTime!.toIso8601String() 
            : null,
        'max_passengers': _maxPassengers,
        'min_passengers': 3,
        'current_passengers': 1,
        'status': 'forming',
        'invite_code': inviteCode,
        'created_at': DateTime.now().toIso8601String(),
        'is_locked': false,
      };
      
      debugPrint('📦 Inserting group ride: $groupRideData');
      
      // Insert into Supabase
      final response = await supabaseClient
          .from('group_rides')
          .insert(groupRideData)
          .select()
          .single();
      
      debugPrint('✅ Group created with ID: ${response['id']}');
      
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
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Colors.green.shade700, Colors.green.shade400],
                ),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Travelers',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Start a New Journey',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    'Spirit calls, travel together, save more.',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ROUTE DETAILS section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'ROUTE DETAILS',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey,
                            letterSpacing: 1,
                          ),
                        ),
                        TextButton.icon(
                          onPressed: _isFetchingLocation ? null : _useCurrentLocation,
                          icon: _isFetchingLocation
                              ? const SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.my_location_rounded, size: 16, color: Colors.green),
                          label: Text(
                            _isFetchingLocation ? 'Locating...' : 'Use Live Location',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.green),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    
                    // Origin / Pickup field
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: TextField(
                        controller: _originController,
                        decoration: InputDecoration(
                          labelText: 'Pickup Location / Route',
                          hintText: 'e.g. Westlands Stage or Live Location',
                          prefixIcon: const Icon(Icons.trip_origin_rounded, color: Colors.green),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.gps_fixed_rounded, color: Colors.green),
                            tooltip: 'Use current GPS location',
                            onPressed: _isFetchingLocation ? null : _useCurrentLocation,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Destination field
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: TextField(
                        controller: _destinationController,
                        decoration: const InputDecoration(
                          labelText: 'Destination',
                          hintText: 'Where are you going?',
                          prefixIcon: Icon(Icons.location_on_rounded, color: Colors.redAccent),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Popular Destination Chips / Suggestions
                    const Text(
                      'Popular Destination Stages:',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.grey),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: _popularDestinations.map((dest) {
                        return ActionChip(
                          avatar: const Icon(Icons.place, size: 14, color: Colors.green),
                          label: Text(dest, style: const TextStyle(fontSize: 12)),
                          backgroundColor: Colors.grey.shade100,
                          side: BorderSide(color: Colors.grey.shade300),
                          onPressed: () {
                            setState(() {
                              _destinationController.text = dest;
                            });
                          },
                        );
                      }).toList(),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // SCHEDULE section
                    const Text(
                      'SCHEDULE',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 12),
                    
                    // Now / Later toggle buttons
                    Row(
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
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              decoration: BoxDecoration(
                                color: _scheduleType == 'Now' 
                                    ? Colors.green 
                                    : Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Center(
                                child: Text(
                                  'Now',
                                  style: TextStyle(
                                    color: _scheduleType == 'Now' 
                                        ? Colors.white 
                                        : Colors.grey.shade600,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _scheduleType = 'Later'),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              decoration: BoxDecoration(
                                color: _scheduleType == 'Later' 
                                    ? Colors.green 
                                    : Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Center(
                                child: Text(
                                  'Later',
                                  style: TextStyle(
                                    color: _scheduleType == 'Later' 
                                        ? Colors.white 
                                        : Colors.grey.shade600,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    
                    // Date picker (only shown when "Later" is selected)
                    if (_scheduleType == 'Later') ...[
                      const SizedBox(height: 12),
                      GestureDetector(
                        onTap: _selectDateTime,
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.calendar_today, color: Colors.green.shade700),
                              const SizedBox(width: 12),
                              Text(
                                _scheduledDateTime == null
                                    ? 'Select date and time'
                                    : '${_scheduledDateTime!.day}/${_scheduledDateTime!.month}/${_scheduledDateTime!.year} at ${_scheduledDateTime!.hour}:${_scheduledDateTime!.minute.toString().padLeft(2, '0')}',
                                style: TextStyle(
                                  color: _scheduledDateTime == null 
                                      ? Colors.grey 
                                      : Colors.black,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                    
                    const SizedBox(height: 24),
                    
                    // MAXIMUM PASSENGERS section
                    const Text(
                      'MAXIMUM PASSENGERS',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Minimum of 3 passengers required.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                      ),
                    ),
                    const SizedBox(height: 12),
                    
                    // Passenger slider
                    Row(
                      children: [
                        Expanded(
                          child: Slider(
                            value: _maxPassengers.toDouble(),
                            min: 3,
                            max: 14,
                            divisions: 11,
                            activeColor: Colors.green,
                            inactiveColor: Colors.grey.shade300,
                            label: '$_maxPassengers seats',
                            onChanged: (value) {
                              setState(() {
                                _maxPassengers = value.round();
                              });
                            },
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.green.shade200),
                          ),
                          child: Text(
                            '$_maxPassengers seats available',
                            style: TextStyle(
                              color: Colors.green.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // Create Group button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isCreating ? null : _createGroup,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isCreating
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'Create Group',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                    
                    const SizedBox(height: 12),
                    
                    // Terms and conditions notice
                    Center(
                      child: Text(
                        'By creating a group, you agree to our Travel Safety Guidelines.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
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
}
