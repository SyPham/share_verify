import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_verify/core/data/sources/ocr_remote_source.dart';
import 'package:share_verify/core/services/app_config_service.dart';

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
  });

  test('extractIdentity sends pre_cropped=false for CMND auto-crop', () async {
    final appConfig = AppConfigService();
    await appConfig.load();

    String? preCroppedField;
    final dio = Dio();
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          final data = options.data;
          if (data is FormData) {
            for (final field in data.fields) {
              if (field.key == 'pre_cropped') {
                preCroppedField = field.value;
              }
            }
          }
          handler.resolve(
            Response<Map<String, dynamic>>(
              requestOptions: options,
              data: {
                'success': true,
                'documentType': 'CMND',
                'idNumber': '480630497',
                'fullName': 'PHẠM VĂN ĐẠI',
              },
            ),
          );
        },
      ),
    );

    final source = OcrRemoteSource(appConfig: appConfig, dio: dio);
    await source.extractIdentity(
      Uint8List.fromList([1, 2, 3]),
      docType: 'CMND',
    );

    expect(preCroppedField, 'false');
  });

  test('extractIdentity sends pre_cropped=true for CCCD crop snippets', () async {
    final appConfig = AppConfigService();
    await appConfig.load();

    String? preCroppedField;
    final dio = Dio();
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          final data = options.data;
          if (data is FormData) {
            for (final field in data.fields) {
              if (field.key == 'pre_cropped') {
                preCroppedField = field.value;
              }
            }
          }
          handler.resolve(
            Response<Map<String, dynamic>>(
              requestOptions: options,
              data: {
                'success': true,
                'documentType': 'CCCD',
                'idNumber': '079090001234',
                'fullName': 'Nguyễn Văn A',
              },
            ),
          );
        },
      ),
    );

    final source = OcrRemoteSource(appConfig: appConfig, dio: dio);
    await source.extractIdentity(
      Uint8List.fromList([1, 2, 3]),
      docType: 'CCCD',
    );

    expect(preCroppedField, 'true');
  });

  test('extractIdentity maps CCCD response to OcrResult', () async {
    final appConfig = AppConfigService();
    await appConfig.load();
    await appConfig.saveDevMachineIp('192.168.1.10');

    final dio = Dio();
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          handler.resolve(
            Response<Map<String, dynamic>>(
              requestOptions: options,
              data: {
                'success': true,
                'documentType': 'CCCD',
                'idNumber': '079090001234',
                'fullName': 'Nguyễn Văn A',
              },
            ),
          );
        },
      ),
    );

    final source = OcrRemoteSource(appConfig: appConfig, dio: dio);
    final result = await source.extractIdentity(
      Uint8List.fromList([1, 2, 3]),
      docType: 'CCCD',
    );

    expect(result.identityNo, '079090001234');
    expect(result.fullName, 'Nguyễn Văn A');
  });

  test('extractIdentity uses passportNumber for PASSPORT', () async {
    final appConfig = AppConfigService();
    await appConfig.load();

    String? requestPath;
    final dio = Dio();
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          requestPath = options.path;
          handler.resolve(
            Response<Map<String, dynamic>>(
              requestOptions: options,
              data: {
                'success': true,
                'documentType': 'PASSPORT',
                'passportNumber': 'A12345678',
                'idNumber': '012977636',
                'fullName': 'Nguyen Van A',
              },
            ),
          );
        },
      ),
    );

    final source = OcrRemoteSource(appConfig: appConfig, dio: dio);
    final result = await source.extractIdentity(
      Uint8List.fromList([1, 2, 3]),
      docType: 'PASSPORT',
    );

    expect(requestPath, '/api/ocr/passport');
    expect(result.identityNo, 'A12345678');
    expect(result.legacyIdentityNo, '012977636');
    expect(result.fullName, 'Nguyen Van A');
  });

  test('extractIdentity passes through fullName from API unchanged', () async {
    final appConfig = AppConfigService();
    await appConfig.load();

    final dio = Dio();
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          handler.resolve(
            Response<Map<String, dynamic>>(
              requestOptions: options,
              data: {
                'success': true,
                'documentType': 'CMND',
                'idNumber': '174324001',
                'fullName': 'NGUYỄN HOÀI LINH',
              },
            ),
          );
        },
      ),
    );

    final source = OcrRemoteSource(appConfig: appConfig, dio: dio);
    final result = await source.extractIdentity(
      Uint8List.fromList([1, 2, 3]),
      docType: 'CMND',
    );

    expect(result.identityNo, '174324001');
    expect(result.fullName, 'NGUYỄN HOÀI LINH');
  });

  test('extractIdentity maps confidence fields from API', () async {
    final appConfig = AppConfigService();
    await appConfig.load();

    final dio = Dio();
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          handler.resolve(
            Response<Map<String, dynamic>>(
              requestOptions: options,
              data: {
                'success': true,
                'documentType': 'CMND',
                'idNumber': '285558670',
                'fullName': 'LÊ THỊ TRANG',
                'idConfidence': 0.12,
                'nameConfidence': 0.796,
              },
            ),
          );
        },
      ),
    );

    final source = OcrRemoteSource(appConfig: appConfig, dio: dio);
    final result = await source.extractIdentity(
      Uint8List.fromList([1, 2, 3]),
      docType: 'CMND',
    );

    expect(result.idConfidence, 0.12);
    expect(result.nameConfidence, 0.796);
    expect(result.hasLowIdConfidence, isTrue);
  });

  test('searchNames calls autocomplete endpoint with pagination params', () async {
    final appConfig = AppConfigService();
    await appConfig.load();
    await appConfig.saveDevMachineIp('192.168.1.10');

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
                'success': true,
                'query': 'nguyen',
                'items': [
                  {'name': 'NGUYỄN VĂN A', 'type': 'full_name'},
                ],
                'page': 2,
                'pageSize': 10,
                'total': 15,
                'totalPages': 2,
              },
            ),
          );
        },
      ),
    );

    final source = OcrRemoteSource(appConfig: appConfig, dio: dio);
    final result = await source.searchNames(
      'nguyen',
      page: 2,
      pageSize: 10,
      type: 'full_name',
    );

    expect(queryParams?['q'], 'nguyen');
    expect(queryParams?['page'], 2);
    expect(queryParams?['pageSize'], 10);
    expect(queryParams?['type'], 'full_name');
    expect(result.items.single.name, 'NGUYỄN VĂN A');
    expect(result.page, 2);
    expect(result.hasMore, isFalse);
  });
}
