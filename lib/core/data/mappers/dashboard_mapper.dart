import 'package:share_verify/core/data/dto/dashboard_dtos.dart';
import 'package:share_verify/core/models/dashboard_stats.dart';

class DashboardMapper {
  static DashboardStats fromDto(DashboardSummaryDto dto) {
    return DashboardStats(
      totalShareholders: dto.totalShareholders,
      receivedCount: dto.receivedCount,
      notReceivedCount: dto.notReceivedCount,
    );
  }
}
