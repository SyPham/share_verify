import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:share_verify/core/commons/app_spacing.dart';
import 'package:share_verify/core/commons/palette.dart';
import 'package:share_verify/core/controllers/shareholders_list_controller.dart';
import 'package:share_verify/core/screens/shareholders/components/shareholder_list_tile.dart';
import 'package:share_verify/core/screens/shareholders/shareholder_detail_screen.dart';
import 'package:share_verify/core/widgets/sv_card.dart';

class ShareholdersListArgs {
  final bool received;
  final bool embedded;
  final String? title;

  const ShareholdersListArgs({
    required this.received,
    this.embedded = false,
    this.title,
  });
}

class ShareholdersListScreen extends StatelessWidget {
  const ShareholdersListScreen({
    super.key,
    this.embedded = false,
    this.controllerTag,
    this.titleOverride,
  });

  static const routeName = '/shareholders';

  final bool embedded;
  final String? controllerTag;
  final String? titleOverride;

  ShareholdersListController get controller =>
      Get.find<ShareholdersListController>(tag: controllerTag);

  @override
  Widget build(BuildContext context) {
    final title = titleOverride ??
        (controller.received ? 'Cổ đông đã check-in' : 'Chưa nhận hỗ trợ');

    if (embedded) {
      return _ShareholdersListBody(controller: controller);
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: Get.back,
        ),
        title: Text(title),
        centerTitle: true,
      ),
      body: _ShareholdersListBody(controller: controller),
    );
  }
}

class _ShareholdersListBody extends StatelessWidget {
  const _ShareholdersListBody({required this.controller});

  final ShareholdersListController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
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
              hintText: 'Tìm theo họ tên, mã cổ đông, số giấy tờ...',
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
            horizontal: SvSpacing.containerMargin,
          ),
          child: Obx(() {
            if (controller.isLoading.value) return const SizedBox.shrink();
            return Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '${controller.totalCount.value} cổ đông',
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
                  'Không tìm thấy cổ đông',
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
                    horizontal: SvSpacing.containerMargin,
                  ),
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
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          );
                        }

                        final item = controller.items[index];
                        return ShareholderListTile(
                          item: item,
                          onTap: () => Get.toNamed(
                            ShareholderDetailScreen.routeName,
                            arguments: ShareholderDetailArgs(mcd: item.mcd),
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
    );
  }
}
