import 'package:get/get.dart';
import 'package:share_verify/core/controllers/recipients_list_controller.dart';
import 'package:share_verify/core/controllers/shareholders_list_controller.dart';

class DashboardDrilldownBinding extends Bindings {
  static const receivedShareholdersTag = 'dashboard_received_shareholders';
  static const receivedRecipientsTag = 'dashboard_received_recipients';
  static const warningRecipientsTag = 'dashboard_warning_recipients';

  @override
  void dependencies() {
    Get.lazyPut<ShareholdersListController>(
      () => ShareholdersListController(received: true),
      tag: receivedShareholdersTag,
    );
    Get.lazyPut<RecipientsListController>(
      () => RecipientsListController(groupByPerson: true),
      tag: receivedRecipientsTag,
    );
    Get.lazyPut<RecipientsListController>(
      () => RecipientsListController(groupByPerson: true, minLinkedMcd: 2),
      tag: warningRecipientsTag,
    );
  }
}
