import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:share_verify/core/commons/app_spacing.dart';
import 'package:share_verify/core/config/app_setting.dart';
import 'package:share_verify/core/services/app_config_service.dart';

class EvidencePhotoPreview extends StatelessWidget {
  final Uint8List? photoBytes;
  final String? photoPath;
  final String label;

  const EvidencePhotoPreview({
    super.key,
    this.photoBytes,
    this.photoPath,
    this.label = 'Ảnh chứng cứ',
  });

  bool get _hasLocalBytes => photoBytes != null && photoBytes!.isNotEmpty;

  bool get _hasRemotePath => photoPath != null && photoPath!.isNotEmpty;

  bool get hasPhoto => _hasLocalBytes || _hasRemotePath;

  String? get _remoteUrl {
    if (!_hasRemotePath) return null;
    final path = photoPath!.startsWith('/')
        ? photoPath!.substring(1)
        : photoPath!;
    final base = Get.isRegistered<AppConfigService>()
        ? Get.find<AppConfigService>().baseUrl
        : AppSetting.defaultBaseUrl;
    return '$base/$path';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (!hasPhoto) {
      return Row(
        children: [
          Icon(
            Icons.photo_camera_outlined,
            size: 20,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: SvSpacing.xs),
          Text(
            'Chưa có ảnh chứng cứ',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.labelLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: SvSpacing.xs),
        GestureDetector(
          onTap: () => _openFullscreen(context),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(SvSpacing.radiusLg),
            child: AspectRatio(
              aspectRatio: 4 / 3,
              child: _buildImage(),
            ),
          ),
        ),
        const SizedBox(height: SvSpacing.xs),
        Text(
          'Chạm ảnh để xem phóng to',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildImage() {
    if (_hasLocalBytes) {
      return Image.memory(
        photoBytes!,
        fit: BoxFit.cover,
        gaplessPlayback: true,
      );
    }

    return Image.network(
      _remoteUrl!,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return const Center(child: CircularProgressIndicator());
      },
      errorBuilder: (_, __, ___) => const _ImageErrorPlaceholder(),
    );
  }

  void _openFullscreen(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.all(SvSpacing.md),
        backgroundColor: Colors.black,
        child: Stack(
          children: [
            InteractiveViewer(
              minScale: 0.5,
              maxScale: 4,
              child: _hasLocalBytes
                  ? Image.memory(photoBytes!, fit: BoxFit.contain)
                  : Image.network(
                      _remoteUrl!,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) =>
                          const _ImageErrorPlaceholder(),
                    ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: IconButton(
                style: IconButton.styleFrom(
                  backgroundColor: Colors.black54,
                  foregroundColor: Colors.white,
                ),
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ImageErrorPlaceholder extends StatelessWidget {
  const _ImageErrorPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black12,
      child: const Center(
        child: Icon(Icons.broken_image_outlined, size: 40),
      ),
    );
  }
}
