import 'package:flutter/material.dart';
import 'package:share_verify/core/widgets/sv_primary_button.dart';

class VerificationStepAdvanceFooter extends StatelessWidget {
  final String label;
  final bool enabled;
  final VoidCallback onAdvance;
  final IconData icon;

  const VerificationStepAdvanceFooter({
    super.key,
    required this.label,
    required this.enabled,
    required this.onAdvance,
    this.icon = Icons.arrow_forward,
  });

  @override
  Widget build(BuildContext context) {
    return SvPrimaryButton(
      label: label,
      icon: icon,
      onPressed: enabled ? onAdvance : null,
      height: 56,
    );
  }
}
