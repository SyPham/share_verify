import 'package:share_verify/core/data/mappers/dashboard_mapper.dart';
import 'package:share_verify/core/data/sources/dashboard_remote_source.dart';
import 'package:share_verify/core/models/dashboard_stats.dart';

abstract class DashboardRepository {
  Future<DashboardStats> getSummary();
}

class DashboardRepositoryImpl implements DashboardRepository {
  final DashboardRemoteSource _dashboardSource;

  DashboardRepositoryImpl({
    required DashboardRemoteSource dashboardSource,
  }) : _dashboardSource = dashboardSource;

  @override
  Future<DashboardStats> getSummary() async {
    final dto = await _dashboardSource.getSummary();
    return DashboardMapper.fromDto(dto);
  }
}
