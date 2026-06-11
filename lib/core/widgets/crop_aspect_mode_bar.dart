import 'package:flutter/material.dart';
import 'package:share_verify/core/commons/app_spacing.dart';
import 'package:share_verify/core/models/crop_aspect_mode.dart';

class CropAspectModeBar extends StatelessWidget {
  final CropAspectMode selected;
  final ValueChanged<CropAspectMode> onChanged;

  const CropAspectModeBar({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: SvSpacing.sm),
      child: SegmentedButton<CropAspectMode>(
        segments: CropAspectMode.values
            .map(
              (mode) => ButtonSegment(
                value: mode,
                label: Text(mode.label),
              ),
            )
            .toList(),
        selected: {selected},
        onSelectionChanged: (selection) => onChanged(selection.first),
        style: ButtonStyle(
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return Colors.white;
            }
            return theme.colorScheme.onSurface;
          }),
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return theme.colorScheme.primary;
            }
            return theme.colorScheme.surfaceContainerHighest;
          }),
        ),
      ),
    );
  }
}
