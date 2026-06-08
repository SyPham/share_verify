import 'package:get/get.dart';
import 'package:share_verify/core/mock/mock_data.dart';
import 'package:share_verify/core/models/shareholder.dart';

class VerificationController extends GetxController {
  static const captureRouteName = '/capture';
  static const successRouteName = '/success';

  final idNumberInput = ''.obs;
  final selectedShareholder = Rxn<Shareholder>();
  final isSearching = false.obs;

  void searchByIdNumber() {
    isSearching.value = true;
    selectedShareholder.value = MockData.findByIdNumber(idNumberInput.value);
    isSearching.value = false;
  }

  void onScanQr() {
    // Mock: auto-fill SH0001 CCCD
    idNumberInput.value = '001234567890';
    searchByIdNumber();
  }

  void onCaptureId() {
    if (selectedShareholder.value != null) {
      Get.toNamed(
        captureRouteName,
        arguments: selectedShareholder.value,
      );
    }
  }

  void onManualEntry() {
    // Focus handled in UI; no-op for mock
  }

  void confirmPayment() {
    final sh = selectedShareholder.value;
    if (sh == null) return;
    Get.toNamed(successRouteName, arguments: sh);
  }
}
