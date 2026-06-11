import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:share_verify/core/controllers/dashboard_controller.dart';
import 'package:share_verify/core/data/dto/shareholder_dtos.dart';
import 'package:share_verify/core/data/dto/travel_support_dtos.dart';
import 'package:share_verify/core/models/attendance_type.dart';
import 'package:share_verify/core/models/capture_route_args.dart';
import 'package:share_verify/core/models/identity_verification.dart';
import 'package:share_verify/core/models/invitation_barcode.dart';
import 'package:share_verify/core/models/payment_status.dart';
import 'package:share_verify/core/models/shareholder.dart';
import 'package:share_verify/core/network/api_client.dart';
import 'package:share_verify/core/repositories/shareholder_repository.dart';
import 'package:share_verify/core/utils/date_input_utils.dart';
import 'package:share_verify/core/utils/identity_type_utils.dart';
import 'package:share_verify/core/repositories/travel_support_repository.dart';
import 'package:share_verify/core/models/travel_support_info.dart';
import 'package:share_verify/core/screens/verification/components/recipient_info_sheet.dart';
import 'package:share_verify/core/services/barcode_scanner_service.dart';
import 'package:share_verify/core/utils/barcode_parser.dart';
import 'package:share_verify/core/utils/cccd_qr_parser.dart';

enum ManualFormPrefillSource { qr, capture }

class VerificationController extends GetxController {
  static const captureRouteName = '/capture';
  static const barcodeRouteName = '/verification/barcode';
  static const successRouteName = '/success';

  final ShareholderRepository _shareholderRepository;
  final TravelSupportRepository _travelSupportRepository;
  final BarcodeScannerService _barcodeScannerService;
  final ImagePicker _imagePicker = ImagePicker();

  VerificationController({
    ShareholderRepository? shareholderRepository,
    TravelSupportRepository? travelSupportRepository,
    BarcodeScannerService? barcodeScannerService,
  })  : _shareholderRepository =
            shareholderRepository ?? Get.find<ShareholderRepository>(),
        _travelSupportRepository =
            travelSupportRepository ?? Get.find<TravelSupportRepository>(),
        _barcodeScannerService =
            barcodeScannerService ?? Get.find<BarcodeScannerService>();

  final scannedBarcode = Rxn<InvitationBarcode>();
  final selectedShareholder = Rxn<Shareholder>();
  final selectedPickerShareholder = Rxn<ShareholderSearchDto>();
  final identityCheckResult = Rxn<IdentityCheckResultDto>();
  final attendanceType = AttendanceType.direct.obs;
  final isSearching = false.obs;
  final isSubmitting = false.obs;
  final isCheckingIdentity = false.obs;
  final isLoadingRecipients = false.obs;
  final errorMessage = RxnString();

  final barcodeInputFocus = FocusNode();
  final barcodeInputController = TextEditingController();
  final manualNameController = TextEditingController();
  final manualIdController = TextEditingController();
  final manualCmndController = TextEditingController();
  final manualDateOfBirthController = TextEditingController();
  final manualIdentityType = 'CCCD'.obs;
  final manualFormPrefillSource = Rxn<ManualFormPrefillSource>();
  final manualPhotoPath = RxnString();
  final manualPhotoBytes = Rxn<Uint8List>();

  bool get isProxy => attendanceType.value == AttendanceType.proxy;

  IdentityVerification? get effectivePendingIdentity =>
      _buildPendingFromManualForm();

  /// Giấy tờ đã đủ thông tin để quét mã cổ đông (chưa lưu backend).
  IdentityVerification? get activeIdentity => effectivePendingIdentity;

  bool get isIdentityReady => effectivePendingIdentity?.isComplete == true;

  bool get canProceedToBarcodeScreen => isIdentityReady;

  bool get hasIdentityUsageWarning =>
      identityCheckResult.value?.alreadyUsed == true;

