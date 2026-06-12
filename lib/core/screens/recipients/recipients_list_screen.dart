import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:share_verify/core/commons/app_spacing.dart';
import 'package:share_verify/core/commons/palette.dart';
import 'package:share_verify/core/controllers/recipients_list_controller.dart';
import 'package:share_verify/core/screens/recipients/components/recipient_list_tile.dart';
import 'package:share_verify/core/screens/recipients/recipient_detail_screen.dart';
import 'package:share_verify/core/widgets/sv_card.dart';

class RecipientsListScreen extends GetView<RecipientsListController> {
  const RecipientsListScreen({super.key});

  static const routeName = '/recipients';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: Get.back,
        ),
        title: const Text('Người nhận hỗ trợ'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              SvSpacing.containerMargin,
              SvSpacing.sm,
              SvSpacing.containerMargin,
              SvSpacing.sm,
            ),
            child: TextField(
              onChanged: controller.onSearchChanged,
              decoration: InputDecoration(
                hintText:
                    'Tìm theo họ tên, CMND, CCCD, hộ chiếu, mã cổ đông...',
                prefixIcon: const Icon(Icons.search),
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
                  borderSide: const BorderSide(
                    color: SvPalette.primary,
                    width: 2,
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: SvSpacing.containerMargin),
            child: Obx(() {
              if (controller.isLoading.value) return const SizedBox.shrink();
              return Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '${controller.totalCount.value} người nhận',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: SvSpacing.xs),
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value && controller.items.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }

              if (controller.errorMessage.value != null &&
                  controller.items.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(SvSpacing.containerMargin),
                    child: Text(
                      controller.errorMessage.value!,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.error,
                      ),
                    ),
                  ),
                );
              }

              if (controller.items.isEmpty) {
                return Center(
                  child: Text(
                    'Không tìm thấy người nhận',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: controller.reload,
                child: NotificationListener<ScrollNotification>(
                  onNotification: (notification) {
                    if (notification.metrics.pixels >=
                            notification.metrics.maxScrollExtent - 200 &&
                        notification is ScrollUpdateNotification) {
                      controller.loadMore();
                    }
                    return false;
                  },
                  child: Container(
                    margin: const EdgeInsets.symmetric(
                        horizontal: SvSpacing.containerMargin),
                    child: SvCard(
                      padding: EdgeInsets.zero,
                      child: ListView.separated(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.symmetric(
                          vertical: SvSpacing.xs,
                        ),
                        itemCount: controller.items.length +
                            (controller.isLoadingMore.value ? 1 : 0),
                        separatorBuilder: (_, __) => Divider(
                          height: 1,
                          indent: SvSpacing.cardPadding,
                          endIndent: SvSpacing.cardPadding,
                          color: SvPalette.outlineVariant,
                        ),
                        itemBuilder: (context, index) {
                          if (index >= controller.items.length) {
                            return const Padding(
                              padding: EdgeInsets.all(SvSpacing.md),
                              child: Center(
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              ),
                            );
                          }

                          final item = controller.items[index];
                          return RecipientListTile(
                            item: item,
                            onTap: () => Get.toNamed(
                              RecipientDetailScreen.routeName,
                              arguments: item.personId,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}
