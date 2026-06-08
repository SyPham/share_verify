import 'package:flutter/material.dart';
import 'package:share_verify/core/commons/app_spacing.dart';
import 'package:share_verify/core/commons/palette.dart';

enum SvCardVariant { outlined, primaryAccent }

class SvCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final SvCardVariant variant;
  final bool showShadow;
  final Color? backgroundColor;

  const SvCard({
    super.key,
    required this.child,
    this.padding,
    this.variant = SvCardVariant.outlined,
    this.showShadow = true,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final borderSide = variant == SvCardVariant.primaryAccent
        ? const BorderSide(color: SvPalette.primary, width: 2)
        : const BorderSide(color: SvPalette.outlineVariant, width: 1);

    final shadow = showShadow
        ? [
            BoxShadow(
              color: Colors.black.withValues(
                alpha: variant == SvCardVariant.primaryAccent ? 0.12 : 0.06,
              ),
              blurRadius: variant == SvCardVariant.primaryAccent ? 8 : 4,
              offset: Offset(0, variant == SvCardVariant.primaryAccent ? 2 : 1),
            ),
          ]
        : null;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: backgroundColor ?? SvPalette.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(SvSpacing.radiusXl),
        border: Border.fromBorderSide(borderSide),
        boxShadow: shadow,
      ),
      clipBehavior: Clip.antiAlias,
      child: padding != null ? Padding(padding: padding!, child: child) : child,
    );
  }
}
