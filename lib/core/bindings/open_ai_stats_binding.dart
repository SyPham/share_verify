import 'package:get/get.dart';
import 'package:share_verify/core/controllers/open_ai_stats_controller.dart';
import 'package:share_verify/core/data/sources/ocr_remote_source.dart';
import 'package:share_verify/core/services/open_ai_usage_store.dart';

class OpenAiStatsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<OpenAiStatsController>(
      () => OpenAiStatsController(
        usageStore: Get.find<OpenAiUsageStore>(),
        ocrRemote: Get.find<OcrRemoteSource>(),
      ),
      fenix: true,
    );
  }
}
