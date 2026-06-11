import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:share_verify/core/models/payment_status.dart';
import 'package:share_verify/core/widgets/sv_status_badge.dart';

void main() {
  testWidgets('shows CHƯA NHẬN for notReceived status', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: SvStatusBadge(status: PaymentStatus.notReceived)),
      ),
    );
    expect(find.text('CHƯA NHẬN'), findsOneWidget);
    expect(find.text('TRẠNG THÁI'), findsOneWidget);
  });

  testWidgets('shows ĐÃ NHẬN for received status', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: SvStatusBadge(status: PaymentStatus.received)),
      ),
    );
    expect(find.text('ĐÃ NHẬN'), findsOneWidget);
  });
}
