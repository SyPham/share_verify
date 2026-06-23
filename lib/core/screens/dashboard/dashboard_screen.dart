import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:share_verify/core/commons/app_spacing.dart';
import 'package:share_verify/core/controllers/dashboard_controller.dart';
import 'package:share_verify/core/screens/settings/settings_screen.dart';
import 'package:share_verify/core/widgets/sv_app_bar.dart';
import 'package:share_verify/core/widgets/sv_kpi_card.dart';

const String _dashboardReceivedRoute = '/dashboard/received';
const String _dashboardWarningsRoute = '/dashboard/warnings';
const String _shareholdersRoute = '/shareholders';

class ShareholdersListArgs {
  final bool received;

  const ShareholdersListArgs({required this.received});
}

class DashboardScreen extends GetView<DashboardController> {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: SvAppBar.dashboard(
        onOpenSettings: () => Get.toNamed(SettingsScreen.routeName),
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        return RefreshIndicator(
          onRefresh: controller.refresh,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(
              SvSpacing.containerMargin,
              SvSpacing.lg,
              SvSpacing.containerMargin,
              SvSpacing.lg,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (controller.errorMessage.value != null) ...[
                  _DashboardErrorBanner(
                    message: controller.errorMessage.value!,
                  ),
                  const SizedBox(height: SvSpacing.md),
                ],
                GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: SvSpacing.sm,
                  mainAxisSpacing: SvSpacing.sm,
                  childAspectRatio: 1.4,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    SvKpiCard(
                      label: 'Đã nhận hỗ trợ',
                      value: controller.receivedCount.toString(),
                      backgroundColor: colorScheme.tertiaryContainer,
                      foregroundColor: colorScheme.onTertiaryContainer,
                      icon: Icons.check_circle,
                      onTap: () => Get.toNamed(_dashboardReceivedRoute),
                    ),
                    SvKpiCard(
                      label: 'Chưa nhận hỗ trợ',
                      value: controller.notReceivedCount.toString(),
                      backgroundColor: colorScheme.errorContainer,
                      foregroundColor: colorScheme.onErrorContainer,
                      icon: Icons.pending_actions,
                      onTap: () => Get.toNamed(
                        _shareholdersRoute,
                        arguments: const ShareholdersListArgs(received: false),
                      ),
                    ),
                    SvKpiCard(
                      label: 'Cảnh báo',
                      value: controller.warningCount.toString(),
                      backgroundColor: colorScheme.secondaryContainer,
                      foregroundColor: colorScheme.onSecondaryContainer,
                      icon: Icons.warning_amber_rounded,
                      onTap: () => Get.toNamed(_dashboardWarningsRoute),
                    ),
                    SvKpiCard(
                      label: 'Cổ đông đã check-in',
                      value: controller.receivedCount.toString(),
                      backgroundColor: colorScheme.primaryContainer,
                      foregroundColor: colorScheme.onPrimaryContainer,
                      icon: Icons.how_to_reg,
                      onTap: () => Get.toNamed(
                        _shareholdersRoute,
                        arguments: const ShareholdersListArgs(received: true),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      }),
    );
  }
}

class _DashboardErrorBanner extends StatelessWidget {
  final String message;

  const _DashboardErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(SvSpacing.sm),
      decoration: BoxDecoration(
        color: colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(SvSpacing.radiusLg),
      ),
      child: Text(
        message,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: colorScheme.onErrorContainer,
            ),
      ),
    );
  }
}
