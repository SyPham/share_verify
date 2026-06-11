import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:share_verify/core/commons/app_spacing.dart';
import 'package:share_verify/core/screens/settings/settings_screen.dart';
import 'package:share_verify/core/services/app_config_service.dart';

class SvServerConfigBanner extends StatelessWidget {
  const SvServerConfigBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final config = Get.find<AppConfigService>();

    return Obx(() {
      if (!config.needsLanIpForPhysicalDevice) {
        return const SizedBox.shrink();
      }

      final theme = Theme.of(context);
      return Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: SvSpacing.sm),
        padding: const EdgeInsets.all(SvSpacing.sm),
        decoration: BoxDecoration(
          color: theme.colorScheme.errorContainer,
          borderRadius: BorderRadius.circular(SvSpacing.radiusLg),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.wifi_off,
                  size: 20,
                  color: theme.colorScheme.onErrorContainer,
                ),
                const SizedBox(width: SvSpacing.xs),
                Expanded(
                  child: Text(
                    'Thiết bị thật cần IP máy dev trên LAN. '
                    'Hiện tại: ${config.baseUrl}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onErrorContainer,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: SvSpacing.xs),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => Get.toNamed(SettingsScreen.routeName),
                child: const Text('Cấu hình IP máy chủ'),
              ),
            ),
          ],
        ),
      );
    });
  }
}
