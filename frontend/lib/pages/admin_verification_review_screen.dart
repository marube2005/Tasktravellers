import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../themes/app_colors.dart';

/// Admin screen to review and approve/reject Sacco verification requests.
/// Only accessible to users with 'admin' role.
class AdminVerificationReviewScreen extends StatefulWidget {
  const AdminVerificationReviewScreen({super.key});

  @override
  State<AdminVerificationReviewScreen> createState() =>
      _AdminVerificationReviewScreenState();
}

class _AdminVerificationReviewScreenState
    extends State<AdminVerificationReviewScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  List<Map<String, dynamic>> _pendingRequests = [];
  List<Map<String, dynamic>> _processedRequests = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadRequests();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadRequests() async {
    setState(() => _isLoading = true);

    try {
      // Fetch pending verification requests
      final pending = await Supabase.instance.client
          .from('sacco_profiles')
          .select('*, users!inner(id, name, email)')
          .eq('verification_status', 'pending')
          .order('created_at', ascending: false);

      // Fetch processed (approved/rejected) requests
      final processed = await Supabase.instance.client
          .from('sacco_profiles')
          .select('*, users!inner(id, name, email)')
          .neq('verification_status', 'pending')
          .order('updated_at', ascending: false)
          .limit(50);

      if (mounted) {
        setState(() {
          _pendingRequests = List<Map<String, dynamic>>.from(pending);
          _processedRequests = List<Map<String, dynamic>>.from(processed);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading requests: $e')),
        );
      }
    }
  }

  Future<void> _approveRequest(String saccoId, String userId) async {
    try {
      await Supabase.instance.client.from('sacco_profiles').update({
        'verification_status': 'approved',
        'rejection_reason': null,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', saccoId);

      // Update user's is_verified status
      await Supabase.instance.client
          .from('users')
          .update({'is_verified': true}).eq('id', userId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sacco approved successfully'),
            backgroundColor: Colors.green,
          ),
        );
        _loadRequests();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to update verification status right now.')),
        );
      }
    }
  }

  Future<void> _rejectRequest(String saccoId, String reason) async {
    try {
      await Supabase.instance.client.from('sacco_profiles').update({
        'verification_status': 'rejected',
        'rejection_reason': reason,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', saccoId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sacco rejected'),
            backgroundColor: Colors.orange,
          ),
        );
        _loadRequests();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to update verification status right now.')),
        );
      }
    }
  }

  void _showRejectDialog(String saccoId) {
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Verification'),
        content: TextField(
          controller: reasonController,
          decoration: const InputDecoration(
            labelText: 'Rejection reason',
            hintText: 'Enter reason for rejection...',
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final reason = reasonController.text.trim();
              if (reason.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter a reason')),
                );
                return;
              }
              Navigator.pop(context);
              _rejectRequest(saccoId, reason);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
  }

  void _showDocumentViewer(String? url, String docName) {
    if (url == null || url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$docName not uploaded')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppBar(
              title: Text(docName),
              automaticallyImplyLeading: false,
              actions: [
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            Flexible(
              child: url.endsWith('.pdf')
                  ? Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.picture_as_pdf,
                              size: 64, color: Colors.red),
                          const SizedBox(height: 16),
                          Text(docName),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: () {
                              // In production, use url_launcher to open PDF
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Opening: $url')),
                              );
                            },
                            icon: const Icon(Icons.open_in_new),
                            label: const Text('Open PDF'),
                          ),
                        ],
                      ),
                    )
                  : Image.network(
                      url,
                      fit: BoxFit.contain,
                      loadingBuilder: (context, child, progress) {
                        if (progress == null) return child;
                        return const Center(child: CircularProgressIndicator());
                      },
                      errorBuilder: (context, error, stack) => const Padding(
                        padding: EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.broken_image, size: 64),
                            SizedBox(height: 16),
                            Text('Failed to load image'),
                          ],
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Verification Requests',
          style: GoogleFonts.manrope(fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Pending'),
                  if (_pendingRequests.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.orange,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${_pendingRequests.length}',
                        style: const TextStyle(
                            color: Colors.white, fontSize: 12),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const Tab(text: 'Processed'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadRequests,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildRequestList(_pendingRequests, isPending: true),
                _buildRequestList(_processedRequests, isPending: false),
              ],
            ),
    );
  }

  Widget _buildRequestList(List<Map<String, dynamic>> requests,
      {required bool isPending}) {
    if (requests.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isPending ? Icons.inbox : Icons.check_circle_outline,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              isPending ? 'No pending requests' : 'No processed requests',
              style: GoogleFonts.manrope(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadRequests,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: requests.length,
        itemBuilder: (context, index) {
          final req = requests[index];
          final user = req['users'] as Map<String, dynamic>?;
          final status = req['verification_status'] as String? ?? 'pending';

          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            child: ExpansionTile(
              leading: CircleAvatar(
                backgroundColor: _getStatusColor(status).withValues(alpha: 0.2),
                child: Icon(
                  _getStatusIcon(status),
                  color: _getStatusColor(status),
                ),
              ),
              title: Text(
                req['sacco_name'] ?? 'Unknown Sacco',
                style: GoogleFonts.manrope(fontWeight: FontWeight.w600),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(user?['email'] ?? 'No email'),
                  if (!isPending)
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: _getStatusColor(status).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        status.toUpperCase(),
                        style: TextStyle(
                          color: _getStatusColor(status),
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildInfoRow('Contact', req['contact_name']),
                      _buildInfoRow('Phone', req['contact_phone']),
                      _buildInfoRow('Email', req['contact_email']),
                      _buildInfoRow('NTSA License', req['ntsa_license']),
                      _buildInfoRow('Fleet Size', '${req['fleet_size'] ?? 0}'),
                      if (status == 'rejected' &&
                          req['rejection_reason'] != null)
                        _buildInfoRow(
                            'Rejection Reason', req['rejection_reason']),
                      const Divider(height: 24),
                      Text(
                        'Documents',
                        style: GoogleFonts.manrope(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _buildDocButton(
                            'NTSA Cert',
                            req['ntsa_cert_url'],
                            Icons.description,
                          ),
                          _buildDocButton(
                            'Sacco Reg',
                            req['sacco_reg_url'],
                            Icons.business,
                          ),
                          _buildDocButton(
                            'KRA PIN',
                            req['kra_pin_url'],
                            Icons.badge,
                          ),
                        ],
                      ),
                      if (isPending) ...[
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () =>
                                    _showRejectDialog(req['id'] as String),
                                icon: const Icon(Icons.close),
                                label: const Text('Reject'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.red,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () => _approveRequest(
                                  req['id'] as String,
                                  user?['id'] as String? ?? '',
                                ),
                                icon: const Icon(Icons.check),
                                label: const Text('Approve'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value ?? '-',
              style: const TextStyle(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocButton(String label, String? url, IconData icon) {
    final hasDoc = url != null && url.isNotEmpty;
    return OutlinedButton.icon(
      onPressed: () => _showDocumentViewer(url, label),
      icon: Icon(
        icon,
        size: 18,
        color: hasDoc ? AppColors.primary : Colors.grey,
      ),
      label: Text(
        label,
        style: TextStyle(
          color: hasDoc ? AppColors.primary : Colors.grey,
        ),
      ),
      style: OutlinedButton.styleFrom(
        side: BorderSide(
          color: hasDoc ? AppColors.primary : Colors.grey.shade300,
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'pending':
      default:
        return Colors.orange;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'approved':
        return Icons.check_circle;
      case 'rejected':
        return Icons.cancel;
      case 'pending':
      default:
        return Icons.pending;
    }
  }
}
