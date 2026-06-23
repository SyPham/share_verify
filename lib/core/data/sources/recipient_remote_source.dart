import 'package:share_verify/core/data/dto/recipient_dtos.dart';
import 'package:share_verify/core/network/api_client.dart';

class RecipientRemoteSource {
  final ApiClient _client;

  RecipientRemoteSource(this._client);

  Future<RecipientSearchPageDto> search({
    String keyword = '',
    int page = 1,
    int pageSize = 20,
    bool groupByPerson = false,
    int? minLinkedMcd,
  }) async {
    final queryParameters = <String, dynamic>{
      'keyword': keyword,
      'page': page,
      'pageSize': pageSize,
      if (groupByPerson) 'groupBy': 'person',
      if (minLinkedMcd != null) 'minLinkedMcd': minLinkedMcd,
    };

    final response = await _client.get<Map<String, dynamic>>(
      '/api/recipients',
      queryParameters: queryParameters,
    );
    return RecipientSearchPageDto.fromJson(response.data ?? {});
  }

  Future<RecipientDetailDto> getDetail(int personId) async {
    final response = await _client.get<Map<String, dynamic>>(
      '/api/recipients/$personId',
    );
    return RecipientDetailDto.fromJson(response.data ?? {});
  }
}
