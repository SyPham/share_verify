import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:share_verify/core/commons/app_spacing.dart';
import 'package:share_verify/core/commons/palette.dart';
import 'package:share_verify/core/data/dto/shareholder_dtos.dart';

class ShareholderListTile extends StatelessWidget {
  final ShareholderSearchDto item;
  final VoidCallback? onTap;

  const ShareholderListTile({
    super.key,
    required this.item,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final subtitleParts = <String>[
      item.mcd,
      if (item.registrationNo != null && item.registrationNo!.isNotEmpty)
        item.registrationNo!,
    ];

    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: SvSpacing.cardPadding,
        vertical: SvSpacing.xs,
      ),
      leading: CircleAvatar(
        backgroundColor: item.travelSupportReceived
            ? theme.colorScheme.primaryContainer.withValues(alpha: 0.35)
            : theme.colorScheme.errorContainer.withValues(alpha: 0.4),
        child: Text(
          item.fullName.isNotEmpty
              ? item.fullName.substring(0, 1).toUpperCase()
              : '?',
          style: TextStyle(
            color: item.travelSupportReceived
                ? theme.colorScheme.primary
                : theme.colorScheme.onErrorContainer,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      title: Text(
        item.fullName,
        style:
            theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 2),
          Text(
            subtitleParts.join(' · '),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '${NumberFormat('#,###').format(item.totalShares)} CP',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: SvSpacing.xs,
              vertical: 2,
            ),
            decoration: BoxDecoration(
              color: item.travelSupportReceived
                  ? SvPalette.primaryFixed
                  : theme.colorScheme.errorContainer,
              borderRadius: BorderRadius.circular(SvSpacing.radiusLg),
            ),
            child: Text(
              item.travelSupportReceived ? 'ĐÃ NHẬN' : 'CHƯA NHẬN',
              style: theme.textTheme.labelSmall?.copyWith(
                color: item.travelSupportReceived
                    ? SvPalette.primary
                    : theme.colorScheme.onErrorContainer,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 2),
          const Icon(Icons.chevron_right, color: SvPalette.onSurfaceVariant),
        ],
      ),
    );
  }
}
