// test/controllers/verification_controller_step_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:share_verify/core/controllers/verification_controller.dart';
import 'package:share_verify/core/data/dto/travel_support_dtos.dart';
import 'package:share_verify/core/models/attendance_type.dart';
import 'package:share_verify/core/models/verification_step.dart';
import 'package:share_verify/core/services/barcode_scanner_service.dart';
import '../support/fake_repositories.dart';

void main() {
  setUp(() => Get.testMode = true);
  tearDown(Get.reset);

  VerificationController createController() => VerificationController(
        shareholderRepository: FakeShareholderRepository(),
        travelSupportRepository: FakeTravelSupportRepository(),
        barcodeScannerService: BarcodeScannerService(),
      );

  void setIdentityInfoReady(VerificationController c) {
    c.verificationStep.value = VerificationStep.identity;
    c.manualNameController.text = 'Nguyễn Văn A';
    c.manualIdController.text = '001234567890';
  }

  void setIdentityReady(VerificationController c) {
    setIdentityInfoReady(c);
    c.verificationStep.value = VerificationStep.evidence;
    c.manualPhotoPath.value = 'uploads/test.jpg';
  }

  test('starts at attendance step', () {
    final c = createController();
    expect(c.verificationStep.value, VerificationStep.attendance);
  });

  test('advanceToIdentityStep moves from step 1 to step 2', () {
    final c = createController();
    c.advanceToIdentityStep();
    expect(c.verificationStep.value, VerificationStep.identity);
  });

  test('advanceToEvidenceStep requires identity info', () {
    final c = createController();
    c.verificationStep.value = VerificationStep.identity;
    c.advanceToEvidenceStep();
    expect(c.verificationStep.value, VerificationStep.identity);
    expect(c.errorMessage.value, isNotNull);
  });

  test('advanceToEvidenceStep moves to step 3 when info ready', () async {
    final c = createController();
    setIdentityInfoReady(c);
    await c.advanceToEvidenceStep();
    expect(c.verificationStep.value, VerificationStep.evidence);
  });

  test('advanceToBarcodeStep requires identity ready', () async {
    final c = createController();
    c.verificationStep.value = VerificationStep.evidence;
    await c.advanceToBarcodeStep();
    expect(c.verificationStep.value, VerificationStep.evidence);
    expect(c.errorMessage.value, isNotNull);
  });

  test('goBackStep decrements step', () {
    final c = createController();
    c.verificationStep.value = VerificationStep.barcode;
    c.goBackStep();
    expect(c.verificationStep.value, VerificationStep.evidence);
  });

  test('resetSelection returns to step 1', () async {
    final c = createController();
    c.verificationStep.value = VerificationStep.barcode;
    c.attendanceType.value = AttendanceType.proxy;
    c.resetSelection();
    expect(c.verificationStep.value, VerificationStep.attendance);
    expect(c.attendanceType.value, AttendanceType.proxy);
  });

  test('shouldPromptIdentityUsageDialog when already used on identity step', () {
    final c = createController();
    setIdentityInfoReady(c);
    c.identityCheckResult.value =
        const IdentityCheckResultDto(alreadyUsed: true);
    expect(c.shouldPromptIdentityUsageDialog, isTrue);
  });

  test('shouldPromptIdentityUsageDialog false on evidence step', () {
    final c = createController();
    setIdentityReady(c);
    c.identityCheckResult.value =
        const IdentityCheckResultDto(alreadyUsed: true);
    expect(c.shouldPromptIdentityUsageDialog, isFalse);
  });

  test('shouldPromptIdentityUsageDialog false on barcode step', () {
    final c = createController();
    c.verificationStep.value = VerificationStep.barcode;
    c.identityCheckResult.value =
        const IdentityCheckResultDto(alreadyUsed: true);
    expect(c.shouldPromptIdentityUsageDialog, isFalse);
  });


  test('canGoToNextStep on barcode requires shareholder', () {
    final c = createController();
    c.verificationStep.value = VerificationStep.barcode;
    expect(c.canGoToNextStep, isFalse);

    c.selectedShareholder.value = null;
    c.scannedBarcode.value = null;
    expect(c.canGoToNextStep, isFalse);
  });

  test('goToNextStep on barcode with shareholder resets to step 1', () async {
    final c = createController();
    setIdentityReady(c);
    c.verificationStep.value = VerificationStep.barcode;
    await c.onBarcodeScanned('SH0001');
    expect(c.selectedShareholder.value, isNotNull);

    await c.goToNextStep();

    expect(c.verificationStep.value, VerificationStep.attendance);
    expect(c.selectedShareholder.value, isNull);
  });

  test('goBackStep from identity goes to attendance', () {
    final c = createController();
    c.verificationStep.value = VerificationStep.identity;
    c.goBackStep();
    expect(c.verificationStep.value, VerificationStep.attendance);
  });

  test('processNextPerson returns to step 1', () async {
    final c = createController();
    setIdentityReady(c);
    c.verificationStep.value = VerificationStep.barcode;
    c.receiveJustCompleted.value = true;

    await c.processNextPerson();

    expect(c.verificationStep.value, VerificationStep.attendance);
    expect(c.receiveJustCompleted.value, isFalse);
    expect(c.selectedShareholder.value, isNull);
  });
}
