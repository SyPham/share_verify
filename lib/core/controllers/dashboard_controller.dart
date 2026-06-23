import 'package:get/get.dart';
import 'package:share_verify/core/models/dashboard_stats.dart';
import 'package:share_verify/core/network/api_client.dart';
import 'package:share_verify/core/repositories/dashboard_repository.dart';

class DashboardController extends GetxController {
  final DashboardRepository _dashboardRepository;

  DashboardController({DashboardRepository? dashboardRepository})
      : _dashboardRepository =
            dashboardRepository ?? Get.find<DashboardRepository>();

  final stats = const DashboardStats(
    totalShareholders: 0,
    receivedCount: 0,
    notReceivedCount: 0,
    warningCount: 0,
  ).obs;
  final isLoading = false.obs;
  final errorMessage = RxnString();

  @override
  void onInit() {
    super.onInit();
    refresh();
  }

  int get receivedCount => stats.value.receivedCount;
  int get notReceivedCount => stats.value.notReceivedCount;
  int get warningCount => stats.value.warningCount;
  int get total => stats.value.totalShareholders;
  double get completionFraction => stats.value.completionFraction;
  int get completionPercentDisplay => (completionFraction * 100).round();

  @override
  Future<void> refresh() async {
    isLoading.value = true;
    errorMessage.value = null;

    try {
      stats.value = await _dashboardRepository.getSummary();
    } catch (error) {
      errorMessage.value = ApiClient.messageFrom(error);
    } finally {
      isLoading.value = false;
    }
  }
}
