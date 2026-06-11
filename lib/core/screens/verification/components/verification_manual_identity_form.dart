import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:share_verify/core/commons/app_spacing.dart';
import 'package:share_verify/core/commons/palette.dart';
import 'package:share_verify/core/controllers/verification_controller.dart';
import 'package:share_verify/core/data/dto/registration_no_autocomplete_dtos.dart';
import 'package:share_verify/core/data/sources/ocr_remote_source.dart';
import 'package:share_verify/core/repositories/shareholder_repository.dart';
import 'package:share_verify/core/utils/identity_type_utils.dart';
import 'package:share_verify/core/widgets/date_of_birth_field.dart';
import 'package:share_verify/core/widgets/evidence_photo_preview.dart';
import 'package:share_verify/core/widgets/name_autocomplete_field.dart';
import 'package:share_verify/core/widgets/registration_no_autocomplete_field.dart';
import 'package:share_verify/core/widgets/sv_card.dart';
import 'package:share_verify/core/widgets/sv_primary_button.dart';

class VerificationManualIdentityForm extends GetView<VerificationController> {
  static const identityTypes = ['CCCD', 'CMND', 'PASSPORT'];

  const VerificationManualIdentityForm({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fieldDecoration = InputDecoration(
      filled: true,
      fillColor: SvPalette.surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(SvSpacing.radiusLg),
        borderSide: const BorderSide(color: SvPalette.outline),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(SvSpacing.radiusLg),
        borderSide: const BorderSide(color: SvPalette.outline),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(SvSpacing.radiusLg),
        borderSide: const BorderSide(color: SvPalette.primary, width: 2),
      ),
    );

    return SvCard(
      padding: const EdgeInsets.all(SvSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Obx(() {
            final prefillSource = controller.manualFormPrefillSource.value;
            final identityType = controller.manualIdentityType.value;
            final title = switch (prefillSource) {
              ManualFormPrefillSource.qr => 'Thông tin từ QR CCCD',
              ManualFormPrefillSource.capture =>
                _captureFormTitle(identityType),
              null => 'Nhập tay thông tin giấy tờ',
            };
            final hint = switch (prefillSource) {
              ManualFormPrefillSource.qr =>
                'Kiểm tra và chỉnh sửa thông tin, sau đó chụp ảnh chứng cứ và quét mã cổ đông.',
              ManualFormPrefillSource.capture =>
                'Kiểm tra và chỉnh sửa thông tin, sau đó quét mã cổ đông.',
              null => null,
            };
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (hint != null) ...[
                  const SizedBox(height: SvSpacing.xs),
                  Text(
                    hint,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: SvPalette.onSurfaceVariant,
                      height: 1.35,
                    ),
                  ),
                ],
              ],
            );
          }),
          const SizedBox(height: SvSpacing.sm),
          NameAutocompleteField(
            key: const ValueKey('manual-identity-name'),
            controller: controller.manualNameController,
            onSearch: (query, page) => Get.find<OcrRemoteSource>().searchNames(
              query,
              page: page,
              type: 'full_name',
            ),
            decoration: fieldDecoration.copyWith(
              labelText: 'Họ và tên',
              hintText: 'Nhập họ tên trên giấy tờ',
            ),
          ),
          const SizedBox(height: SvSpacing.sm),
          Obx(() {
            final type = controller.manualIdentityType.value;
            final idLabel = type == 'CCCD'
                ? 'Số CCCD'
                : type == 'CMND'
                    ? 'Số CMND'
                    : 'Số Passport';
            final decoration = fieldDecoration.copyWith(
              labelText: idLabel,
              hintText: 'Nhập $idLabel',
            );
            if (supportsRegistrationNoAutocomplete(type)) {
              final filter = registrationNoAutocompleteIdentityType(type);
              return RegistrationNoAutocompleteField(
                key: const ValueKey('manual-identity-id'),
                controller: controller.manualIdController,
                onSearch: (query, page) =>
                    Get.find<ShareholderRepository>().searchRegistrationNumbers(
                  query,
                  page: page,
                  identityType: filter,
                ),
                onItemSelected: _fillNameFromRegistrationNo,
                decoration: decoration,
              );
            }
            return TextFormField(
              key: const ValueKey('manual-identity-id'),
              controller: controller.manualIdController,
              decoration: decoration,
            );
          }),
          Obx(() {
            final type = controller.manualIdentityType.value;
            if (!supportsLegacyIdentityField(type)) {
              return const SizedBox.shrink();
            }
            final label = legacyIdentityFieldLabel(type);
            final filter = registrationNoAutocompleteIdentityType(
              type,
              legacy: true,
            );
            return Column(
              children: [
                const SizedBox(height: SvSpacing.sm),
                RegistrationNoAutocompleteField(
                  key: const ValueKey('manual-identity-cmnd'),
                  controller: controller.manualCmndController,
                  onSearch: (query, page) =>
                      Get.find<ShareholderRepository>().searchRegistrationNumbers(
                    query,
                    page: page,
                    identityType: filter,
                  ),
                  onItemSelected: _fillNameFromRegistrationNo,
                  decoration: fieldDecoration.copyWith(
                    labelText: label,
                    hintText: type.toUpperCase() == 'PASSPORT'
                        ? 'Hộ chiếu cũ: CMND; hộ chiếu mới: CCCD'
                        : 'Nhập số CMND (nếu có)',
                  ),
                ),
              ],
            );
          }),
          const SizedBox(height: SvSpacing.sm),
          DateOfBirthField(
            key: const ValueKey('manual-identity-dob'),
            controller: controller.manualDateOfBirthController,
            decoration: fieldDecoration.copyWith(
              labelText: 'Ngày sinh',
            ),
          ),
          const SizedBox(height: SvSpacing.sm),
          Obx(() {
            final identityType = controller.manualIdentityType.value;
            return DropdownButtonFormField<String>(
              value: identityTypes.contains(identityType)
                  ? identityType
                  : identityTypes.first,
              decoration: fieldDecoration.copyWith(labelText: 'Loại giấy tờ'),
              items: identityTypes
                  .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                  .toList(),
              onChanged: (v) {
                if (v != null) controller.manualIdentityType.value = v;
              },
            );
          }),
          const SizedBox(height: SvSpacing.sm),
          Obx(() {
            final hasPhoto = controller.manualPhotoPath.value != null;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (hasPhoto) ...[
                  EvidencePhotoPreview(
                    photoBytes: controller.manualPhotoBytes.value,
                    photoPath: controller.manualPhotoPath.value,
                  ),
                  const SizedBox(height: SvSpacing.sm),
                ],
                SvPrimaryButton(
                  label: hasPhoto
                      ? 'Chụp lại ảnh chứng cứ'
                      : 'Chụp ảnh chứng cứ',
                  icon: Icons.camera_alt_outlined,
                  onPressed: controller.onCaptureManualPhoto,
                  backgroundColor: theme.colorScheme.secondaryContainer,
                  foregroundColor: theme.colorScheme.onSecondaryContainer,
                ),
              ],
            );
          }),
        ],
      ),
    );
  }

  static String _captureFormTitle(String identityType) {
    return switch (identityType.toUpperCase()) {
      'CMND' => 'Thông tin từ chụp CMND',
      'PASSPORT' => 'Thông tin từ chụp Hộ chiếu',
      _ => 'Thông tin từ chụp CCCD',
    };
  }

  void _fillNameFromRegistrationNo(RegistrationNoAutocompleteItemDto item) {
    if (controller.manualNameController.text.trim().isEmpty) {
      controller.manualNameController.text = item.fullName;
    }
  }
}
