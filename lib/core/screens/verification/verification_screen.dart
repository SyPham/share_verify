import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:share_verify/core/commons/app_spacing.dart';
import 'package:share_verify/core/controllers/verification_controller.dart';
import 'package:share_verify/core/screens/verification/components/verification_action_buttons.dart';
import 'package:share_verify/core/screens/verification/components/verification_result_section.dart';
import 'package:share_verify/core/screens/verification/components/verification_search_section.dart';
import 'package:share_verify/core/widgets/sv_app_bar.dart';

class VerificationScreen extends GetView<VerificationController> {
  const VerificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DateTime>(
      stream: Stream<DateTime>.periodic(
        const Duration(seconds: 1),
        (_) => DateTime.now(),
      ),
      initialData: DateTime.now(),
      builder: (context, snapshot) {
        final now = snapshot.data ?? DateTime.now();
        return Obx(() {
          final selectedShareholder = controller.selectedShareholder.value;
          return Scaffold(
            appBar: SvAppBar.verification(clockText: _formatClock(now)),
            body: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                SvSpacing.containerMargin,
                SvSpacing.lg,
                SvSpacing.containerMargin,
                SvSpacing.lg,
              ),
              child: Column(
                children: [
                  VerificationActionButtons(
                    onScanQr: controller.onScanQr,
                    onCaptureId: controller.onCaptureId,
                    onManualEntry: controller.onManualEntry,
                  ),
                  const SizedBox(height: SvSpacing.lg),
                  VerificationSearchSection(
                    idNumber: controller.idNumberInput.value,
                    isSearching: controller.isSearching.value,
                    onIdNumberChanged: (value) {
                      controller.idNumberInput.value = value;
                    },
                    onSearch: controller.searchByIdNumber,
                  ),
                  if (selectedShareholder != null) ...[
                    const SizedBox(height: SvSpacing.lg),
                    VerificationResultSection(
                      shareholder: selectedShareholder,
                      onConfirmPayment: controller.confirmPayment,
                    ),
                  ],
                ],
              ),
            ),
          );
        });
      },
    );
  }

  String _formatClock(DateTime dateTime) {
    final day = _twoDigits(dateTime.day);
    final month = _twoDigits(dateTime.month);
    final year = dateTime.year;
    final hour = _twoDigits(dateTime.hour);
    final minute = _twoDigits(dateTime.minute);
    final second = _twoDigits(dateTime.second);
    return '$hour:$minute:$second - $day/$month/$year';
  }

  String _twoDigits(int value) => value.toString().padLeft(2, '0');
}
