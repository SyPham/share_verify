import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:share_verify/core/commons/app_spacing.dart';
import 'package:share_verify/core/controllers/capture_controller.dart';
import 'package:share_verify/core/data/sources/ocr_remote_source.dart';
import 'package:share_verify/core/repositories/shareholder_repository.dart';
import 'package:share_verify/core/utils/identity_type_utils.dart';
import 'package:share_verify/core/screens/capture/components/capture_identity_review_fields.dart';
import 'package:share_verify/core/screens/capture/components/capture_identity_usage_warning.dart';
import 'package:share_verify/core/screens/capture/components/capture_overlay_card.dart';
import 'package:share_verify/core/widgets/capture_image_crop_view.dart';
import 'package:share_verify/core/widgets/crop_aspect_mode_bar.dart';
import 'package:share_verify/core/widgets/document_camera_preview.dart';

class CaptureEvidenceScreen extends GetView<CaptureController> {
  const CaptureEvidenceScreen({super.key});

  static const routeName = '/capture';

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final errorMessage = controller.errorMessage.value;
      final isSubmitting = controller.isSubmitting.value;
      final isOcrProcessing = controller.isOcrProcessing.value;
      final phase = controller.capturePhase.value;
      final bytes = controller.imageBytes.value;
      final rawBytes = controller.rawImageBytes.value;
      final showOcrReview =
          phase == CaptureUiPhase.review && controller.needsOcrReview;
      final confirmLabel = controller.hasIdentityUsageWarning
          ? 'Vẫn tiếp tục'
          : 'Xác Nhận';

      return Scaffold(
        resizeToAvoidBottomInset: true,
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          leading: IconButton(
            onPressed: Get.back,
            icon: const Icon(Icons.arrow_back),
          ),
          title: Text(_titleForPhase(phase, controller.identityType)),
          centerTitle: true,
        ),
        body: Column(
          children: [
            if (errorMessage != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  SvSpacing.containerMargin,
                  SvSpacing.sm,
                  SvSpacing.containerMargin,
                  0,
                ),
                child: _CaptureErrorBanner(message: errorMessage),
              ),
            Expanded(
              child: switch (phase) {
                CaptureUiPhase.camera => DocumentCameraPreview(
                    key: controller.cameraPreviewKey,
                    showDocumentFrame: controller.usesAutoCrop,
                  ),
                CaptureUiPhase.cropping when rawBytes != null =>
                  _CaptureCroppingPanel(
                    rawBytes: rawBytes,
                    controller: controller,
                  ),
                CaptureUiPhase.review when bytes != null =>
                  _ImagePreview(bytes: bytes),
                _ => const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  ),
              },
            ),
            if (showOcrReview)
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(
                    SvSpacing.containerMargin,
                    SvSpacing.sm,
                    SvSpacing.containerMargin,
                    SvSpacing.lg,
                  ),
                  child: _CaptureBottomPanel(
                    controller: controller,
                    phase: phase,
                    showOcrReview: showOcrReview,
                    isSubmitting: isSubmitting,
                    isOcrProcessing: isOcrProcessing,
                    confirmLabel: confirmLabel,
                  ),
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  SvSpacing.containerMargin,
                  SvSpacing.sm,
                  SvSpacing.containerMargin,
                  SvSpacing.lg,
                ),
                child: _CaptureBottomPanel(
                  controller: controller,
                  phase: phase,
                  showOcrReview: showOcrReview,
                  isSubmitting: isSubmitting,
                  isOcrProcessing: isOcrProcessing,
                  confirmLabel: confirmLabel,
                ),
              ),
          ],
        ),
      );
    });
  }

  String _titleForPhase(CaptureUiPhase phase, String type) {
    return switch (phase) {
      CaptureUiPhase.cropping => 'Cắt ảnh',
      _ => _titleForDocType(type),
    };
  }

  String _titleForDocType(String type) {
    return switch (type.toUpperCase()) {
      'PASSPORT' => 'Chụp Hộ Chiếu',
      'CMND' => 'Chụp CMND',
      _ => 'Chụp CCCD',
    };
  }
}

bool _showsLegacyCmndField(CaptureController controller) {
  final type = controller.identityType.toUpperCase();
  return controller.isQrPrefilled || type == 'PASSPORT' || type == 'CCCD';
}

class _CaptureBottomPanel extends StatelessWidget {
  final CaptureController controller;
  final CaptureUiPhase phase;
  final bool showOcrReview;
  final bool isSubmitting;
  final bool isOcrProcessing;
  final String confirmLabel;

