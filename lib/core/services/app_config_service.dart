import 'dart:io';

import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_verify/core/config/app_setting.dart';

class AppConfigService extends GetxService {
  static const _prefsKeyDevMachineIp = 'dev_machine_ip';
  static const _prefsKeyUseRemoteOcr = 'use_remote_ocr';

  final devMachineIp = ''.obs;
  final useRemoteOcr = true.obs;

  Future<AppConfigService> load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_prefsKeyDevMachineIp)?.trim() ?? '';
    final fromBuild = AppSetting.devMachineIpFromEnvironment.trim();

    devMachineIp.value = saved.isNotEmpty ? saved : fromBuild;
    useRemoteOcr.value = prefs.getBool(_prefsKeyUseRemoteOcr) ?? true;
    return this;
  }

  String get baseUrl => resolveBaseUrl(devMachineIp.value);

  String get ocrApiBaseUrl => resolveOcrApiBaseUrl(devMachineIp.value);

  /// `localhost` / `10.0.2.2` không hoạt động trên thiết bị thật.
  bool get needsLanIpForPhysicalDevice {
    final url = baseUrl;
    return url.contains('localhost') || url.contains('10.0.2.2');
  }

  String resolveBaseUrl(String ip) {
    const envOverride = String.fromEnvironment('API_BASE_URL');
    if (envOverride.isNotEmpty) return envOverride;

    final trimmed = ip.trim();
    if (trimmed.isNotEmpty) {
      return 'http://$trimmed:${AppSetting.apiPort}';
    }

    if (Platform.isAndroid) {
      return 'http://10.0.2.2:${AppSetting.apiPort}';
    }

    return 'http://localhost:${AppSetting.apiPort}';
  }

  String resolveOcrApiBaseUrl(String ip) {
    const envOverride = String.fromEnvironment('OCR_API_BASE_URL');
    if (envOverride.isNotEmpty) return envOverride;

    final trimmed = ip.trim();
    if (trimmed.isNotEmpty) {
      return 'http://$trimmed:${AppSetting.ocrApiPort}';
    }

    if (Platform.isAndroid) {
      return 'http://10.0.2.2:${AppSetting.ocrApiPort}';
    }

    return 'http://localhost:${AppSetting.ocrApiPort}';
  }

  Future<void> saveUseRemoteOcr(bool enabled) async {
    useRemoteOcr.value = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefsKeyUseRemoteOcr, enabled);
  }

  Future<void> saveDevMachineIp(String ip) async {
    final trimmed = ip.trim();
    devMachineIp.value = trimmed;

    final prefs = await SharedPreferences.getInstance();
    if (trimmed.isEmpty) {
      await prefs.remove(_prefsKeyDevMachineIp);
    } else {
      await prefs.setString(_prefsKeyDevMachineIp, trimmed);
    }
  }

  Future<void> clearDevMachineIp() => saveDevMachineIp('');
}
