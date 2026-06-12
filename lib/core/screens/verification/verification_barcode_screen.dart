import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:share_verify/core/commons/app_spacing.dart';
import 'package:share_verify/core/controllers/verification_controller.dart';
import 'package:share_verify/core/screens/verification/components/verification_barcode_section.dart';
import 'package:share_verify/core/screens/verification/components/verification_error_banner.dart';
import 'package:share_verify/core/screens/verification/components/verification_identity_summary.dart';
import 'package:share_verify/core/screens/verification/components/verification_identity_usage_warning.dart';
import 'package:share_verify/core/screens/verification/components/verification_result_section.dart';
import 'package:share_verify/core/widgets/sv_app_bar.dart';

class VerificationBarcodeScreen extends GetView<VerificationController> {
  const VerificationBarcodeScreen({super.key});

  static const routeName = VerificationController.barcodeRouteName;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (!controller.isIdentityReady) {
        return Scaffold(
          appBar: SvAppBar.verification(
            clockText: 'Quét mã thiệp mời',
            onBack: Get.back,
          ),
          body: const Center(child: CircularProgressIndicator()),
        );
      }

      return Scaffold(
        appBar: SvAppBar.verification(
          clockText: 'Quét mã thiệp mời',
          onBack: Get.back,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            SvSpacing.containerMargin,
            SvSpacing.lg,
            SvSpacing.containerMargin,
            SvSpacing.lg,
          ),
          child: Column(
            children: [
              const VerificationIdentityUsageWarning(),
              const SizedBox(height: SvSpacing.lg),
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
                      onViewRecipients: () =>
                          controller.onViewRecipientInfo(context),
                      onProcessNextPerson: controller.processNextPerson,
                    ),
                  ],
                );
              }),
              Obx(() {
                final message = controller.errorMessage.value;
                if (message == null) return const SizedBox.shrink();
                return Column(
                  children: [
                    const SizedBox(height: SvSpacing.sm),
                    VerificationErrorBanner(message: message),
                  ],
                );
              }),
            ],
          ),
        ),
      );
    });
  }
}
