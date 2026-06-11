import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:share_verify/core/screens/verification/verification_barcode_screen.dart';

/// Legacy route — redirects to [VerificationBarcodeScreen].
class ShareholderIdentityScreen extends StatelessWidget {
  const ShareholderIdentityScreen({super.key});

  static const routeName = '/verification/identity';

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (Get.currentRoute == routeName) {
        Get.offNamed(VerificationBarcodeScreen.routeName);
      }
    });
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
