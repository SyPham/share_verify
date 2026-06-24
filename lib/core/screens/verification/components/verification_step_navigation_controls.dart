import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:share_verify/core/controllers/verification_controller.dart';
import 'package:share_verify/core/screens/verification/components/verification_step_indicator.dart';

class VerificationStepNavigationControls extends GetView<VerificationController> {
  static const backKey = Key('verification-step-nav-back');
  static const forwardKey = Key('verification-step-nav-forward');
  static const _navSlotSize = 36.0;

  const VerificationStepNavigationControls({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      controller.manualIdentityFormRevision.value;
      controller.manualPhotoPath.value;
      controller.verificationStep.value;
      controller.isCheckingIdentity.value;
      controller.isSubmitting.value;
      controller.isSearching.value;
      controller.selectedShareholder.value;
      controller.scannedBarcode.value;
      controller.selectedPickerShareholder.value;

      final step = controller.verificationStep.value;
      final canBack = controller.canGoToPreviousStep;
      final canForward = controller.canGoToNextStep;

      return VerificationStepIndicator(
        current: step,
        leading: _navSlot(
          child: _CompactStepNavButton(
            buttonKey: backKey,
            icon: Icons.chevron_left_rounded,
            tooltip: 'Lùi bước',
            enabled: canBack,
            onPressed: controller.goBackStep,
          ),
        ),
        trailing: _navSlot(
          child: _CompactStepNavButton(
            buttonKey: forwardKey,
            icon: Icons.chevron_right_rounded,
            tooltip: 'Tiến bước',
            enabled: canForward,
            onPressed: () => unawaited(controller.goToNextStep()),
          ),
        ),
      );
    });
  }

  static Widget _navSlot({required Widget child}) {
    return SizedBox(
      width: _navSlotSize,
      height: _navSlotSize,
      child: child,
    );
  }
}

class _CompactStepNavButton extends StatelessWidget {
  final Key buttonKey;
  final IconData icon;
  final String tooltip;
  final bool enabled;
  final VoidCallback onPressed;

  const _CompactStepNavButton({
    required this.buttonKey,
    required this.icon,
    required this.tooltip,
    required this.enabled,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      key: buttonKey,
      onPressed: enabled ? onPressed : null,
      tooltip: tooltip,
      icon: Icon(icon, size: 24),
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints.tightFor(
        width: VerificationStepNavigationControls._navSlotSize,
        height: VerificationStepNavigationControls._navSlotSize,
      ),
    );
  }
}
