import 'package:get/get.dart';
import 'package:share_verify/core/controllers/dashboard_controller.dart';

class ShellController extends GetxController {
  final tabIndex = 0.obs;

  void switchTab(int index) {
    tabIndex.value = index;
    if (index == 1 && Get.isRegistered<DashboardController>()) {
      Get.find<DashboardController>().refresh();
    }
  }
}
