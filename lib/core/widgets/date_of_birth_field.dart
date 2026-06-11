import 'package:flutter/material.dart';
import 'package:share_verify/core/utils/date_input_utils.dart';

class DateOfBirthField extends StatelessWidget {
  final TextEditingController controller;
  final InputDecoration decoration;
  final bool enabled;
  final VoidCallback? onChanged;
  final TextStyle? style;

  const DateOfBirthField({
    super.key,
    required this.controller,
    required this.decoration,
    this.enabled = true,
    this.onChanged,
    this.style,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final hasText = controller.text.isNotEmpty;
        return TextFormField(
          controller: controller,
          enabled: enabled,
          keyboardType: TextInputType.number,
          inputFormatters: const [DdMmYyyyInputFormatter()],
          onChanged: (_) => onChanged?.call(),
          style: style,
          decoration: decoration.copyWith(
            hintText: decoration.hintText ?? 'dd/MM/yyyy',
            suffixIcon: hasText && enabled
                ? IconButton(
                    icon: Icon(
                      Icons.clear,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    onPressed: controller.clear,
                  )
                : decoration.suffixIcon,
          ),
        );
      },
    );
  }
}
