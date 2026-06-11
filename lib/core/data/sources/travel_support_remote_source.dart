import 'package:share_verify/core/data/dto/travel_support_dtos.dart';
import 'package:share_verify/core/network/api_client.dart';

class TravelSupportRemoteSource {
  final ApiClient _client;

  TravelSupportRemoteSource(this._client);

  Future<List<RecentTravelSupportDto>> getRecent() async {
    final response = await _client.get<List<dynamic>>(
      '/api/travel-support/recent',
    );
    final data = response.data ?? [];
    return data
        .map(
          (item) =>
              RecentTravelSupportDto.fromJson(item as Map<String, dynamic>),
        )
        .toList();
  }

  Future<void> receive(ReceiveTravelSupportRequest request) async {
    await _client.post<void>(
      '/api/travel-support/receive',
      data: request.toJson(),
    );
  }

  Future<IdentityCheckResultDto> checkIdentity({
    required String identityNo,
    required String identityType,
    String? fullName,
    String? dateOfBirth,
  }) async {
    final response = await _client.get<Map<String, dynamic>>(
      '/api/travel-support/check-identity',
      queryParameters: {
        'identityNo': identityNo,
        'identityType': identityType,
        if (fullName != null && fullName.isNotEmpty) 'fullName': fullName,
        if (dateOfBirth != null && dateOfBirth.isNotEmpty)
          'dateOfBirth': dateOfBirth,
      },
    );
    return IdentityCheckResultDto.fromJson(
      response.data ?? const <String, dynamic>{},
    );
  }
}
