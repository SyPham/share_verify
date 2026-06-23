import 'package:share_verify/core/models/dashboard_stats.dart';
import 'package:share_verify/core/models/payment_status.dart';
import 'package:share_verify/core/models/shareholder.dart';
import 'package:share_verify/core/models/travel_support_info.dart';

class TestData {
  static final shareholders = <Shareholder>[
    const Shareholder(
      code: 'SH0001',
      fullName: 'Nguyễn Văn A',
      idNumber: '001234567890',
      shares: 10000,
      status: PaymentStatus.notReceived,
    ),
    Shareholder(
      code: 'SH0002',
      fullName: 'Nguyễn Văn B',
      idNumber: '001234567891',
      shares: 5000,
      status: PaymentStatus.received,
      travelSupport: TravelSupportInfo(
        receiverName: 'Nguyễn Văn B',
        receiverIdentityNo: '001234567891',
        identityType: 'CCCD',
        receiveAmount: 5000000,
        receiveTime: DateTime(2026, 6, 10, 8, 40),
        photoPath: 'uploads/sh0002.jpg',
      ),
    ),
    Shareholder(
      code: 'SH0003',
      fullName: 'Trần Thị C',
      idNumber: '001234567892',
      shares: 8000,
      status: PaymentStatus.received,
      travelSupport: TravelSupportInfo(
        receiverName: 'Trần Thị C',
        receiverIdentityNo: '001234567892',
        identityType: 'CCCD',
        receiveAmount: 8000000,
        receiveTime: DateTime(2026, 6, 10, 8, 35),
      ),
    ),
  ];

  static const dashboardStats = DashboardStats(
    totalShareholders: 1200,
    receivedCount: 450,
    notReceivedCount: 750,
    warningCount: 27,
  );

  static Shareholder? findByIdNumber(String idNumber) {
    final normalized = idNumber.trim();
    if (normalized.isEmpty) return null;
    for (final s in shareholders) {
      if (s.idNumber == normalized) return s;
    }
    return null;
  }

  static Shareholder? findByMcd(String mcd) {
    final normalized = switch (mcd) {
      'MCD001' => 'SH0001',
      _ => mcd,
    };
    try {
      return shareholders.firstWhere((s) => s.code == normalized);
    } catch (_) {
      return null;
    }
  }

  static const sampleCccdOcrText =
      'CĂN CƯỚC CÔNG DÂN\nNguyễn Văn A\nSố: 001234567890';
}
