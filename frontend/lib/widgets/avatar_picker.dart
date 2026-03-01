import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../themes/app_colors.dart';

/// A reusable widget for uploading and displaying profile avatars.
class AvatarPicker extends StatefulWidget {
  final String? currentAvatarUrl;
  final String storageBucket;
  final String storagePath;
  final double size;
  final Function(String url)? onUploaded;
  final bool enabled;

  const AvatarPicker({
    super.key,
    this.currentAvatarUrl,
    this.storageBucket = 'profile-photos',
    required this.storagePath,
    this.size = 120,
    this.onUploaded,
    this.enabled = true,
  });

  @override
  State<AvatarPicker> createState() => _AvatarPickerState();
}

class _AvatarPickerState extends State<AvatarPicker> {
  String? _avatarUrl;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _avatarUrl = widget.currentAvatarUrl;
  }

  @override
  void didUpdateWidget(AvatarPicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentAvatarUrl != widget.currentAvatarUrl) {
      _avatarUrl = widget.currentAvatarUrl;
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
          .from(widget.storageBucket)
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
          .from(widget.storageBucket)
          .getPublicUrl(fullPath);

      if (mounted) {
        setState(() {
          _avatarUrl = publicUrl;
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
      child: Stack(
        children: [
          Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.grey.shade200,
              border: Border.all(
                color: AppColors.primary.withOpacity(0.3),
                width: 3,
              ),
              image: _avatarUrl != null && _avatarUrl!.isNotEmpty
                  ? DecorationImage(
                      image: NetworkImage(_avatarUrl!),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: _avatarUrl == null || _avatarUrl!.isEmpty
                ? Icon(
                    Icons.person,
                    size: widget.size * 0.5,
                    color: Colors.grey.shade400,
                  )
                : null,
          ),
          if (_isUploading)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.black.withOpacity(0.5),
                ),
                child: const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),
              ),
            ),
          if (widget.enabled && !_isUploading)
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: Icon(
                  Icons.camera_alt,
                  size: widget.size * 0.16,
                  color: Colors.white,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
