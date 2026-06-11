import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:share_verify/core/controllers/verification_controller.dart';
import 'package:share_verify/core/models/attendance_type.dart';
import 'package:share_verify/core/models/identity_verification.dart';
import 'package:share_verify/core/models/payment_status.dart';
import 'package:share_verify/core/services/barcode_scanner_service.dart';
import '../support/fake_repositories.dart';

void main() {
  late FakeShareholderRepository shareholderRepository;
  late FakeTravelSupportRepository travelSupportRepository;

  setUp(() {
    Get.testMode = true;
    shareholderRepository = FakeShareholderRepository();
    travelSupportRepository = FakeTravelSupportRepository();
  });

  tearDown(Get.reset);

  VerificationController createController() {
    return VerificationController(
      shareholderRepository: shareholderRepository,
      travelSupportRepository: travelSupportRepository,
      barcodeScannerService: BarcodeScannerService(),
    );
  }

  const completeIdentity = IdentityVerification(
    identityNo: '001234567890',
    identityType: 'CCCD',
    receiverName: 'Nguyễn Văn A',
    photoPath: 'uploads/test.jpg',
  );

  test('onManualBarcodeEntry auto-receives when identity is ready', () async {
    final c = createController();
    await c.setIdentityVerification(completeIdentity);
    c.barcodeInputController.text = 'SH0001';

    await c.onManualBarcodeEntry();

    expect(c.selectedShareholder.value?.code, 'SH0001');
    expect(c.scannedBarcode.value?.mcd, 'SH0001');
    expect(travelSupportRepository.receiveCallCount, 1);
  });

  test('onBarcodeScanned auto-receives for eligible shareholder', () async {
    final c = createController();
    await c.setIdentityVerification(completeIdentity);

    await c.onBarcodeScanned('SH0001');

    expect(c.scannedBarcode.value?.mcd, 'SH0001');
    expect(c.selectedShareholder.value?.code, 'SH0001');
    expect(c.selectedShareholder.value?.status, PaymentStatus.notReceived);
    expect(travelSupportRepository.receiveCallCount, 1);
  });

  test('onBarcodeScanned blocked when shareholder already received', () async {
    final c = createController();
    await c.setIdentityVerification(completeIdentity);

    await c.onBarcodeScanned('SH0002');

    expect(travelSupportRepository.receiveCallCount, 0);
    expect(c.errorMessage.value, contains('đã nhận phụ cấp'));
  });

  test('auto-receive sends proxy fields when attendance is proxy', () async {
    final c = createController();
    c.attendanceType.value = AttendanceType.proxy;
    await c.setIdentityVerification(
      const IdentityVerification(
        identityNo: '998877665544',
        identityType: 'CCCD',
        receiverName: 'Nguyễn Thị Proxy',
        photoPath: 'uploads/proxy.jpg',
      ),
    );

    await c.onBarcodeScanned('SH0001');

    expect(travelSupportRepository.receiveCallCount, 1);
    expect(travelSupportRepository.lastAttendanceType, AttendanceType.proxy);
    expect(travelSupportRepository.lastProxyPersonName, 'Nguyễn Thị Proxy');
    expect(travelSupportRepository.lastProxyIdentityNo, '998877665544');
    expect(travelSupportRepository.lastProxyIdentityType, 'CCCD');
    expect(travelSupportRepository.lastPhotoPath, 'uploads/proxy.jpg');
    expect(travelSupportRepository.lastIdentity?.receiverName, 'Nguyễn Văn A');
  });
}
