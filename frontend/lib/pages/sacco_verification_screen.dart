import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:file_picker/file_picker.dart';
import '../themes/app_colors.dart';

/// Sacco document upload and verification status screen.
/// Upload: NTSA certificate, Sacco registration, KRA PIN.
/// Status: pending → approved (verified badge) or rejected (reason + re-upload).
class SaccoVerificationScreen extends StatefulWidget {
  const SaccoVerificationScreen({super.key});

  @override
  State<SaccoVerificationScreen> createState() =>
      _SaccoVerificationScreenState();
}

class _SaccoVerificationScreenState extends State<SaccoVerificationScreen> {
  bool _isLoading = false;
  String _verificationStatus = 'pending'; // pending, approved, rejected
  String? _rejectionReason;

  // Track which documents have been "uploaded" (file paths / names)
  String? _ntsaCertFile;
  String? _saccoRegFile;
  String? _kraPinFile;

  @override
  void initState() {
    super.initState();
    _loadVerificationStatus();
  }

  Future<void> _loadVerificationStatus() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return;

      final result = await Supabase.instance.client
          .from('sacco_profiles')
          .select('verification_status, rejection_reason, ntsa_cert_url, sacco_reg_url, kra_pin_url')
          .eq('user_id', userId)
          .maybeSingle();

