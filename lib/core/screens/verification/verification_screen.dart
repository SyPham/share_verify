import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:share_verify/core/commons/app_spacing.dart';
import 'package:share_verify/core/controllers/verification_controller.dart';
import 'package:share_verify/core/screens/settings/settings_screen.dart';
import 'package:share_verify/core/screens/verification/components/verification_attendance_section.dart';
import 'package:share_verify/core/screens/verification/components/verification_error_banner.dart';
import 'package:share_verify/core/screens/verification/components/verification_identity_section.dart';
import 'package:share_verify/core/screens/verification/components/verification_identity_usage_warning.dart';
import 'package:share_verify/core/widgets/sv_app_bar.dart';
import 'package:share_verify/core/widgets/sv_primary_button.dart';
import 'package:share_verify/core/widgets/sv_server_config_banner.dart';

class VerificationScreen extends GetView<VerificationController> {
  const VerificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: StreamBuilder<DateTime>(
          stream: Stream<DateTime>.periodic(
            const Duration(seconds: 1),
            (_) => DateTime.now(),
          ),
          initialData: DateTime.now(),
          builder: (context, snapshot) {
            final now = snapshot.data ?? DateTime.now();
            return SvAppBar.verification(
              clockText: _formatClock(now),
              onOpenSettings: () => Get.toNamed(SettingsScreen.routeName),
            );
          },
        ),
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
            const SvServerConfigBanner(),
            const SizedBox(height: SvSpacing.md),
            Obx(
              () => VerificationAttendanceSection(
                attendanceType: controller.attendanceType.value,
                onAttendanceTypeChanged: controller.onAttendanceTypeChanged,
              ),
            ),
            const SizedBox(height: SvSpacing.md),
            const VerificationIdentitySection(),
            const VerificationIdentityUsageWarning(),
            Obx(() {
              if (!controller.canProceedToBarcodeScreen ||
                  controller.isCheckingIdentity.value) {
                return const SizedBox.shrink();
              }
              return Column(
                children: [
                  const SizedBox(height: SvSpacing.md),
                  SvPrimaryButton(
                    label: 'Quét mã thiệp mời',
                    icon: Icons.qr_code_2,
                    onPressed: controller.goToBarcodeScreen,
                    height: 56,
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
