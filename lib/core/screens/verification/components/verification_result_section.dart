import 'package:flutter/material.dart';
import 'package:share_verify/core/commons/app_spacing.dart';
import 'package:share_verify/core/models/shareholder.dart';
import 'package:share_verify/core/widgets/sv_primary_button.dart';
import 'package:share_verify/core/widgets/sv_result_info_row.dart';
import 'package:share_verify/core/widgets/sv_status_badge.dart';

class VerificationResultSection extends StatelessWidget {
  final Shareholder shareholder;
  final VoidCallback onConfirmPayment;

  const VerificationResultSection({
    super.key,
    required this.shareholder,
    required this.onConfirmPayment,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(SvSpacing.radiusXl),
      ),
      child: Padding(
        padding: const EdgeInsets.all(SvSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Mã cổ đông',
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
                    ],
                  ),
                ),
                SvStatusBadge(status: shareholder.status),
              ],
            ),
            const SizedBox(height: SvSpacing.md),
            SvResultInfoRow(
              icon: Icons.person_outline,
              label: 'Họ và tên',
              value: shareholder.fullName,
            ),
            const SizedBox(height: SvSpacing.sm),
            SvResultInfoRow(
              icon: Icons.pie_chart_outline,
              label: 'Số cổ phần sở hữu',
              value: '${shareholder.shares} CP',
            ),
            const SizedBox(height: SvSpacing.md),
            SvPrimaryButton(
              label: 'XÁC NHẬN ĐÃ PHÁT TIỀN',
              onPressed: onConfirmPayment,
              height: 64,
            ),
            const SizedBox(height: SvSpacing.sm),
            Text(
              'Vui lòng kiểm tra kỹ CCCD trước khi xác nhận.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
