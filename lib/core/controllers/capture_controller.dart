import 'dart:typed_data';

import 'package:crop_your_image/crop_your_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:share_verify/core/controllers/dashboard_controller.dart';
import 'package:share_verify/core/data/dto/travel_support_dtos.dart';
import 'package:share_verify/core/models/attendance_type.dart';
import 'package:share_verify/core/models/capture_route_args.dart';
import 'package:share_verify/core/utils/date_input_utils.dart';
import 'package:share_verify/core/utils/identity_type_utils.dart';
import 'package:share_verify/core/models/crop_aspect_mode.dart';
import 'package:share_verify/core/models/identity_verification.dart';
import 'package:share_verify/core/models/payment_status.dart';
import 'package:share_verify/core/models/shareholder.dart';
import 'package:share_verify/core/network/api_client.dart';
import 'package:share_verify/core/repositories/travel_support_repository.dart';
import 'package:share_verify/core/services/ocr_service.dart';
import 'package:share_verify/core/utils/camera_image_crop.dart';
import 'package:share_verify/core/widgets/document_camera_preview.dart';

enum CaptureUiPhase { camera, cropping, review }

class CaptureController extends GetxController {
  static const successRouteName = '/success';

  static const Shareholder placeholderShareholder = Shareholder(
    code: '—',
    fullName: 'Chưa quét mã cổ đông',
    idNumber: '',
    shares: 0,
    status: PaymentStatus.notReceived,
  );

  final TravelSupportRepository _travelSupportRepository;
  final OcrService _ocrService;
  final ImagePicker _imagePicker = ImagePicker();

  CaptureController({
    TravelSupportRepository? travelSupportRepository,
    OcrService? ocrService,
    CaptureRouteArgs? routeArgsOverride,
    Shareholder? shareholderOverride,
    CaptureMode? modeOverride,
    String? identityTypeOverride,
    CaptureIntent? intentOverride,
    String? prefillNameOverride,
    String? prefillIdentityNoOverride,
    String? prefillDateOfBirthOverride,
    String? prefillCmndNoOverride,
  })  : _travelSupportRepository =
            travelSupportRepository ?? Get.find<TravelSupportRepository>(),
        _ocrService = ocrService ?? Get.find<OcrService>(),
        _routeArgsOverride = routeArgsOverride,
        _shareholderOverride = shareholderOverride,
        _modeOverride = modeOverride,
        _identityTypeOverride = identityTypeOverride,
        _intentOverride = intentOverride,
        _prefillNameOverride = prefillNameOverride,
        _prefillIdentityNoOverride = prefillIdentityNoOverride,
        _prefillDateOfBirthOverride = prefillDateOfBirthOverride,
        _prefillCmndNoOverride = prefillCmndNoOverride;

  final CaptureRouteArgs? _routeArgsOverride;
  final Shareholder? _shareholderOverride;
  final CaptureMode? _modeOverride;
  final String? _identityTypeOverride;
  final CaptureIntent? _intentOverride;
  final String? _prefillNameOverride;
  final String? _prefillIdentityNoOverride;
  final String? _prefillDateOfBirthOverride;
  final String? _prefillCmndNoOverride;

  late final Shareholder shareholder;
  late final CaptureMode mode;
  late final String identityType;
  late final CaptureIntent intent;
  String? prefillName;
  String? prefillIdentityNo;
  String? prefillDateOfBirth;
  String? prefillCmndNo;

  final capturePhase = CaptureUiPhase.camera.obs;
  final hasCaptured = false.obs;
  final isCapturing = false.obs;
  final rawImageBytes = Rxn<Uint8List>();
  final imageBytes = Rxn<Uint8List>();
  final isSubmitting = false.obs;
  final isOcrProcessing = false.obs;
  final errorMessage = RxnString();
  final identityCheckResult = Rxn<IdentityCheckResultDto>();
  final identityUsageWarningShown = false.obs;
  final ocrIdConfidence = Rxn<double>();
  final ocrNameConfidence = Rxn<double>();
  final identityNoController = TextEditingController();
  final cmndNoController = TextEditingController();
  final receiverNameController = TextEditingController();
  final dateOfBirthController = TextEditingController();
  final cameraPreviewKey = GlobalKey<DocumentCameraPreviewState>();
  final cropController = CropController();
  final cropAspectMode = CropAspectMode.free.obs;

