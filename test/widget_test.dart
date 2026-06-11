import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_verify/core/manager/init_application.dart';
import 'package:share_verify/main.dart';

void main() {
  setUp(() async {
    Get.testMode = true;
    SharedPreferences.setMockInitialValues({});
    await InitApplication().runInit();
  });

  tearDown(Get.reset);

  testWidgets('ShareVerifyApp opens verification tab', (WidgetTester tester) async {
    await tester.pumpWidget(const ShareVerifyApp());
    await tester.pumpAndSettle();

    expect(find.text('Quét Mã Thiệp Mời'), findsOneWidget);
    expect(find.text('Kiểm Tra'), findsOneWidget);
    expect(find.text('Dashboard'), findsOneWidget);
  });
}
