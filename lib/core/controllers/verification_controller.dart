import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:share_verify/core/mock/mock_data.dart';
import 'package:share_verify/core/models/shareholder.dart';

class VerificationController extends GetxController {
  static const captureRouteName = '/capture';
  static const successRouteName = '/success';

  final idNumberInput = ''.obs;
  final selectedShareholder = Rxn<Shareholder>();
  final isSearching = false.obs;
  final idNumberFocus = FocusNode();

  @override
  void onClose() {
    idNumberFocus.dispose();
    super.onClose();
  }

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
    Get.toNamed(
      captureRouteName,
      arguments: selectedShareholder.value,
    );
  }

  void onManualEntry() {
    idNumberFocus.requestFocus();
  }

  void confirmPayment() {
    final sh = selectedShareholder.value;
    if (sh == null) return;
    Get.toNamed(successRouteName, arguments: sh);
  }

  void resetSelection() {
    idNumberInput.value = '';
    selectedShareholder.value = null;
    isSearching.value = false;
  }
}
