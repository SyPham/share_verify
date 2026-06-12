import 'package:flutter/material.dart';
import 'package:share_verify/core/commons/app_spacing.dart';
import 'package:share_verify/core/models/identity_verification.dart';
import 'package:share_verify/core/utils/identity_type_utils.dart';
import 'package:share_verify/core/widgets/sv_card.dart';
import 'package:share_verify/core/widgets/sv_result_info_row.dart';

class VerificationIdentitySummary extends StatelessWidget {
  final IdentityVerification identity;

  const VerificationIdentitySummary({
    super.key,
    required this.identity,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SvCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Giấy tờ đã xác minh',
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: SvSpacing.sm),
          SvResultInfoRow(
            icon: Icons.person_outline,
            label: 'Họ và tên',
            value: identity.receiverName,
          ),
          const SizedBox(height: SvSpacing.sm),
          SvResultInfoRow(
            icon: Icons.badge_outlined,
            label: 'Số ${identity.identityType}',
            value: identity.identityNo,
          ),
          if (identity.legacyIdentityNo != null &&
              identity.legacyIdentityNo!.isNotEmpty) ...[
            const SizedBox(height: SvSpacing.sm),
            SvResultInfoRow(
              icon: Icons.credit_card_outlined,
              label: legacyIdentityFieldLabel(identity.identityType),
              value: identity.legacyIdentityNo!,
            ),
          ],
        ],
      ),
    );
  }
}