  bool get hasIdentityUsageWarning =>
      identityCheckResult.value?.alreadyUsed == true &&
      identityUsageWarningShown.value;

  List<String> get usedShareholderCodes =>
      identityCheckResult.value?.usedForMcds ??
      (identityCheckResult.value?.usedForMcd != null
          ? [identityCheckResult.value!.usedForMcd!]
          : const []);

  @override
  void onInit() {
    final routeArgs = _routeArgsOverride ??
        (Get.arguments is CaptureRouteArgs
            ? Get.arguments as CaptureRouteArgs
            : null);

    if (routeArgs != null) {
      shareholder = routeArgs.shareholder ?? placeholderShareholder;
      mode = routeArgs.mode;
      identityType = routeArgs.identityType;
      intent = routeArgs.intent;
      prefillName = routeArgs.prefillName;
      prefillIdentityNo = routeArgs.prefillIdentityNo;
      prefillDateOfBirth = routeArgs.prefillDateOfBirth;
      prefillCmndNo = routeArgs.prefillCmndNo;
    } else if (_shareholderOverride != null) {
      shareholder = _shareholderOverride!;
      mode = _modeOverride ?? CaptureMode.identity;
      identityType = _identityTypeOverride ?? 'CCCD';
      intent = _intentOverride ?? CaptureIntent.ocr;
      prefillName = _prefillNameOverride;
      prefillIdentityNo = _prefillIdentityNoOverride;
      prefillDateOfBirth = _prefillDateOfBirthOverride;
      prefillCmndNo = _prefillCmndNoOverride;
    } else if (Get.arguments is Shareholder) {
      shareholder = Get.arguments as Shareholder;
      mode = CaptureMode.identity;
      identityType = 'CCCD';
      intent = CaptureIntent.ocr;
    } else {
      throw StateError(
        'CaptureController requires CaptureRouteArgs or Shareholder arguments',
      );
    }

    super.onInit();
    if (intent == CaptureIntent.qrPrefilled) {
      _applyQrPrefillToControllers();
    } else if (prefillDateOfBirth != null && prefillDateOfBirth!.isNotEmpty) {
      dateOfBirthController.text =
          formatDateOfBirthForInput(prefillDateOfBirth);
    }
  }

  @override
  void onClose() {
    identityNoController.dispose();
    cmndNoController.dispose();
    receiverNameController.dispose();
    dateOfBirthController.dispose();
    super.onClose();
  }

  bool get needsOcrReview =>
      intent == CaptureIntent.ocr || intent == CaptureIntent.qrPrefilled;

  bool get isQrPrefilled => intent == CaptureIntent.qrPrefilled;

  /// CMND: auto-crop theo khung overlay trên camera, bỏ bước crop tay.
  bool get usesAutoCrop => identityType.toUpperCase() == 'CMND';

  void _applyQrPrefillToControllers() {
    if (prefillIdentityNo != null && prefillIdentityNo!.isNotEmpty) {
      identityNoController.text = prefillIdentityNo!;
    }
    if (prefillName != null && prefillName!.isNotEmpty) {
      receiverNameController.text = prefillName!;
    }
    if (prefillDateOfBirth != null && prefillDateOfBirth!.isNotEmpty) {
      dateOfBirthController.text =
          formatDateOfBirthForInput(prefillDateOfBirth);
    }
    if (prefillCmndNo != null && prefillCmndNo!.isNotEmpty) {
      cmndNoController.text = prefillCmndNo!;
    }
  }

  /// CMND: OCR trên ảnh gốc (đủ vùng ngày sinh); loại khác dùng ảnh đã crop.
  Uint8List? get _ocrInputBytes {
    if (identityType.toUpperCase() == 'CMND') {
      return rawImageBytes.value ?? imageBytes.value;
    }
    return imageBytes.value;
  }

  /// Ảnh lưu làm chứng cứ — CMND dùng ảnh gốc chưa crop; loại khác dùng ảnh đã crop.
  Uint8List? get _evidencePhotoBytes {
    if (identityType.toUpperCase() == 'CMND') {
      return rawImageBytes.value ?? imageBytes.value;
    }
    return imageBytes.value;
  }

  int get _cameraFallbackQuality =>
      identityType.toUpperCase() == 'CMND' ? 100 : 92;