  List<String> get usedShareholderCodes =>
      identityCheckResult.value?.usedForMcds ??
      (identityCheckResult.value?.usedForMcd != null
          ? [identityCheckResult.value!.usedForMcd!]
          : const []);

  bool get _canUseTextControllers => !isClosed;

  @override
  void onClose() {
    barcodeInputController.dispose();
    barcodeInputFocus.dispose();
    manualNameController.dispose();
    manualIdController.dispose();
    manualCmndController.dispose();
    manualDateOfBirthController.dispose();
    super.onClose();
  }

  Future<void> goToBarcodeScreen() async {
    errorMessage.value = null;

    if (!isIdentityReady) {
      errorMessage.value =
          'Vui lòng chụp ảnh chứng cứ và nhập đủ thông tin trước khi quét mã cổ đông';
      return;
    }

    _resetBarcodeFlow();
    await Get.toNamed(barcodeRouteName);
  }

  Future<void> onScanInvitationBarcode() async {
    if (!isIdentityReady) {
      errorMessage.value =
          'Vui lòng quét hoặc chụp giấy tờ trước khi quét mã cổ đông';
      return;
    }

    final context = Get.context;
    if (context == null) return;

    final raw = await _barcodeScannerService.scanInvitation(context);
    if (raw != null) await onBarcodeScanned(raw);
  }

  Future<ShareholderSearchPageDto> searchShareholdersForPicker(
    String keyword,
    int page,
  ) {
    return _shareholderRepository.searchShareholders(
      keyword,
      page: page,
    );
  }

  Future<void> onShareholderPicked(ShareholderSearchDto item) async {
    selectedPickerShareholder.value = item;
    await onBarcodeScanned(item.mcd);
  }

  Future<void> onManualBarcodeEntry() async {
    final mcd = selectedPickerShareholder.value?.mcd ??
        barcodeInputController.text.trim();
    if (mcd.isEmpty) return;

    if (!isIdentityReady) {
      errorMessage.value =
          'Vui lòng quét hoặc chụp giấy tờ trước khi nhập mã cổ đông';
      return;
    }

    await onBarcodeScanned(mcd);
  }

  void clearShareholderPicker() {
    selectedPickerShareholder.value = null;
    barcodeInputController.clear();
    scannedBarcode.value = null;
    selectedShareholder.value = null;
    errorMessage.value = null;
  }

  Future<void> onBarcodeScanned(String raw) async {
    if (!isIdentityReady) {
      errorMessage.value =
          'Vui lòng quét hoặc chụp giấy tờ trước khi quét mã cổ đông';
      return;
    }

    errorMessage.value = null;

    final barcode = BarcodeParser.parse(raw);
    scannedBarcode.value = barcode;
    isSearching.value = true;

    Shareholder? shareholder;
    try {
      shareholder = await _shareholderRepository.findByMcd(barcode.mcd);
    } catch (error) {
      selectedShareholder.value = null;
      errorMessage.value = ApiClient.messageFrom(error);
      isSearching.value = false;
      return;
    } finally {
      isSearching.value = false;
    }

    if (shareholder == null) {
      selectedShareholder.value = null;
      errorMessage.value = 'Không tìm thấy cổ đông với mã ${barcode.mcd}';
      return;
    }

    selectedShareholder.value = shareholder;

    if (shareholder.status == PaymentStatus.received) {
      errorMessage.value =
          'Cổ đông ${shareholder.code} đã nhận phụ cấp. Không thể lưu lại.';
      return;
    }

    await _autoReceive(shareholder);
  }

