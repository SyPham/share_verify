import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:share_verify/core/commons/app_spacing.dart';
import 'package:share_verify/core/controllers/recipient_detail_controller.dart';
import 'package:share_verify/core/screens/recipients/components/recipient_detail_body.dart';

class RecipientDetailScreen extends GetView<RecipientDetailController> {
  const RecipientDetailScreen({super.key});

  static const routeName = '/recipients/detail';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: Get.back,
        ),
        title: const Text('Chi tiết người nhận'),
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
          return const Center(child: Text('Không tìm thấy thông tin'));
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            SvSpacing.containerMargin,
            SvSpacing.md,
            SvSpacing.containerMargin,
            SvSpacing.lg,
          ),
          child: RecipientDetailBody(detail: detail),
        );
      }),
    );
  }
}
