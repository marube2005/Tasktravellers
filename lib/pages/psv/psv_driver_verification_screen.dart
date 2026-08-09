import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:file_picker/file_picker.dart';
import '../../themes/app_colors.dart';

/// Step 2 of 3: Document Credentials Upload for PSV Drivers.
/// Requires: PSV Badge, Driving License, Road Service License, Insurance Certificate.
class PsvDriverVerificationScreen extends StatefulWidget {
  const PsvDriverVerificationScreen({super.key});

  @override
  State<PsvDriverVerificationScreen> createState() =>
      _PsvDriverVerificationScreenState();
}

class _PsvDriverVerificationScreenState
    extends State<PsvDriverVerificationScreen> {
  bool _isLoading = false;
  String _verificationStatus = 'pending';

  String? _psvBadgeUrl;
  String? _drivingLicenseUrl;
  String? _roadServiceLicenseUrl;
  String? _insuranceCertUrl;

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
          .from('psv_driver_profiles')
          .select(
              'verification_status, psv_badge_url, driving_license_url, road_service_license_url, insurance_cert_url')
          .eq('user_id', userId)
          .maybeSingle();

      if (result != null && mounted) {
        setState(() {
          _verificationStatus =
              result['verification_status'] as String? ?? 'pending';
          _psvBadgeUrl = result['psv_badge_url'] as String?;
          _drivingLicenseUrl = result['driving_license_url'] as String?;
          _roadServiceLicenseUrl = result['road_service_license_url'] as String?;
          _insuranceCertUrl = result['insurance_cert_url'] as String?;
        });
      }
    } catch (e) {
      debugPrint('Error loading verification status: $e');
    }
  }

  int get _uploadedCount {
    int count = 0;
    if (_psvBadgeUrl != null && _psvBadgeUrl!.isNotEmpty) count++;
    if (_drivingLicenseUrl != null && _drivingLicenseUrl!.isNotEmpty) count++;
    if (_roadServiceLicenseUrl != null && _roadServiceLicenseUrl!.isNotEmpty) count++;
    if (_insuranceCertUrl != null && _insuranceCertUrl!.isNotEmpty) count++;
    return count;
  }

  double get _completionPercentage => (_uploadedCount / 4.0);

  Future<void> _uploadDocument(String docType) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
        withData: true,
      );

      if (result == null || result.files.isEmpty) return;

      setState(() => _isLoading = true);

      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) throw Exception('Not authenticated');

      final file = result.files.first;
      final fileExt = file.extension ?? 'jpg';
      final fileName =
          '${userId}_${docType}_${DateTime.now().millisecondsSinceEpoch}.$fileExt';
      final storagePath = 'psv_documents/$userId/$fileName';

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

      final publicUrl = Supabase.instance.client.storage
          .from('sacco-documents')
          .getPublicUrl(storagePath);

      final dbColumn = {
        'psv_badge': 'psv_badge_url',
        'driving_license': 'driving_license_url',
        'road_service_license': 'road_service_license_url',
        'insurance_cert': 'insurance_cert_url',
      }[docType]!;

      await Supabase.instance.client
          .from('psv_driver_profiles')
          .update({dbColumn: publicUrl}).eq('user_id', userId);

      if (mounted) {
        setState(() {
          switch (docType) {
            case 'psv_badge':
              _psvBadgeUrl = publicUrl;
              break;
            case 'driving_license':
              _drivingLicenseUrl = publicUrl;
              break;
            case 'road_service_license':
              _roadServiceLicenseUrl = publicUrl;
              break;
            case 'insurance_cert':
              _insuranceCertUrl = publicUrl;
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

  String _docLabel(String docType) {
    switch (docType) {
      case 'psv_badge':
        return 'PSV Badge';
      case 'driving_license':
        return 'Driving License';
      case 'road_service_license':
        return 'Road Service License';
      case 'insurance_cert':
        return 'Insurance Certificate';
      default:
        return docType;
    }
  }

  Future<void> _submitForVerification() async {
    setState(() => _isLoading = true);

    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) throw Exception('Not authenticated');

      await Supabase.instance.client
          .from('psv_driver_profiles')
          .update({'verification_status': 'pending'}).eq('user_id', userId);

      if (mounted) {
        setState(() {
          _verificationStatus = 'pending';
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Credentials submitted for verification!')),
        );

        Navigator.pushReplacementNamed(context, '/psv-driver-dashboard');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Submission failed: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final progressPercentInt = (_completionPercentage * 100).toInt();

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundLight,
        elevation: 0,
        centerTitle: false,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.directions_bus, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 8),
            Text(
              'SafariFlow',
              style: GoogleFonts.poppins(
                color: AppColors.primary,
                fontWeight: FontWeight.w800,
                fontSize: 18,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none, color: AppColors.textLight),
            onPressed: () {},
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header & Step Progress
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Text(
                        'Step 2 of 3',
                        style: GoogleFonts.poppins(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: _verificationStatus == 'approved'
                              ? Colors.green.shade100
                              : Colors.amber.shade100,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          _verificationStatus.toUpperCase(),
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: _verificationStatus == 'approved'
                                ? Colors.green.shade800
                                : Colors.amber.shade900,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Text(
                    '$progressPercentInt% Complete',
                    style: GoogleFonts.poppins(
                      color: AppColors.textGrey,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Verify Credentials',
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textLight,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Upload high-quality photos of your documents. Ensure all text is legible and edges are visible.',
                style: GoogleFonts.poppins(
                  color: AppColors.textGrey,
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 12),

              // Progress Bar
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: _completionPercentage,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                  minHeight: 8,
                ),
              ),
              const SizedBox(height: 24),

              // 4 Document Cards
              _buildDocCard(
                docType: 'psv_badge',
                title: 'PSV Badge (Photo)',
                subtitle: 'Front face clear view of details.',
                icon: Icons.badge_outlined,
                uploadedUrl: _psvBadgeUrl,
              ),
              const SizedBox(height: 16),

              _buildDocCard(
                docType: 'driving_license',
                title: 'Driving License',
                subtitle: 'Valid Class A/B/C License.',
                icon: Icons.verified_user_outlined,
                uploadedUrl: _drivingLicenseUrl,
              ),
              const SizedBox(height: 16),

              _buildDocCard(
                docType: 'road_service_license',
                title: 'Road Service License',
                subtitle: 'Latest RSL for current vehicle.',
                icon: Icons.local_shipping_outlined,
                uploadedUrl: _roadServiceLicenseUrl,
              ),
              const SizedBox(height: 16),

              _buildDocCard(
                docType: 'insurance_cert',
                title: 'Insurance Certificate',
                subtitle: 'Valid comprehensive coverage.',
                icon: Icons.shield_outlined,
                uploadedUrl: _insuranceCertUrl,
              ),
              const SizedBox(height: 28),

              // Support Info Banner
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.15),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.help_outline, color: AppColors.primary, size: 22),
                    const SizedBox(width: 12),
                    Expanded(
                      child: RichText(
                        text: TextSpan(
                          style: GoogleFonts.poppins(
                            color: AppColors.textGrey,
                            fontSize: 13,
                            height: 1.4,
                          ),
                          children: const [
                            TextSpan(
                              text: 'Need help? ',
                              style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textLight),
                            ),
                            TextSpan(
                              text:
                                  'Our support team is available 24/7. Reach out via the Profile section if you\'re having trouble capturing clear images.',
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Submit for Verification Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitForVerification,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    disabledBackgroundColor: Colors.grey.shade300,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: _uploadedCount == 4 ? 2 : 0,
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Submit for Verification',
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 17,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(Icons.lock_outline, color: Colors.white, size: 18),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 10),

              if (_uploadedCount < 4)
                Center(
                  child: Text(
                    'Complete all 4 uploads to proceed',
                    style: GoogleFonts.poppins(
                      color: AppColors.error,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDocCard({
    required String docType,
    required String title,
    required String subtitle,
    required IconData icon,
    required String? uploadedUrl,
  }) {
    final isUploaded = uploadedUrl != null && uploadedUrl.isNotEmpty;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isUploaded
              ? AppColors.primary.withValues(alpha: 0.5)
              : Colors.grey.shade200,
          width: isUploaded ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isUploaded
                      ? AppColors.primary.withValues(alpha: 0.1)
                      : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: isUploaded ? AppColors.primary : AppColors.textGrey,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: AppColors.textLight,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: AppColors.textGrey,
                      ),
                    ),
                  ],
                ),
              ),
              // Status Indicator Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isUploaded
                      ? Colors.green.shade50
                      : Colors.red.shade50,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isUploaded ? Colors.green.shade300 : Colors.red.shade200,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isUploaded ? Icons.check_circle : Icons.error_outline,
                      size: 14,
                      color: isUploaded ? Colors.green.shade700 : Colors.red.shade700,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isUploaded ? 'Uploaded' : 'Missing',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isUploaded ? Colors.green.shade700 : Colors.red.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 42,
            child: OutlinedButton(
              onPressed: _isLoading ? null : () => _uploadDocument(docType),
              style: OutlinedButton.styleFrom(
                side: BorderSide(
                  color: isUploaded ? Colors.grey.shade300 : AppColors.primary,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                backgroundColor: isUploaded ? Colors.grey.shade50 : Colors.white,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isUploaded ? Icons.refresh : Icons.file_upload_outlined,
                    size: 18,
                    color: isUploaded ? AppColors.textGrey : AppColors.primary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    isUploaded ? 'Replace' : 'Upload',
                    style: GoogleFonts.poppins(
                      color: isUploaded ? AppColors.textLight : AppColors.primary,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
