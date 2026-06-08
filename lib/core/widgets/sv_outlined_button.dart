import 'package:flutter/material.dart';
import 'package:share_verify/core/commons/app_spacing.dart';
import 'package:share_verify/core/commons/palette.dart';

class SvOutlinedButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final Color? foregroundColor;
  final Color? borderColor;
  final double? height;

  const SvOutlinedButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.foregroundColor,
    this.borderColor,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final color = foregroundColor ?? SvPalette.primary;
    return SizedBox(
      width: double.infinity,
      height: height ?? SvSpacing.touchTarget,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: color,
          backgroundColor: SvPalette.surfaceContainerHigh,
          side: BorderSide(color: borderColor ?? SvPalette.outlineVariant),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(SvSpacing.radiusXl),
          ),
        ),
        icon: icon != null ? Icon(icon) : const SizedBox.shrink(),
        label: Text(label, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
      ),
    );
  }
}
