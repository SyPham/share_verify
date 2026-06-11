import 'package:share_verify/core/data/dto/shareholder_dtos.dart';
import 'package:share_verify/core/data/dto/registration_no_autocomplete_dtos.dart';
import 'package:share_verify/core/network/api_client.dart';

class ShareholderRemoteSource {
  final ApiClient _client;

  ShareholderRemoteSource(this._client);

  Future<ShareholderSearchPageDto> search(
    String keyword, {
    int page = 1,
    int pageSize = 20,
  }) async {
    final response = await _client.get<Map<String, dynamic>>(
      '/api/shareholders/search',
      queryParameters: {
        'keyword': keyword,
        'page': page,
        'pageSize': pageSize,
      },
    );
    return ShareholderSearchPageDto.fromJson(response.data ?? {});
  }

  Future<RegistrationNoAutocompletePageDto> searchRegistrationNumbers(
    String keyword, {
    int page = 1,
    int pageSize = 20,
    String? identityType,
  }) async {
    final response = await _client.get<Map<String, dynamic>>(
      '/api/shareholders/registration-numbers/autocomplete',
      queryParameters: {
        'keyword': keyword,
        'page': page,
        'pageSize': pageSize,
        if (identityType != null) 'identityType': identityType,
      },
    );
    return RegistrationNoAutocompletePageDto.fromJson(response.data ?? {});
  }

  Future<ShareholderDetailDto> getDetail(String mcd) async {
    final response = await _client.get<Map<String, dynamic>>(
      '/api/shareholders/$mcd',
    );
    return ShareholderDetailDto.fromJson(response.data ?? {});
  }
}
