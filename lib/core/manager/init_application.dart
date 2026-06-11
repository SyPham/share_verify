import 'package:get/get.dart';
import 'package:share_verify/core/data/sources/dashboard_remote_source.dart';
import 'package:share_verify/core/data/sources/ocr_remote_source.dart';
import 'package:share_verify/core/data/sources/photo_remote_source.dart';
import 'package:share_verify/core/data/sources/shareholder_remote_source.dart';
import 'package:share_verify/core/data/sources/travel_support_remote_source.dart';
import 'package:share_verify/core/network/api_client.dart';
import 'package:share_verify/core/repositories/dashboard_repository.dart';
import 'package:share_verify/core/repositories/shareholder_repository.dart';
import 'package:share_verify/core/repositories/travel_support_repository.dart';
import 'package:share_verify/core/services/app_config_service.dart';
import 'package:share_verify/core/services/barcode_scanner_service.dart';
import 'package:share_verify/core/services/ocr_service.dart';

class InitApplication {
  Future<void> runInit() async {
    await Get.putAsync<AppConfigService>(
      () async => AppConfigService().load(),
      permanent: true,
    );
    _registerDependencies();
  }

  void _registerDependencies() {
    final appConfig = Get.find<AppConfigService>();
    final apiClient = ApiClient(baseUrl: appConfig.baseUrl);
    Get.put<ApiClient>(apiClient, permanent: true);

    final shareholderRemote = ShareholderRemoteSource(apiClient);
    final dashboardRemote = DashboardRemoteSource(apiClient);
    final travelSupportRemote = TravelSupportRemoteSource(apiClient);
    final photoRemote = PhotoRemoteSource(apiClient);

    Get.put<ShareholderRepository>(
      ShareholderRepositoryImpl(remoteSource: shareholderRemote),
      permanent: true,
    );
    Get.put<DashboardRepository>(
      DashboardRepositoryImpl(
        dashboardSource: dashboardRemote,
        travelSupportSource: travelSupportRemote,
      ),
      permanent: true,
    );
    Get.put<TravelSupportRepository>(
      TravelSupportRepositoryImpl(
        remoteSource: travelSupportRemote,
        photoSource: photoRemote,
      ),
      permanent: true,
    );

    Get.put<BarcodeScannerService>(BarcodeScannerService(), permanent: true);

    final ocrRemote = OcrRemoteSource(appConfig: appConfig);
    Get.put<OcrRemoteSource>(ocrRemote, permanent: true);
    Get.put<OcrService>(
      OcrService(ocrRemote: ocrRemote, appConfig: appConfig),
      permanent: true,
    );
  }
}
