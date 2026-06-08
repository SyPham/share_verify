import 'package:flutter/material.dart';
import 'package:share_verify/core/commons/app_spacing.dart';
import 'package:share_verify/core/commons/palette.dart';
import 'package:share_verify/core/models/shareholder.dart';
import 'package:share_verify/core/widgets/sv_card.dart';
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
    return SvCard(
      variant: SvCardVariant.primaryAccent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
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
                              letterSpacing: 0.5,
                            ),
                          ),
                          Text(
                            shareholder.code,
                            style: theme.textTheme.headlineMedium?.copyWith(
                              color: SvPalette.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SvStatusBadge(status: shareholder.status),
                  ],
                ),
                const SizedBox(height: SvSpacing.md),
                Divider(color: SvPalette.outlineVariant, height: 1),
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
                  icon: Icons.check_circle,
                  onPressed: onConfirmPayment,
                  height: 64,
                ),
              ],
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: SvSpacing.md,
              vertical: SvSpacing.sm,
            ),
            color: SvPalette.surfaceContainerHigh,
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 16,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: SvSpacing.xs),
                Expanded(
                  child: Text(
                    'Vui lòng kiểm tra kỹ CCCD trước khi xác nhận.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
