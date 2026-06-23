import 'package:flutter/material.dart';
import 'package:share_verify/core/commons/app_spacing.dart';
import 'package:share_verify/core/commons/palette.dart';
import 'package:share_verify/core/data/dto/registration_no_autocomplete_dtos.dart';
import 'package:share_verify/core/data/dto/name_autocomplete_dtos.dart';
import 'package:share_verify/core/models/open_ai_usage_info.dart';
import 'package:share_verify/core/models/ocr_result.dart';
import 'package:share_verify/core/utils/identity_type_utils.dart';
import 'package:share_verify/core/widgets/name_autocomplete_field.dart';
import 'package:share_verify/core/widgets/open_ai_usage_banner.dart';
import 'package:share_verify/core/widgets/registration_no_autocomplete_field.dart';

class CaptureIdentityReviewFields extends StatelessWidget {
  final TextEditingController nameController;
  final TextEditingController identityNoController;
  final TextEditingController? cmndNoController;
  final String identityType;
  final bool isOcrProcessing;
  final double? idConfidence;
  final double? nameConfidence;
  final OpenAiUsageInfo? openAiUsage;
  final bool fromQr;
  final VoidCallback? onRerunOcr;
  final VoidCallback? onFieldEdited;
  final NameAutocompleteSearchCallback? onNameSearch;
  final RegistrationNoAutocompleteSearchCallback? onIdentityNoSearch;
  final RegistrationNoAutocompleteSearchCallback? onLegacyIdentityNoSearch;
  final RegistrationNoAutocompleteSelectedCallback? onRegistrationNoItemSelected;

  const CaptureIdentityReviewFields({
    super.key,
    required this.nameController,
    required this.identityNoController,
    this.cmndNoController,
    required this.identityType,
    this.isOcrProcessing = false,
    this.idConfidence,
    this.nameConfidence,
    this.openAiUsage,
    this.fromQr = false,
    this.onRerunOcr,
    this.onFieldEdited,
    this.onNameSearch,
    this.onIdentityNoSearch,
    this.onLegacyIdentityNoSearch,
    this.onRegistrationNoItemSelected,
  });

  bool get _showCmnd => cmndNoController != null;

  bool get _hasLowIdConfidence =>
      !fromQr &&
      idConfidence != null &&
      idConfidence! < OcrResult.lowConfidenceThreshold;

  bool get _hasLowNameConfidence =>
      !fromQr &&
      nameConfidence != null &&
      nameConfidence! < OcrResult.lowConfidenceThreshold;

  String get _helperText {
    if (fromQr) {
      return 'Kiểm tra thông tin từ QR và chụp ảnh CCCD làm minh chứng.';
    }
    return switch (identityType.toUpperCase()) {
      'CMND' =>
        'Gõ họ tên hoặc số CMND để gợi ý; nhập tay nếu OCR đọc sai (thường gặp với CMND cũ).',
      'CCCD' =>
        'Gõ họ tên, số CCCD hoặc số CMND cũ để gợi ý; nhập tay nếu OCR đọc sai.',
      _ =>
        'Gõ họ tên hoặc số giấy tờ để gợi ý; nhập tay nếu OCR đọc sai.',
    };
  }