  const _CaptureBottomPanel({
    required this.controller,
    required this.phase,
    required this.showOcrReview,
    required this.isSubmitting,
    required this.isOcrProcessing,
    required this.confirmLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showOcrReview)
          CaptureIdentityReviewFields(
            nameController: controller.receiverNameController,
            identityNoController: controller.identityNoController,
            dateOfBirthController: controller.dateOfBirthController,
            cmndNoController: _showsLegacyCmndField(controller)
                ? controller.cmndNoController
                : null,
            identityType: controller.identityType,
            isOcrProcessing: isOcrProcessing,
            idConfidence: controller.ocrIdConfidence.value,
            nameConfidence: controller.ocrNameConfidence.value,
            fromQr: controller.isQrPrefilled,
            onRerunOcr: controller.isQrPrefilled ? null : controller.rerunOcr,
            onFieldEdited: controller.onIdentityFieldsEdited,
            onNameSearch: (query, page) => Get.find<OcrRemoteSource>().searchNames(
                  query,
                  page: page,
                  type: 'full_name',
                ),
            onIdentityNoSearch: supportsRegistrationNoAutocomplete(
              controller.identityType,
            )
                ? (query, page) =>
                    Get.find<ShareholderRepository>().searchRegistrationNumbers(
                      query,
                      page: page,
                      identityType: registrationNoAutocompleteIdentityType(
                        controller.identityType,
                      ),
                    )
                : null,
            onLegacyIdentityNoSearch: supportsRegistrationNoAutocomplete(
              controller.identityType,
              legacy: true,
            )
                ? (query, page) =>
                    Get.find<ShareholderRepository>().searchRegistrationNumbers(
                      query,
                      page: page,
                      identityType: registrationNoAutocompleteIdentityType(
                        controller.identityType,
                        legacy: true,
                      ),
                    )
                : null,
            onRegistrationNoItemSelected: (item) {
              if (controller.receiverNameController.text.trim().isEmpty) {
                controller.receiverNameController.text = item.fullName;
              }
            },
          ),
        if (phase == CaptureUiPhase.review) const CaptureIdentityUsageWarning(),
        CaptureOverlayCard(
          shareholder: controller.shareholder,
          phase: phase,
          isSubmitting: isSubmitting || isOcrProcessing,
          onCapture: controller.pickImage,
          onRetake: controller.retake,
          onApplyCrop: controller.applyCrop,
          onConfirm: controller.confirm,
          confirmEnabled: phase == CaptureUiPhase.review && !isOcrProcessing,
          confirmLabel: confirmLabel,
          identityType: controller.identityType,
        ),
      ],
    );
  }
}

class _CaptureCroppingPanel extends StatefulWidget {
  final Uint8List rawBytes;
  final CaptureController controller;

  const _CaptureCroppingPanel({
    required this.rawBytes,
    required this.controller,
  });

  @override
  State<_CaptureCroppingPanel> createState() => _CaptureCroppingPanelState();
}

class _CaptureCroppingPanelState extends State<_CaptureCroppingPanel> {
  late final double? _initialAspectRatio;

  @override
  void initState() {
    super.initState();
    _initialAspectRatio = widget.controller.cropAspectMode.value.aspectRatio;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Obx(
          () => CropAspectModeBar(
            selected: widget.controller.cropAspectMode.value,
            onChanged: widget.controller.setCropAspectMode,
          ),
        ),
        const SizedBox(height: SvSpacing.sm),
        Expanded(
          child: CaptureImageCropView(
            key: ValueKey(widget.rawBytes.hashCode),
            imageBytes: widget.rawBytes,
            cropController: widget.controller.cropController,
            aspectRatio: _initialAspectRatio,
            onCropped: widget.controller.onCropCompleted,
            onCropError: widget.controller.onCropFailed,
          ),
        ),
      ],
    );
  }
}

class _ImagePreview extends StatelessWidget {
  final Uint8List bytes;

  const _ImagePreview({required this.bytes});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(SvSpacing.md),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(SvSpacing.radiusLg),
        child: Image.memory(bytes, fit: BoxFit.contain),
      ),
    );
  }
}

class _CaptureErrorBanner extends StatelessWidget {
  final String message;

  const _CaptureErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(SvSpacing.sm),
      decoration: BoxDecoration(
        color: colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(SvSpacing.radiusLg),
      ),
      child: Text(
        message,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: colorScheme.onErrorContainer,
            ),
      ),
    );
  }
}
