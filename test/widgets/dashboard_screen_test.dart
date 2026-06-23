import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:share_verify/core/controllers/dashboard_controller.dart';
import 'package:share_verify/core/screens/dashboard/dashboard_screen.dart';

import '../support/fake_repositories.dart';
import '../support/pump_app.dart';

void main() {
  setUp(() {
    Get.testMode = true;
    Get.put(
      DashboardController(
        dashboardRepository: FakeDashboardRepository(),
      ),
    );
  });

  tearDown(Get.reset);

  testWidgets('renders four dashboard KPI cards without legacy sections', (
    tester,
  ) async {
    await pumpApp(tester, const DashboardScreen());

    expect(find.text('Đã nhận hỗ trợ'), findsOneWidget);
    expect(find.text('Chưa nhận hỗ trợ'), findsOneWidget);
    expect(find.text('Cảnh báo'), findsOneWidget);
    expect(find.text('Cổ đông đã check-in'), findsOneWidget);

    expect(find.text('Tổng số cổ đông'), findsNothing);
    expect(find.text('Hoạt động gần đây'), findsNothing);
    expect(find.byType(LinearProgressIndicator), findsNothing);
  });
}
