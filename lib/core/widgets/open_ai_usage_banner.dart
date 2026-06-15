import 'package:flutter/material.dart';
import 'package:share_verify/core/commons/app_spacing.dart';
import 'package:share_verify/core/models/open_ai_usage_info.dart';

class OpenAiUsageBanner extends StatelessWidget {
  final OpenAiUsageInfo usage;

  const OpenAiUsageBanner({super.key, required this.usage});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: SvSpacing.sm,
        vertical: SvSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(SvSpacing.radiusLg),
      ),
      child: Text(
        'Chi phí OpenAI (${usage.model}): ${usage.displayLabel} · '
        '${usage.totalTokens} token '
        '(${usage.promptTokens} in / ${usage.completionTokens} out)',
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onPrimaryContainer,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
