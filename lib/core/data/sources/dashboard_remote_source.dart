import 'package:share_verify/core/data/dto/dashboard_dtos.dart';
import 'package:share_verify/core/network/api_client.dart';

class DashboardRemoteSource {
  final ApiClient _client;

  DashboardRemoteSource(this._client);

  Future<DashboardSummaryDto> getSummary() async {
    final response = await _client.get<Map<String, dynamic>>(
      '/api/dashboard/summary',
    );
    return DashboardSummaryDto.fromJson(response.data ?? {});
  }
}
