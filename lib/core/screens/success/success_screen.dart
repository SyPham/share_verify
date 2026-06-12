import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:share_verify/core/commons/app_spacing.dart';
import 'package:share_verify/core/controllers/verification_controller.dart';
import 'package:share_verify/core/models/shareholder.dart';
import 'package:share_verify/core/commons/palette.dart';
import 'package:share_verify/core/widgets/sv_card.dart';
import 'package:share_verify/core/widgets/sv_outlined_button.dart';
import 'package:share_verify/core/widgets/sv_primary_button.dart';

class SuccessScreen extends StatelessWidget {
  const SuccessScreen({super.key});

  static const routeName = '/success';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final argument = Get.arguments;
    final shareholder = argument is Shareholder ? argument : null;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            SvSpacing.containerMargin,
            SvSpacing.lg,
            SvSpacing.containerMargin,
            SvSpacing.lg,
          ),
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 44,
                        backgroundColor: theme.colorScheme.tertiaryContainer,
                        child: Icon(
                          Icons.check_rounded,
                          size: 48,
                          color: theme.colorScheme.onTertiaryContainer,
                        ),
                      ),
                      const SizedBox(height: SvSpacing.md),
                      Text(
                        'ĐÃ GHI NHẬN HỖ TRỢ THÀNH CÔNG',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: SvSpacing.sm),
                      Text(
                        'Thông tin trợ cấp đã được cập nhật vào hệ thống quản lý cổ đông.',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: SvSpacing.lg),
                      SvCard(
                        child: Column(
                          children: [
                            _DetailRow(
                              label: 'Mã cổ đông',
                              value: shareholder?.code ?? '--',
                            ),
                            Divider(color: SvPalette.outlineVariant, height: 24),
                            _DetailRow(
                              label: 'Họ tên',
                              value: shareholder?.fullName ?? '--',
                            ),
                            Divider(color: SvPalette.outlineVariant, height: 24),
                            const _DetailRow(
                              label: 'Thời gian',
                              value: '08:45, 25/05/2024',
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: SvSpacing.md),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: SvSpacing.sm,
                          vertical: SvSpacing.xs,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.tertiaryContainer,
                          borderRadius: BorderRadius.circular(SvSpacing.radiusLg),
                        ),
                        child: Text(
                          'Hoàn tất xác minh',
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: theme.colorScheme.onTertiaryContainer,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SvPrimaryButton(
                label: 'Xử lý người tiếp theo',
                icon: Icons.restart_alt,
                onPressed: () async {
                  if (Get.isRegistered<VerificationController>()) {
                    await Get.find<VerificationController>().processNextPerson();
                  } else {
                    await Get.offAllNamed('/shell');
                  }
                },
              ),
              const SizedBox(height: SvSpacing.sm),
              SvOutlinedButton(
                label: 'Về Trang Chủ',
                onPressed: () async {
                  if (Get.isRegistered<VerificationController>()) {
                    Get.find<VerificationController>().resetSelection();
                  }
                  await Get.offAllNamed('/shell');
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        const SizedBox(width: SvSpacing.sm),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}
