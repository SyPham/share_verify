import 'package:flutter/material.dart';
import 'package:share_verify/core/commons/app_spacing.dart';
import 'package:share_verify/core/data/dto/travel_support_dtos.dart';
import 'package:share_verify/core/widgets/identity_usage_shareholder_section.dart';

class VerificationIdentityUsageDialog extends StatelessWidget {
  final IdentityCheckResultDto check;

  const VerificationIdentityUsageDialog({
    super.key,
    required this.check,
  });

  static Future<bool> show(
    BuildContext context, {
    required IdentityCheckResultDto check,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => VerificationIdentityUsageDialog(
        check: check,
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      icon: Icon(
        Icons.warning_amber_rounded,
        color: theme.colorScheme.error,
        size: 28,
      ),
      title: const Text('Giấy tờ đã được sử dụng'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              check.message ?? 'Người này đã nhận phụ cấp trước đó.',
              style: theme.textTheme.bodyMedium?.copyWith(height: 1.4),
            ),
            const SizedBox(height: SvSpacing.sm),
            IdentityUsageShareholderSection(check: check),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('OK'),
        ),
      ],
    );
  }
}
