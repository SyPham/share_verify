import 'package:flutter/material.dart';
import 'package:share_verify/core/commons/app_spacing.dart';
import 'package:share_verify/core/widgets/sv_card.dart';

class ProgressRingSection extends StatelessWidget {
  final double progress;
  final String percentText;

  const ProgressRingSection({
    super.key,
    required this.progress,
    required this.percentText,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return SvCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Tiến độ chi trả', style: theme.textTheme.titleMedium),
          const SizedBox(height: SvSpacing.md),
          Center(
            child: SizedBox(
              width: 120,
              height: 120,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 120,
                    height: 120,
                    child: CircularProgressIndicator(
                      value: progress,
                      strokeWidth: 10,
                      backgroundColor: colorScheme.surfaceContainerHigh,
                      valueColor: AlwaysStoppedAnimation(colorScheme.primary),
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        percentText,
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text('Hoàn thành', style: theme.textTheme.labelLarge),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
