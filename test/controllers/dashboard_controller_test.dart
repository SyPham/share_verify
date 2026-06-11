import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:share_verify/core/controllers/dashboard_controller.dart';
import '../fixtures/test_data.dart';
import '../support/fake_repositories.dart';

void main() {
  setUp(() => Get.testMode = true);
  tearDown(Get.reset);

  test('refresh loads dashboard stats and activities', () async {
    final controller = DashboardController(
      dashboardRepository: FakeDashboardRepository(),
    );

    await controller.refresh();

    expect(controller.stats.value.totalShareholders,
        TestData.dashboardStats.totalShareholders);
    expect(controller.recentActivities.length,
        TestData.recentActivities.length);
    expect(controller.isLoading.value, isFalse);
    expect(controller.errorMessage.value, isNull);
  });
}
