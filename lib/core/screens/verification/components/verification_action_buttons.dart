import 'package:flutter/material.dart';
import 'package:share_verify/core/commons/app_spacing.dart';
import 'package:share_verify/core/widgets/sv_primary_button.dart';

@Deprecated('Use VerificationIdentitySection instead')
class VerificationActionButtons extends StatelessWidget {
  final VoidCallback onScanQr;
  final VoidCallback onCaptureId;
  final VoidCallback onManualEntry;

  const VerificationActionButtons({
    super.key,
    required this.onScanQr,
    required this.onCaptureId,
    required this.onManualEntry,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        SvPrimaryButton(
          label: 'Quét QR CCCD',
          icon: Icons.qr_code_scanner,
          onPressed: onScanQr,
        ),
        const SizedBox(height: SvSpacing.sm),
        Row(
          children: [
            Expanded(
              child: SvPrimaryButton(
                label: 'Chụp CCCD / Hộ Chiếu',
                onPressed: onCaptureId,
                backgroundColor: colorScheme.secondaryContainer,
                foregroundColor: colorScheme.onSecondaryContainer,
              ),
            ),
            const SizedBox(width: SvSpacing.sm),
            Expanded(
              child: SvPrimaryButton(
                label: 'Nhập Tay',
                onPressed: onManualEntry,
                backgroundColor: colorScheme.surfaceContainerHigh,
                foregroundColor: colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
