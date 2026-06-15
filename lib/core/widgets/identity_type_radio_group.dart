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
        LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final compact = width < 360;
            final stacked = width < 300;

            return DecoratedBox(
              decoration: BoxDecoration(
                color: SvPalette.surface,
                borderRadius: BorderRadius.circular(SvSpacing.radiusLg),
                border: Border.all(color: SvPalette.outline),
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: compact ? 2 : SvSpacing.xs,
                  vertical: SvSpacing.xs,
                ),
                child: Row(
                  children: [
                    for (var i = 0; i < options.length; i++) ...[
                      if (i > 0)
                        Container(
                          width: 1,
                          height: stacked ? 44 : 28,
                          color: SvPalette.outlineVariant,
                        ),
                      Expanded(
                        child: _IdentityTypeRadioOption(
                          type: options[i],
                          label: _labelFor(options[i]),
                          groupValue: selected,
                          onChanged: onChanged,
                          compact: compact,
                          stacked: stacked,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
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

class _IdentityTypeRadioOption extends StatelessWidget {
  const _IdentityTypeRadioOption({
    required this.type,
    required this.label,
    required this.groupValue,
    required this.onChanged,
    required this.compact,
    required this.stacked,
  });

  final String type;
  final String label;
  final String groupValue;
  final ValueChanged<String> onChanged;
  final bool compact;
  final bool stacked;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final labelStyle = (compact ? theme.textTheme.bodySmall : theme.textTheme.bodyMedium)
        ?.copyWith(fontWeight: FontWeight.w500);

    final radio = Radio<String>(
      value: type,
      groupValue: groupValue,
      onChanged: (v) {
        if (v != null) onChanged(v);
      },
      activeColor: SvPalette.primary,
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );

    final labelWidget = Text(
      label,
      style: labelStyle,
      textAlign: TextAlign.center,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );

    return InkWell(
      borderRadius: BorderRadius.circular(SvSpacing.radiusLg),
      onTap: () => onChanged(type),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: SvSpacing.xs),
        child: stacked
            ? Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  radio,
                  labelWidget,
                ],
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  radio,
                  Flexible(child: labelWidget),
                ],
              ),
      ),
    );
  }
}
