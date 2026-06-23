import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:share_verify/core/commons/app_spacing.dart';
import 'package:share_verify/core/commons/palette.dart';
import 'package:share_verify/core/controllers/verification_controller.dart';
import 'package:share_verify/core/data/sources/ocr_remote_source.dart';
import 'package:share_verify/core/repositories/shareholder_repository.dart';
import 'package:share_verify/core/utils/identity_type_utils.dart';
import 'package:share_verify/core/widgets/identity_type_radio_group.dart';
import 'package:share_verify/core/widgets/name_autocomplete_field.dart';
import 'package:share_verify/core/widgets/open_ai_usage_banner.dart';
import 'package:share_verify/core/widgets/registration_no_autocomplete_field.dart';
import 'package:share_verify/core/widgets/sv_card.dart';

class VerificationManualIdentityForm extends GetView<VerificationController> {
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
                'Kiểm tra và chỉnh sửa thông tin, sau đó tiếp tục chụp ảnh chứng cứ.',
              ManualFormPrefillSource.capture =>
                'Kiểm tra và chỉnh sửa thông tin, sau đó tiếp tục chụp ảnh chứng cứ.',
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
          Obx(() {
            final usage = controller.manualOpenAiUsage.value;
            if (usage == null) return const SizedBox.shrink();
            return Column(
              children: [
                const SizedBox(height: SvSpacing.sm),
                OpenAiUsageBanner(usage: usage),
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
            final filter = registrationNoAutocompleteIdentityType(type);
            final digitsOnly = isNumericIdentityType(type);
            return RegistrationNoAutocompleteField(
              key: const ValueKey('manual-identity-id'),
              controller: controller.manualIdController,
              keyboardType:
                  digitsOnly ? TextInputType.number : TextInputType.text,
              inputFormatters:
                  digitsOnly ? numericIdentityInputFormatters : null,
              onSearch: (query, page) =>
                  Get.find<ShareholderRepository>().searchRegistrationNumbers(
                query,
                page: page,
                identityType: filter,
              ),
              onItemSelected: (item) =>
                  controller.applyManualRegistrationLookup(item),
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
              legacyIdentityNo: controller.manualCmndController.text,
            );
            return Column(
              children: [
                const SizedBox(height: SvSpacing.sm),
                RegistrationNoAutocompleteField(
                  key: const ValueKey('manual-identity-cmnd'),
                  controller: controller.manualCmndController,
                  keyboardType: TextInputType.number,
                  inputFormatters: numericIdentityInputFormatters,
                  onSearch: (query, page) =>
                      Get.find<ShareholderRepository>().searchRegistrationNumbers(
                    query,
                    page: page,
                    identityType: filter,
                  ),
                  onItemSelected: (item) =>
                      controller.applyManualRegistrationLookup(item),
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
          Obx(
            () => IdentityTypeRadioGroup(
              value: controller.manualIdentityType.value,
              onChanged: (v) => controller.manualIdentityType.value = v,
            ),
          ),

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
}
