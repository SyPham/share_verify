import 'package:flutter/material.dart';
import 'package:share_verify/core/commons/app_spacing.dart';
import 'package:share_verify/core/commons/palette.dart';
import 'package:share_verify/core/widgets/identity_type_radio_group.dart';

class VerificationProxyForm extends StatelessWidget {
  final String proxyPersonName;
  final String proxyIdentityNo;
  final String proxyIdentityType;
  final ValueChanged<String> onProxyPersonNameChanged;
  final ValueChanged<String> onProxyIdentityNoChanged;
  final ValueChanged<String> onProxyIdentityTypeChanged;

  const VerificationProxyForm({
    super.key,
    required this.proxyPersonName,
    required this.proxyIdentityNo,
    required this.proxyIdentityType,
    required this.onProxyPersonNameChanged,
    required this.onProxyIdentityNoChanged,
    required this.onProxyIdentityTypeChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fieldDecoration = InputDecoration(
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
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Thông tin người được ủy quyền',
          style: theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: SvSpacing.sm),
        TextFormField(
          initialValue: proxyPersonName,
          onChanged: onProxyPersonNameChanged,
          decoration: fieldDecoration.copyWith(
            labelText: 'Họ và tên',
            hintText: 'Nhập họ tên người ủy quyền',
          ),
        ),
        const SizedBox(height: SvSpacing.sm),
        TextFormField(
          initialValue: proxyIdentityNo,
          onChanged: onProxyIdentityNoChanged,
          decoration: fieldDecoration.copyWith(
            labelText: 'Số giấy tờ',
            hintText: 'Nhập số CCCD / CMND / Passport',
          ),
        ),
        const SizedBox(height: SvSpacing.sm),
        IdentityTypeRadioGroup(
          value: proxyIdentityType,
          onChanged: onProxyIdentityTypeChanged,
        ),
      ],
    );
  }
}
