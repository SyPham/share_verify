import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:share_verify/core/commons/app_spacing.dart';
import 'package:share_verify/core/commons/palette.dart';
import 'package:share_verify/core/config/app_setting.dart';
import 'package:share_verify/core/controllers/settings_controller.dart';
import 'package:share_verify/core/widgets/sv_card.dart';
import 'package:share_verify/core/widgets/sv_primary_button.dart';
import 'package:share_verify/core/widgets/sv_server_config_banner.dart';

class SettingsScreen extends GetView<SettingsController> {
  const SettingsScreen({super.key});

  static const routeName = '/settings';

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

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: Get.back,
        ),
        title: const Text('Cấu hình máy chủ'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          SvSpacing.containerMargin,
          SvSpacing.lg,
          SvSpacing.containerMargin,
          SvSpacing.lg,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SvServerConfigBanner(),
            SvCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'IP máy dev (DEV_MACHINE_IP)',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: SvSpacing.xs),
                  Text(
                    'Trên thiết bị thật (iPad/điện thoại), bắt buộc nhập IP máy chạy backend '
                    '(cùng Wi‑Fi/LAN). Simulator/emulator có thể để trống.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: SvSpacing.md),
                  TextFormField(
                    key: const ValueKey('settings-ip'),
                    controller: controller.ipController,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: SvPalette.onSurface,
                    ),
                    cursorColor: SvPalette.primary,
                    decoration: fieldDecoration.copyWith(
                      labelText: 'Địa chỉ IP',
                      hintText: '10.10.22.21',
                      prefixIcon: Icon(
                        Icons.dns_outlined,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    keyboardType: TextInputType.text,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
                    ],
                  ),
                  const SizedBox(height: SvSpacing.sm),
                  Obx(
                    () => _UrlPreview(url: controller.previewBaseUrl.value),
                  ),
                  const SizedBox(height: SvSpacing.md),
                  Obx(
                    () => SvPrimaryButton(
                      label: controller.isSaving.value
                          ? 'Đang lưu...'
                          : 'Lưu cấu hình',
                      icon: Icons.save_outlined,
                      onPressed:
                          controller.isSaving.value ? null : controller.save,
                    ),
                  ),
                  const SizedBox(height: SvSpacing.sm),
                  Obx(
                    () => SvPrimaryButton(
                      label: controller.isTesting.value
                          ? 'Đang kiểm tra...'
                          : 'Kiểm tra kết nối',
                      icon: Icons.wifi_tethering,
                      onPressed: controller.isTesting.value
                          ? null
                          : controller.testConnection,
                      backgroundColor: theme.colorScheme.secondaryContainer,
                      foregroundColor: theme.colorScheme.onSecondaryContainer,
                    ),
                  ),
                  const SizedBox(height: SvSpacing.sm),
                  Obx(
                    () => TextButton.icon(
                      onPressed:
                          controller.isSaving.value ? null : controller.clearIp,
                      icon: const Icon(Icons.restore),
                      label: const Text('Xóa IP — dùng mặc định'),
                    ),
                  ),
                ],
              ),
            ),
            Obx(() {
              final status = controller.statusMessage.value;
              if (status == null) return const SizedBox.shrink();
              return Column(
                children: [
                  const SizedBox(height: SvSpacing.md),
                  _InfoBanner(
                    icon: controller.isStatusError.value
                        ? Icons.error_outline
                        : Icons.check_circle_outline,
                    message: status,
                    color: controller.isStatusError.value
                        ? theme.colorScheme.errorContainer
                        : theme.colorScheme.tertiaryContainer,
                    textColor: controller.isStatusError.value
                        ? theme.colorScheme.onErrorContainer
                        : theme.colorScheme.onTertiaryContainer,
                  ),
                ],
              );
            }),
            const SizedBox(height: SvSpacing.md),
            SvCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'OCR API (vietnam-ocr-api)',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: SvSpacing.xs),
                  Text(
                    'Ưu tiên gọi OCR server (PaddleOCR + AI). Nếu lỗi sẽ tự '
                    'fallback sang nhận dạng trên thiết bị.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: SvSpacing.md),
                  Obx(
                    () => SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Bật OCR API'),
                      subtitle: Text(
                        'Cổng mặc định: ${AppSetting.ocrApiPort}',
                        style: theme.textTheme.bodySmall,
                      ),
                      value: controller.useRemoteOcr.value,
                      onChanged: controller.isSaving.value
                          ? null
                          : controller.toggleRemoteOcr,
                    ),
                  ),
                  Obx(
                    () => _UrlPreview(url: controller.previewOcrApiUrl.value),
                  ),
                  const SizedBox(height: SvSpacing.md),
                  Obx(
                    () => SvPrimaryButton(
                      label: controller.isTestingOcr.value
                          ? 'Đang kiểm tra OCR...'
                          : 'Kiểm tra kết nối OCR API',
                      icon: Icons.document_scanner_outlined,
                      onPressed: controller.isTestingOcr.value
                          ? null
                          : controller.testOcrConnection,
                      backgroundColor: theme.colorScheme.secondaryContainer,
                      foregroundColor: theme.colorScheme.onSecondaryContainer,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: SvSpacing.md),
            SvCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Gợi ý',
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: SvSpacing.sm),
                  _HintRow(
                    icon: Icons.terminal,
                    text:
                        'Có thể set khi build: flutter run --dart-define=DEV_MACHINE_IP=10.10.22.21',
                  ),
                  const SizedBox(height: SvSpacing.xs),
                  _HintRow(
                    icon: Icons.settings_ethernet,
                    text:
                        'Cổng ShareVerify API: ${AppSetting.apiPort} · OCR API: ${AppSetting.ocrApiPort}',
                  ),
                  const SizedBox(height: SvSpacing.xs),
                  _HintRow(
                    icon: Icons.phone_iphone,
                    text: 'Thiết bị thật và máy dev phải cùng mạng Wi‑Fi/LAN',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UrlPreview extends StatelessWidget {
  final String url;

  const _UrlPreview({required this.url});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(SvSpacing.sm),
      decoration: BoxDecoration(
        color: SvPalette.surfaceContainerLow,
        borderRadius: BorderRadius.circular(SvSpacing.radiusLg),
        border: Border.all(color: SvPalette.outlineVariant),
      ),
      child: Row(
        children: [
          Icon(
            Icons.link,
            size: 18,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: SvSpacing.xs),
          Expanded(
            child: Text(
              url,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
                color: SvPalette.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoBanner extends StatelessWidget {
  final IconData icon;
  final String message;
  final Color color;
  final Color textColor;

  const _InfoBanner({
    required this.icon,
    required this.message,
    required this.color,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(SvSpacing.sm),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(SvSpacing.radiusLg),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: textColor),
          const SizedBox(width: SvSpacing.xs),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: textColor,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HintRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _HintRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: SvSpacing.xs),
        Expanded(
          child: Text(
            text,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}
