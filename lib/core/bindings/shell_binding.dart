import 'package:get/get.dart';
import 'package:share_verify/core/controllers/capture_controller.dart';
import 'package:share_verify/core/controllers/dashboard_controller.dart';
import 'package:share_verify/core/controllers/shell_controller.dart';
import 'package:share_verify/core/controllers/verification_controller.dart';

class ShellBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ShellController>(() => ShellController());
    Get.lazyPut<VerificationController>(() => VerificationController());
    Get.lazyPut<DashboardController>(() => DashboardController());
  }
}

class CaptureBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<CaptureController>(() => CaptureController());
  }
}
