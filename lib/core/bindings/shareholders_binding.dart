import 'package:get/get.dart';
import 'package:share_verify/core/controllers/shareholder_detail_controller.dart';
import 'package:share_verify/core/controllers/shareholders_list_controller.dart';
import 'package:share_verify/core/screens/shareholders/shareholder_detail_screen.dart';
import 'package:share_verify/core/screens/shareholders/shareholders_list_screen.dart';

class ShareholdersListBinding extends Bindings {
  @override
  void dependencies() {
    final args = Get.arguments is ShareholdersListArgs
        ? Get.arguments as ShareholdersListArgs
        : null;
    Get.lazyPut<ShareholdersListController>(
      () => ShareholdersListController(received: args?.received ?? false),
    );
  }
}

class ShareholderDetailBinding extends Bindings {
  @override
  void dependencies() {
    final args = Get.arguments is ShareholderDetailArgs
        ? Get.arguments as ShareholderDetailArgs
        : null;
    Get.lazyPut<ShareholderDetailController>(
      () => ShareholderDetailController(mcd: args?.mcd ?? ''),
    );
  }
}
