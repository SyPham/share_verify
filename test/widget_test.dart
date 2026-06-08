import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:share_verify/main.dart';

void main() {
  testWidgets('ShareVerifyApp shows shell stub', (WidgetTester tester) async {
    await tester.pumpWidget(const ShareVerifyApp());
    await tester.pumpAndSettle();

    expect(find.text('Shell'), findsOneWidget);
    Get.reset();
  });
}
