import 'package:flutter/material.dart';
import 'package:share_verify/core/commons/app_spacing.dart';
import 'package:share_verify/core/commons/palette.dart';

class SvKpiCard extends StatelessWidget {
  final String label;
  final String value;
  final Color backgroundColor;
  final Color foregroundColor;
  final Color progressColor;
  final double progress;
  final IconData icon;

  const SvKpiCard({
    super.key,
    required this.label,
    required this.value,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.progress,
    required this.icon,
    this.progressColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(SvSpacing.md),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(SvSpacing.radiusXl),
        border: Border.all(
          color: SvPalette.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: foregroundColor),
              const SizedBox(width: 4),
              Text(
                label,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: foregroundColor.withValues(alpha: 0.9),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: theme.textTheme.headlineLarge?.copyWith(color: foregroundColor),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: progressColor.withValues(alpha: 0.3),
              valueColor: AlwaysStoppedAnimation(progressColor),
            ),
          ),
        ],
      ),
    );
  }
}
