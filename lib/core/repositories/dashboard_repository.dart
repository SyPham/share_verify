import 'package:share_verify/core/data/mappers/activity_mapper.dart';
import 'package:share_verify/core/data/mappers/dashboard_mapper.dart';
import 'package:share_verify/core/data/sources/dashboard_remote_source.dart';
import 'package:share_verify/core/data/sources/travel_support_remote_source.dart';
import 'package:share_verify/core/models/activity_item.dart';
import 'package:share_verify/core/models/dashboard_stats.dart';

abstract class DashboardRepository {
  Future<DashboardStats> getSummary();
  Future<List<ActivityItem>> getRecentActivity();
}

class DashboardRepositoryImpl implements DashboardRepository {
  final DashboardRemoteSource _dashboardSource;
  final TravelSupportRemoteSource _travelSupportSource;

  DashboardRepositoryImpl({
    required DashboardRemoteSource dashboardSource,
    required TravelSupportRemoteSource travelSupportSource,
  })  : _dashboardSource = dashboardSource,
        _travelSupportSource = travelSupportSource;

  @override
  Future<DashboardStats> getSummary() async {
    final dto = await _dashboardSource.getSummary();
    return DashboardMapper.fromDto(dto);
  }

  @override
  Future<List<ActivityItem>> getRecentActivity() async {
    final dtos = await _travelSupportSource.getRecent();
    return dtos.map(ActivityMapper.fromDto).toList();
  }
}
