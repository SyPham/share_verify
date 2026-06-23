import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:share_verify/core/commons/app_spacing.dart';
import 'package:share_verify/core/controllers/shareholder_detail_controller.dart';
import 'package:share_verify/core/screens/shareholders/components/shareholder_detail_body.dart';

class ShareholderDetailArgs {
  final String mcd;

  const ShareholderDetailArgs({required this.mcd});
}

class ShareholderDetailScreen extends GetView<ShareholderDetailController> {
  const ShareholderDetailScreen({super.key});

  static const routeName = '/shareholders/detail';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: Get.back,
        ),
        title: const Text('Chi tiết cổ đông'),
        centerTitle: true,
      ),
      body: Obx(() {
        if (controller.isLoading.value && controller.detail.value == null) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.errorMessage.value != null &&
            controller.detail.value == null) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(SvSpacing.containerMargin),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    controller.errorMessage.value!,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.error,
                    ),
                  ),
                  const SizedBox(height: SvSpacing.md),
                  FilledButton(
                    onPressed: controller.loadDetail,
                    child: const Text('Thử lại'),
                  ),
                ],
              ),
            ),
          );
        }

        final detail = controller.detail.value;
        if (detail == null) {
          return const Center(child: Text('Không tìm thấy thông tin cổ đông'));
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            SvSpacing.containerMargin,
            SvSpacing.md,
            SvSpacing.containerMargin,
            SvSpacing.lg,
          ),
          child: ShareholderDetailBody(detail: detail),
        );
      }),
    );
  }
}
