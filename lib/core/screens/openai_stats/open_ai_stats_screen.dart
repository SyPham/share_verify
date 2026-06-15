import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:share_verify/core/commons/app_spacing.dart';
import 'package:share_verify/core/commons/palette.dart';
import 'package:share_verify/core/controllers/open_ai_stats_controller.dart';
import 'package:share_verify/core/models/open_ai_stats.dart';
import 'package:share_verify/core/widgets/sv_card.dart';
import 'package:share_verify/core/widgets/sv_kpi_card.dart';

class OpenAiStatsScreen extends GetView<OpenAiStatsController> {
  const OpenAiStatsScreen({super.key});

  static const routeName = '/openai-stats';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: Get.back,
        ),
        title: const Text('Thống kê OpenAI'),
        centerTitle: true,
      ),
      body: Obx(() {
        if (controller.isLoading.value &&
            controller.deviceStats.value == null &&
            controller.serverStats.value == null) {
          return const Center(child: CircularProgressIndicator());
        }

        return RefreshIndicator(
          onRefresh: controller.refresh,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(
              SvSpacing.containerMargin,
              SvSpacing.lg,
              SvSpacing.containerMargin,
              SvSpacing.lg,
            ),
            children: [
              if (controller.errorMessage.value != null) ...[
                _ErrorBanner(message: controller.errorMessage.value!),
                const SizedBox(height: SvSpacing.md),
              ],
              _StatsSection(
                title: 'Thiết bị này',
                subtitle:
                    'Lưu cục bộ mỗi lần OCR CMND qua OpenAI trên máy này.',
                stats: controller.deviceStats.value,
                emptyMessage: 'Chưa có request OpenAI trên thiết bị.',
                trailing: TextButton(
                  onPressed: controller.isClearing.value
                      ? null
                      : controller.clearDeviceHistory,
                  child: controller.isClearing.value
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Xóa lịch sử'),
                ),
              ),
              const SizedBox(height: SvSpacing.md),
              _StatsSection(
                title: 'Server OCR API',
                subtitle:
                    'Tổng hợp từ metadata request đã lưu trên server '
                    '(SAVE_REQUEST_IMAGES).',
                stats: controller.serverStats.value,
                emptyMessage:
                    'Không tải được thống kê server hoặc chưa có request nào.',
              ),
              const SizedBox(height: SvSpacing.md),
              Text(
                'Gợi ý',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: SvSpacing.xs),
              Text(
                'Chi phí là ước tính theo bảng giá OpenAI. '
                'Bật OpenAI trong Cài đặt và chụp CMND để tích lũy số liệu.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  height: 1.4,
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}

class _StatsSection extends StatelessWidget {
  final String title;
  final String subtitle;
  final OpenAiStatsInfo? stats;
  final String emptyMessage;
  final Widget? trailing;

  const _StatsSection({
    required this.title,
    required this.subtitle,
    required this.stats,
    required this.emptyMessage,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final summary = stats?.summary;
    final hasData = summary != null && summary.requestCount > 0;

    return SvCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: SvSpacing.xs),
          Text(
            subtitle,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
              height: 1.35,
            ),
          ),
          const SizedBox(height: SvSpacing.md),
          if (!hasData)
            Text(
              emptyMessage,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            )
          else ...[
            GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: SvSpacing.sm,
              mainAxisSpacing: SvSpacing.sm,
              childAspectRatio: 1.45,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                SvKpiCard(
                  label: 'Số request',
                  value: summary!.requestCount.toString(),
                  backgroundColor: colorScheme.primaryContainer,
                  foregroundColor: colorScheme.onPrimaryContainer,
                  progress: 1,
                  progressColor: colorScheme.primary,
                  icon: Icons.smart_toy_outlined,
                ),
                SvKpiCard(
                  label: 'Tổng token',
                  value: summary.totalTokens.toString(),
                  backgroundColor: colorScheme.secondaryContainer,
                  foregroundColor: colorScheme.onSecondaryContainer,
                  progress: 1,
                  progressColor: colorScheme.secondary,
                  icon: Icons.data_usage,
                ),
                SvKpiCard(
                  label: 'Chi phí USD',
                  value: _shortUsd(summary.totalCostUsd),
                  backgroundColor: colorScheme.tertiaryContainer,
                  foregroundColor: colorScheme.onTertiaryContainer,
                  progress: 1,
                  progressColor: colorScheme.tertiary,
                  icon: Icons.payments_outlined,
                ),
                SvKpiCard(
                  label: 'Chi phí VND',
                  value: _shortVnd(summary.totalCostVnd),
                  backgroundColor: colorScheme.surfaceContainerHighest,
                  foregroundColor: colorScheme.onSurface,
                  progress: 1,
                  progressColor: colorScheme.outline,
                  icon: Icons.currency_exchange,
                ),
              ],
            ),
            if (stats!.byModel.isNotEmpty) ...[
              const SizedBox(height: SvSpacing.md),
              Text(
                'Theo model',
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: SvSpacing.xs),
              ...stats!.byModel.map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: SvSpacing.xs),
                  child: Text(
                    '${item.model}: ${item.requestCount} req · '
                    '${item.totalTokens} token · '
                    '${_formatCost(item.totalCostUsd, item.totalCostVnd)}',
                    style: theme.textTheme.bodySmall,
                  ),
                ),
              ),
            ],
            if (stats!.recent.isNotEmpty) ...[
              const SizedBox(height: SvSpacing.md),
              Text(
                'Gần đây',
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: SvSpacing.xs),
              ...stats!.recent.take(10).map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: SvSpacing.sm),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(SvSpacing.sm),
                    decoration: BoxDecoration(
                      color: SvPalette.surfaceContainerLow,
                      borderRadius:
                          BorderRadius.circular(SvSpacing.radiusLg),
                      border: Border.all(
                        color: SvPalette.outlineVariant.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${item.model} · ${item.costLabel}',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${item.totalTokens} token · '
                          '${_formatSavedAt(item.savedAt)}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        if ((item.idNumber ?? item.fullName) != null)
                          Text(
                            [
                              if (item.idNumber != null &&
                                  item.idNumber!.isNotEmpty)
                                item.idNumber,
                              if (item.fullName != null &&
                                  item.fullName!.isNotEmpty)
                                item.fullName,
                            ].join(' · '),
                            style: theme.textTheme.bodySmall,
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;

  const _ErrorBanner({required this.message});

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

String _shortUsd(double value) {
  if (value >= 0.01) return '\$${value.toStringAsFixed(3)}';
  return '\$${value.toStringAsFixed(6)}';
}

String _shortVnd(double value) {
  final rounded = value.round();
  final text = rounded.toString().replaceAllMapped(
        RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
        (match) => '${match[1]}.',
      );
  return '$text đ';
}

String _formatCost(double usd, double vnd) {
  return '${_shortUsd(usd)} · ${_shortVnd(vnd)}';
}

String _formatSavedAt(String? value) {
  if (value == null || value.isEmpty) return '—';
  final parsed = DateTime.tryParse(value);
  if (parsed == null) return value;
  final local = parsed.toLocal();
  final date =
      '${local.day.toString().padLeft(2, '0')}/'
      '${local.month.toString().padLeft(2, '0')}/'
      '${local.year}';
  final time =
      '${local.hour.toString().padLeft(2, '0')}:'
      '${local.minute.toString().padLeft(2, '0')}';
  return '$date $time';
}
