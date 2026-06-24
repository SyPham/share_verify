import 'package:flutter/material.dart';
import 'package:share_verify/core/commons/app_spacing.dart';
import 'package:share_verify/core/commons/palette.dart';

class SvKpiCard extends StatelessWidget {
  final String label;
  final String value;
  final Color backgroundColor;
  final Color foregroundColor;
  final Color? progressColor;
  final double? progress;
  final IconData icon;
  final bool showProgress;
  final VoidCallback? onTap;

  const SvKpiCard({
    super.key,
    required this.label,
    required this.value,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.icon,
    this.progress,
    this.progressColor,
    this.showProgress = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 1),
              child: Icon(icon, size: 16, color: foregroundColor),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: foregroundColor.withValues(alpha: 0.9),
                  height: 1.2,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.headlineLarge?.copyWith(color: foregroundColor),
        ),
        if (showProgress) ...[
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: (progressColor ?? Colors.white).withValues(alpha: 0.3),
              valueColor: AlwaysStoppedAnimation(progressColor ?? Colors.white),
            ),
          ),
        ],
      ],
    );

    final decoration = BoxDecoration(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(SvSpacing.radiusXl),
      border: Border.all(
        color: SvPalette.outlineVariant.withValues(alpha: 0.3),
      ),
    );

    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(SvSpacing.radiusXl),
          child: Ink(
            padding: const EdgeInsets.all(SvSpacing.cardPadding),
            decoration: decoration,
            child: content,
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(SvSpacing.cardPadding),
      decoration: decoration,
      child: content,
    );
  }
}