  Future<void> pickImage() async {
    if (isCapturing.value) return;

    errorMessage.value = null;
    isCapturing.value = true;
    try {
      Uint8List? bytes;

      final preview = cameraPreviewKey.currentState;
      if (preview != null && preview.isInitialized) {
        bytes = await preview.capture();
      }

      if (bytes == null) {
        final file = await _imagePicker.pickImage(
          source: ImageSource.camera,
          imageQuality: _cameraFallbackQuality,
          preferredCameraDevice: CameraDevice.rear,
        );
        if (file == null) {
          errorMessage.value =
              'Không chụp được ảnh. Kiểm tra quyền Camera trong Cài đặt.';
          return;
        }
        bytes = await file.readAsBytes();
      }

      rawImageBytes.value = bytes;

      if (usesAutoCrop) {
        final cropped = await _autoCropForOcr(bytes);
        imageBytes.value = cropped;
        hasCaptured.value = true;
        capturePhase.value = CaptureUiPhase.review;
        isCapturing.value = false;
        await _finishCapturedImageProcessing();
      } else {
        isCapturing.value = false;
        capturePhase.value = CaptureUiPhase.cropping;
      }
      errorMessage.value = null;
    } catch (error) {
      errorMessage.value = 'Không chụp được ảnh. Thử lại sau vài giây.';
    } finally {
      isCapturing.value = false;
    }
  }

  Future<Uint8List> _autoCropForOcr(Uint8List bytes) async {
    final preview = cameraPreviewKey.currentState;
    if (preview == null || !preview.isInitialized) return bytes;

    try {
      return await CameraImageCrop.cropFromPreview(
        imageBytes: bytes,
        frameKey: preview.frameKey,
        previewKey: preview.previewKey,
      );
    } catch (_) {
      return bytes;
    }
  }

  void setCropAspectMode(CropAspectMode mode) {
    cropAspectMode.value = mode;
    _applyCropAspectMode(mode);
  }

  void _applyCropAspectMode(CropAspectMode mode) {
    cropController.aspectRatio = mode.aspectRatio;
  }

  void applyCrop() {
    cropController.crop();
  }

  Future<void> onCropCompleted(Uint8List bytes) async {
    imageBytes.value = bytes;
    hasCaptured.value = true;
    capturePhase.value = CaptureUiPhase.review;
    await _finishCapturedImageProcessing();
  }

  Future<void> _finishCapturedImageProcessing() async {
    if (intent == CaptureIntent.qrPrefilled) {
      _applyQrPrefillToControllers();
      return;
    }
    if (needsOcrReview) {
      await _runOcrPreview();
    }
  }

  void onCropFailed(Object error) {
    errorMessage.value = 'Không crop được ảnh. Thử chụp lại.';
  }

  Future<void> rerunOcr() => _runOcrPreview();

  Future<void> _runOcrPreview() async {
    final bytes = _ocrInputBytes;
    if (bytes == null) return;

    isOcrProcessing.value = true;
    errorMessage.value = null;

    try {
      final ocr = await _ocrService.extractIdentity(
        bytes,
        docType: identityType,
      );

      identityNoController.text =
          ocr.identityNo ?? prefillIdentityNo ?? '';
      receiverNameController.text =
          ocr.fullName ?? prefillName ?? '';
      if (identityType.toUpperCase() == 'PASSPORT') {
        cmndNoController.text = ocr.legacyIdentityNo ?? '';
      }
      _applyBirthDateFromOcr(ocr.birthDate);
      ocrIdConfidence.value = ocr.idConfidence;
      ocrNameConfidence.value = ocr.nameConfidence;

      if (!ocr.hasIdentityNo) {
        errorMessage.value =
            'Không đọc được số $identityType — vui lòng nhập tay bên dưới.';
      } else if (!ocr.hasFullName) {
        errorMessage.value =
            'Không đọc được họ tên — vui lòng nhập tay bên dưới.';
      }
    } catch (error) {
      errorMessage.value =
          'OCR lỗi: ${ApiClient.messageFrom(error)}. Nhập tay thông tin bên dưới.';
      receiverNameController.text = prefillName ?? '';
    } finally {
      isOcrProcessing.value = false;
    }
  }

