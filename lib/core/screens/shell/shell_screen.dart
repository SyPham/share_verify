import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:share_verify/core/controllers/shell_controller.dart';
import 'package:share_verify/core/controllers/verification_controller.dart';
import 'package:share_verify/core/screens/dashboard/dashboard_screen.dart';
import 'package:share_verify/core/screens/verification/verification_screen.dart';
import 'package:share_verify/core/widgets/sv_bottom_nav.dart';
import 'package:share_verify/core/widgets/sv_fab_qr.dart';

class ShellScreen extends GetView<ShellController> {
  static const routeName = '/shell';

  const ShellScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final verificationController = Get.find<VerificationController>();
    return Obx(() => Scaffold(
          body: IndexedStack(
            index: controller.tabIndex.value,
            children: const [
              VerificationScreen(),
              DashboardScreen(),
            ],
          ),
          floatingActionButton: controller.tabIndex.value == 0
              ? Obx(() {
                  final ready =
                      verificationController.canProceedToBarcodeScreen &&
                      !verificationController.isSubmitting.value;
                  return SvFabQr(
                    onPressed: ready
                        ? verificationController.goToBarcodeScreen
                        : () {
                            verificationController.errorMessage.value =
                                'Vui lòng chụp ảnh chứng cứ và nhập đủ thông tin trước';
                          },
                    icon: Icons.qr_code_2,
                  );
                })
              : null,
          floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
          bottomNavigationBar: SvBottomNav(
            currentIndex: controller.tabIndex.value,
            onTap: controller.switchTab,
          ),
        ));
  }
}