  Future<void> onViewRecipientInfo() async {
    final context = Get.context;
    if (context == null) return;

    final sh = selectedShareholder.value;
    if (sh == null || sh.status != PaymentStatus.received) return;

    isLoadingRecipients.value = true;
    errorMessage.value = null;

    try {
      Shareholder current = sh;
      TravelSupportInfo? travelSupport = sh.travelSupport;

      if (travelSupport == null) {
        final refreshed = await _shareholderRepository.findByMcd(sh.code);
        if (refreshed == null) {
          errorMessage.value = 'Không tìm thấy thông tin cổ đông';
          return;
        }
        current = refreshed;
        travelSupport = refreshed.travelSupport;
        selectedShareholder.value = refreshed;
      }

      if (travelSupport == null) {
        errorMessage.value = 'Chưa có dữ liệu người nhận phụ cấp';
        return;
      }

      await RecipientInfoSheet.show(
        context,
        shareholder: current,
        travelSupport: travelSupport,
      );
    } catch (error) {
      errorMessage.value = ApiClient.messageFrom(error);
    } finally {
      isLoadingRecipients.value = false;
    }
  }

  void _resetIdentityFlow() {
    identityCheckResult.value = null;
    attendanceType.value = AttendanceType.direct;
    _clearManualForm(resetIdentityType: true);
    isSubmitting.value = false;
    isCheckingIdentity.value = false;
  }

  void _resetBarcodeFlow() {
    if (!_canUseTextControllers) return;
    barcodeInputController.clear();
    selectedPickerShareholder.value = null;
    scannedBarcode.value = null;
    selectedShareholder.value = null;
  }

  Future<void> setIdentityVerification(IdentityVerification verification) =>
      applyCaptureResult(verification);

  void onAttendanceTypeChanged(AttendanceType type) {
    attendanceType.value = type;
    _clearManualForm(resetIdentityType: true);
    identityCheckResult.value = null;
    _resetBarcodeFlow();
  }

  Future<void> applyCaptureResult(IdentityVerification verification) async {
    if (isClosed) return;
    _fillManualFormFromCapture(verification);
    _resetBarcodeFlow();
    errorMessage.value = null;
    await _checkIdentityUsage(verification);
  }

  void _clearManualForm({bool resetIdentityType = false}) {
    if (!_canUseTextControllers) return;
    manualNameController.clear();
    manualIdController.clear();
    manualCmndController.clear();
    manualDateOfBirthController.clear();
    if (resetIdentityType) {
      manualIdentityType.value = 'CCCD';
    }
    manualFormPrefillSource.value = null;
    manualPhotoPath.value = null;
    manualPhotoBytes.value = null;
  }

  IdentityVerification? _buildPendingFromManualForm() {
    if (!_canUseTextControllers) return null;
    final name = manualNameController.text.trim();
    final id = manualIdController.text.trim();
    final type = manualIdentityType.value;
    final dateOfBirth = manualDateOfBirthController.text.trim();
    final cmnd = manualCmndController.text.trim();
    final photo = manualPhotoPath.value;

    if (name.isEmpty || id.isEmpty || type.isEmpty) return null;
    if (photo == null || photo.isEmpty) return null;

    return IdentityVerification(
      identityNo: id,
      identityType: type,
      receiverName: name,
      dateOfBirth: dateOfBirth.isEmpty ? null : dateOfBirth,
      legacyIdentityNo: _manualLegacyIdentityValue(type, cmnd),
      photoPath: photo,
      photoBytes: manualPhotoBytes.value,
    );
  }

