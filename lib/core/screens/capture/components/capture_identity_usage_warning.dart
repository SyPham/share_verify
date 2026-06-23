import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:share_verify/core/commons/app_spacing.dart';
import 'package:share_verify/core/commons/palette.dart';
import 'package:share_verify/core/controllers/capture_controller.dart';
import 'package:share_verify/core/widgets/identity_usage_shareholder_section.dart';

class CaptureIdentityUsageWarning extends GetView<CaptureController> {
  const CaptureIdentityUsageWarning({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (!controller.hasIdentityUsageWarning) {
        return const SizedBox.shrink();
      }

      final check = controller.identityCheckResult.value!;
      final theme = Theme.of(context);
      return Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: SvSpacing.sm),
        padding: const EdgeInsets.all(SvSpacing.sm),
        decoration: BoxDecoration(
          color: SvPalette.warningContainer,
          borderRadius: BorderRadius.circular(SvSpacing.radiusLg),
          border: Border.all(color: SvPalette.warningBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.warning_amber_rounded,
                  color: SvPalette.warning,
                  size: 22,
                ),
                const SizedBox(width: SvSpacing.xs),
                Expanded(
                  child: Text(
                    'Giấy tờ đã được sử dụng',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: SvPalette.warning,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: SvSpacing.xs),
            Text(
              check.message ??
                  'Người này đã nhận phụ cấp cho mã cổ đông khác.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: SvPalette.onWarningContainer,
                height: 1.35,
              ),
            ),
            const SizedBox(height: SvSpacing.sm),
            IdentityUsageShareholderSection(
              check: check,
              titleStyle: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: SvPalette.onWarningContainer,
              ),
            ),
            const SizedBox(height: SvSpacing.xs),
            Text(
              'Kiểm tra lại thông tin hoặc bấm Xác nhận lần nữa để tiếp tục.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: SvPalette.warningMuted,
                height: 1.35,
              ),
            ),
          ],
        ),
      );
    });
  }
}
