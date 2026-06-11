import 'package:flutter/material.dart';
import 'package:share_verify/core/commons/palette.dart';
import 'package:share_verify/core/commons/app_spacing.dart';
import 'package:share_verify/core/models/payment_status.dart';

class SvStatusBadge extends StatelessWidget {
  final PaymentStatus status;

  const SvStatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isReceived = status == PaymentStatus.received;
    final backgroundColor =
        isReceived ? theme.colorScheme.error : SvPalette.tertiary;
    final foregroundColor =
        isReceived ? theme.colorScheme.onError : SvPalette.onTertiary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(SvSpacing.radiusLg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'TRẠNG THÁI',
            style: theme.textTheme.labelLarge?.copyWith(
              color: foregroundColor.withValues(alpha: 0.8),
              fontSize: 14,
            ),
          ),
          Text(
            status.verificationBadgeLabel,
            style: theme.textTheme.headlineSmall?.copyWith(
              color: foregroundColor,
              fontWeight: FontWeight.w800,
              fontSize: 20,
            ),
          ),
        ],
      ),
    );
  }
}