  static const _manualEntryHint = 'Gõ để gợi ý hoặc nhập tay';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fieldDecoration = InputDecoration(
      filled: true,
      fillColor: SvPalette.surface,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: SvSpacing.sm,
        vertical: SvSpacing.sm,
      ),
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

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: SvSpacing.sm),
      padding: const EdgeInsets.all(SvSpacing.sm),
      decoration: BoxDecoration(
        color: SvPalette.surfaceContainerLow,
        borderRadius: BorderRadius.circular(SvSpacing.radiusLg),
        border: Border.all(color: SvPalette.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  fromQr ? 'Thông tin đọc từ QR CCCD' : 'Thông tin đọc từ ảnh',
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              if (isOcrProcessing)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),
          const SizedBox(height: SvSpacing.xs),
          Text(
            _helperText,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          if (openAiUsage != null) ...[
            const SizedBox(height: SvSpacing.sm),
            OpenAiUsageBanner(usage: openAiUsage!),
          ],
          if (onRerunOcr != null) ...[
            const SizedBox(height: SvSpacing.sm),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: isOcrProcessing ? null : onRerunOcr,
                icon: const Icon(Icons.document_scanner_outlined),
                label: Text(
                  isOcrProcessing ? 'Đang đọc OCR...' : 'Đọc lại OCR',
                ),
              ),
            ),
          ],
          if (_hasLowIdConfidence) ...[
            const SizedBox(height: SvSpacing.sm),
            const _LowIdConfidenceBanner(),
          ],
          if (_hasLowNameConfidence) ...[
            const SizedBox(height: SvSpacing.sm),
            const _LowNameConfidenceBanner(),
          ],
          const SizedBox(height: SvSpacing.sm),
          if (onNameSearch != null)
            NameAutocompleteField(
              controller: nameController,
              enabled: !isOcrProcessing,
              onSearch: onNameSearch!,
              onChanged: onFieldEdited,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: SvPalette.onSurface,
              ),
              decoration: fieldDecoration.copyWith(
                labelText: 'Họ và tên trên giấy tờ',
                hintText: _manualEntryHint,
                enabledBorder: _hasLowNameConfidence
                    ? OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(SvSpacing.radiusLg),
                        borderSide: const BorderSide(
                          color: SvPalette.warning,
                          width: 2,
                        ),
                      )
                    : fieldDecoration.enabledBorder,
                focusedBorder: _hasLowNameConfidence
                    ? OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(SvSpacing.radiusLg),
                        borderSide: const BorderSide(
                          color: SvPalette.warning,
                          width: 2,
                        ),
                      )
                    : fieldDecoration.focusedBorder,
              ),
            )
          else
            ListenableBuilder(
              listenable: nameController,
              builder: (context, _) {
                final hasText = nameController.text.isNotEmpty;
                return TextFormField(
                  controller: nameController,
                  enabled: !isOcrProcessing,
                  onChanged: (_) => onFieldEdited?.call(),
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: SvPalette.onSurface,
                  ),
                  decoration: fieldDecoration.copyWith(
                    labelText: 'Họ và tên trên giấy tờ',
                    suffixIcon: hasText && !isOcrProcessing
                        ? IconButton(
                            icon: Icon(
                              Icons.clear,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            onPressed: nameController.clear,
                          )
                        : null,
                  ),
                );
              },
            ),
          const SizedBox(height: SvSpacing.sm),
          if (onIdentityNoSearch != null &&
              supportsRegistrationNoAutocomplete(identityType))
            RegistrationNoAutocompleteField(
              controller: identityNoController,
              enabled: !isOcrProcessing,
              keyboardType: isNumericIdentityType(identityType)
                  ? TextInputType.number
                  : TextInputType.text,
              inputFormatters: isNumericIdentityType(identityType)
                  ? numericIdentityInputFormatters
                  : null,
              onSearch: onIdentityNoSearch!,
              onItemSelected: onRegistrationNoItemSelected,
              onChanged: onFieldEdited,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: SvPalette.onSurface,
              ),
              decoration: fieldDecoration.copyWith(
                labelText: 'Số $identityType',
                hintText: _manualEntryHint,
                enabledBorder: _hasLowIdConfidence
                    ? OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(SvSpacing.radiusLg),
                        borderSide: const BorderSide(
                          color: SvPalette.warning,
                          width: 2,
                        ),
                      )
                    : fieldDecoration.enabledBorder,
                focusedBorder: _hasLowIdConfidence
                    ? OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(SvSpacing.radiusLg),
                        borderSide: const BorderSide(
                          color: SvPalette.warning,
                          width: 2,
                        ),
                      )
                    : fieldDecoration.focusedBorder,
              ),
            )
          else
            ListenableBuilder(
              listenable: identityNoController,
              builder: (context, _) {
                final hasText = identityNoController.text.isNotEmpty;
                final lowConfidenceBorder = OutlineInputBorder(
                  borderRadius: BorderRadius.circular(SvSpacing.radiusLg),
                  borderSide:
                      const BorderSide(color: SvPalette.warning, width: 2),
                );
                return TextFormField(
                  controller: identityNoController,
                  enabled: !isOcrProcessing,
                  onChanged: (_) => onFieldEdited?.call(),
                  keyboardType: isNumericIdentityType(identityType)
                      ? TextInputType.number
                      : TextInputType.text,
                  inputFormatters: isNumericIdentityType(identityType)
                      ? numericIdentityInputFormatters
                      : null,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: SvPalette.onSurface,
                  ),
                  decoration: fieldDecoration.copyWith(
                    labelText: 'Số $identityType',
                    hintText: _manualEntryHint,
                    enabledBorder: _hasLowIdConfidence
                        ? lowConfidenceBorder
                        : fieldDecoration.enabledBorder,
                    focusedBorder: _hasLowIdConfidence
                        ? lowConfidenceBorder
                        : fieldDecoration.focusedBorder,
                    suffixIcon: hasText && !isOcrProcessing
                        ? IconButton(
                            icon: Icon(
                              Icons.clear,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            onPressed: identityNoController.clear,
                          )
                        : null,
                  ),
                );
              },
            ),
          if (_showCmnd) ...[
            const SizedBox(height: SvSpacing.sm),
            if (onLegacyIdentityNoSearch != null)
              RegistrationNoAutocompleteField(
                controller: cmndNoController!,
                enabled: !isOcrProcessing,
                keyboardType: TextInputType.number,
                inputFormatters: numericIdentityInputFormatters,
                onSearch: onLegacyIdentityNoSearch!,
                onItemSelected: onRegistrationNoItemSelected,
                onChanged: onFieldEdited,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: SvPalette.onSurface,
                ),
                decoration: fieldDecoration.copyWith(
                  labelText: legacyIdentityFieldLabel(
                    identityType,
                    fromQr: fromQr,
                  ),
                  hintText: _legacyIdentityHint,
                ),
              )
            else
              ListenableBuilder(
                listenable: cmndNoController!,
                builder: (context, _) {
                  final hasText = cmndNoController!.text.isNotEmpty;
                  return TextFormField(
                    controller: cmndNoController,
                    enabled: !isOcrProcessing,
                    onChanged: (_) => onFieldEdited?.call(),
                    keyboardType: TextInputType.number,
                    inputFormatters: numericIdentityInputFormatters,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: SvPalette.onSurface,
                    ),
                    decoration: fieldDecoration.copyWith(
                      labelText: legacyIdentityFieldLabel(
                        identityType,
                        fromQr: fromQr,
                      ),
                      hintText: _legacyIdentityHint,
                      suffixIcon: hasText && !isOcrProcessing
                          ? IconButton(
                              icon: Icon(
                                Icons.clear,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                              onPressed: cmndNoController!.clear,
                            )
                          : null,
                    ),
                  );
                },
              ),
          ],
        ],
      ),
    );
  }

  String? get _legacyIdentityHint {
    return switch (identityType.toUpperCase()) {
      'PASSPORT' => 'Hộ chiếu cũ: CMND; hộ chiếu mới: CCCD',
      'CCCD' => 'Nhập số CMND cũ (nếu có) · $_manualEntryHint',
      _ => _manualEntryHint,
    };
  }
}

