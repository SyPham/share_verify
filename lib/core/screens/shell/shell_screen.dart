import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:share_verify/core/controllers/shell_controller.dart';
import 'package:share_verify/core/screens/dashboard/dashboard_screen.dart';
import 'package:share_verify/core/screens/verification/verification_screen.dart';
import 'package:share_verify/core/widgets/sv_bottom_nav.dart';

class ShellScreen extends GetView<ShellController> {
  static const routeName = '/shell';

  const ShellScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() => Scaffold(
          body: IndexedStack(
            index: controller.tabIndex.value,
            children: const [
              VerificationScreen(),
              DashboardScreen(),
            ],
          ),
          bottomNavigationBar: SvBottomNav(
            currentIndex: controller.tabIndex.value,
            onTap: controller.switchTab,
          ),
        ));
  }
}
