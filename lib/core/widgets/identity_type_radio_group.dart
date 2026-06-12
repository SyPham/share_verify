import 'package:flutter/material.dart';
import 'package:share_verify/core/commons/app_spacing.dart';
import 'package:share_verify/core/commons/palette.dart';

class IdentityTypeRadioGroup extends StatelessWidget {
  static const options = ['CCCD', 'CMND', 'PASSPORT'];

  final String value;
  final ValueChanged<String> onChanged;

  const IdentityTypeRadioGroup({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selected = options.contains(value) ? value : options.first;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Loại giấy tờ',
          style: theme.textTheme.labelLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: SvSpacing.xs),
        DecoratedBox(
          decoration: BoxDecoration(
            color: SvPalette.surface,
            borderRadius: BorderRadius.circular(SvSpacing.radiusLg),
            border: Border.all(color: SvPalette.outline),
          ),
          child: Column(
            children: [
              for (var i = 0; i < options.length; i++) ...[
                if (i > 0) Divider(height: 1, color: SvPalette.outlineVariant),
                RadioListTile<String>(
                  value: options[i],
                  groupValue: selected,
                  onChanged: (v) {
                    if (v != null) onChanged(v);
                  },
                  title: Text(
                    _labelFor(options[i]),
                    style: theme.textTheme.bodyLarge,
                  ),
                  activeColor: SvPalette.primary,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: SvSpacing.sm,
                  ),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  static String _labelFor(String type) {
    return switch (type.toUpperCase()) {
      'CMND' => 'CMND',
      'PASSPORT' => 'Hộ chiếu',
      _ => 'CCCD',
    };
  }
}
