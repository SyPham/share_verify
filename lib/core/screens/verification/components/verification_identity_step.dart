import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:share_verify/core/commons/app_spacing.dart';
import 'package:share_verify/core/controllers/verification_controller.dart';
import 'package:share_verify/core/screens/verification/components/verification_identity_section.dart';
import 'package:share_verify/core/screens/verification/components/verification_step_advance_footer.dart';

class VerificationIdentityStepBody extends GetView<VerificationController> {
  const VerificationIdentityStepBody({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: controller.goBackStep,
            icon: const Icon(Icons.arrow_back),
            label: const Text('Quay lại'),
          ),
        ),
        const VerificationIdentitySection(),
        const SizedBox(height: SvSpacing.md),
        Obx(() {
          if (controller.isCheckingIdentity.value) {
            return const LinearProgressIndicator();
          }
          return const SizedBox.shrink();
        }),
      ],
    );
  }
}

class VerificationIdentityStepFooter extends GetView<VerificationController> {
  const VerificationIdentityStepFooter({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      controller.manualIdentityFormRevision.value;
      controller.manualFormPrefillSource.value;
      controller.manualIdentityType.value;
      controller.manualPhotoPath.value;

      if (!controller.isIdentityInfoReady) {
        return const SizedBox.shrink();
      }

      final isBusy = controller.isCheckingIdentity.value;
      final label = controller.isIdentityReady
          ? 'Tiếp tục'
          : 'Tiếp tục chụp ảnh chứng cứ';

      return Padding(
        padding: const EdgeInsets.only(top: SvSpacing.md),
        child: VerificationStepAdvanceFooter(
          label: label,
          enabled: !isBusy,
          onAdvance: controller.advanceToEvidenceStep,
        ),
      );
    });
  }
}

class VerificationIdentityStep extends GetView<VerificationController> {
  const VerificationIdentityStep({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        VerificationIdentityStepBody(),
        VerificationIdentityStepFooter(),
      ],
    );
  }
}
