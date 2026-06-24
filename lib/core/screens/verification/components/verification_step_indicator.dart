import 'package:flutter/material.dart';
import 'package:share_verify/core/commons/app_spacing.dart';
import 'package:share_verify/core/commons/palette.dart';
import 'package:share_verify/core/models/verification_step.dart';

class VerificationStepIndicator extends StatelessWidget {
  final VerificationStep current;
  final Widget? leading;
  final Widget? trailing;

  const VerificationStepIndicator({
    super.key,
    required this.current,
    this.leading,
    this.trailing,
  });

  static const _steps = VerificationStep.values;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final total = _steps.length;

    return Semantics(
      label: 'Bước ${current.number} trên $total: ${current.title}',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              if (leading != null) leading!,
              Expanded(
                child: Text(
                  'Bước ${current.number}/$total',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: SvPalette.primary,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: SvSpacing.xs),
          Text(
            current.title,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              height: 1.15,
            ),
          ),
          const SizedBox(height: SvSpacing.md),
          LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 420;
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (var i = 0; i < _steps.length; i++) ...[
                    if (i > 0)
                      Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(
                            top: compact ? 17 : 21,
                          ),
                          child: _StepConnector(
                            filled: _steps[i].number <= current.number,
                          ),
                        ),
                      ),
                    _StepNode(
                      step: _steps[i],
                      current: current,
                      compact: compact,
                    ),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _StepNode extends StatelessWidget {
  final VerificationStep step;
  final VerificationStep current;
  final bool compact;

  const _StepNode({
    required this.step,
    required this.current,
    required this.compact,
  });

  bool get isCompleted => step.number < current.number;
  bool get isCurrent => step == current;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final radius = isCurrent ? (compact ? 22.0 : 24.0) : (compact ? 17.0 : 19.0);

    final Color circleColor;
    final Color contentColor;
    final Border? border;

    if (isCompleted) {
      circleColor = SvPalette.primary;
      contentColor = SvPalette.onPrimary;
      border = null;
    } else if (isCurrent) {
      circleColor = SvPalette.primary;
      contentColor = SvPalette.onPrimary;
      border = Border.all(color: SvPalette.primaryFixed, width: 3);
    } else {
      circleColor = SvPalette.surfaceContainerHigh;
      contentColor = SvPalette.onSurfaceVariant;
      border = Border.all(color: SvPalette.outlineVariant, width: 1.5);
    }

    final titleStyle = theme.textTheme.labelSmall?.copyWith(
      fontWeight: isCurrent ? FontWeight.w800 : FontWeight.w500,
      fontSize: isCurrent ? (compact ? 11 : 12) : (compact ? 10 : 11),
      height: 1.2,
      color: isCurrent
          ? SvPalette.primary
          : isCompleted
              ? SvPalette.onSurface
              : SvPalette.onSurfaceVariant.withValues(alpha: 0.65),
    );

    return Expanded(
      child: Column(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
            width: radius * 2,
            height: radius * 2,
            decoration: BoxDecoration(
              color: circleColor,
              shape: BoxShape.circle,
              border: border,
              boxShadow: isCurrent
                  ? [
                      BoxShadow(
                        color: SvPalette.primary.withValues(alpha: 0.28),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ]
                  : null,
            ),
            alignment: Alignment.center,
            child: isCompleted
                ? Icon(Icons.check_rounded, color: contentColor, size: compact ? 20 : 22)
                : Text(
                    '${step.number}',
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: contentColor,
                      fontWeight: FontWeight.w800,
                      fontSize: isCurrent ? 18 : 15,
                    ),
                  ),
          ),
          if (!compact || isCurrent || isCompleted) ...[
            const SizedBox(height: SvSpacing.xs),
            Text(
              step.title,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: titleStyle,
            ),
          ],
        ],
      ),
    );
  }
}

class _StepConnector extends StatelessWidget {
  final bool filled;

  const _StepConnector({required this.filled});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      height: 3,
      margin: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        color: filled ? SvPalette.primary : SvPalette.outlineVariant,
        borderRadius: BorderRadius.circular(999),
      ),
    );
  }
}