  void retake() {
    capturePhase.value = CaptureUiPhase.camera;
    hasCaptured.value = false;
    isCapturing.value = false;
    rawImageBytes.value = null;
    imageBytes.value = null;
    identityNoController.clear();
    cmndNoController.clear();
    receiverNameController.clear();
    dateOfBirthController.clear();
    isOcrProcessing.value = false;
    errorMessage.value = null;
    ocrIdConfidence.value = null;
    ocrNameConfidence.value = null;
    _clearIdentityUsageWarning();
    if (intent == CaptureIntent.qrPrefilled) {
      _applyQrPrefillToControllers();
    }
  }

  void _clearIdentityUsageWarning() {
    identityCheckResult.value = null;
    identityUsageWarningShown.value = false;
  }

  Future<void> confirm() async {
    if (mode == CaptureMode.identity) {
      await _confirmIdentity();
      return;
    }
    await _confirmEvidence();
  }

  Future<void> _confirmIdentity() async {
    if (isSubmitting.value) return;
    final evidenceBytes = _evidencePhotoBytes;
    if (!hasCaptured.value || evidenceBytes == null) {
      errorMessage.value = 'Vui lòng chụp ảnh giấy tờ trước khi xác nhận';
      return;
    }

    isSubmitting.value = true;
    errorMessage.value = null;

    try {
      final ocrBytes = _ocrInputBytes ?? evidenceBytes;
      final upload = await _travelSupportRepository.uploadPhoto(
        bytes: evidenceBytes,
        fileName: 'identity_${identityType.toLowerCase()}.jpg',
      );
      final photoPath = upload?.photoPath;

      String identityNo;
      String receiverName;
      String? birthDateValue;

      if (intent == CaptureIntent.photoEvidenceOnly) {
        identityNo = prefillIdentityNo ?? '';
        receiverName = prefillName ?? '';
        birthDateValue = _dateOfBirthValue ?? prefillDateOfBirth;
      } else {
        identityNo = identityNoController.text.trim();
        receiverName = receiverNameController.text.trim();
        birthDateValue = _dateOfBirthValue;

        if (intent == CaptureIntent.ocr && identityNo.isEmpty) {
          final ocr = await _ocrService.extractIdentity(
            ocrBytes,
            docType: identityType,
          );
          identityNo = ocr.identityNo ?? prefillIdentityNo ?? '';
          if (receiverName.isEmpty) {
            receiverName = ocr.fullName ?? prefillName ?? '';
          }
          birthDateValue ??= _formatBirthDateFromOcr(ocr.birthDate);
          if (identityType.toUpperCase() == 'PASSPORT' &&
              cmndNoController.text.trim().isEmpty) {
            cmndNoController.text = ocr.legacyIdentityNo ?? '';
          }
        }

        if (identityNo.isEmpty) {
          errorMessage.value =
              'Vui lòng nhập số $identityType (OCR không đọc được từ ảnh)';
          return;
        }
        if (receiverName.isEmpty) {
          errorMessage.value = 'Vui lòng nhập họ tên trên giấy tờ';
          return;
        }
      }

      if (identityNo.isEmpty || receiverName.isEmpty) {
        errorMessage.value = 'Thiếu thông tin giấy tờ';
        return;
      }

      final legacyIdentityNo = cmndNoController.text.trim();
      final shouldProceed = await _handleIdentityUsageCheck(
        identityNo: identityNo,
        receiverName: receiverName,
        birthDateValue: birthDateValue,
        legacyIdentityNo:
            legacyIdentityNo.isEmpty ? null : legacyIdentityNo,
      );
      if (!shouldProceed) return;

      Get.back(
        result: IdentityVerification(
          identityNo: identityNo,
          identityType: identityType,
          receiverName: receiverName,
          dateOfBirth: birthDateValue,
          legacyIdentityNo:
              legacyIdentityNo.isEmpty ? null : legacyIdentityNo,
          photoPath: photoPath,
          photoBytes: evidenceBytes,
        ),
      );
    } catch (error) {
      errorMessage.value = ApiClient.messageFrom(error);
    } finally {
      isSubmitting.value = false;
    }
  }

