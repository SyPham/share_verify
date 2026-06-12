import 'package:get/get.dart';
import 'package:share_verify/core/models/recipient_detail.dart';
import 'package:share_verify/core/network/api_client.dart';
import 'package:share_verify/core/repositories/recipient_repository.dart';

class RecipientDetailController extends GetxController {
  final RecipientRepository _recipientRepository;
  final int personId;

  RecipientDetailController({
    required this.personId,
    RecipientRepository? recipientRepository,
  }) : _recipientRepository =
            recipientRepository ?? Get.find<RecipientRepository>();

  final detail = Rxn<RecipientDetail>();
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
      detail.value = await _recipientRepository.getDetail(personId);
    } catch (error) {
      errorMessage.value = ApiClient.messageFrom(error);
      detail.value = null;
    } finally {
      isLoading.value = false;
    }
  }
}
