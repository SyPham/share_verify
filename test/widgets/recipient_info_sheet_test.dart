import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:share_verify/core/models/payment_status.dart';
import 'package:share_verify/core/models/shareholder.dart';
import 'package:share_verify/core/models/travel_support_info.dart';
import 'package:share_verify/core/screens/verification/components/recipient_info_sheet.dart';

void main() {
  testWidgets('RecipientInfoSheet.show opens bottom sheet', (tester) async {
    final shareholder = const Shareholder(
      code: 'SH0002',
      fullName: 'Nguyễn Văn B',
      idNumber: '001234567891',
      shares: 5000,
      status: PaymentStatus.received,
    );
    final travelSupport = TravelSupportInfo(
      receiverName: 'Nguyễn Văn B',
      receiverIdentityNo: '001234567891',
      identityType: 'CCCD',
      receiveAmount: 5000000,
      receiveTime: DateTime(2026, 6, 10, 8, 30),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            return Scaffold(
              body: ElevatedButton(
                onPressed: () => RecipientInfoSheet.show(
                  context,
                  shareholder: shareholder,
                  travelSupport: travelSupport,
                ),
                child: const Text('Open'),
              ),
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(find.text('Thông tin người nhận phụ cấp'), findsOneWidget);
  });
}
