import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:share_verify/core/commons/app_spacing.dart';
import 'package:share_verify/core/commons/palette.dart';
import 'package:share_verify/core/controllers/verification_controller.dart';
import 'package:share_verify/core/models/invitation_barcode.dart';
import 'package:share_verify/core/widgets/shareholder_picker_field.dart';
import 'package:share_verify/core/widgets/sv_card.dart';
import 'package:share_verify/core/widgets/sv_primary_button.dart';

class VerificationBarcodeSection extends GetView<VerificationController> {
  const VerificationBarcodeSection({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SvCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quét mã cổ đông',
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: SvSpacing.xs),
          Text(
            'Quét mã trên thiệp mời hoặc chọn cổ đông từ danh sách. Thông tin sẽ được lưu tự động.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: SvSpacing.sm),
          Obx(() {
            final isSearching = controller.isSearching.value;
            return SvPrimaryButton(
              label: isSearching ? 'Đang quét...' : 'Quét mã cổ đông',
              icon: Icons.qr_code_2,
              onPressed: isSearching ? null : controller.onScanInvitationBarcode,
            );
          }),
          const SizedBox(height: SvSpacing.md),
          Row(
            children: [
              Expanded(child: Divider(color: SvPalette.outlineVariant)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: SvSpacing.sm),
                child: Text(
                  'hoặc',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              Expanded(child: Divider(color: SvPalette.outlineVariant)),
            ],
          ),
          const SizedBox(height: SvSpacing.md),
          Text(
            'Nhập mã cổ đông',
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: SvSpacing.xs),
          Text(
            'Nhập trực tiếp mã MCD trên thiệp mời',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: SvSpacing.sm),
          TextField(
            controller: controller.barcodeInputController,
            textCapitalization: TextCapitalization.characters,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => controller.onManualBarcodeEntry(),
            decoration: InputDecoration(
              labelText: 'Mã cổ đông',
              hintText: 'VD: SH0001',
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
            ),
          ),
          const SizedBox(height: SvSpacing.sm),
          Obx(() {
            final isSearching = controller.isSearching.value;
            return SvPrimaryButton(
              label: isSearching ? 'Đang xử lý...' : 'Xác nhận mã cổ đông',
              icon: Icons.check,
              onPressed: isSearching ? null : controller.onManualBarcodeEntry,
            );
          }),
          const SizedBox(height: SvSpacing.md),
          Row(
            children: [
              Expanded(child: Divider(color: SvPalette.outlineVariant)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: SvSpacing.sm),
                child: Text(
                  'hoặc',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              Expanded(child: Divider(color: SvPalette.outlineVariant)),
            ],
          ),
          const SizedBox(height: SvSpacing.md),
          Text(
            'Chọn cổ đông',
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: SvSpacing.xs),
          Text(
            'Tìm theo mã MCD, họ tên, Số ĐKSH hoặc số điện thoại',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: SvSpacing.sm),
          Obx(() {
            return ShareholderPickerField(
              selected: controller.selectedPickerShareholder.value,
              isLoading: controller.isSearching.value,
              onSearch: controller.searchShareholdersForPicker,
              onSelected: controller.onShareholderPicked,
              onClear: controller.clearShareholderPicker,
            );
          }),
          Obx(() {
            final scannedBarcode = controller.scannedBarcode.value;
            if (scannedBarcode == null) return const SizedBox.shrink();
            return _ScannedBarcodeChips(barcode: scannedBarcode);
          }),
        ],
      ),
    );
  }
}

class _ScannedBarcodeChips extends StatelessWidget {
  final InvitationBarcode barcode;

  const _ScannedBarcodeChips({required this.barcode});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        const SizedBox(height: SvSpacing.sm),
        Wrap(
          spacing: SvSpacing.xs,
          runSpacing: SvSpacing.xs,
          children: [
            Chip(
              avatar: Icon(
                Icons.confirmation_number_outlined,
                size: 18,
                color: theme.colorScheme.primary,
              ),
              label: Text(
                barcode.mcd,
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              backgroundColor: SvPalette.primaryFixed,
              side: BorderSide.none,
            ),
            if (barcode.name != null && barcode.name!.isNotEmpty)
              Chip(
                avatar: Icon(
                  Icons.person_outline,
                  size: 18,
                  color: theme.colorScheme.primary,
                ),
                label: Text(barcode.name!),
                backgroundColor: SvPalette.surfaceContainerLow,
                side: BorderSide.none,
              ),
          ],
        ),
      ],
    );
  }
}
