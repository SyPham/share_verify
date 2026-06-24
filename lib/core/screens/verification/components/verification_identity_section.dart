import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:share_verify/core/commons/app_spacing.dart';
import 'package:share_verify/core/commons/palette.dart';
import 'package:share_verify/core/controllers/verification_controller.dart';
import 'package:share_verify/core/screens/verification/components/verification_manual_identity_form.dart';
import 'package:share_verify/core/widgets/sv_card.dart';

class VerificationIdentitySection extends GetView<VerificationController> {
  const VerificationIdentitySection({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final compactLabels = MediaQuery.sizeOf(context).width < 360;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SvCard(
          padding: const EdgeInsets.symmetric(
            horizontal: SvSpacing.cardPadding,
            vertical: 8,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _IdentityCaptureAction(
                  icon: Icons.qr_code_scanner,
                  label: 'Quét QR CCCD',
                  tooltip: 'Quét QR CCCD',
                  onPressed: controller.onScanQrCccd,
                  backgroundColor: SvPalette.primary,
                  foregroundColor: SvPalette.onPrimary,
                  compactLabel: compactLabels,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _IdentityCaptureAction(
                  icon: Icons.badge_outlined,
                  label: 'Chụp CMND',
                  tooltip: 'Chụp CMND',
                  onPressed: controller.onCaptureCmnd,
                  backgroundColor: colorScheme.secondaryContainer,
                  foregroundColor: colorScheme.onSecondaryContainer,
                  compactLabel: compactLabels,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _IdentityCaptureAction(
                  icon: Icons.card_travel_outlined,
                  label: 'Chụp Hộ chiếu',
                  tooltip: 'Chụp Hộ chiếu',
                  onPressed: controller.onCapturePassport,
                  backgroundColor: colorScheme.surfaceContainerHigh,
                  foregroundColor: colorScheme.onSurface,
                  compactLabel: compactLabels,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: SvSpacing.sm),
        const VerificationManualIdentityForm(),
      ],
    );
  }
}

class _IdentityCaptureAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final String tooltip;
  final VoidCallback onPressed;
  final Color backgroundColor;
  final Color foregroundColor;
  final bool compactLabel;

  const _IdentityCaptureAction({
    required this.icon,
    required this.label,
    required this.tooltip,
    required this.onPressed,
    required this.backgroundColor,
    required this.foregroundColor,
    this.compactLabel = false,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Theme(
        data: Theme.of(context).copyWith(
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          visualDensity: VisualDensity.compact,
        ),
        child: Material(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(SvSpacing.radiusLg),
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(SvSpacing.radiusLg),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 20, color: foregroundColor),
                  const SizedBox(height: 4),
                  Text(
                    label,
                    textAlign: TextAlign.center,
                    maxLines: compactLabel ? 1 : 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: compactLabel ? 10 : 11,
                      fontWeight: FontWeight.w600,
                      height: 1.1,
                      color: foregroundColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
