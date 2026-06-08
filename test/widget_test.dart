import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:share_verify/main.dart';

void main() {
  tearDown(Get.reset);

  testWidgets('ShareVerifyApp opens verification tab', (WidgetTester tester) async {
    await tester.pumpWidget(const ShareVerifyApp());
    await tester.pumpAndSettle();

    expect(find.text('Quét QR CCCD'), findsOneWidget);
    expect(find.text('Kiểm Tra'), findsOneWidget);
    expect(find.text('Dashboard'), findsOneWidget);
  });
}
