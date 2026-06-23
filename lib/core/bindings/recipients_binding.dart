import 'package:get/get.dart';
import 'package:share_verify/core/controllers/recipient_detail_controller.dart';
import 'package:share_verify/core/controllers/recipients_list_controller.dart';
import 'package:share_verify/core/screens/recipients/recipients_list_screen.dart';

class RecipientsListBinding extends Bindings {
  @override
  void dependencies() {
    final args = Get.arguments is RecipientsListArgs
        ? Get.arguments as RecipientsListArgs
        : null;

    Get.lazyPut<RecipientsListController>(
      () => RecipientsListController(
        groupByPerson: args?.groupByPerson ?? false,
        minLinkedMcd: args?.minLinkedMcd,
      ),
    );
  }
}

class RecipientDetailBinding extends Bindings {
  @override
  void dependencies() {
    final personId = Get.arguments is int ? Get.arguments as int : 0;
    Get.lazyPut<RecipientDetailController>(
      () => RecipientDetailController(personId: personId),
    );
  }
}
