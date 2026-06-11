import 'package:dio/dio.dart';
import 'package:share_verify/core/data/dto/photo_dtos.dart';
import 'package:share_verify/core/network/api_client.dart';

class PhotoRemoteSource {
  final ApiClient _client;

  PhotoRemoteSource(this._client);

  Future<PhotoUploadResultDto> upload(List<int> bytes, String fileName) async {
    final formData = FormData.fromMap({
      'file': MultipartFile.fromBytes(bytes, filename: fileName),
    });
    final response = await _client.postMultipart<Map<String, dynamic>>(
      '/api/photos/upload',
      formData: formData,
    );
    return PhotoUploadResultDto.fromJson(response.data ?? {});
  }
}
