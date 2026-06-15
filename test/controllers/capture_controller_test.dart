import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:share_verify/core/controllers/capture_controller.dart';
import 'package:share_verify/core/data/dto/travel_support_dtos.dart';
import 'package:share_verify/core/models/capture_route_args.dart';
import 'package:share_verify/core/models/crop_aspect_mode.dart';
import 'package:share_verify/core/services/app_config_service.dart';
import 'package:share_verify/core/services/ocr_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../fixtures/test_data.dart';
import '../support/fake_repositories.dart';

void main() {
  late FakeTravelSupportRepository travelSupportRepository;
  late OcrService ocrService;

  setUp(() {
    Get.testMode = true;
    travelSupportRepository = FakeTravelSupportRepository();
    ocrService = OcrService(
      recognizeText: (_, {required String docType}) async =>
          TestData.sampleCccdOcrText,
    );
  });

  tearDown(Get.reset);

  test('confirm in evidence mode submits travel support receive request',
      () async {
    final controller = CaptureController(
      travelSupportRepository: travelSupportRepository,
      ocrService: ocrService,
      shareholderOverride: TestData.shareholders.first,
      modeOverride: CaptureMode.evidence,
    );
    controller.onInit();

    await controller.confirm();

    expect(travelSupportRepository.receiveCallCount, 1);
    expect(controller.errorMessage.value, isNull);
  });

  test('confirm in identity mode uploads photo and extracts OCR data', () async {
    final controller = CaptureController(
      travelSupportRepository: travelSupportRepository,
      ocrService: ocrService,
      shareholderOverride: TestData.shareholders.first,
      modeOverride: CaptureMode.identity,
      intentOverride: CaptureIntent.ocr,
    );
    controller.onInit();
    controller.hasCaptured.value = true;
    controller.imageBytes.value = Uint8List.fromList([1, 2, 3]);
    controller.identityNoController.text = '001234567890';
    controller.receiverNameController.text = 'Nguyễn Văn A';

    await controller.confirm();

    expect(travelSupportRepository.receiveCallCount, 0);
    expect(controller.errorMessage.value, isNull);
  });

  test('confirm in identity mode requires captured photo', () async {
    final controller = CaptureController(
      travelSupportRepository: travelSupportRepository,
      ocrService: ocrService,
      shareholderOverride: TestData.shareholders.first,
      modeOverride: CaptureMode.identity,
    );
    controller.onInit();

    await controller.confirm();

    expect(travelSupportRepository.receiveCallCount, 0);
    expect(
      controller.errorMessage.value,
      'Vui lòng chụp ảnh giấy tờ trước khi xác nhận',
    );
  });

  test('confirm in CMND mode uploads uncropped photo as evidence', () async {
    final controller = CaptureController(
      travelSupportRepository: travelSupportRepository,
      ocrService: ocrService,
      shareholderOverride: TestData.shareholders.first,
      modeOverride: CaptureMode.identity,
      identityTypeOverride: 'CMND',
      intentOverride: CaptureIntent.ocr,
    );
    controller.onInit();
    controller.hasCaptured.value = true;
    controller.rawImageBytes.value = Uint8List.fromList([10, 20, 30]);
    controller.imageBytes.value = Uint8List.fromList([1, 2, 3]);
    controller.identityNoController.text = '123456789';
    controller.receiverNameController.text = 'Trần Thị B';

    await controller.confirm();

    expect(controller.errorMessage.value, isNull);
    expect(travelSupportRepository.lastUploadedBytes, [10, 20, 30]);
    expect(travelSupportRepository.lastUploadedFileName, 'identity_cmnd.jpg');
  });

  test('confirm in CCCD mode uploads cropped photo as evidence', () async {
    final controller = CaptureController(
      travelSupportRepository: travelSupportRepository,
      ocrService: ocrService,
      shareholderOverride: TestData.shareholders.first,
      modeOverride: CaptureMode.identity,
      identityTypeOverride: 'CCCD',
      intentOverride: CaptureIntent.ocr,
    );
    controller.onInit();
    controller.hasCaptured.value = true;
    controller.rawImageBytes.value = Uint8List.fromList([10, 20, 30]);
    controller.imageBytes.value = Uint8List.fromList([1, 2, 3]);
    controller.identityNoController.text = '001234567890';
    controller.receiverNameController.text = 'Nguyễn Văn A';

    await controller.confirm();

    expect(controller.errorMessage.value, isNull);
    expect(travelSupportRepository.lastUploadedBytes, [1, 2, 3]);
  });

  test('confirm in CMND mode uses edited OCR fields', () async {
    final cmndOcr = OcrService(
      recognizeText: (_, {required String docType}) async => '''
CHỨNG MINH NHÂN DÂN
Họ và tên: Trần Thị B
123456789
''',
    );
    final controller = CaptureController(
      travelSupportRepository: travelSupportRepository,
      ocrService: cmndOcr,
      shareholderOverride: TestData.shareholders.first,
      modeOverride: CaptureMode.identity,
      identityTypeOverride: 'CMND',
      intentOverride: CaptureIntent.ocr,
    );
    controller.onInit();
    controller.hasCaptured.value = true;
    controller.imageBytes.value = Uint8List.fromList([1, 2, 3]);
    controller.identityNoController.text = '123456789';
    controller.receiverNameController.text = 'Trần Thị B';

    await controller.confirm();

    expect(controller.errorMessage.value, isNull);
  });

  test('usesAutoCrop is true for CMND without OpenAI', () async {
    SharedPreferences.setMockInitialValues({});
    final appConfig = AppConfigService();
    await appConfig.load();

    final cmnd = CaptureController(
      travelSupportRepository: travelSupportRepository,
      ocrService: ocrService,
      appConfig: appConfig,
      shareholderOverride: TestData.shareholders.first,
      identityTypeOverride: 'CMND',
    );
    cmnd.onInit();
    expect(cmnd.usesAutoCrop, isTrue);
    expect(cmnd.usesOpenAiCmndOcr, isFalse);

    final cccd = CaptureController(
      travelSupportRepository: travelSupportRepository,
      ocrService: ocrService,
      appConfig: appConfig,
      shareholderOverride: TestData.shareholders.first,
      identityTypeOverride: 'CCCD',
    );
    cccd.onInit();
    expect(cccd.usesAutoCrop, isFalse);
  });

  test('setCropAspectMode before crop UI does not throw', () async {
    SharedPreferences.setMockInitialValues({});
    final appConfig = AppConfigService();
    await appConfig.load();
    await appConfig.saveUseOpenAiOcr(true);

    final controller = CaptureController(
      travelSupportRepository: travelSupportRepository,
      ocrService: ocrService,
      appConfig: appConfig,
      shareholderOverride: TestData.shareholders.first,
      identityTypeOverride: 'CMND',
    );
    controller.onInit();

    expect(
      () => controller.setCropAspectMode(CropAspectMode.free),
      returnsNormally,
    );
    expect(controller.cropAspectMode.value, CropAspectMode.free);
  });

  test('usesAutoCrop is false for CMND when OpenAI enabled', () async {
    SharedPreferences.setMockInitialValues({});
    final appConfig = AppConfigService();
    await appConfig.load();
    await appConfig.saveUseOpenAiOcr(true);

    final cmnd = CaptureController(
      travelSupportRepository: travelSupportRepository,
      ocrService: ocrService,
      appConfig: appConfig,
      shareholderOverride: TestData.shareholders.first,
      identityTypeOverride: 'CMND',
    );
    cmnd.onInit();

    expect(cmnd.usesOpenAiCmndOcr, isTrue);
    expect(cmnd.usesAutoCrop, isFalse);
  });

  test('confirm in evidence mode surfaces conflict errors', () async {
    travelSupportRepository.shouldThrowConflict = true;
    final controller = CaptureController(
      travelSupportRepository: travelSupportRepository,
      ocrService: ocrService,
      shareholderOverride: TestData.shareholders.first,
      modeOverride: CaptureMode.evidence,
    );
    controller.onInit();

    await controller.confirm();

    expect(controller.errorMessage.value, 'Người này đã nhận phụ cấp.');
  });

  test('confirm in identity mode shows usage warning when already used', () async {
    travelSupportRepository.checkIdentityResult = const IdentityCheckResultDto(
      alreadyUsed: true,
      usedForMcd: 'SH0002',
      usedForMcds: ['SH0002'],
      message: 'Đã nhận cho SH0002',
    );

    final controller = CaptureController(
      travelSupportRepository: travelSupportRepository,
      ocrService: ocrService,
      shareholderOverride: TestData.shareholders.first,
      modeOverride: CaptureMode.identity,
      identityTypeOverride: 'CMND',
      intentOverride: CaptureIntent.ocr,
    );
    controller.onInit();
    controller.hasCaptured.value = true;
    controller.imageBytes.value = Uint8List.fromList([1, 2, 3]);
    controller.identityNoController.text = '123456789';
    controller.receiverNameController.text = 'Trần Thị B';

    await controller.confirm();

    expect(controller.hasIdentityUsageWarning, isTrue);
    expect(controller.errorMessage.value, isNull);
    expect(travelSupportRepository.checkIdentityCallCount, 1);

    await controller.confirm();

    expect(travelSupportRepository.checkIdentityCallCount, 2);
  });
}
