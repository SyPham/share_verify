import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:share_verify/core/commons/app_spacing.dart';
import 'package:share_verify/core/controllers/verification_controller.dart';
import 'package:share_verify/core/widgets/evidence_photo_preview.dart';
import 'package:share_verify/core/widgets/sv_card.dart';
import 'package:share_verify/core/widgets/sv_outlined_button.dart';
import 'package:share_verify/core/widgets/sv_primary_button.dart';
import 'package:share_verify/core/widgets/sv_result_info_row.dart';

class VerificationEvidenceStep extends GetView<VerificationController> {
  const VerificationEvidenceStep({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: controller.goBackStep,
            icon: const Icon(Icons.arrow_back),
            label: const Text('Quay lại'),
          ),
        ),
        Text(
          'Chụp ảnh minh chứng người nhận trước khi quét mã cổ đông.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            height: 1.35,
          ),
        ),
        const SizedBox(height: SvSpacing.md),
        Obx(() {
          final name = controller.manualNameController.text.trim();
          final id = controller.manualIdController.text.trim();
          final type = controller.manualIdentityType.value;
          if (name.isEmpty || id.isEmpty) {
            return const SizedBox.shrink();
          }
          return SvCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Thông tin giấy tờ',
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: SvSpacing.sm),
                SvResultInfoRow(
                  icon: Icons.person_outline,
                  label: 'Họ và tên',
                  value: name,
                ),
                const SizedBox(height: SvSpacing.sm),
                SvResultInfoRow(
                  icon: Icons.badge_outlined,
                  label: 'Số $type',
                  value: id,
                ),
              ],
            ),
          );
        }),
        const SizedBox(height: SvSpacing.md),
        Obx(() {
          final hasPhoto = controller.manualPhotoPath.value != null;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (hasPhoto) ...[
                EvidencePhotoPreview(
                  photoBytes: controller.manualPhotoBytes.value,
                  photoPath: controller.manualPhotoPath.value,
                ),
                const SizedBox(height: SvSpacing.sm),
              ],
              SvPrimaryButton(
                label: hasPhoto
                    ? 'Chụp lại ảnh chứng cứ'
                    : 'Chụp ảnh chứng cứ',
                icon: Icons.camera_alt_outlined,
                onPressed: controller.onCaptureManualPhoto,
                backgroundColor: theme.colorScheme.secondaryContainer,
                foregroundColor: theme.colorScheme.onSecondaryContainer,
                height: 56,
              ),
              const SizedBox(height: SvSpacing.sm),
              SvOutlinedButton(
                label: 'Xóa và nhập lại',
                icon: Icons.restart_alt,
                onPressed: controller.resetManualIdentityForm,
                foregroundColor: theme.colorScheme.onSurfaceVariant,
              ),
            ],
          );
        }),
        const SizedBox(height: SvSpacing.md),
        Obx(() {
          if (controller.isCheckingIdentity.value) {
            return const LinearProgressIndicator();
          }
          if (!controller.isIdentityReady) {
            return const SizedBox.shrink();
          }
          return SvPrimaryButton(
            label: 'Tiếp tục quét mã cổ đông',
            icon: Icons.arrow_forward,
            onPressed: controller.advanceToBarcodeStep,
            height: 56,
          );
        }),
      ],
    );
  }
}
