import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:share_verify/core/controllers/dashboard_controller.dart';
import 'package:share_verify/core/data/dto/registration_no_autocomplete_dtos.dart';
import 'package:share_verify/core/data/dto/shareholder_dtos.dart';
import 'package:share_verify/core/data/dto/travel_support_dtos.dart';
import 'package:share_verify/core/models/attendance_type.dart';
import 'package:share_verify/core/models/verification_step.dart';
import 'package:share_verify/core/models/capture_route_args.dart';
import 'package:share_verify/core/models/identity_verification.dart';
import 'package:share_verify/core/models/invitation_barcode.dart';
import 'package:share_verify/core/models/open_ai_usage_info.dart';
import 'package:share_verify/core/models/payment_status.dart';
import 'package:share_verify/core/models/shareholder.dart';
import 'package:share_verify/core/network/api_client.dart';
import 'package:share_verify/core/repositories/shareholder_repository.dart';
import 'package:share_verify/core/utils/identity_type_utils.dart';
import 'package:share_verify/core/repositories/travel_support_repository.dart';
import 'package:share_verify/core/models/travel_support_info.dart';
import 'package:share_verify/core/utils/allowance_amount.dart';
import 'package:share_verify/core/screens/verification/components/recipient_info_sheet.dart';
import 'package:share_verify/core/screens/verification/components/verification_identity_usage_dialog.dart';
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
  final verificationStep = VerificationStep.attendance.obs;
  final isSearching = false.obs;
  final isSubmitting = false.obs;
  final isCheckingIdentity = false.obs;
  final isLoadingRecipients = false.obs;
  final receiveJustCompleted = false.obs;
  final errorMessage = RxnString();

  final barcodeInputFocus = FocusNode();
  final barcodeInputController = TextEditingController();
  final manualNameController = TextEditingController();
  final manualIdController = TextEditingController();
  final manualCmndController = TextEditingController();
  final manualIdentityType = 'CCCD'.obs;
  final manualFormPrefillSource = Rxn<ManualFormPrefillSource>();
  final manualPhotoPath = RxnString();
  final manualPhotoBytes = Rxn<Uint8List>();
  final manualOpenAiUsage = Rxn<OpenAiUsageInfo>();
  final _identityUsageDialogShown = false.obs;
  final manualIdentityFormRevision = 0.obs;

  Timer? _manualIdentityLookupDebounce;
  String? _lastManualIdentityLookupKey;

  bool get isProxy => attendanceType.value == AttendanceType.proxy;

  bool get isOnAttendanceStep =>
      verificationStep.value == VerificationStep.attendance;

  bool get isOnIdentityStep =>
      verificationStep.value == VerificationStep.identity;

  bool get isOnEvidenceStep =>
      verificationStep.value == VerificationStep.evidence;

  bool get isOnBarcodeStep =>
      verificationStep.value == VerificationStep.barcode;

  IdentityVerification? get effectivePendingIdentity =>
      _buildPendingFromManualForm();

  /// Giấy tờ đã đủ thông tin để quét mã cổ đông (chưa lưu backend).
  IdentityVerification? get activeIdentity => effectivePendingIdentity;

  bool get isIdentityInfoReady {
    if (!_canUseTextControllers) return false;
    final name = manualNameController.text.trim();
    final id = manualIdController.text.trim();
    final type = manualIdentityType.value;
    return name.isNotEmpty && id.isNotEmpty && type.isNotEmpty;
  }

  bool get isIdentityReady => effectivePendingIdentity?.isComplete == true;

  bool get canProceedToBarcodeScreen => isIdentityReady;

  bool get hasShareholderSelected =>
      selectedShareholder.value != null ||
      scannedBarcode.value != null ||
      selectedPickerShareholder.value != null;

  bool get canGoToPreviousStep => !isOnAttendanceStep;

  bool get canGoToNextStep {
    if (isCheckingIdentity.value) return false;
    if (isOnBarcodeStep && (isSubmitting.value || isSearching.value)) {
      return false;
    }
    return switch (verificationStep.value) {
      VerificationStep.attendance => true,
      VerificationStep.identity => isIdentityInfoReady,
      VerificationStep.evidence => isIdentityReady,
      VerificationStep.barcode => hasShareholderSelected,
    };
  }

  bool get hasIdentityUsageWarning =>
      identityCheckResult.value?.alreadyUsed == true;

  List<String> get usedShareholderCodes =>
      identityCheckResult.value?.usedForMcds ??
      (identityCheckResult.value?.usedForMcd != null
          ? [identityCheckResult.value!.usedForMcd!]
          : const []);

  bool get shouldPromptIdentityUsageDialog =>
      isOnIdentityStep &&
      hasIdentityUsageWarning &&
      isIdentityInfoReady &&
      !_identityUsageDialogShown.value;

  bool get _canUseTextControllers => !isClosed;

  void _bumpManualIdentityFormRevision() {
    manualIdentityFormRevision.value++;
  }

  @override
  void onInit() {
    super.onInit();
    manualNameController.addListener(_onManualNameChanged);
    manualIdController.addListener(_onManualPrimaryIdChanged);
    manualCmndController.addListener(_onManualLegacyIdChanged);
    ever(manualIdentityType, (_) {
      _identityUsageDialogShown.value = false;
      _bumpManualIdentityFormRevision();
      _scheduleManualIdentityLookup();
      _scheduleManualIdentityUsageRecheck();
    });
  }

  @override
  void onClose() {
    _manualIdentityLookupDebounce?.cancel();
    _manualIdentityUsageRecheckDebounce?.cancel();
    manualNameController.removeListener(_onManualNameChanged);
    manualIdController.removeListener(_onManualPrimaryIdChanged);
    manualCmndController.removeListener(_onManualLegacyIdChanged);
    barcodeInputController.dispose();
    barcodeInputFocus.dispose();
    manualNameController.dispose();
    manualIdController.dispose();
    manualCmndController.dispose();
    super.onClose();
  }

  Future<void> _maybeShowIdentityUsageDialog() async {
    if (!shouldPromptIdentityUsageDialog) return;

    BuildContext? context;
    try {
      context = Get.context;
    } catch (_) {
      return;
    }
    if (context == null || !context.mounted) return;

    _identityUsageDialogShown.value = true;
    final accepted = await VerificationIdentityUsageDialog.show(
      context,
      check: identityCheckResult.value!,
    );
    if (accepted) {
      advanceToEvidenceStep(force: true);
    } else {
      _identityUsageDialogShown.value = false;
    }
  }

  Future<void> goToBarcodeScreen() => advanceToBarcodeStep();

  void advanceToIdentityStep() {
    errorMessage.value = null;
    verificationStep.value = VerificationStep.identity;
  }

  Future<void> advanceToEvidenceStep({bool force = false}) async {
    errorMessage.value = null;

    if (!isIdentityInfoReady) {
      errorMessage.value =
          'Vui lòng nhập đủ thông tin giấy tờ trước khi chụp ảnh chứng cứ';
      return;
    }

    if (!force) {
      await _flushManualIdentityUsageCheck();
      if (shouldPromptIdentityUsageDialog) {
        await _maybeShowIdentityUsageDialog();
        return;
      }
    }

    verificationStep.value = VerificationStep.evidence;
  }

  Future<void> advanceToBarcodeStep() async {
    errorMessage.value = null;

    if (!isIdentityReady) {
      errorMessage.value =
          'Vui lòng chụp ảnh chứng cứ và nhập đủ thông tin trước khi quét mã cổ đông';
      return;
    }

    verificationStep.value = VerificationStep.barcode;
    _resetBarcodeFlow();
  }

  void goBackStep() {
    errorMessage.value = null;
    verificationStep.value = switch (verificationStep.value) {
      VerificationStep.barcode => VerificationStep.evidence,
      VerificationStep.evidence => VerificationStep.identity,
      VerificationStep.identity => VerificationStep.attendance,
      VerificationStep.attendance => VerificationStep.attendance,
    };
    if (isOnIdentityStep && isIdentityInfoReady) {
      _identityUsageDialogShown.value = false;
      _scheduleManualIdentityUsageRecheck();
    }
  }

  Future<void> goToNextStep() async {
    switch (verificationStep.value) {
      case VerificationStep.attendance:
        advanceToIdentityStep();
      case VerificationStep.identity:
        await advanceToEvidenceStep();
      case VerificationStep.evidence:
        await advanceToBarcodeStep();
      case VerificationStep.barcode:
        if (hasShareholderSelected) {
          await processNextPerson();
        }
    }
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
      final refreshed = await _refreshShareholderDetail(shareholder.code);
      if (refreshed != null) {
        selectedShareholder.value = refreshed;
      }
      errorMessage.value =
          'Cổ đông ${shareholder.code} đã nhận phụ cấp. Không thể lưu lại.';
      return;
    }

    await _autoReceive(shareholder);
  }

  Future<void> onViewRecipientInfo(BuildContext context) async {
    final sh = selectedShareholder.value;
    if (sh == null) {
      errorMessage.value = 'Chưa chọn cổ đông';
      return;
    }
    if (sh.status != PaymentStatus.received) {
      errorMessage.value = 'Cổ đông này chưa nhận phụ cấp';
      return;
    }

    isLoadingRecipients.value = true;
    errorMessage.value = null;

    try {
      final resolved = await _resolveRecipientInfo(sh);
      if (resolved == null) {
        errorMessage.value = 'Chưa có dữ liệu người nhận phụ cấp';
        return;
      }

      selectedShareholder.value = resolved.shareholder;

      await RecipientInfoSheet.show(
        context,
        shareholder: resolved.shareholder,
        travelSupport: resolved.travelSupport,
      );
    } catch (error) {
      errorMessage.value = ApiClient.messageFrom(error);
    } finally {
      isLoadingRecipients.value = false;
    }
  }

  Future<Shareholder?> _refreshShareholderDetail(String mcd) async {
    try {
      return await _shareholderRepository.findByMcd(mcd);
    } catch (_) {
      return null;
    }
  }

  Future<({Shareholder shareholder, TravelSupportInfo travelSupport})?>
      _resolveRecipientInfo(Shareholder sh) async {
    Shareholder current = sh;
    TravelSupportInfo? travelSupport = sh.travelSupport;

    if (travelSupport == null) {
      final refreshed = await _refreshShareholderDetail(sh.code);
      if (refreshed != null) {
        current = refreshed;
        travelSupport = refreshed.travelSupport;
      }
    }

    travelSupport ??= _buildSessionTravelSupport(current);
    if (travelSupport == null) return null;

    return (shareholder: current, travelSupport: travelSupport);
  }

  TravelSupportInfo? _buildSessionTravelSupport(Shareholder shareholder) {
    final identity = effectivePendingIdentity;
    if (identity == null || !identity.isComplete) return null;

    if (isProxy) {
      return TravelSupportInfo(
        receiverName: shareholder.fullName,
        receiverIdentityNo:
            shareholder.idNumber.isNotEmpty ? shareholder.idNumber : null,
        identityType: 'CCCD',
        attendanceType: 'Proxy',
        proxyPersonName: identity.receiverName,
        proxyIdentityNo: identity.identityNo,
        proxyIdentityType: identity.identityType,
        receiveAmount: AllowanceAmount.forShareholder(shareholder),
        receiveTime: DateTime.now(),
        photoPath: identity.photoPath,
        operatorName: null,
      );
    }

    return TravelSupportInfo(
      receiverName: identity.receiverName,
      receiverIdentityNo: identity.identityNo,
      identityType: identity.identityType,
      attendanceType: 'Direct',
      receiveAmount: AllowanceAmount.forShareholder(shareholder),
      receiveTime: DateTime.now(),
      photoPath: identity.photoPath,
      operatorName: null,
    );
  }

  void _resetIdentityFlow() {
    verificationStep.value = VerificationStep.attendance;
    identityCheckResult.value = null;
    _identityUsageDialogShown.value = false;
    receiveJustCompleted.value = false;
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
    if (attendanceType.value == type) return;

    attendanceType.value = type;
    _identityUsageDialogShown.value = false;
    _clearManualForm(resetIdentityType: true);
    identityCheckResult.value = null;
    _resetBarcodeFlow();
  }

  bool _shouldAdvanceToEvidenceAfterCapture(IdentityVerification verification) {
    return switch (verification.identityType.toUpperCase()) {
      'CMND' || 'PASSPORT' => true,
      _ => false,
    };
  }

  Future<void> applyCaptureResult(IdentityVerification verification) async {
    if (isClosed) return;
    _fillManualFormFromCapture(verification);
    _resetBarcodeFlow();
    errorMessage.value = null;
    verificationStep.value = VerificationStep.identity;

    if (verification.identityUsageAcknowledged &&
        verification.identityUsageCheck != null) {
      identityCheckResult.value = verification.identityUsageCheck;
      if (verification.identityUsageCheck!.alreadyUsed) {
        _identityUsageDialogShown.value = true;
      }
    } else {
      await _checkIdentityUsage(verification);
    }

    if (_shouldAdvanceToEvidenceAfterCapture(verification)) {
      verificationStep.value = VerificationStep.evidence;
    }
  }

  void _clearManualForm({bool resetIdentityType = false}) {
    if (!_canUseTextControllers) return;
    _identityUsageDialogShown.value = false;
    _lastManualIdentityLookupKey = null;
    manualNameController.clear();
    manualIdController.clear();
    manualCmndController.clear();
    if (resetIdentityType) {
      manualIdentityType.value = 'CCCD';
    }
    manualFormPrefillSource.value = null;
    manualPhotoPath.value = null;
    manualPhotoBytes.value = null;
    manualOpenAiUsage.value = null;
    _bumpManualIdentityFormRevision();
  }

  void resetManualIdentityForm() {
    if (!_canUseTextControllers) return;
    _manualIdentityLookupDebounce?.cancel();
    _manualIdentityUsageRecheckDebounce?.cancel();
    _identityUsageDialogShown.value = false;
    _clearManualForm(resetIdentityType: true);
    identityCheckResult.value = null;
    isCheckingIdentity.value = false;
    errorMessage.value = null;
    _resetBarcodeFlow();
    verificationStep.value = VerificationStep.identity;
  }

  IdentityVerification? _buildPendingFromManualForm() {
    if (!_canUseTextControllers) return null;
    final name = manualNameController.text.trim();
    final id = manualIdController.text.trim();
    final type = manualIdentityType.value;
    final cmnd = manualCmndController.text.trim();
    final photo = manualPhotoPath.value;

    if (name.isEmpty || id.isEmpty || type.isEmpty) return null;
    if (photo == null || photo.isEmpty) return null;

    return IdentityVerification(
      identityNo: id,
      identityType: type,
      receiverName: name,
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
      );

      var result = primary;
      final legacyNo = verification.legacyIdentityNo;
      if (legacyNo != null && legacyNo.isNotEmpty) {
        final legacy = await _travelSupportRepository.checkIdentity(
          identityNo: legacyNo,
          identityType: inferLegacyIdentityType(legacyNo),
          fullName: verification.receiverName,
        );
        result = _mergeIdentityCheckResults(
          primary,
          legacy,
          primaryIdentityType: verification.identityType,
        );
      }

      identityCheckResult.value = result;
    } catch (error) {
      if (!isClosed) {
        errorMessage.value = ApiClient.messageFrom(error);
      }
    } finally {
      if (!isClosed) {
        isCheckingIdentity.value = false;
        await _maybeShowIdentityUsageDialog();
      }
    }
  }

  IdentityCheckResultDto _mergeIdentityCheckResults(
    IdentityCheckResultDto primary,
    IdentityCheckResultDto legacy, {
    String? primaryIdentityType,
  }) {
    if (!primary.alreadyUsed && legacy.alreadyUsed) {
      return IdentityCheckResultDto(
        alreadyUsed: true,
        usedForMcd: legacy.usedForMcd,
        usedForMcds: legacy.usedForMcds,
        usedForShareholders: legacy.usedForShareholders,
        receiverName: legacy.receiverName,
        usedIdentityType: legacy.usedIdentityType,
        usedIdentityNo: legacy.usedIdentityNo,
        usedDateOfBirth: legacy.usedDateOfBirth,
        receiveTime: legacy.receiveTime,
        message: legacy.message ??
            _legacyIdentityUsedMessage(primaryIdentityType),
      );
    }

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
      usedForShareholders: IdentityCheckResultDto.mergeUsedShareholders(
        primary,
        legacy,
      ),
      receiverName: primary.receiverName ?? legacy.receiverName,
      usedIdentityType: primary.usedIdentityType ?? legacy.usedIdentityType,
      usedIdentityNo: primary.usedIdentityNo ?? legacy.usedIdentityNo,
      usedDateOfBirth: primary.usedDateOfBirth ?? legacy.usedDateOfBirth,
      receiveTime: primary.receiveTime ?? legacy.receiveTime,
      message: primary.message ?? legacy.message,
    );
  }

  String? _legacyIdentityUsedMessage(String? primaryIdentityType) {
    return switch (primaryIdentityType?.toUpperCase()) {
      'CCCD' =>
        'Số CMND đã được sử dụng. Số CCCD này coi như đã nhận phụ cấp.',
      'PASSPORT' =>
        'Số CMND/CCCD phụ đã được sử dụng. Hộ chiếu này coi như đã nhận phụ cấp.',
      _ => null,
    };
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
    manualOpenAiUsage.value = null;
    manualFormPrefillSource.value = ManualFormPrefillSource.qr;

    manualIdentityType.value = 'CCCD';
    manualNameController.text = qrData.fullName;
    manualIdController.text = qrData.identityNo;
    manualCmndController.text = qrData.cmndNo ?? '';
    _bumpManualIdentityFormRevision();
  }

  void _fillManualFormFromCapture(IdentityVerification verification) {
    if (!_canUseTextControllers) return;
    identityCheckResult.value = null;
    manualFormPrefillSource.value = ManualFormPrefillSource.capture;

    manualIdentityType.value = verification.identityType;
    manualNameController.text = verification.receiverName;
    manualIdController.text = verification.identityNo;
    manualCmndController.text = verification.legacyIdentityNo ?? '';
    manualPhotoPath.value = verification.photoPath;
    manualPhotoBytes.value = verification.photoBytes;
    manualOpenAiUsage.value = verification.openAiUsage;
    _bumpManualIdentityFormRevision();
  }

  void applyManualRegistrationLookup(RegistrationNoAutocompleteItemDto item) {
    if (manualFormPrefillSource.value != null) return;
    _fillManualFieldsFromRegistrationLookup(item);
  }

  void _fillManualFieldsFromRegistrationLookup(
    RegistrationNoAutocompleteItemDto item,
  ) {
    if (!_canUseTextControllers) return;

    if (manualNameController.text.trim().isEmpty && item.fullName.isNotEmpty) {
      manualNameController.text = item.fullName;
    }
  }

  void _onManualNameChanged() {
    _identityUsageDialogShown.value = false;
    _bumpManualIdentityFormRevision();
    _scheduleManualIdentityUsageRecheck();
  }

  void _onManualPrimaryIdChanged() {
    _identityUsageDialogShown.value = false;
    _bumpManualIdentityFormRevision();
    _scheduleManualIdentityLookup(isLegacy: false);
    _scheduleManualIdentityUsageRecheck();
  }

  void _onManualLegacyIdChanged() {
    _identityUsageDialogShown.value = false;
    _bumpManualIdentityFormRevision();
    _scheduleManualIdentityLookup(isLegacy: true);
    _scheduleManualIdentityUsageRecheck();
  }

  Timer? _manualIdentityUsageRecheckDebounce;

  void _scheduleManualIdentityUsageRecheck() {
    if (!isOnIdentityStep) return;

    _manualIdentityUsageRecheckDebounce?.cancel();
    _manualIdentityUsageRecheckDebounce = Timer(
      const Duration(milliseconds: 450),
      () => unawaited(_previewManualIdentityCheck()),
    );
  }

  Future<void> _flushManualIdentityUsageCheck() async {
    _manualIdentityUsageRecheckDebounce?.cancel();
    _manualIdentityUsageRecheckDebounce = null;
    if (!isOnIdentityStep || !isIdentityInfoReady) return;
    await _previewManualIdentityCheck();
  }

  void _scheduleManualIdentityLookup({bool isLegacy = false}) {
    if (manualFormPrefillSource.value != null) return;

    _manualIdentityLookupDebounce?.cancel();
    _manualIdentityLookupDebounce = Timer(
      const Duration(milliseconds: 400),
      () => unawaited(_lookupManualIdentityPrefill(isLegacy: isLegacy)),
    );
  }

  Future<void> _lookupManualIdentityPrefill({required bool isLegacy}) async {
    if (!_canUseTextControllers || manualFormPrefillSource.value != null) {
      return;
    }

    final type = manualIdentityType.value;
    final controller = isLegacy ? manualCmndController : manualIdController;
    final id = controller.text.trim();
    if (id.isEmpty) return;

    final lookupType = isLegacy ? inferLegacyIdentityType(id) : type;
    if (!isCompleteIdentityNumber(lookupType, id)) return;

    final lookupKey = '${isLegacy ? 'legacy' : 'primary'}:$lookupType:$id';
    if (_lastManualIdentityLookupKey == lookupKey) return;

    try {
      final filter = registrationNoAutocompleteIdentityType(
        type,
        legacy: isLegacy,
        legacyIdentityNo: isLegacy ? id : null,
      );
      final result = await _shareholderRepository.lookupRegistrationNumber(
        id,
        identityType: filter,
      );
      if (result == null) return;
      if (controller.text.trim() != id) return;
      if (manualFormPrefillSource.value != null) return;

      _lastManualIdentityLookupKey = lookupKey;
      _fillManualFieldsFromRegistrationLookup(result);
    } catch (_) {
      // Lookup is best-effort while typing manually.
    }
  }

  Future<void> _previewManualIdentityCheck() async {
    if (!_canUseTextControllers || !isOnIdentityStep) return;
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
      );

      var result = primary;
      final cmnd = manualCmndController.text.trim();
      if (cmnd.isNotEmpty) {
        final legacy = await _travelSupportRepository.checkIdentity(
          identityNo: cmnd,
          identityType: inferLegacyIdentityType(cmnd),
          fullName: name,
        );
        result = _mergeIdentityCheckResults(
          primary,
          legacy,
          primaryIdentityType: type,
        );
      }

      identityCheckResult.value = result;
    } catch (error) {
      if (!isClosed) {
        errorMessage.value = ApiClient.messageFrom(error);
      }
    } finally {
      if (!isClosed) {
        isCheckingIdentity.value = false;
        await _maybeShowIdentityUsageDialog();
      }
    }
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
    String? prefillCmndNo,
  }) async {
    final args = CaptureRouteArgs(
      identityType: identityType,
      intent: intent,
      prefillName: prefillName,
      prefillIdentityNo: prefillIdentityNo,
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

  }

  Future<String?> _resolvePhotoPathForReceive(IdentityVerification identity) async {
    final existing = identity.photoPath?.trim();
    if (existing != null && existing.isNotEmpty) return existing;

    final bytes = identity.photoBytes ?? manualPhotoBytes.value;
    if (bytes == null || bytes.isEmpty) return null;

    final upload = await _travelSupportRepository.uploadPhoto(
      bytes: bytes,
      fileName: 'identity_${identity.identityType.toLowerCase()}.jpg',
    );
    final path = upload?.photoPath;
    if (path != null && path.isNotEmpty) {
      manualPhotoPath.value = path;
    }
    return path;
  }

  Future<void> _autoReceive(Shareholder sh) async {
    if (isSubmitting.value) return;

    final identity = effectivePendingIdentity;
    if (identity == null || !identity.isComplete) return;

    isSubmitting.value = true;
    errorMessage.value = null;

    try {
      final photoPath = await _resolvePhotoPathForReceive(identity);
      if (photoPath == null || photoPath.isEmpty) {
        errorMessage.value =
            'Vui lòng chụp ảnh chứng cứ trước khi lưu nhận phụ cấp';
        return;
      }

      if (isProxy) {
        await _travelSupportRepository.receive(
          shareholder: sh,
          identity: IdentityVerification(
            identityNo: sh.idNumber.isNotEmpty ? sh.idNumber : 'N/A',
            identityType: 'CCCD',
            receiverName: sh.fullName,
            photoPath: photoPath,
            photoBytes: identity.photoBytes,
          ),
          attendanceType: AttendanceType.proxy,
          proxyPersonName: identity.receiverName,
          proxyIdentityNo: identity.identityNo,
          proxyIdentityType: identity.identityType,
          photoPath: photoPath,
        );
      } else {
        await _travelSupportRepository.receive(
          shareholder: sh,
          identity: IdentityVerification(
            identityNo: identity.identityNo,
            identityType: identity.identityType,
            receiverName: identity.receiverName,
            legacyIdentityNo: identity.legacyIdentityNo,
            photoPath: photoPath,
            photoBytes: identity.photoBytes,
          ),
          attendanceType: AttendanceType.direct,
          photoPath: photoPath,
        );
      }

      await _refreshDashboard();
      final refreshed = await _refreshShareholderDetail(sh.code);
      selectedShareholder.value = (refreshed ?? sh).copyWith(
        status: PaymentStatus.received,
      );
      receiveJustCompleted.value = true;
    } catch (error) {
      final apiError = ApiClient.asApiException(error);
      if (apiError?.isConflict == true) {
        final apiMessage = ApiClient.messageFrom(error);
        errorMessage.value = apiMessage.contains('đã')
            ? apiMessage
            : 'Người này đã nhận phụ cấp.';
        final refreshed = await _refreshShareholderDetail(sh.code);
        selectedShareholder.value = refreshed ?? sh;
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
    try {
      if (Get.currentRoute != shellRouteName) {
        await Get.offAllNamed(shellRouteName);
      }
    } catch (_) {
      // No navigation context (e.g. unit tests) — reset is enough.
    }
  }

  Future<void> _refreshDashboard() async {
    if (Get.isRegistered<DashboardController>()) {
      await Get.find<DashboardController>().refresh();
    }
  }
}
