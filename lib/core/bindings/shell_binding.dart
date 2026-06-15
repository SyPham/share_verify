import 'package:get/get.dart';
import 'package:share_verify/core/controllers/capture_controller.dart';
import 'package:share_verify/core/controllers/dashboard_controller.dart';
import 'package:share_verify/core/controllers/shell_controller.dart';
import 'package:share_verify/core/controllers/verification_controller.dart';
import 'package:share_verify/core/models/capture_route_args.dart';
import 'package:share_verify/core/repositories/dashboard_repository.dart';
import 'package:share_verify/core/repositories/shareholder_repository.dart';
import 'package:share_verify/core/repositories/travel_support_repository.dart';
import 'package:share_verify/core/services/barcode_scanner_service.dart';
import 'package:share_verify/core/services/app_config_service.dart';
import 'package:share_verify/core/services/ocr_service.dart';

class ShellBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ShellController>(() => ShellController());
    if (!Get.isRegistered<VerificationController>()) {
      Get.put<VerificationController>(
        VerificationController(
          shareholderRepository: Get.find<ShareholderRepository>(),
          travelSupportRepository: Get.find<TravelSupportRepository>(),
          barcodeScannerService: Get.find<BarcodeScannerService>(),
        ),
        permanent: true,
      );
    }
    Get.lazyPut<DashboardController>(
      () => DashboardController(
        dashboardRepository: Get.find<DashboardRepository>(),
      ),
    );
  }
}

class CaptureBinding extends Bindings {
  @override
  void dependencies() {
    if (Get.isRegistered<CaptureController>()) {
      Get.delete<CaptureController>(force: true);
    }

    final args =
        Get.arguments is CaptureRouteArgs ? Get.arguments as CaptureRouteArgs : null;

    Get.put<CaptureController>(
      CaptureController(
        travelSupportRepository: Get.find<TravelSupportRepository>(),
        ocrService: Get.find<OcrService>(),
        appConfig: Get.find<AppConfigService>(),
        routeArgsOverride: args,
      ),
    );
  }
}
