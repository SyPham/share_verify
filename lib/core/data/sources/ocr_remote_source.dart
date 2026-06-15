import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:share_verify/core/config/app_setting.dart';
import 'package:share_verify/core/data/dto/name_autocomplete_dtos.dart';
import 'package:share_verify/core/models/open_ai_usage_info.dart';
import 'package:share_verify/core/models/ocr_result.dart';
import 'package:share_verify/core/models/open_ai_stats.dart';
import 'package:share_verify/core/services/app_config_service.dart';

class OcrRemoteException implements Exception {
  final String message;

  const OcrRemoteException(this.message);

  @override
  String toString() => message;
}

class OcrRemoteSource {
  final AppConfigService _appConfig;
  final Dio _dio;

  OcrRemoteSource({
    required AppConfigService appConfig,
    Dio? dio,
  })  : _appConfig = appConfig,
        _dio = dio ??
            Dio(
              BaseOptions(
                connectTimeout: AppSetting.connectTimeout,
                receiveTimeout: const Duration(seconds: 120),
                headers: {'Accept': 'application/json'},
              ),
            );

  Future<OcrResult> extractIdentity(
    Uint8List imageBytes, {
    required String docType,
  }) async {
    _dio.options.baseUrl = _appConfig.ocrApiBaseUrl;

    final normalizedType = docType.toUpperCase();
    final isPassport = normalizedType == 'PASSPORT';
    final isCmnd = normalizedType == 'CMND';
    final useOpenAi = _appConfig.useOpenAiOcr.value;
    final useOpenAiCmnd = isCmnd && useOpenAi;
    final useOpenAiPassport = isPassport && useOpenAi;
    final useOpenAiEndpoint = useOpenAiCmnd || useOpenAiPassport;

    final endpoint = isPassport
        ? (useOpenAiPassport
            ? '/api/ocr/passport/openai'
            : '/api/ocr/passport')
        : (useOpenAiCmnd
            ? '/api/ocr/document/openai'
            : '/api/ocr/document');

    final formData = FormData.fromMap({
      'file': MultipartFile.fromBytes(
        imageBytes,
        filename: 'document.jpg',
      ),
      if (!isPassport && !useOpenAiCmnd)
        'pre_cropped': isCmnd ? 'false' : 'true',
      if (useOpenAiCmnd) 'pre_cropped': 'true',
      if (useOpenAiEndpoint && _appConfig.openAiModel.value.trim().isNotEmpty)
        'model': _appConfig.openAiModel.value.trim(),
    });

    final response = await _dio.post<Map<String, dynamic>>(
      endpoint,
      data: formData,
      options: Options(contentType: 'multipart/form-data'),
    );

    final data = response.data;
    if (data == null) {
      throw const OcrRemoteException('OCR API không trả dữ liệu');
    }

    if (data['success'] != true) {
      final error = data['error'];
      if (error is Map) {
        final message = error['message']?.toString();
        if (message != null && message.isNotEmpty) {
          throw OcrRemoteException(message);
        }
      }
      throw const OcrRemoteException('OCR API xử lý thất bại');
    }

    return OcrResult.fromApiResponse(data, docType: docType).copyWith(
      ocrSource: useOpenAiEndpoint ? 'OpenAI OCR API' : 'OCR API',
    );
  }

  Future<void> pingHealth() async {
    _dio.options.baseUrl = _appConfig.ocrApiBaseUrl;
    await _dio.get<Map<String, dynamic>>('/health');
  }

  Future<OpenAiPricingInfo> fetchOpenAiPricing() async {
    _dio.options.baseUrl = _appConfig.ocrApiBaseUrl;
    final response = await _dio.get<Map<String, dynamic>>('/api/ocr/openai/pricing');
    final data = response.data;
    if (data == null || data['success'] != true) {
      throw const OcrRemoteException('Không tải được bảng giá OpenAI');
    }
    return OpenAiPricingInfo.fromJson(data);
  }

  Future<OpenAiStatsInfo> fetchOpenAiStats() async {
    _dio.options.baseUrl = _appConfig.ocrApiBaseUrl;
    final response = await _dio.get<Map<String, dynamic>>('/api/ocr/openai/stats');
    final data = response.data;
    if (data == null || data['success'] != true) {
      throw const OcrRemoteException('Không tải được thống kê OpenAI');
    }
    return OpenAiStatsInfo.fromJson(data);
  }

  Future<NameAutocompletePageDto> searchNames(
    String query, {
    int page = 1,
    int pageSize = 20,
    String? type,
  }) async {
    _dio.options.baseUrl = _appConfig.ocrApiBaseUrl;

    final response = await _dio.get<Map<String, dynamic>>(
      '/api/names/autocomplete',
      queryParameters: {
        'q': query.trim(),
        'page': page,
        'pageSize': pageSize,
        if (type != null) 'type': type,
      },
    );

    final data = response.data;
    if (data == null) {
      throw const OcrRemoteException('API gợi ý họ tên không trả dữ liệu');
    }

    if (data['success'] != true) {
      throw const OcrRemoteException('API gợi ý họ tên xử lý thất bại');
    }

    return NameAutocompletePageDto.fromJson(data);
  }
}
