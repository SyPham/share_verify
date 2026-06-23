import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:share_verify/core/commons/app_spacing.dart';
import 'package:share_verify/core/controllers/verification_controller.dart';
import 'package:share_verify/core/screens/verification/components/verification_attendance_section.dart';
import 'package:share_verify/core/widgets/sv_primary_button.dart';

class VerificationAttendanceStep extends GetView<VerificationController> {
  const VerificationAttendanceStep({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Obx(
          () => VerificationAttendanceSection(
            attendanceType: controller.attendanceType.value,
            onAttendanceTypeChanged: controller.onAttendanceTypeChanged,
          ),
        ),
        const SizedBox(height: SvSpacing.lg),
        SvPrimaryButton(
          label: 'Tiếp tục',
          icon: Icons.arrow_forward,
          onPressed: controller.advanceToIdentityStep,
          height: 56,
        ),
      ],
    );
  }
}
