import 'package:flutter_test/flutter_test.dart';
import 'package:share_verify/core/data/dto/dashboard_dtos.dart';
import 'package:share_verify/core/data/mappers/dashboard_mapper.dart';

void main() {
  test('DashboardSummaryDto parses API summary payload', () {
    final dto = DashboardSummaryDto.fromJson({
      'totalShareholders': 9220,
      'receivedCount': 4,
      'notReceivedCount': 9216,
      'completionRate': 0.04,
      'warningCount': 12,
    });

    expect(dto.totalShareholders, 9220);
    expect(dto.receivedCount, 4);
    expect(dto.notReceivedCount, 9216);
    expect(dto.completionRate, 0.04);
    expect(dto.warningCount, 12);
  });

  test('DashboardSummaryDto parses warningCount', () {
    final dto = DashboardSummaryDto.fromJson({
      'totalShareholders': 1801,
      'receivedCount': 1234,
      'notReceivedCount': 567,
      'completionRate': 68.52,
      'warningCount': 42,
    });
    expect(dto.warningCount, 42);
  });

  test('DashboardMapper uses completionRate from API', () {
    final stats = DashboardMapper.fromDto(
      const DashboardSummaryDto(
        totalShareholders: 9220,
        receivedCount: 4,
        notReceivedCount: 9216,
        warningCount: 7,
        completionRate: 0.04,
      ),
    );

    expect(stats.completionRatePercent, 0.04);
    expect(stats.warningCount, 7);
    expect(stats.completionFraction, closeTo(0.0004, 0.000001));
  });

  test('DashboardMapper falls back when completionRate is zero', () {
    final stats = DashboardMapper.fromDto(
      const DashboardSummaryDto(
        totalShareholders: 100,
        receivedCount: 37,
        notReceivedCount: 63,
        warningCount: 5,
        completionRate: 0,
      ),
    );

    expect(stats.completionRatePercent, 37);
    expect(stats.warningCount, 5);
    expect(stats.completionFraction, 0.37);
  });
}
