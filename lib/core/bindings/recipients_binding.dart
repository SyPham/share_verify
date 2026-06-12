import 'package:get/get.dart';
import 'package:share_verify/core/controllers/recipient_detail_controller.dart';
import 'package:share_verify/core/controllers/recipients_list_controller.dart';

class RecipientsListBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<RecipientsListController>(() => RecipientsListController());
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
