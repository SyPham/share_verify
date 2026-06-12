import 'package:share_verify/core/data/dto/dashboard_dtos.dart';
import 'package:share_verify/core/models/dashboard_stats.dart';

class DashboardMapper {
  static DashboardStats fromDto(DashboardSummaryDto dto) {
    final completionRatePercent = dto.completionRate > 0
        ? dto.completionRate
        : (dto.totalShareholders == 0
            ? 0.0
            : dto.receivedCount / dto.totalShareholders * 100);

    return DashboardStats(
      totalShareholders: dto.totalShareholders,
      receivedCount: dto.receivedCount,
      notReceivedCount: dto.notReceivedCount,
      completionRatePercent: completionRatePercent,
    );
  }
}
