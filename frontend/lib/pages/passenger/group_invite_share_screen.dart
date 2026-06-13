import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/booking_service.dart';
import '../../themes/app_colors.dart';
import 'ride_chat_screen.dart';

class GroupInviteShareScreen extends StatefulWidget {
  const GroupInviteShareScreen({super.key, required this.ride});

  final Map<String, dynamic> ride;

  @override
  State<GroupInviteShareScreen> createState() => _GroupInviteShareScreenState();
}

class _GroupInviteShareScreenState extends State<GroupInviteShareScreen> {
  final BookingService _bookingService = BookingService();
  bool _joining = false;

  String get _rideId => widget.ride['id'] as String;
  String get _origin => widget.ride['origin'] as String? ?? 'Unknown';
  String get _destination => widget.ride['destination'] as String? ?? 'Unknown';
  String get _inviteLink => widget.ride['invite_link'] as String? ?? '';
  String get _acceptanceCode => widget.ride['acceptance_code'] as String? ?? '';
  String get _groupNote => widget.ride['group_note'] as String? ?? '';
  int get _groupSize => (widget.ride['group_size'] as int?) ?? 0;

  Future<void> _copy(String value, String label) async {
    await Clipboard.setData(ClipboardData(text: value));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$label copied to clipboard')),
      );
    }
  }

  Future<void> _joinRide() async {
    setState(() => _joining = true);
    try {
      await _bookingService.joinRide(rideId: _rideId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You joined the ride pool')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
        );
      }
    } finally {
      if (mounted) setState(() => _joining = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Invite shared'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: StreamBuilder<List<Map<String, dynamic>>>(
          stream: _bookingService.rideBookingsStream(rideId: _rideId),
          builder: (context, snapshot) {
            final passengers = snapshot.data?.length ?? 0;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Share this ride',
                    style: GoogleFonts.manrope(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textLight,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Passengers can join through the invite link and the sacco can use the acceptance code.',
                    style: GoogleFonts.manrope(
                      color: AppColors.textGrey,
                    ),
                  ),
                  const SizedBox(height: 24),
                  _InfoCard(
                    title: 'Route',
                    value: '$_origin → $_destination',
                  ),
                  const SizedBox(height: 12),
                  _InfoCard(
                    title: 'Group',
                    value: '$passengers / $_groupSize joined',
                  ),
                  if (_groupNote.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _InfoCard(title: 'Trip note', value: _groupNote),
                  ],
                  const SizedBox(height: 20),
                  Text(
                    'Invite link',
                    style: GoogleFonts.manrope(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  SelectableText(_inviteLink),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      OutlinedButton.icon(
                        onPressed: _inviteLink.isEmpty ? null : () => _copy(_inviteLink, 'Invite link'),
                        icon: const Icon(Icons.copy),
                        label: const Text('Copy link'),
                      ),
                      OutlinedButton.icon(
                        onPressed: _acceptanceCode.isEmpty ? null : () => _copy(_acceptanceCode, 'Acceptance code'),
                        icon: const Icon(Icons.pin_outlined),
                        label: const Text('Copy code'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Acceptance code',
                    style: GoogleFonts.manrope(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      _acceptanceCode.isEmpty ? 'Not generated' : _acceptanceCode,
                      style: GoogleFonts.manrope(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 4,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _joining ? null : _joinRide,
                      child: _joining
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('Join ride pool'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => RideChatScreen(
                              rideId: _rideId,
                              title: '$_origin → $_destination',
                            ),
                          ),
                        );
                      },
                      child: const Text('Open in-app chat'),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.title, required this.value});

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.manrope(
              color: AppColors.textGrey,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: GoogleFonts.manrope(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textLight,
            ),
          ),
        ],
      ),
    );
  }
}
