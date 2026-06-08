import 'package:flutter/material.dart';
import 'package:share_verify/core/commons/app_spacing.dart';
import 'package:share_verify/core/models/shareholder.dart';
import 'package:share_verify/core/widgets/sv_card.dart';
import 'package:share_verify/core/widgets/sv_outlined_button.dart';
import 'package:share_verify/core/widgets/sv_primary_button.dart';

class CaptureOverlayCard extends StatelessWidget {
  final Shareholder shareholder;
  final VoidCallback onRetake;
  final VoidCallback onConfirm;

  const CaptureOverlayCard({
    super.key,
    required this.shareholder,
    required this.onRetake,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SvCard(
      padding: const EdgeInsets.all(SvSpacing.md),
      child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Mã Cổ Đông',
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            Text(
              shareholder.code,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: SvSpacing.sm),
            Text(
              'Họ và Tên',
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            Text(
              shareholder.fullName,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: SvSpacing.sm),
            Row(
              children: [
                Icon(
                  Icons.check_circle,
                  color: theme.colorScheme.tertiary,
                  size: 20,
                ),
                const SizedBox(width: SvSpacing.xs),
                Text(
                  'Thông tin đã khớp',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.tertiary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: SvSpacing.md),
            Row(
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
                    label: 'Xác Nhận',
                    onPressed: onConfirm,
                  ),
                ),
              ],
            ),
            const SizedBox(height: SvSpacing.sm),
            Text(
              'Đảm bảo ảnh chụp rõ nét khuôn mặt và thẻ căn cước/hộ chiếu của cổ đông.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
    );
  }
}
