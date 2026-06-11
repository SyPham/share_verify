import 'package:flutter/material.dart';
import 'package:share_verify/core/commons/app_spacing.dart';
import 'package:share_verify/core/commons/palette.dart';
import 'package:share_verify/core/widgets/sv_card.dart';
import 'package:share_verify/core/widgets/sv_primary_button.dart';

class VerificationSearchSection extends StatelessWidget {
  final TextEditingController controller;
  final bool isSearching;
  final FocusNode? focusNode;
  final ValueChanged<String> onIdNumberChanged;
  final VoidCallback onSearch;

  const VerificationSearchSection({
    super.key,
    required this.controller,
    required this.isSearching,
    this.focusNode,
    required this.onIdNumberChanged,
    required this.onSearch,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SvCard(
      padding: const EdgeInsets.all(SvSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Số giấy tờ',
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: SvSpacing.sm),
          TextFormField(
            controller: controller,
            focusNode: focusNode,
            onChanged: onIdNumberChanged,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: SvPalette.onSurface,
            ),
            decoration: InputDecoration(
              hintText: 'Nhập CCCD / CMND / Passport',
              hintStyle: theme.textTheme.bodyLarge?.copyWith(
                color: SvPalette.onSurfaceVariant,
              ),
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
                borderSide: const BorderSide(
                  color: SvPalette.primary,
                  width: 2,
                ),
              ),
            ),
          ),
          const SizedBox(height: SvSpacing.sm),
          SvPrimaryButton(
            label: isSearching ? 'Đang tìm...' : 'Xác nhận số giấy tờ',
            onPressed: isSearching ? null : onSearch,
          ),
        ],
      ),
    );
  }
}
