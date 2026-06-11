import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:share_verify/core/commons/app_spacing.dart';
import 'package:share_verify/core/commons/palette.dart';
import 'package:share_verify/core/controllers/capture_controller.dart';

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
      final mcds = controller.usedShareholderCodes;

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
            if (mcds.isNotEmpty) ...[
              const SizedBox(height: SvSpacing.sm),
              Text(
                'Mã cổ đông đã nhận:',
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: SvPalette.onWarningContainer,
                ),
              ),
              const SizedBox(height: SvSpacing.xs),
              Wrap(
                spacing: SvSpacing.xs,
                runSpacing: SvSpacing.xs,
                children: [
                  for (final mcd in mcds)
                    Chip(
                      label: Text(
                        mcd,
                        style: theme.textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: SvPalette.onWarningContainer,
                        ),
                      ),
                      backgroundColor: SvPalette.warningChipBackground,
                      side: BorderSide.none,
                      visualDensity: VisualDensity.compact,
                    ),
                ],
              ),
            ],
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
