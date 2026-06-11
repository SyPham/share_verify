import 'package:get/get.dart';
import 'package:share_verify/core/controllers/settings_controller.dart';
import 'package:share_verify/core/data/sources/ocr_remote_source.dart';
import 'package:share_verify/core/network/api_client.dart';
import 'package:share_verify/core/services/app_config_service.dart';

class SettingsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<SettingsController>(
      () => SettingsController(
        appConfigService: Get.find<AppConfigService>(),
        apiClient: Get.find<ApiClient>(),
        ocrRemote: Get.find<OcrRemoteSource>(),
      ),
      fenix: true,
    );
  }
}
