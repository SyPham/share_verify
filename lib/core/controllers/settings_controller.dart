import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:share_verify/core/data/sources/ocr_remote_source.dart';
import 'package:share_verify/core/network/api_client.dart';
import 'package:share_verify/core/services/app_config_service.dart';

class SettingsController extends GetxController {
  final AppConfigService _appConfigService;
  final ApiClient _apiClient;
  final OcrRemoteSource _ocrRemote;

  SettingsController({
    AppConfigService? appConfigService,
    ApiClient? apiClient,
    OcrRemoteSource? ocrRemote,
  })  : _appConfigService = appConfigService ?? Get.find<AppConfigService>(),
        _apiClient = apiClient ?? Get.find<ApiClient>(),
        _ocrRemote = ocrRemote ?? Get.find<OcrRemoteSource>();

  final ipController = TextEditingController();
  final isSaving = false.obs;
  final isTesting = false.obs;
  final isTestingOcr = false.obs;
  final useRemoteOcr = true.obs;
  final statusMessage = RxnString();
  final isStatusError = false.obs;
  final previewBaseUrl = ''.obs;
  final previewOcrApiUrl = ''.obs;

  @override
  void onInit() {
    super.onInit();
    ipController.text = _appConfigService.devMachineIp.value;
    useRemoteOcr.value = _appConfigService.useRemoteOcr.value;
    ipController.addListener(_onIpChanged);
    _refreshPreview();
  }

  void _onIpChanged() {
    statusMessage.value = null;
    _refreshPreview();
  }

  void _refreshPreview() {
    final ip = ipController.text.trim();
    previewBaseUrl.value = _appConfigService.resolveBaseUrl(ip);
    previewOcrApiUrl.value = _appConfigService.resolveOcrApiBaseUrl(ip);
  }

  Future<void> toggleRemoteOcr(bool enabled) async {
    useRemoteOcr.value = enabled;
    await _appConfigService.saveUseRemoteOcr(enabled);
  }

  @override
  void onClose() {
    ipController.removeListener(_onIpChanged);
    ipController.dispose();
    super.onClose();
  }

  Future<void> save() async {
    final ip = ipController.text.trim();
    if (ip.isNotEmpty && !_isValidIpv4(ip)) {
      _setStatus('Địa chỉ IP không hợp lệ', isError: true);
      return;
    }

    isSaving.value = true;
    statusMessage.value = null;

    try {
      await _appConfigService.saveDevMachineIp(ip);
      await _appConfigService.saveUseRemoteOcr(useRemoteOcr.value);
      _apiClient.updateBaseUrl(_appConfigService.baseUrl);
      _setStatus(
        ip.isEmpty
            ? 'Đã xóa IP — dùng địa chỉ mặc định theo thiết bị'
            : 'Đã lưu cấu hình máy chủ',
      );
    } catch (error) {
      _setStatus('Không thể lưu cấu hình: $error', isError: true);
    } finally {
      isSaving.value = false;
    }
  }

  Future<void> testConnection() async {
    final ip = ipController.text.trim();
    if (ip.isNotEmpty && !_isValidIpv4(ip)) {
      _setStatus('Địa chỉ IP không hợp lệ', isError: true);
      return;
    }

    isTesting.value = true;
    statusMessage.value = null;

    final testUrl = _appConfigService.resolveBaseUrl(ip);
    final previousUrl = _apiClient.baseUrl;

    try {
      _apiClient.updateBaseUrl(testUrl);
      await _apiClient.get<Map<String, dynamic>>('/api/dashboard/summary');
      _setStatus('Kết nối thành công tới $testUrl');
    } catch (error) {
      _setStatus(
        'Không kết nối được: ${ApiClient.messageFrom(error)}',
        isError: true,
      );
    } finally {
      _apiClient.updateBaseUrl(previousUrl);
      isTesting.value = false;
    }
  }

  Future<void> testOcrConnection() async {
    final ip = ipController.text.trim();
    if (ip.isNotEmpty && !_isValidIpv4(ip)) {
      _setStatus('Địa chỉ IP không hợp lệ', isError: true);
      return;
    }

    isTestingOcr.value = true;
    statusMessage.value = null;

    try {
      await _appConfigService.saveDevMachineIp(ip);
      await _ocrRemote.pingHealth();
      _setStatus(
        'Kết nối OCR API thành công tới ${_appConfigService.ocrApiBaseUrl}',
      );
    } catch (error) {
      _setStatus(
        'Không kết nối OCR API: ${ApiClient.messageFrom(error)}',
        isError: true,
      );
    } finally {
      isTestingOcr.value = false;
    }
  }

  Future<void> clearIp() async {
    ipController.text = '';
    await save();
  }

  void _setStatus(String message, {bool isError = false}) {
    statusMessage.value = message;
    isStatusError.value = isError;
  }

  bool _isValidIpv4(String ip) {
    final parts = ip.split('.');
    if (parts.length != 4) return false;

    for (final part in parts) {
      final value = int.tryParse(part);
      if (value == null || value < 0 || value > 255) return false;
    }
    return true;
  }
}
