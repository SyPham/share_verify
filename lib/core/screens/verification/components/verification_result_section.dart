import 'package:flutter/material.dart';
import 'package:share_verify/core/commons/app_spacing.dart';
import 'package:share_verify/core/commons/palette.dart';
import 'package:share_verify/core/models/payment_status.dart';
import 'package:share_verify/core/models/shareholder.dart';
import 'package:share_verify/core/widgets/sv_card.dart';
import 'package:share_verify/core/widgets/sv_primary_button.dart';
import 'package:share_verify/core/widgets/sv_result_info_row.dart';
import 'package:share_verify/core/widgets/sv_status_badge.dart';

class VerificationResultSection extends StatelessWidget {
  final Shareholder shareholder;
  final VoidCallback? onViewRecipients;
  final VoidCallback? onProcessNextPerson;
  final bool isSubmitting;
  final bool isLoadingRecipients;
  final bool receiveJustCompleted;

  const VerificationResultSection({
    super.key,
    required this.shareholder,
    this.onViewRecipients,
    this.onProcessNextPerson,
    this.isSubmitting = false,
    this.isLoadingRecipients = false,
    this.receiveJustCompleted = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SvCard(
      variant: SvCardVariant.primaryAccent,
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(SvSpacing.cardPadding),
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
                if (isSubmitting) ...[
                  const SizedBox(height: SvSpacing.md),
                  const LinearProgressIndicator(),
                  const SizedBox(height: SvSpacing.sm),
                  Text(
                    'Đang lưu thông tin phụ cấp...',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                if (receiveJustCompleted) ...[
                  const SizedBox(height: SvSpacing.md),
                  Text(
                    'Đã ghi nhận hỗ trợ thành công.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.tertiary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
                if (shareholder.status == PaymentStatus.received ||
                    receiveJustCompleted) ...[
                  const SizedBox(height: SvSpacing.md),
                  if (onViewRecipients != null &&
                      shareholder.status == PaymentStatus.received)
                    SvPrimaryButton(
                      label: isLoadingRecipients
                          ? 'Đang tải...'
                          : 'Xem thông tin người nhận',
                      icon: Icons.people_outline,
                      onPressed: isLoadingRecipients ? null : onViewRecipients,
                      backgroundColor: theme.colorScheme.secondaryContainer,
                      foregroundColor: theme.colorScheme.onSecondaryContainer,
                      height: 56,
                    ),
                  if (onViewRecipients != null &&
                      shareholder.status == PaymentStatus.received)
                    const SizedBox(height: SvSpacing.sm),
                  if (onProcessNextPerson != null) ...[
                    SvPrimaryButton(
                      label: 'Xử lý người tiếp theo',
                      icon: Icons.restart_alt,
                      onPressed: onProcessNextPerson,
                      height: 56,
                    ),
                    const SizedBox(height: SvSpacing.sm),
                  ],
                  if (!receiveJustCompleted)
                    Text(
                      'Cổ đông này đã nhận phụ cấp.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                ],
              ],
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: SvSpacing.cardPadding,
              vertical: SvSpacing.xs,
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
                    receiveJustCompleted
                        ? 'Nhấn "Xử lý người tiếp theo" để quay về bước 1.'
                        : shareholder.status == PaymentStatus.received
                            ? 'Xem chi tiết người nhận và ảnh chứng cứ bên trên.'
                            : isSubmitting
                            ? 'Hệ thống đang tự động lưu sau khi quét mã cổ đông.'
                            : 'Thông tin sẽ được lưu tự động khi quét mã cổ đông.',
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