  Future<void> _checkIdentityUsage(IdentityVerification verification) async {
    isCheckingIdentity.value = true;
    identityCheckResult.value = null;

    try {
      final primary = await _travelSupportRepository.checkIdentity(
        identityNo: verification.identityNo,
        identityType: verification.identityType,
        fullName: verification.receiverName,
        dateOfBirth: verification.dateOfBirth,
      );

      var result = primary;
      final legacyNo = verification.legacyIdentityNo;
      if (legacyNo != null && legacyNo.isNotEmpty) {
        final legacy = await _travelSupportRepository.checkIdentity(
          identityNo: legacyNo,
          identityType: inferLegacyIdentityType(legacyNo),
          fullName: verification.receiverName,
          dateOfBirth: verification.dateOfBirth,
        );
        result = _mergeIdentityCheckResults(primary, legacy);
      }

      identityCheckResult.value = result;
    } catch (error) {
      if (!isClosed) {
        errorMessage.value = ApiClient.messageFrom(error);
      }
    } finally {
      if (!isClosed) {
        isCheckingIdentity.value = false;
      }
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

  Future<void> onScanQrCccd() async {
    final context = Get.context;
    if (context == null) return;

    errorMessage.value = null;

    final raw = await _barcodeScannerService.scanCccdQr(context);
    if (raw == null) return;

    final qrData = CccdQrParser.parse(raw);
    if (qrData == null) {
      errorMessage.value =
          'Không đọc được thông tin từ QR CCCD. Hãy thử chụp CCCD hoặc nhập tay.';
      return;
    }

    _fillManualFormFromQr(qrData);
    await _previewManualIdentityCheck();
  }

  void _fillManualFormFromQr(CccdQrData qrData) {
    if (!_canUseTextControllers) return;
    identityCheckResult.value = null;
    manualPhotoPath.value = null;
    manualPhotoBytes.value = null;

    manualIdentityType.value = 'CCCD';
    manualNameController.text = qrData.fullName;
    manualIdController.text = qrData.identityNo;
    manualCmndController.text = qrData.cmndNo ?? '';
    manualDateOfBirthController.text =
        formatDateOfBirthForInput(qrData.dateOfBirth);
    manualFormPrefillSource.value = ManualFormPrefillSource.qr;
  }

  void _fillManualFormFromCapture(IdentityVerification verification) {
    if (!_canUseTextControllers) return;
    identityCheckResult.value = null;

    manualIdentityType.value = verification.identityType;
    manualNameController.text = verification.receiverName;
    manualIdController.text = verification.identityNo;
    manualCmndController.text = verification.legacyIdentityNo ?? '';
    manualDateOfBirthController.text =
        formatDateOfBirthForInput(verification.dateOfBirth);
    manualPhotoPath.value = verification.photoPath;
    manualPhotoBytes.value = verification.photoBytes;
    manualFormPrefillSource.value = ManualFormPrefillSource.capture;
  }

  Future<void> _previewManualIdentityCheck() async {
    if (!_canUseTextControllers) return;
    final name = manualNameController.text.trim();
    final id = manualIdController.text.trim();
    if (name.isEmpty || id.isEmpty) return;

    final type = manualIdentityType.value;

    isCheckingIdentity.value = true;
    identityCheckResult.value = null;

    try {
      final primary = await _travelSupportRepository.checkIdentity(
        identityNo: id,
        identityType: type,
        fullName: name,
        dateOfBirth: _manualDateOfBirthValue,
      );

      var result = primary;
      final cmnd = manualCmndController.text.trim();
      if (cmnd.isNotEmpty) {
        final legacy = await _travelSupportRepository.checkIdentity(
          identityNo: cmnd,
          identityType: inferLegacyIdentityType(cmnd),
          fullName: name,
          dateOfBirth: _manualDateOfBirthValue,
        );
        result = _mergeIdentityCheckResults(primary, legacy);
      }

      identityCheckResult.value = result;
    } catch (error) {
      if (!isClosed) {
        errorMessage.value = ApiClient.messageFrom(error);
      }
    } finally {
      if (!isClosed) {
        isCheckingIdentity.value = false;
      }
    }
  }

  String? get _manualDateOfBirthValue {
    if (!_canUseTextControllers) return null;
    final value = manualDateOfBirthController.text.trim();
    return value.isEmpty ? null : value;
  }

  String? _manualLegacyIdentityValue(String type, String cmnd) {
    if (cmnd.isEmpty) return null;
    return supportsLegacyIdentityField(type) ? cmnd : null;
  }

  Future<void> onCaptureCccd() => _captureWithOcr('CCCD');

  Future<void> onCaptureCmnd() => _captureWithOcr('CMND');

  Future<void> onCapturePassport() => _captureWithOcr('PASSPORT');

  Future<void> _captureWithOcr(String type) async {
    final result = await _navigateToCapture(
      identityType: type,
      intent: CaptureIntent.ocr,
    );
    if (result == null) return;
    if (!Get.isRegistered<VerificationController>()) return;
    await Get.find<VerificationController>().applyCaptureResult(result);
  }

  Future<IdentityVerification?> _navigateToCapture({
    required String identityType,
    required CaptureIntent intent,
    String? prefillName,
    String? prefillIdentityNo,
    String? prefillDateOfBirth,
    String? prefillCmndNo,
  }) async {
    final args = CaptureRouteArgs(
      identityType: identityType,
      intent: intent,
      prefillName: prefillName,
      prefillIdentityNo: prefillIdentityNo,
      prefillDateOfBirth: prefillDateOfBirth,
      prefillCmndNo: prefillCmndNo,
    );

    final dynamic result = await Get.toNamed<dynamic>(
      captureRouteName,
      arguments: args,
    );

    return result is IdentityVerification ? result : null;
  }

  Future<void> onCaptureManualPhoto() async {
    errorMessage.value = null;
    final file = await _imagePicker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
    );
    if (file == null) return;

    final bytes = await file.readAsBytes();
    final upload = await _travelSupportRepository.uploadPhoto(
      bytes: bytes,
      fileName: 'manual_${manualIdentityType.value.toLowerCase()}.jpg',
    );
    manualPhotoBytes.value = Uint8List.fromList(bytes);
    manualPhotoPath.value = upload?.photoPath;

    final name = manualNameController.text.trim();
    final id = manualIdController.text.trim();
    if (name.isNotEmpty && id.isNotEmpty) {
      await _previewManualIdentityCheck();
    }
  }

  Future<void> _autoReceive(Shareholder sh) async {
    if (isSubmitting.value) return;

    final identity = effectivePendingIdentity;
    if (identity == null || !identity.isComplete) return;

    isSubmitting.value = true;
    errorMessage.value = null;

    try {
      if (isProxy) {
        await _travelSupportRepository.receive(
          shareholder: sh,
          identity: IdentityVerification(
            identityNo: sh.idNumber.isNotEmpty ? sh.idNumber : 'N/A',
            identityType: 'CCCD',
            receiverName: sh.fullName,
          ),
          attendanceType: AttendanceType.proxy,
          proxyPersonName: identity.receiverName,
          proxyIdentityNo: identity.identityNo,
          proxyIdentityType: identity.identityType,
          photoPath: identity.photoPath,
        );
      } else {
        await _travelSupportRepository.receive(
          shareholder: sh,
          identity: identity,
          attendanceType: AttendanceType.direct,
          photoPath: identity.photoPath,
        );
      }

      await _refreshDashboard();
      await Get.offNamed(successRouteName, arguments: sh);
    } catch (error) {
      final apiError = ApiClient.asApiException(error);
      if (apiError?.isConflict == true) {
        final apiMessage = ApiClient.messageFrom(error);
        errorMessage.value = apiMessage.contains('đã')
            ? apiMessage
            : 'Người này đã nhận phụ cấp.';
        selectedShareholder.value = sh.copyWith(status: PaymentStatus.received);
      } else {
        errorMessage.value = ApiClient.messageFrom(error);
      }
    } finally {
      isSubmitting.value = false;
    }
  }

  void resetSelection() {
    _resetBarcodeFlow();
    _resetIdentityFlow();
    isSearching.value = false;
    errorMessage.value = null;
  }

  static const shellRouteName = '/shell';

  Future<void> processNextPerson() async {
    resetSelection();
    await Get.offAllNamed(shellRouteName);
  }

  Future<void> _refreshDashboard() async {
    if (Get.isRegistered<DashboardController>()) {
      await Get.find<DashboardController>().refresh();
    }
  }
}
