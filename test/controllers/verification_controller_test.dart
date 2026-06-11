import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:share_verify/core/controllers/verification_controller.dart';
import 'package:share_verify/core/data/dto/registration_no_autocomplete_dtos.dart';
import 'package:share_verify/core/data/dto/shareholder_dtos.dart';
import 'package:share_verify/core/data/dto/travel_support_dtos.dart';
import 'package:share_verify/core/models/identity_verification.dart';
import 'package:share_verify/core/models/payment_status.dart';
import 'package:share_verify/core/models/shareholder.dart';
import 'package:share_verify/core/network/api_exception.dart';
import 'package:share_verify/core/repositories/shareholder_repository.dart';
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

  test('onBarcodeScanned surfaces repository errors', () async {
    final failingRepository = _ThrowingShareholderRepository();
    final c = VerificationController(
      shareholderRepository: failingRepository,
      travelSupportRepository: travelSupportRepository,
      barcodeScannerService: BarcodeScannerService(),
    );
    await c.setIdentityVerification(completeIdentity);

    await c.onBarcodeScanned('SH0001');

    expect(c.selectedShareholder.value, isNull);
    expect(c.errorMessage.value, 'Server error');
  });

  test('onBarcodeScanned requires identity first', () async {
    final c = createController();

    await c.onBarcodeScanned('SH0001');

    expect(c.selectedShareholder.value, isNull);
    expect(c.errorMessage.value, contains('giấy tờ'));
  });

  test('resetSelection clears barcode and identity state', () async {
    final c = createController();
    await c.setIdentityVerification(completeIdentity);
    c.barcodeInputController.text = 'SH0001';

    c.resetSelection();

    expect(c.selectedShareholder.value, isNull);
    expect(c.barcodeInputController.text, isEmpty);
    expect(c.isIdentityReady, isFalse);
    expect(c.isSearching.value, isFalse);
    expect(c.errorMessage.value, isNull);
  });

  test('applyIdentity checks usage and auto-receives on barcode scan', () async {
    final c = createController();
    await c.setIdentityVerification(completeIdentity);

    expect(c.isIdentityReady, isTrue);
    expect(travelSupportRepository.checkIdentityCallCount, 1);

    await c.onBarcodeScanned('SH0001');

    expect(travelSupportRepository.receiveCallCount, 1);
    expect(travelSupportRepository.lastPhotoPath, 'uploads/test.jpg');
    expect(travelSupportRepository.lastReceiveAmount, greaterThan(0));
  });

  test('identity usage warning does not block barcode scan', () async {
    travelSupportRepository.checkIdentityResult = const IdentityCheckResultDto(
      alreadyUsed: true,
      usedForMcd: 'SH0002',
      usedForMcds: ['SH0002'],
      message: 'Đã nhận cho SH0002',
    );

    final c = createController();
    await c.setIdentityVerification(completeIdentity);

    expect(c.hasIdentityUsageWarning, isTrue);
    expect(c.usedShareholderCodes, ['SH0002']);

    await c.onBarcodeScanned('SH0001');

    expect(travelSupportRepository.receiveCallCount, 1);
  });

  test('manual form with photo enables barcode without persisting early', () {
    final c = createController();
    c.manualIdentityType.value = 'CCCD';
    c.manualNameController.text = 'Nguyễn Văn A';
    c.manualIdController.text = '001234567890';
    c.manualCmndController.text = '123456789';
    c.manualPhotoPath.value = 'uploads/test.jpg';

    expect(c.isIdentityReady, isTrue);
    expect(c.effectivePendingIdentity?.legacyIdentityNo, '123456789');
    expect(travelSupportRepository.receiveCallCount, 0);
  });

  test('barcode scan persists identity via receive', () async {
    final c = createController();
    c.manualIdentityType.value = 'CCCD';
    c.manualNameController.text = 'Nguyễn Văn A';
    c.manualIdController.text = '001234567890';
    c.manualPhotoPath.value = 'uploads/test.jpg';

    await c.onBarcodeScanned('SH0001');

    expect(travelSupportRepository.receiveCallCount, 1);
    expect(travelSupportRepository.lastPhotoPath, 'uploads/test.jpg');
    expect(travelSupportRepository.lastIdentity?.identityType, 'CCCD');
  });

  test('applyCaptureResult fills manual form for CCCD capture', () async {
    final c = createController();
    await c.applyCaptureResult(completeIdentity);

    expect(c.manualFormPrefillSource.value, ManualFormPrefillSource.capture);
    expect(c.manualIdentityType.value, 'CCCD');
    expect(c.manualNameController.text, 'Nguyễn Văn A');
    expect(c.manualIdController.text, '001234567890');
    expect(c.manualPhotoPath.value, 'uploads/test.jpg');
    expect(c.isIdentityReady, isTrue);
    expect(travelSupportRepository.checkIdentityCallCount, 1);
  });

  test('applyCaptureResult fills manual form for CMND capture', () async {
    final c = createController();
    await c.applyCaptureResult(
      const IdentityVerification(
        identityNo: '123456789',
        identityType: 'CMND',
        receiverName: 'Trần Văn B',
        dateOfBirth: '01/01/1985',
        photoPath: 'uploads/cmnd.jpg',
      ),
    );

    expect(c.manualFormPrefillSource.value, ManualFormPrefillSource.capture);
    expect(c.manualIdentityType.value, 'CMND');
    expect(c.manualIdController.text, '123456789');
    expect(c.manualPhotoPath.value, 'uploads/cmnd.jpg');
    expect(c.isIdentityReady, isTrue);
  });

  test('applyCaptureResult fills manual form for Passport capture', () async {
    final c = createController();
    await c.applyCaptureResult(
      const IdentityVerification(
        identityNo: 'B1234567',
        identityType: 'PASSPORT',
        receiverName: 'John Doe',
        photoPath: 'uploads/passport.jpg',
      ),
    );

    expect(c.manualFormPrefillSource.value, ManualFormPrefillSource.capture);
    expect(c.manualIdentityType.value, 'PASSPORT');
    expect(c.manualIdController.text, 'B1234567');
    expect(c.isIdentityReady, isTrue);
  });

  test('canProceedToBarcodeScreen when manual form has photo', () {
    final c = createController();
    c.manualNameController.text = 'Nguyễn Văn A';
    c.manualIdController.text = '001234567890';
    c.manualPhotoPath.value = 'uploads/test.jpg';

    expect(c.isIdentityReady, isTrue);
    expect(c.canProceedToBarcodeScreen, isTrue);
  });
}

class _ThrowingShareholderRepository implements ShareholderRepository {
  @override
  Future<Shareholder?> findByKeyword(String keyword) async {
    throw const ApiException(message: 'Server error', statusCode: 500);
  }

  @override
  Future<ShareholderSearchPageDto> searchShareholders(
    String keyword, {
    int page = 1,
    int pageSize = 20,
  }) async {
    throw const ApiException(message: 'Server error', statusCode: 500);
  }

  @override
  Future<Shareholder?> findByMcd(String mcd) async {
    throw const ApiException(message: 'Server error', statusCode: 500);
  }

  @override
  Future<RegistrationNoAutocompletePageDto> searchRegistrationNumbers(
    String keyword, {
    int page = 1,
    int pageSize = 20,
    String? identityType,
  }) async {
    throw const ApiException(message: 'Server error', statusCode: 500);
  }
}
