import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:share_verify/core/controllers/verification_controller.dart';
import 'package:share_verify/core/models/payment_status.dart';

void main() {
  setUp(() => Get.testMode = true);
  tearDown(Get.reset);

  test('searchByIdNumber finds SH0001 mock shareholder', () {
    final c = VerificationController();
    c.idNumberInput.value = '001234567890';
    c.searchByIdNumber();
    expect(c.selectedShareholder.value?.code, 'SH0001');
    expect(c.selectedShareholder.value?.status, PaymentStatus.notReceived);
  });

  test('searchByIdNumber clears result when not found', () {
    final c = VerificationController();
    c.idNumberInput.value = '999';
    c.searchByIdNumber();
    expect(c.selectedShareholder.value, isNull);
  });
}
