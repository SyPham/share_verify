import 'package:get/get.dart';
import 'package:share_verify/core/models/shareholder.dart';
import 'package:share_verify/core/network/api_client.dart';
import 'package:share_verify/core/repositories/shareholder_repository.dart';

class ShareholderDetailController extends GetxController {
  final ShareholderRepository _shareholderRepository;
  final String mcd;

  ShareholderDetailController({
    required this.mcd,
    ShareholderRepository? shareholderRepository,
  }) : _shareholderRepository =
            shareholderRepository ?? Get.find<ShareholderRepository>();

  final detail = Rxn<Shareholder>();
  final isLoading = false.obs;
  final errorMessage = RxnString();

  @override
  void onInit() {
    super.onInit();
    loadDetail();
  }

  Future<void> loadDetail() async {
    isLoading.value = true;
    errorMessage.value = null;

    try {
      detail.value = await _shareholderRepository.findByMcd(mcd);
    } catch (error) {
      errorMessage.value = ApiClient.messageFrom(error);
      detail.value = null;
    } finally {
      isLoading.value = false;
    }
  }
}
