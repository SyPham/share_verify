import 'package:get/get.dart';
import 'package:share_verify/core/models/activity_item.dart';
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
  ).obs;
  final activities = <ActivityItem>[].obs;
  final isLoading = false.obs;
  final errorMessage = RxnString();

  @override
  void onInit() {
    super.onInit();
    refresh();
  }

  int get receivedCount => stats.value.receivedCount;
  int get notReceivedCount => stats.value.notReceivedCount;
  int get total => stats.value.totalShareholders;
  double get completionFraction => stats.value.completionPercent;
  int get completionPercentDisplay => (completionFraction * 100).round();

  List<ActivityItem> get recentActivities => activities;

  @override
  Future<void> refresh() async {
    isLoading.value = true;
    errorMessage.value = null;

    try {
      final summaryFuture = _dashboardRepository.getSummary();
      final activityFuture = _dashboardRepository.getRecentActivity();
      final results = await Future.wait([summaryFuture, activityFuture]);
      stats.value = results[0] as DashboardStats;
      activities.value = results[1] as List<ActivityItem>;
    } catch (error) {
      errorMessage.value = ApiClient.messageFrom(error);
    } finally {
      isLoading.value = false;
    }
  }
}