      if (result != null && mounted) {
        setState(() {
          _verificationStatus =
              result['verification_status'] as String? ?? 'pending';
          _rejectionReason = result['rejection_reason'] as String?;
          _ntsaCertFile = result['ntsa_cert_url'] as String?;
          _saccoRegFile = result['sacco_reg_url'] as String?;
          _kraPinFile = result['kra_pin_url'] as String?;
        });
      }
    } catch (e) {
      // Silently handle — screen will show default pending state
    }
  }

  Future<void> _uploadDocument(String docType) async {
    try {
      // Pick file using file_picker
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
        withData: true, // Required for web
      );

      if (result == null || result.files.isEmpty) {
        return; // User cancelled
      }

      setState(() => _isLoading = true);

      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) throw Exception('Not authenticated');

      final file = result.files.first;
      final fileExt = file.extension ?? 'pdf';
      final fileName = '${userId}_${docType}_${DateTime.now().millisecondsSinceEpoch}.$fileExt';
      final storagePath = 'sacco_documents/$userId/$fileName';

      // Upload to Supabase Storage
      final bytes = file.bytes;
      if (bytes == null) throw Exception('Could not read file');

      await Supabase.instance.client.storage
          .from('sacco-documents')
          .uploadBinary(
            storagePath,
            bytes,
            fileOptions: FileOptions(
              contentType: _getContentType(fileExt),
              upsert: true,
            ),
          );

      // Get the public URL
      final publicUrl = Supabase.instance.client.storage
          .from('sacco-documents')
          .getPublicUrl(storagePath);

      // Update the database with the file URL
      final updateField = {
        'ntsa_cert': 'ntsa_cert_url',
        'sacco_reg': 'sacco_reg_url',
        'kra_pin': 'kra_pin_url',
      }[docType]!;

      await Supabase.instance.client
          .from('sacco_profiles')
          .update({updateField: publicUrl}).eq('user_id', userId);

      if (mounted) {
        setState(() {
          switch (docType) {
            case 'ntsa_cert':
              _ntsaCertFile = publicUrl;
              break;
            case 'sacco_reg':
              _saccoRegFile = publicUrl;
              break;
            case 'kra_pin':
              _kraPinFile = publicUrl;
              break;
          }
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${_docLabel(docType)} uploaded successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload failed: $e')),
        );
      }
    }
  }

  String _getContentType(String extension) {
    switch (extension.toLowerCase()) {
      case 'pdf':
        return 'application/pdf';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      default:
        return 'application/octet-stream';
    }
  }

  Future<void> _submitForReview() async {
    if (_ntsaCertFile == null || _saccoRegFile == null || _kraPinFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please upload all required documents.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) throw Exception('Not authenticated');

      await Supabase.instance.client
          .from('sacco_profiles')
          .update({'verification_status': 'pending'}).eq('user_id', userId);

      if (mounted) {
        setState(() {
          _verificationStatus = 'pending';
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Documents submitted for review!')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to submit verification right now.')),
        );
      }
    }
  }

  String _docLabel(String docType) {
    switch (docType) {
      case 'ntsa_cert':
        return 'NTSA Certificate';
      case 'sacco_reg':
        return 'Sacco Registration';
      case 'kra_pin':
        return 'KRA PIN Certificate';
      default:
        return docType;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundLight,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Verification',
          style: GoogleFonts.manrope(
            color: AppColors.textLight,
            fontWeight: FontWeight.w700,
            fontSize: 20,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Status banner
              _buildStatusBanner(),
              const SizedBox(height: 28),

              Text(
                'Required Documents',
                style: GoogleFonts.manrope(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textLight,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Upload the following documents for verification.',
                style: GoogleFonts.manrope(
                  color: AppColors.textGrey,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 24),

              // Document cards
              _buildDocCard(
                docType: 'ntsa_cert',
                label: 'NTSA Certificate',
                description: 'National Transport & Safety Authority PSV license.',
                icon: Icons.verified_outlined,
                uploadedUrl: _ntsaCertFile,
              ),
              const SizedBox(height: 16),
              _buildDocCard(
                docType: 'sacco_reg',
                label: 'Sacco Registration',
                description: 'Official Sacco registration certificate.',
                icon: Icons.description_outlined,
                uploadedUrl: _saccoRegFile,
              ),
              const SizedBox(height: 16),
              _buildDocCard(
                docType: 'kra_pin',
                label: 'KRA PIN Certificate',
                description: 'Kenya Revenue Authority PIN certificate.',
                icon: Icons.account_balance_outlined,
                uploadedUrl: _kraPinFile,
              ),
              const SizedBox(height: 32),

              // Submit / Continue button
              if (_verificationStatus == 'approved') ...[
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pushReplacementNamed(
                          context, '/sacco-dashboard');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      'Go to Dashboard',
                      style: GoogleFonts.manrope(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ] else ...[
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _submitForReview,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(
                            'Submit for Review',
                            style: GoogleFonts.manrope(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 16),

                // Skip to dashboard (pending status)
                Center(
                  child: TextButton(
                    onPressed: () {
                      Navigator.pushReplacementNamed(
                          context, '/sacco-dashboard');
                    },
                    child: Text(
                      'Continue to dashboard (pending review)',
                      style: GoogleFonts.manrope(
                        color: AppColors.textGrey,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBanner() {
    Color bgColor;
    Color borderColor;
    Color textColor;
    IconData icon;
    String title;
    String subtitle;

    switch (_verificationStatus) {
      case 'approved':
        bgColor = Colors.green.shade50;
        borderColor = Colors.green.shade300;
        textColor = Colors.green.shade800;
        icon = Icons.check_circle;
        title = 'Verified';
        subtitle = 'Your Sacco has been verified. You have a verified badge.';
        break;
      case 'rejected':
        bgColor = Colors.red.shade50;
        borderColor = Colors.red.shade300;
        textColor = Colors.red.shade800;
        icon = Icons.error;
        title = 'Rejected';
        subtitle =
            _rejectionReason ?? 'Your documents were rejected. Please re-upload.';
        break;
      default: // pending
        bgColor = Colors.amber.shade50;
        borderColor = Colors.amber.shade300;
        textColor = Colors.amber.shade800;
        icon = Icons.hourglass_top;
        title = 'Pending Review';
        subtitle = 'Upload your documents and submit for verification.';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: textColor, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.manrope(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: GoogleFonts.manrope(
                    fontSize: 13,
                    color: textColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocCard({
    required String docType,
    required String label,
    required String description,
    required IconData icon,
    required String? uploadedUrl,
  }) {
    final isUploaded = uploadedUrl != null && uploadedUrl.isNotEmpty;
    final canUpload = _verificationStatus != 'approved';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isUploaded ? Colors.green.shade300 : Colors.grey.shade200,
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: isUploaded
                ? Colors.green.shade50
                : Colors.grey.shade100,
            child: Icon(
              isUploaded ? Icons.check_circle : icon,
              color: isUploaded ? Colors.green : AppColors.textGrey,
              size: 28,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.manrope(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  isUploaded ? 'Uploaded' : description,
                  style: GoogleFonts.manrope(
                    fontSize: 12,
                    color: isUploaded ? Colors.green : AppColors.textGrey,
                  ),
                ),
              ],
            ),
          ),
          if (canUpload)
            TextButton(
              onPressed: _isLoading ? null : () => _uploadDocument(docType),
              child: Text(
                isUploaded ? 'Replace' : 'Upload',
                style: GoogleFonts.manrope(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
