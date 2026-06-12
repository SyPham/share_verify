import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:share_verify/core/commons/app_spacing.dart';
import 'package:share_verify/core/commons/palette.dart';
import 'package:share_verify/core/models/recipient_list_item.dart';

class RecipientListTile extends StatelessWidget {
  final RecipientListItem item;
  final VoidCallback? onTap;

  const RecipientListTile({
    super.key,
    required this.item,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final timeLabel =
        DateFormat('HH:mm dd/MM/yyyy').format(item.receiveTime.toLocal());
    final subtitleParts = <String>[
      item.primaryMcd,
      if (item.identityNo != null && item.identityNo!.isNotEmpty)
        item.identityNo!,
      if (item.isProxy && item.proxyPersonName != null)
        'Ủy quyền: ${item.proxyPersonName}',
    ];

    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: SvSpacing.cardPadding,
        vertical: SvSpacing.xs,
      ),
      leading: CircleAvatar(
        backgroundColor: theme.colorScheme.primaryContainer.withValues(
          alpha: 0.35,
        ),
        child: Text(
          item.displayName.isNotEmpty
              ? item.displayName.substring(0, 1).toUpperCase()
              : '?',
          style: TextStyle(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      title: Text(
        item.displayName,
        style: theme.textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w600,
        ),
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
            timeLabel,
            style: theme.textTheme.labelSmall?.copyWith(
              color: SvPalette.tertiary,
            ),
          ),
        ],
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (item.linkedMcdCount > 1)
            Text(
              '${item.linkedMcdCount} MCD',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          const Icon(Icons.chevron_right, color: SvPalette.onSurfaceVariant),
        ],
      ),
    );
  }
}
