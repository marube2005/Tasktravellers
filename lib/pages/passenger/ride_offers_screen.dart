import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../themes/app_colors.dart';
import 'ride_tracking_screen.dart';

class RideOffersScreen extends StatefulWidget {
  const RideOffersScreen({
    super.key,
    required this.rideId,
    required this.origin,
    required this.destination,
    required this.passengersCount,
    required this.acceptanceCode,
  });

  final String rideId;
  final String origin;
  final String destination;
  final int passengersCount;
  final String acceptanceCode;

  @override
  State<RideOffersScreen> createState() => _RideOffersScreenState();
}

class _RideOffersScreenState extends State<RideOffersScreen> {
  bool _isLoading = false;
  String? _selectedOfferId;

  // Sample Sacco Driver Offers tailored to Kenyan routes
  final List<Map<String, dynamic>> _sampleOffers = [
    {
      'id': 'offer_1',
      'sacco_name': 'Super Metro Sacco',
      'plate_number': 'KDJ 482L',
      'driver_name': 'Peter Njoroge',
      'rating': 4.9,
      'total_trips': 1420,
      'vehicle_type': '14-Seater High-Roof Matatu',
      'amenities': ['WiFi', 'Music', 'USB Charger'],
      'fare_per_seat': 150,
      'eta_minutes': 5,
      'is_verified': true,
    },
    {
      'id': 'offer_2',
      'sacco_name': '2NK Express',
      'plate_number': 'KCF 910P',
      'driver_name': 'Samuel Maina',
      'rating': 4.8,
      'total_trips': 980,
      'vehicle_type': '14-Seater Executive Shuttle',
      'amenities': ['AC', 'Reclining Seats'],
      'fare_per_seat': 160,
      'eta_minutes': 8,
      'is_verified': true,
    },
    {
      'id': 'offer_3',
      'sacco_name': 'Forward Travelers Sacco',
      'plate_number': 'KDB 112X',
      'driver_name': 'Joseph Omondi',
      'rating': 4.7,
      'total_trips': 650,
      'vehicle_type': '14-Seater Standard Matatu',
      'amenities': ['Spacious Legroom'],
      'fare_per_seat': 140,
      'eta_minutes': 12,
      'is_verified': true,
    },
  ];

  Future<void> _selectDriver(Map<String, dynamic> offer) async {
    setState(() {
      _selectedOfferId = offer['id'] as String;
      _isLoading = true;
    });

    try {
      final client = Supabase.instance.client;

      // Update group_rides table status to 'accepted' with driver info
      try {
        await client.from('group_rides').update({
          'status': 'accepted',
          'group_note': 'Assigned to ${offer['sacco_name']} (${offer['plate_number']})',
          'updated_at': DateTime.now().toIso8601String(),
        }).eq('id', widget.rideId);
      } on PostgrestException catch (pe) {
        if (pe.code == 'PGRST204') {
          // Fallback if group_note column has not reloaded in schema cache
          await client.from('group_rides').update({
            'status': 'accepted',
            'updated_at': DateTime.now().toIso8601String(),
          }).eq('id', widget.rideId);
        } else {
          rethrow;
        }
      }


      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('🎉 ${offer['sacco_name']} (${offer['plate_number']}) selected successfully!'),
          backgroundColor: AppColors.primary,
        ),
      );

      // Navigate to live ride tracking screen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => LiveTrackingScreen(
            rideId: widget.rideId,
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to confirm driver: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF0F172A)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Select Sacco Driver',
          style: GoogleFonts.poppins(
            color: const Color(0xFF0F172A),
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Route & Pool Status Summary Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black45,
                    blurRadius: 6,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFDCFCE7),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.check_circle_rounded, color: Color(0xFF16A34A), size: 14),
                            const SizedBox(width: 4),
                            Text(
                              'POOL FULL & READY',
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF16A34A),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      Text(
                        'Code: ${widget.acceptanceCode}',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.my_location_rounded, color: AppColors.primary, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          widget.origin,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Padding(
                    padding: EdgeInsets.only(left: 8),
                    child: Icon(Icons.more_vert, color: Color(0xFFCBD5E1), size: 16),
                  ),
                  Row(
                    children: [
                      const Icon(Icons.location_on_rounded, color: Colors.redAccent, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          widget.destination,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '👥 ${widget.passengersCount} Passengers Confirmed',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF475569),
                        ),
                      ),
                      Text(
                        'Instant Dispatch',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            Text(
              'Available Drivers & Sacco Offers (${_sampleOffers.length})',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 12),

            // Driver Offers List
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _sampleOffers.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final offer = _sampleOffers[index];
                final isSelected = _selectedOfferId == offer['id'];

                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected ? AppColors.primary : const Color(0xFFE2E8F0),
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
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
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      offer['sacco_name'] as String,
                                      style: GoogleFonts.poppins(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                        color: const Color(0xFF0F172A),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    const Icon(
                                      Icons.verified_rounded,
                                      color: AppColors.primary,
                                      size: 16,
                                    ),
                                  ],
                                ),
                                Text(
                                  '${offer['driver_name']} • ${offer['plate_number']}',
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    color: const Color(0xFF64748B),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(Icons.star_rounded, color: Colors.amber, size: 16),
                                    const SizedBox(width: 2),
                                    Text(
                                      '${offer['rating']} (${offer['total_trips']} trips)',
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: const Color(0xFF334155),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                'KES ${offer['fare_per_seat']}',
                                style: GoogleFonts.poppins(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.primary,
                                ),
                              ),
                              Text(
                                'per seat',
                                style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  color: const Color(0xFF94A3B8),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Amenities Chips
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: (offer['amenities'] as List<String>).map((amenity) {
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              amenity,
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                color: const Color(0xFF475569),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          );
                        }).toList(),
                      ),

                      const SizedBox(height: 14),

                      // Select Driver Button
                      SizedBox(
                        width: double.infinity,
                        height: 44,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : () => _selectDriver(offer),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: isSelected && _isLoading
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                )
                              : Text(
                                  'Select & Book Driver (${offer['eta_minutes']} min away)',
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
