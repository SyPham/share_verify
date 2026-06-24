import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:share_verify/core/commons/app_spacing.dart';
import 'package:share_verify/core/controllers/verification_controller.dart';
import 'package:share_verify/core/models/verification_step.dart';
import 'package:share_verify/core/screens/settings/settings_screen.dart';
import 'package:share_verify/core/screens/verification/components/verification_attendance_step.dart';
import 'package:share_verify/core/screens/verification/components/verification_barcode_step.dart';
import 'package:share_verify/core/screens/verification/components/verification_barcode_step_footer.dart';
import 'package:share_verify/core/screens/verification/components/verification_error_banner.dart';
import 'package:share_verify/core/screens/verification/components/verification_evidence_step.dart';
import 'package:share_verify/core/screens/verification/components/verification_identity_step.dart';
import 'package:share_verify/core/screens/verification/components/verification_step_navigation_controls.dart';
import 'package:share_verify/core/widgets/sv_app_bar.dart';
import 'package:share_verify/core/widgets/sv_server_config_banner.dart';

class VerificationScreen extends GetView<VerificationController> {
  const VerificationScreen({super.key});

  static const _bodyPadding = EdgeInsets.fromLTRB(
    SvSpacing.containerMargin,
    SvSpacing.lg,
    SvSpacing.containerMargin,
    SvSpacing.lg,
  );

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
      body: Obx(() {
        final step = controller.verificationStep.value;

        return Padding(
          padding: _bodyPadding,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SvServerConfigBanner(),
                const SizedBox(height: SvSpacing.md),
                const VerificationStepNavigationControls(),
                const SizedBox(height: SvSpacing.lg),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 260),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  transitionBuilder: (child, animation) {
                    final slide = Tween<Offset>(
                      begin: const Offset(0.04, 0),
                      end: Offset.zero,
                    ).animate(animation);
                    return FadeTransition(
                      opacity: animation,
                      child: SlideTransition(position: slide, child: child),
                    );
                  },
                  child: KeyedSubtree(
                    key: ValueKey(step),
                    child: switch (step) {
                      VerificationStep.attendance =>
                        const VerificationAttendanceStep(),
                      VerificationStep.identity =>
                        const VerificationIdentityStepBody(),
                      VerificationStep.evidence =>
                        const VerificationEvidenceStep(),
                      VerificationStep.barcode =>
                        const VerificationBarcodeStep(),
                    },
                  ),
                ),
                _buildErrorBanner(),
                if (step == VerificationStep.identity)
                  const VerificationIdentityStepFooter(),
                if (step == VerificationStep.barcode)
                  const VerificationBarcodeStepFooter(),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildErrorBanner() {
    final message = controller.errorMessage.value;
    if (message == null) return const SizedBox.shrink();
    return Column(
      children: [
        const SizedBox(height: SvSpacing.sm),
        VerificationErrorBanner(message: message),
      ],
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
