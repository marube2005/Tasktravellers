import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../themes/app_colors.dart';

/// A reusable widget for uploading and displaying vehicle images.
class VehicleImagePicker extends StatefulWidget {
  final String? currentImageUrl;
  final String storagePath;
  final double width;
  final double height;
  final Function(String url)? onUploaded;
  final bool enabled;

  const VehicleImagePicker({
    super.key,
    this.currentImageUrl,
    required this.storagePath,
    this.width = double.infinity,
    this.height = 180,
    this.onUploaded,
    this.enabled = true,
  });

  @override
  State<VehicleImagePicker> createState() => _VehicleImagePickerState();
}

class _VehicleImagePickerState extends State<VehicleImagePicker> {
  String? _imageUrl;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _imageUrl = widget.currentImageUrl;
  }

  @override
  void didUpdateWidget(VehicleImagePicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentImageUrl != widget.currentImageUrl) {
      _imageUrl = widget.currentImageUrl;
    }
  }

  Future<void> _pickAndUpload() async {
    if (!widget.enabled) return;

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        withData: true,
      );

      if (result == null || result.files.isEmpty) return;

      setState(() => _isUploading = true);

      final file = result.files.first;
      final bytes = file.bytes;
      if (bytes == null) throw Exception('Could not read file');

      final fileExt = file.extension ?? 'jpg';
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.$fileExt';
      final fullPath = '${widget.storagePath}/$fileName';

      // Upload to Supabase Storage
      await Supabase.instance.client.storage
          .from('vehicle-images')
          .uploadBinary(
            fullPath,
            bytes,
            fileOptions: FileOptions(
              contentType: _getContentType(fileExt),
              upsert: true,
            ),
          );

      // Get the public URL
      final publicUrl = Supabase.instance.client.storage
          .from('vehicle-images')
          .getPublicUrl(fullPath);

      if (mounted) {
        setState(() {
          _imageUrl = publicUrl;
          _isUploading = false;
        });
        widget.onUploaded?.call(publicUrl);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUploading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload failed: $e')),
        );
      }
    }
  }

  String _getContentType(String extension) {
    switch (extension.toLowerCase()) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';
      default:
        return 'image/jpeg';
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _isUploading ? null : _pickAndUpload,
      child: Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.primary.withOpacity(0.3),
            width: 2,
          ),
          image: _imageUrl != null && _imageUrl!.isNotEmpty
              ? DecorationImage(
                  image: NetworkImage(_imageUrl!),
                  fit: BoxFit.cover,
                )
              : null,
        ),
        child: Stack(
          children: [
            if (_imageUrl == null || _imageUrl!.isEmpty)
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.directions_bus_outlined,
                      size: 48,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Tap to add vehicle photo',
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            if (_isUploading)
              Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),
              ),
            if (widget.enabled && !_isUploading && (_imageUrl != null && _imageUrl!.isNotEmpty))
              Positioned(
                bottom: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.camera_alt,
                    size: 20,
                    color: Colors.white,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
