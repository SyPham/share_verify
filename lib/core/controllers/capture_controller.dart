import 'package:get/get.dart';
import 'package:share_verify/core/models/shareholder.dart';

class CaptureController extends GetxController {
  static const successRouteName = '/success';

  late final Shareholder shareholder;
  final hasCaptured = true.obs; // mock: always has preview

  @override
  void onInit() {
    shareholder = Get.arguments as Shareholder;
    super.onInit();
  }

  void retake() => hasCaptured.value = false;

  void confirm() => Get.toNamed(successRouteName, arguments: shareholder);
}
