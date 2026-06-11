import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:share_verify/core/commons/app_spacing.dart';
import 'package:share_verify/core/controllers/verification_controller.dart';
import 'package:share_verify/core/models/attendance_type.dart';
import 'package:share_verify/core/screens/verification/components/verification_manual_identity_form.dart';
import 'package:share_verify/core/widgets/sv_card.dart';
import 'package:share_verify/core/widgets/sv_primary_button.dart';

class VerificationIdentitySection extends GetView<VerificationController> {
  const VerificationIdentitySection({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SvCard(
          padding: const EdgeInsets.all(SvSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Obx(() {
                final isProxy =
                    controller.attendanceType.value == AttendanceType.proxy;
                final title = isProxy
                    ? 'Bước 1: Xác minh giấy tờ người ủy quyền'
                    : 'Bước 1: Xác minh giấy tờ người nhận';
                return Text(
                  title,
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                );
              }),
              const SizedBox(height: SvSpacing.sm),
              SvPrimaryButton(
                label: 'Quét QR CCCD',
                icon: Icons.qr_code_scanner,
                onPressed: controller.onScanQrCccd,
              ),
              const SizedBox(height: SvSpacing.sm),
              Row(
                children: [
                  Expanded(
                    child: SvPrimaryButton(
                      label: 'Chụp CCCD',
                      icon: Icons.camera_alt_outlined,
                      onPressed: controller.onCaptureCccd,
                      backgroundColor: colorScheme.secondaryContainer,
                      foregroundColor: colorScheme.onSecondaryContainer,
                    ),
                  ),
                  const SizedBox(width: SvSpacing.sm),
                  Expanded(
                    child: SvPrimaryButton(
                      label: 'Chụp CMND',
                      icon: Icons.badge_outlined,
                      onPressed: controller.onCaptureCmnd,
                      backgroundColor: colorScheme.secondaryContainer,
                      foregroundColor: colorScheme.onSecondaryContainer,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: SvSpacing.sm),
              SvPrimaryButton(
                label: 'Chụp Hộ Chiếu',
                icon: Icons.card_travel_outlined,
                onPressed: controller.onCapturePassport,
                backgroundColor: colorScheme.surfaceContainerHigh,
                foregroundColor: colorScheme.onSurface,
              ),
            ],
          ),
        ),
        const SizedBox(height: SvSpacing.sm),
        const VerificationManualIdentityForm(),
      ],
    );
  }
}
