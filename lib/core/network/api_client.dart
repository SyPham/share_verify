import 'package:dio/dio.dart';
import 'package:share_verify/core/config/app_setting.dart';
import 'package:share_verify/core/network/api_exception.dart';

class ApiClient {
  final Dio dio;

  ApiClient({Dio? dio, String? baseUrl})
      : dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: baseUrl ?? AppSetting.defaultBaseUrl,
                connectTimeout: AppSetting.connectTimeout,
                receiveTimeout: AppSetting.receiveTimeout,
                headers: {
                  'Accept': 'application/json',
                  'Content-Type': 'application/json',
                },
              ),
            ) {
    this.dio.interceptors.add(
          InterceptorsWrapper(
            onError: (error, handler) {
              final response = error.response;
              if (response != null) {
                handler.reject(
                  DioException(
                    requestOptions: error.requestOptions,
                    response: response,
                    type: error.type,
                    error: ApiException.fromResponse(
                      statusCode: response.statusCode ?? 0,
                      data: response.data,
                    ),
                  ),
                );
                return;
              }
              handler.next(error);
            },
          ),
        );
  }

  String get baseUrl => dio.options.baseUrl;

  void updateBaseUrl(String baseUrl) {
    dio.options.baseUrl = baseUrl;
  }

  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) {
    return dio.get<T>(path, queryParameters: queryParameters);
  }

  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Options? options,
  }) {
    return dio.post<T>(path, data: data, options: options);
  }

  Future<Response<T>> postMultipart<T>(
    String path, {
    required FormData formData,
  }) {
    return dio.post<T>(
      path,
      data: formData,
      options: Options(contentType: 'multipart/form-data'),
    );
  }

  static ApiException? asApiException(Object error) {
    if (error is DioException && error.error is ApiException) {
      return error.error as ApiException;
    }
    if (error is ApiException) return error;
    return null;
  }

  static String messageFrom(Object error) {
    final apiError = asApiException(error);
    if (apiError != null) return apiError.message;
    if (error is DioException) {
      return error.message ?? 'Không thể kết nối máy chủ';
    }
    return 'Đã xảy ra lỗi không xác định';
  }
}
