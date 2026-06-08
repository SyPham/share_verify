import 'package:get/get.dart';
import 'package:share_verify/core/mock/mock_data.dart';
import 'package:share_verify/core/models/shareholder.dart';

class CaptureController extends GetxController {
  static const successRouteName = '/success';

  late final Shareholder shareholder;
  final hasCaptured = true.obs; // mock: always has preview

  @override
  void onInit() {
    final argument = Get.arguments;
    shareholder =
        argument is Shareholder ? argument : MockData.shareholders.first;
    super.onInit();
  }

  void retake() => hasCaptured.value = false;

  void confirm() => Get.toNamed(successRouteName, arguments: shareholder);
}
