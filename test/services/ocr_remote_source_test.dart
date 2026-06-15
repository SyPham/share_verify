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

  test('extractIdentity uses OpenAI endpoint when configured for CMND', () async {
    final appConfig = AppConfigService();
    await appConfig.load();
    await appConfig.saveUseOpenAiOcr(true);
    await appConfig.saveOpenAiModel('gpt-4o');

    String? requestPath;
    String? modelField;
    String? preCroppedField;
    final dio = Dio();
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          requestPath = options.path;
          final data = options.data;
          if (data is FormData) {
            for (final field in data.fields) {
              if (field.key == 'model') modelField = field.value;
              if (field.key == 'pre_cropped') preCroppedField = field.value;
            }
          }
          handler.resolve(
            Response<Map<String, dynamic>>(
              requestOptions: options,
              data: {
                'success': true,
                'documentType': 'CMND',
                'idNumber': '174324001',
                'fullName': 'NGUYỄN HOÀI LINH',
                'openAiUsage': {
                  'model': 'gpt-4o',
                  'promptTokens': 850,
                  'completionTokens': 42,
                  'totalTokens': 892,
                  'costUsd': 0.000153,
                  'costVnd': 4,
                },
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

    expect(requestPath, '/api/ocr/document/openai');
    expect(modelField, 'gpt-4o');
    expect(preCroppedField, 'true');
    expect(result.identityNo, '174324001');
    expect(result.fullName, 'NGUYỄN HOÀI LINH');
    expect(result.ocrSource, 'OpenAI OCR API');
    expect(result.openAiUsage?.model, 'gpt-4o');
    expect(result.openAiUsage?.costUsd, 0.000153);
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

  test('extractIdentity uses OpenAI passport endpoint when configured', () async {
    final appConfig = AppConfigService();
    await appConfig.load();
    await appConfig.saveUseOpenAiOcr(true);

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
                'passportNumber': 'B4815163',
                'idNumber': '012977636',
                'fullName': 'NGÔ THỊ THU HÀ',
                'openAiUsage': {
                  'model': 'gpt-4o-mini',
                  'promptTokens': 900,
                  'completionTokens': 50,
                  'totalTokens': 950,
                  'costUsd': 0.0002,
                  'costVnd': 5,
                },
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

    expect(requestPath, '/api/ocr/passport/openai');
    expect(result.identityNo, 'B4815163');
    expect(result.legacyIdentityNo, '012977636');
    expect(result.fullName, 'NGÔ THỊ THU HÀ');
    expect(result.ocrSource, 'OpenAI OCR API');
    expect(result.openAiUsage?.model, 'gpt-4o-mini');
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

  test('fetchOpenAiPricing loads pricing table from API', () async {
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
                'currency': 'USD',
                'usdToVnd': 25000,
                'models': [
                  {
                    'model': 'gpt-4o-mini',
                    'inputPer1M': 0.15,
                    'outputPer1M': 0.60,
                    'description': 'Vision — rẻ',
                  },
                ],
              },
            ),
          );
        },
      ),
    );

    final source = OcrRemoteSource(appConfig: appConfig, dio: dio);
    final pricing = await source.fetchOpenAiPricing();

    expect(requestPath, '/api/ocr/openai/pricing');
    expect(pricing.usdToVnd, 25000);
    expect(pricing.models.single.model, 'gpt-4o-mini');
    expect(pricing.models.single.inputPer1M, 0.15);
  });

  test('fetchOpenAiStats loads stats from API', () async {
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
                'source': 'server',
                'summary': {
                  'requestCount': 2,
                  'totalPromptTokens': 1000,
                  'totalCompletionTokens': 80,
                  'totalTokens': 1080,
                  'totalCostUsd': 0.0003,
                  'totalCostVnd': 8,
                  'usdToVnd': 25000,
                },
                'byModel': [
                  {
                    'model': 'gpt-4o-mini',
                    'requestCount': 2,
                    'totalTokens': 1080,
                    'totalCostUsd': 0.0003,
                    'totalCostVnd': 8,
                  },
                ],
                'recent': [],
              },
            ),
          );
        },
      ),
    );

    final source = OcrRemoteSource(appConfig: appConfig, dio: dio);
    final stats = await source.fetchOpenAiStats();

    expect(requestPath, '/api/ocr/openai/stats');
    expect(stats.summary.requestCount, 2);
    expect(stats.summary.totalTokens, 1080);
    expect(stats.byModel.single.model, 'gpt-4o-mini');
  });
}
