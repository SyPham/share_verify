import 'package:get/get.dart';
import 'package:share_verify/core/data/sources/ocr_remote_source.dart';
import 'package:share_verify/core/models/open_ai_stats.dart';
import 'package:share_verify/core/services/open_ai_usage_store.dart';

class OpenAiStatsController extends GetxController {
  final OpenAiUsageStore _usageStore;
  final OcrRemoteSource _ocrRemote;

  OpenAiStatsController({
    OpenAiUsageStore? usageStore,
    OcrRemoteSource? ocrRemote,
  })  : _usageStore = usageStore ?? Get.find<OpenAiUsageStore>(),
        _ocrRemote = ocrRemote ?? Get.find<OcrRemoteSource>();

  final isLoading = false.obs;
  final isClearing = false.obs;
  final errorMessage = RxnString();
  final deviceStats = Rxn<OpenAiStatsInfo>();
  final serverStats = Rxn<OpenAiStatsInfo>();

  @override
  void onInit() {
    super.onInit();
    refresh();
  }

  Future<void> refresh() async {
    isLoading.value = true;
    errorMessage.value = null;

    try {
      deviceStats.value = await _usageStore.loadLocalStats();
      try {
        serverStats.value = await _ocrRemote.fetchOpenAiStats();
      } catch (_) {
        serverStats.value = null;
      }
    } catch (error) {
      errorMessage.value = error.toString();
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> clearDeviceHistory() async {
    isClearing.value = true;
    try {
      await _usageStore.clear();
      deviceStats.value = await _usageStore.loadLocalStats();
    } finally {
      isClearing.value = false;
    }
  }
}
