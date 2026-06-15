import 'package:flutter/material.dart';
import 'package:share_verify/core/commons/app_spacing.dart';
import 'package:share_verify/core/controllers/capture_controller.dart';
import 'package:share_verify/core/models/shareholder.dart';
import 'package:share_verify/core/widgets/sv_card.dart';
import 'package:share_verify/core/widgets/sv_outlined_button.dart';
import 'package:share_verify/core/widgets/sv_primary_button.dart';

class CaptureOverlayCard extends StatelessWidget {
  final Shareholder shareholder;
  final CaptureUiPhase phase;
  final VoidCallback onRetake;
  final VoidCallback onConfirm;
  final VoidCallback? onCapture;
  final VoidCallback? onApplyCrop;
  final bool isSubmitting;
  final bool isCapturing;
  final bool confirmEnabled;
  final String? confirmLabel;
  final String identityType;
  final bool openAiCmndCrop;

  const CaptureOverlayCard({
    super.key,
    required this.shareholder,
    required this.phase,
    required this.onRetake,
    required this.onConfirm,
    this.onCapture,
    this.onApplyCrop,
    this.isSubmitting = false,
    this.isCapturing = false,
    this.confirmEnabled = true,
    this.confirmLabel,
    this.identityType = 'CCCD',
    this.openAiCmndCrop = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SvCard(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: SvSpacing.md),
          _buildActions(),
          const SizedBox(height: SvSpacing.sm),
          Text(
            _hintForPhase(phase, identityType, openAiCmndCrop: openAiCmndCrop),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActions() {
    return switch (phase) {
      CaptureUiPhase.camera => SvPrimaryButton(
          label: isCapturing ? 'Đang chụp...' : 'Chụp ảnh',
          icon: isCapturing ? null : Icons.camera_alt,
          onPressed: isCapturing ? null : onCapture,
        ),
      CaptureUiPhase.cropping => Row(
          children: [
            Expanded(
              child: SvOutlinedButton(
                label: 'Chụp Lại',
                onPressed: onRetake,
              ),
            ),
            const SizedBox(width: SvSpacing.sm),
            Expanded(
              child: SvPrimaryButton(
                label: 'Dùng ảnh',
                icon: Icons.crop,
                onPressed: onApplyCrop,
              ),
            ),
          ],
        ),
      CaptureUiPhase.review => Row(
          children: [
            Expanded(
              child: SvOutlinedButton(
                label: 'Chụp Lại',
                onPressed: onRetake,
              ),
            ),
            const SizedBox(width: SvSpacing.sm),
            Expanded(
              child: SvPrimaryButton(
                label: isSubmitting
                    ? 'Đang xác nhận...'
                    : (confirmLabel ?? 'Xác Nhận'),
                onPressed: isSubmitting || !confirmEnabled ? null : onConfirm,
              ),
            ),
          ],
        ),
    };
  }

  String _hintForPhase(
    CaptureUiPhase phase,
    String type, {
    bool openAiCmndCrop = false,
  }) {
    return switch (phase) {
      CaptureUiPhase.camera =>
        _hintForCapture(type, openAiCmndCrop: openAiCmndCrop),
      CaptureUiPhase.cropping =>
        _hintForCrop(type, openAiCmndCrop: openAiCmndCrop),
      CaptureUiPhase.review =>
        _hintForReview(type, openAiCmndCrop: openAiCmndCrop),
    };
  }

  String _hintForCapture(String type, {bool openAiCmndCrop = false}) {
    if (type.toUpperCase() == 'CMND' && openAiCmndCrop) {
      return 'Chụp toàn bộ CMND rõ nét. Sau đó cắt tự do vùng số CMND và họ tên.';
    }
    return switch (type.toUpperCase()) {
      'CMND' =>
        'Đặt toàn bộ mặt trước CMND vào khung, chụp rõ và thẳng. Ảnh sẽ được tự cắt.',
      'PASSPORT' =>
        'Chụp rõ trang có ảnh và số hộ chiếu. Sau đó bạn sẽ cắt ảnh.',
      _ => 'Chụp rõ mặt trước CCCD. Sau đó bạn sẽ cắt ảnh.',
    };
  }

  String _hintForCrop(String type, {bool openAiCmndCrop = false}) {
    if (type.toUpperCase() == 'CMND' && openAiCmndCrop) {
      return 'Chọn Tự do, kéo khung chữ nhật ngang bao vùng số CMND và họ tên.';
    }
    return switch (type.toUpperCase()) {
      'CMND' =>
        'Chọn Vuông/Ngang/Dọc hoặc Tự do, kéo khung cắt rồi bấm Dùng ảnh.',
      'CCCD' =>
        'Chọn Vuông/Ngang/Dọc hoặc Tự do, kéo khung cắt rồi bấm Dùng ảnh.',
      _ => 'Chọn Vuông/Ngang/Dọc hoặc Tự do, kéo khung cắt rồi bấm Dùng ảnh.',
    };
  }

  String _hintForReview(String type, {bool openAiCmndCrop = false}) {
    if (type.toUpperCase() == 'CMND' && openAiCmndCrop) {
      return 'Kiểm tra vùng đã cắt và thông tin OpenAI OCR bên trên.';
    }
    return switch (type.toUpperCase()) {
      'CMND' =>
        'Kiểm tra ảnh đã tự cắt và thông tin OCR. Có thể sửa họ tên/số CMND bên trên.',
      'PASSPORT' =>
        'Kiểm tra ảnh và thông tin OCR. Có thể sửa thông tin bên trên.',
      _ =>
        'Kiểm tra ảnh và thông tin OCR. Có thể sửa thông tin bên trên nếu đọc sai.',
    };
  }
}
