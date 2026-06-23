import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:share_verify/core/controllers/verification_controller.dart';
import 'package:share_verify/core/models/verification_step.dart';
import 'package:share_verify/core/screens/shell/shell_screen.dart';

class VerificationBarcodeScreen extends StatelessWidget {
  const VerificationBarcodeScreen({super.key});

  static const routeName = VerificationController.barcodeRouteName;

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final c = Get.find<VerificationController>();
      if (c.isIdentityReady) {
        c.verificationStep.value = VerificationStep.barcode;
      }
      Get.until((route) => route.settings.name == ShellScreen.routeName);
    });
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