  Future<void> _confirmEvidence() async {
    if (isSubmitting.value) return;

    isSubmitting.value = true;
    errorMessage.value = null;

    try {
      String? photoPath;
      if (hasCaptured.value && imageBytes.value != null) {
        final upload = await _travelSupportRepository.uploadPhoto(
          bytes: imageBytes.value!,
          fileName: 'evidence.jpg',
        );
        photoPath = upload?.photoPath;
      }

      await _travelSupportRepository.receive(
        shareholder: shareholder,
        identity: IdentityVerification(
          identityNo: shareholder.idNumber.isNotEmpty
              ? shareholder.idNumber
              : 'unknown',
          identityType: 'CCCD',
          receiverName: shareholder.fullName,
          photoPath: photoPath,
        ),
        attendanceType: AttendanceType.direct,
        photoPath: photoPath,
      );
      await _refreshDashboard();
      Get.toNamed(successRouteName, arguments: shareholder);
    } catch (error) {
      final apiError = ApiClient.asApiException(error);
      if (apiError?.isConflict == true) {
        errorMessage.value = 'Người này đã nhận phụ cấp.';
      } else {
        errorMessage.value = ApiClient.messageFrom(error);
      }
    } finally {
      isSubmitting.value = false;
    }
  }

  String? get _dateOfBirthValue {
    final value = dateOfBirthController.text.trim();
    return value.isEmpty ? null : value;
  }

  void _applyBirthDateFromOcr(String? birthDate) {
    final formatted = _formatBirthDateFromOcr(birthDate);
    if (formatted != null) {
      dateOfBirthController.text = formatted;
    }
  }

  String? _formatBirthDateFromOcr(String? birthDate) {
    if (birthDate == null || birthDate.trim().isEmpty) return null;
    final formatted = formatDateOfBirthForInput(birthDate);
    return formatted.isEmpty ? null : formatted;
  }

  /// Returns true when confirm should proceed (pop screen).
  Future<bool> _handleIdentityUsageCheck({
    required String identityNo,
    required String receiverName,
    String? birthDateValue,
    String? legacyIdentityNo,
  }) async {
    try {
      final primary = await _travelSupportRepository.checkIdentity(
        identityNo: identityNo,
        identityType: identityType,
        fullName: receiverName,
        dateOfBirth: birthDateValue,
      );

      IdentityCheckResultDto result = primary;
      if (legacyIdentityNo != null && legacyIdentityNo.isNotEmpty) {
        final legacy = await _travelSupportRepository.checkIdentity(
          identityNo: legacyIdentityNo,
          identityType: inferLegacyIdentityType(legacyIdentityNo),
          fullName: receiverName,
          dateOfBirth: birthDateValue,
        );
        result = _mergeIdentityCheckResults(primary, legacy);
      }

      identityCheckResult.value = result;

      if (!result.alreadyUsed) {
        _clearIdentityUsageWarning();
        return true;
      }

      if (!identityUsageWarningShown.value) {
        identityUsageWarningShown.value = true;
        errorMessage.value = null;
        return false;
      }

      return true;
    } catch (error) {
      errorMessage.value = ApiClient.messageFrom(error);
      return false;
    }
  }

  IdentityCheckResultDto _mergeIdentityCheckResults(
    IdentityCheckResultDto primary,
    IdentityCheckResultDto legacy,
  ) {
    if (!primary.alreadyUsed) return legacy;
    if (!legacy.alreadyUsed) return primary;

    final mcds = <String>{
      ...primary.usedForMcds,
      ...legacy.usedForMcds,
      if (primary.usedForMcd != null) primary.usedForMcd!,
      if (legacy.usedForMcd != null) legacy.usedForMcd!,
    }.toList();

    return IdentityCheckResultDto(
      alreadyUsed: true,
      usedForMcd: mcds.isNotEmpty ? mcds.first : primary.usedForMcd,
      usedForMcds: mcds,
      receiverName: primary.receiverName ?? legacy.receiverName,
      usedIdentityType: primary.usedIdentityType ?? legacy.usedIdentityType,
      usedIdentityNo: primary.usedIdentityNo ?? legacy.usedIdentityNo,
      usedDateOfBirth: primary.usedDateOfBirth ?? legacy.usedDateOfBirth,
      receiveTime: primary.receiveTime ?? legacy.receiveTime,
      message: primary.message ?? legacy.message,
    );
  }

  void onIdentityFieldsEdited() {
    if (identityUsageWarningShown.value) {
      _clearIdentityUsageWarning();
    }
  }

  Future<void> _refreshDashboard() async {
    if (Get.isRegistered<DashboardController>()) {
      await Get.find<DashboardController>().refresh();
    }
  }
}
