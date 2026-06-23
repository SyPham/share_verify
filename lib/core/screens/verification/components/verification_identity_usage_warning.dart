import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:share_verify/core/commons/app_spacing.dart';
import 'package:share_verify/core/commons/palette.dart';
import 'package:share_verify/core/controllers/verification_controller.dart';
import 'package:share_verify/core/widgets/sv_card.dart';
import 'package:share_verify/core/widgets/identity_usage_shareholder_section.dart';
import 'package:share_verify/core/widgets/sv_primary_button.dart';

class VerificationIdentityUsageWarning extends GetView<VerificationController> {
  const VerificationIdentityUsageWarning({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.isCheckingIdentity.value) {
        return const Padding(
          padding: EdgeInsets.only(top: SvSpacing.sm),
          child: LinearProgressIndicator(),
        );
      }

      final check = controller.identityCheckResult.value;
      if (check == null || !check.alreadyUsed) {
        return const SizedBox.shrink();
      }

      final theme = Theme.of(context);
      return Padding(
        padding: const EdgeInsets.only(top: SvSpacing.lg),
        child: SvCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    color: theme.colorScheme.error,
                    size: 22,
                  ),
                  const SizedBox(width: SvSpacing.xs),
                  Expanded(
                    child: Text(
                      'Giấy tờ đã được sử dụng',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.error,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: SvSpacing.sm),
              Text(
                check.message ?? 'Người này đã nhận phụ cấp trước đó.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  height: 1.4,
                ),
              ),
              const SizedBox(height: SvSpacing.sm),
              IdentityUsageShareholderSection(
                check: check,
                titleStyle: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: SvSpacing.sm),
              Obx(() {
                final canProceed = controller.canProceedToBarcodeScreen;
                final isBusy = controller.isCheckingIdentity.value ||
                    controller.isSubmitting.value;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      canProceed
                          ? 'Bạn vẫn có thể tiếp tục quét mã cổ đông khác.'
                          : 'Vui lòng chụp ảnh chứng cứ và nhập đủ thông tin trước khi quét mã cổ đông.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        height: 1.35,
                      ),
                    ),
                    if (canProceed) ...[
                      const SizedBox(height: SvSpacing.sm),
                      SvPrimaryButton(
                        label: 'Quét mã cổ đông',
                        icon: Icons.qr_code_2,
                        onPressed: isBusy ? null : controller.goToBarcodeScreen,
                        height: 48,
                      ),
                    ],
                  ],
                );
              }),
            ],
          ),
        ),
      );
    });
  }
}
