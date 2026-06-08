import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:share_verify/core/commons/app_spacing.dart';
import 'package:share_verify/core/controllers/dashboard_controller.dart';
import 'package:share_verify/core/screens/dashboard/components/progress_ring_section.dart';
import 'package:share_verify/core/screens/dashboard/components/recent_activity_list.dart';
import 'package:share_verify/core/widgets/sv_app_bar.dart';
import 'package:share_verify/core/widgets/sv_kpi_card.dart';

class DashboardScreen extends GetView<DashboardController> {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: const SvAppBar.dashboard(),
      body: Obx(() {
        final completionPercent = (controller.completionFraction * 100).floor();
        final completionValue = completionPercent / 100;
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            SvSpacing.containerMargin,
            SvSpacing.lg,
            SvSpacing.containerMargin,
            SvSpacing.lg,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ProgressRingSection(
                progress: completionValue,
                percentText: '$completionPercent%',
              ),
              const SizedBox(height: SvSpacing.md),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: SvSpacing.md,
                  vertical: SvSpacing.sm,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(SvSpacing.radiusXl),
                  border: Border.all(color: colorScheme.outlineVariant),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Tổng số cổ đông', style: Theme.of(context).textTheme.titleMedium),
                    Text(
                      _formatNumber(controller.total),
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Hoạt động gần đây', style: Theme.of(context).textTheme.titleLarge),
                  TextButton(onPressed: () {}, child: const Text('Xem tất cả')),
                ],
              ),
              const SizedBox(height: SvSpacing.sm),
              RecentActivityList(activities: controller.recentActivities),
            ],
          ),
        );
      }),
    );
  }

  String _formatNumber(int value) {
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
}
