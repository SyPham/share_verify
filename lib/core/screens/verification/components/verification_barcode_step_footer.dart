import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:share_verify/core/commons/app_spacing.dart';
import 'package:share_verify/core/controllers/verification_controller.dart';
import 'package:share_verify/core/screens/verification/components/verification_step_advance_footer.dart';

class VerificationBarcodeStepFooter extends GetView<VerificationController> {
  const VerificationBarcodeStepFooter({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (!controller.hasShareholderSelected) {
        return const SizedBox.shrink();
      }

      final isBusy =
          controller.isSubmitting.value || controller.isSearching.value;

      return Padding(
        padding: const EdgeInsets.only(top: SvSpacing.md),
        child: VerificationStepAdvanceFooter(
          label: 'Xử lý người tiếp theo',
          icon: Icons.restart_alt,
          enabled: !isBusy,
          onAdvance: controller.processNextPerson,
        ),
      );
    });
  }
}
