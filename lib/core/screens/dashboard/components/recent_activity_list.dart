import 'package:flutter/material.dart';
import 'package:share_verify/core/commons/app_spacing.dart';
import 'package:share_verify/core/commons/palette.dart';
import 'package:share_verify/core/models/activity_item.dart';
import 'package:share_verify/core/widgets/sv_card.dart';

class RecentActivityList extends StatelessWidget {
  final List<ActivityItem> activities;

  const RecentActivityList({super.key, required this.activities});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return SvCard(
      showShadow: false,
      child: ListView.separated(
        itemCount: activities.length,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        separatorBuilder: (_, __) => Divider(
          height: 1,
          indent: SvSpacing.md,
          endIndent: SvSpacing.md,
          color: SvPalette.outlineVariant,
        ),
        itemBuilder: (context, index) {
          final activity = activities[index];
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: colorScheme.primaryContainer.withValues(alpha: 0.2),
              child: Text(
                activity.fullName.substring(0, 1).toUpperCase(),
                style: TextStyle(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            title: Text(
              '${activity.fullName}/${activity.shareholderCode}',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(activity.timeLabel, style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: SvSpacing.xs),
                Text(
                  activity.statusLabel,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: colorScheme.tertiary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