class _LowNameConfidenceBanner extends StatelessWidget {
  const _LowNameConfidenceBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(SvSpacing.sm),
      decoration: BoxDecoration(
        color: SvPalette.warningContainer,
        borderRadius: BorderRadius.circular(SvSpacing.radiusLg),
        border: Border.all(color: SvPalette.warningBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            color: SvPalette.warning,
            size: 20,
          ),
          const SizedBox(width: SvSpacing.xs),
          Expanded(
            child: Text(
              'Họ tên có thể đọc sai. Gõ để chọn gợi ý hoặc nhập tay cho đúng.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: SvPalette.onWarningContainer,
                    height: 1.35,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LowIdConfidenceBanner extends StatelessWidget {
  const _LowIdConfidenceBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(SvSpacing.sm),
      decoration: BoxDecoration(
        color: SvPalette.warningContainer,
        borderRadius: BorderRadius.circular(SvSpacing.radiusLg),
        border: Border.all(color: SvPalette.warningBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            color: SvPalette.warning,
            size: 20,
          ),
          const SizedBox(width: SvSpacing.xs),
          Expanded(
            child: Text(
              'Số giấy tờ có thể đọc sai (mực mờ hoặc mất nét). '
              'Gõ để chọn gợi ý hoặc nhập tay cho đúng.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: SvPalette.onWarningContainer,
                    height: 1.35,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
