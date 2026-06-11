import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:share_verify/core/data/sources/shareholder_remote_source.dart';
import 'package:share_verify/core/network/api_client.dart';

void main() {
  test('searchRegistrationNumbers calls autocomplete endpoint', () async {
    Map<String, dynamic>? queryParams;
    final dio = Dio();
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          queryParams = options.queryParameters;
          handler.resolve(
            Response<Map<String, dynamic>>(
              requestOptions: options,
              data: {
                'items': [
                  {
                    'registrationNo': '079090001234',
                    'identityType': 'CCCD',
                    'mcd': 'MCD001',
                    'fullName': 'Nguyễn Văn A',
                  },
                ],
                'totalCount': 1,
                'page': 1,
                'pageSize': 10,
              },
            ),
          );
        },
      ),
    );

    final source = ShareholderRemoteSource(ApiClient(dio: dio));
    final result = await source.searchRegistrationNumbers(
      '079090',
      page: 1,
      pageSize: 10,
      identityType: 'CCCD',
    );

    expect(queryParams?['keyword'], '079090');
    expect(queryParams?['identityType'], 'CCCD');
    expect(queryParams?['page'], 1);
    expect(queryParams?['pageSize'], 10);
    expect(result.items.single.registrationNo, '079090001234');
    expect(result.items.single.identityType, 'CCCD');
  });
}
