import 'package:get/get.dart';
import 'package:share_verify/core/mock/mock_data.dart';
import 'package:share_verify/core/models/activity_item.dart';
import 'package:share_verify/core/models/dashboard_stats.dart';

class DashboardController extends GetxController {
  final stats = MockData.dashboardStats.obs;
  final activities = MockData.recentActivities.obs;

  int get receivedCount => stats.value.receivedCount;
  int get notReceivedCount => stats.value.notReceivedCount;
  int get total => stats.value.totalShareholders;
  double get completionFraction => stats.value.completionPercent;
  int get completionPercentDisplay => (completionFraction * 100).round();

  List<ActivityItem> get recentActivities => activities;
}
