import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:share_verify/core/commons/app_spacing.dart';
import 'package:share_verify/core/controllers/verification_controller.dart';
import 'package:share_verify/core/screens/verification/components/verification_barcode_section.dart';
import 'package:share_verify/core/screens/verification/components/verification_identity_summary.dart';
import 'package:share_verify/core/screens/verification/components/verification_result_section.dart';

class VerificationBarcodeStep extends GetView<VerificationController> {
  const VerificationBarcodeStep({super.key});

  @override
  Widget build(BuildContext context) {
    final identity = controller.effectivePendingIdentity;

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
        if (identity != null) ...[
          const SizedBox(height: SvSpacing.md),
          VerificationIdentitySummary(identity: identity),
        ],
        const SizedBox(height: SvSpacing.md),
        const VerificationBarcodeSection(),
        Obx(() {
          final shareholder = controller.selectedShareholder.value;
          if (shareholder == null) return const SizedBox.shrink();
          return Column(
            children: [
              const SizedBox(height: SvSpacing.lg),
              VerificationResultSection(
                shareholder: shareholder,
                isSubmitting: controller.isSubmitting.value,
                isLoadingRecipients: controller.isLoadingRecipients.value,
                receiveJustCompleted: controller.receiveJustCompleted.value,
                onViewRecipients: () => controller.onViewRecipientInfo(context),
              ),
            ],
          );
        }),
      ],
    );
  }
}
