import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:share_verify/core/models/recipient_check_in.dart';
import 'package:share_verify/core/models/recipient_detail.dart';
import 'package:share_verify/core/models/travel_support_info.dart';
import 'package:share_verify/core/screens/recipients/components/recipient_detail_body.dart';

void main() {
  testWidgets('renders multiple recipient check-in blocks', (tester) async {
    final detail = RecipientDetail(
      personId: 42,
      personFullName: 'Nguyen Van A',
      identityNo: '001234567890',
      identityType: 'CCCD',
      checkIns: [
        RecipientCheckIn(
          mcd: 'MCD001',
          shareholderFullName: 'Nguyen Van A',
          totalShares: 1000,
          travelSupport: TravelSupportInfo(
            receiverName: 'Nguyen Van A',
            receiverIdentityNo: '001234567890',
            identityType: 'CCCD',
            attendanceType: 'Direct',
            receiveAmount: 500000,
            receiveTime: DateTime.parse('2026-06-20T08:30:00Z'),
            photoPath: '/uploads/a.jpg',
            operatorName: 'NV01',
          ),
        ),
        RecipientCheckIn(
          mcd: 'MCD002',
          shareholderFullName: 'Nguyen Van A',
          totalShares: 1500,
          travelSupport: TravelSupportInfo(
            receiverName: 'Nguyen Van A',
            attendanceType: 'Proxy',
            proxyPersonName: 'Tran Thi B',
            proxyIdentityNo: '123456789',
            proxyIdentityType: 'CMND',
            receiveAmount: 750000,
            receiveTime: DateTime.parse('2026-06-19T08:30:00Z'),
            photoPath: '/uploads/b.jpg',
          ),
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: RecipientDetailBody(detail: detail),
          ),
        ),
      ),
    );

    expect(find.text('Nguyen Van A'), findsWidgets);
    expect(find.text('Lượt check-in #1'), findsOneWidget);
    expect(find.text('Lượt check-in #2'), findsOneWidget);
    expect(find.text('MCD001'), findsOneWidget);
    expect(find.text('MCD002'), findsOneWidget);
    expect(find.text('500,000 ₫'), findsOneWidget);
    expect(find.text('750,000 ₫'), findsOneWidget);
    expect(find.text('Người nhận trực tiếp'), findsOneWidget);
    expect(find.text('Người ủy quyền nhận'), findsOneWidget);
  });
}
