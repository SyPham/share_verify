import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:share_verify/core/commons/app_spacing.dart';
import 'package:share_verify/core/controllers/dashboard_controller.dart';
import 'package:share_verify/core/screens/dashboard/components/progress_ring_section.dart';
import 'package:share_verify/core/screens/settings/settings_screen.dart';
import 'package:share_verify/core/widgets/sv_app_bar.dart';
import 'package:share_verify/core/widgets/sv_card.dart';
import 'package:share_verify/core/screens/recipients/recipients_list_screen.dart';
import 'package:share_verify/core/utils/dashboard_format.dart';
import 'package:share_verify/core/widgets/sv_kpi_card.dart';

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

        final completionFraction = controller.completionFraction;
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
              ProgressRingSection(
                progress: DashboardFormat.completionRingValue(completionFraction),
                percentText: DashboardFormat.completionPercentLabel(
                  completionFraction,
                ),
              ),
              const SizedBox(height: SvSpacing.md),
              SvCard(
                padding: const EdgeInsets.symmetric(
                  horizontal: SvSpacing.cardPadding,
                  vertical: SvSpacing.xs,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Tổng số cổ đông', style: Theme.of(context).textTheme.titleMedium),
                    Text(
                      _formatDashboardNumber(controller.total),
                      style: Theme.of(
                        context,
                      ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: SvSpacing.md),
              GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: SvSpacing.sm,
                mainAxisSpacing: SvSpacing.sm,
                childAspectRatio: 1.55,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  SvKpiCard(
                    label: 'Đã nhận hỗ trợ',
                    value: controller.receivedCount.toString(),
                    backgroundColor: colorScheme.tertiaryContainer,
                    foregroundColor: colorScheme.onTertiaryContainer,
                    progress: controller.total == 0
                        ? 0
                        : controller.receivedCount / controller.total,
                    progressColor: colorScheme.onTertiaryContainer,
                    icon: Icons.check_circle,
                  ),
                  SvKpiCard(
                    label: 'Chưa nhận hỗ trợ',
                    value: controller.notReceivedCount.toString(),
                    backgroundColor: colorScheme.errorContainer,
                    foregroundColor: colorScheme.onErrorContainer,
                    progress: controller.total == 0
                        ? 0
                        : controller.notReceivedCount / controller.total,
                    progressColor: colorScheme.error,
                    icon: Icons.pending_actions,
                  ),
                ],
              ),
              const SizedBox(height: SvSpacing.md),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Get.toNamed(RecipientsListScreen.routeName),
                  child: const Text('Xem danh sách người nhận'),
                ),
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

String _formatDashboardNumber(int value) {
  final source = value.toString();
  final buffer = StringBuffer();
  for (int i = 0; i < source.length; i++) {
    final indexFromEnd = source.length - i;
    buffer.write(source[i]);
    if (indexFromEnd > 1 && indexFromEnd % 3 == 1) {
      buffer.write(',');
    }
  }
  return buffer.toString();
}
