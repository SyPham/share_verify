import 'package:flutter/material.dart';
import 'package:share_verify/core/commons/app_spacing.dart';
import 'package:share_verify/core/widgets/sv_primary_button.dart';

class VerificationSearchSection extends StatelessWidget {
  final String idNumber;
  final bool isSearching;
  final ValueChanged<String> onIdNumberChanged;
  final VoidCallback onSearch;

  const VerificationSearchSection({
    super.key,
    required this.idNumber,
    required this.isSearching,
    required this.onIdNumberChanged,
    required this.onSearch,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(SvSpacing.radiusXl),
      ),
      child: Padding(
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
              key: ValueKey(idNumber),
              initialValue: idNumber,
              onChanged: onIdNumberChanged,
              decoration: InputDecoration(
                hintText: 'Nhập CCCD / CMND / Passport',
                filled: true,
                fillColor: theme.colorScheme.surfaceContainerLow,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(SvSpacing.radiusXl),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(SvSpacing.radiusXl),
                  borderSide:
                      BorderSide(color: theme.colorScheme.outlineVariant),
                ),
              ),
            ),
            const SizedBox(height: SvSpacing.sm),
            SvPrimaryButton(
              label: 'Tìm Kiếm',
              onPressed: isSearching ? null : onSearch,
            ),
          ],
        ),
      ),
    );
  }
}
