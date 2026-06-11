import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_verify/core/services/app_config_service.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('resolveBaseUrl uses custom IP when provided', () {
    final service = AppConfigService();

    expect(
      service.resolveBaseUrl('10.10.22.21'),
      'http://10.10.22.21:5054',
    );
  });

  test('resolveOcrApiBaseUrl uses OCR port 8000', () {
    final service = AppConfigService();

    expect(
      service.resolveOcrApiBaseUrl('10.10.22.21'),
      'http://10.10.22.21:8000',
    );
  });

  test('saveUseRemoteOcr persists toggle', () async {
    final service = AppConfigService();
    await service.load();

    await service.saveUseRemoteOcr(false);
    expect(service.useRemoteOcr.value, isFalse);

    final reloaded = AppConfigService();
    await reloaded.load();
    expect(reloaded.useRemoteOcr.value, isFalse);
  });

  test('saveDevMachineIp persists value', () async {
    final service = AppConfigService();
    await service.load();

    await service.saveDevMachineIp('192.168.1.50');

    expect(service.devMachineIp.value, '192.168.1.50');
    expect(service.baseUrl, 'http://192.168.1.50:5054');

    final reloaded = AppConfigService();
    await reloaded.load();
    expect(reloaded.devMachineIp.value, '192.168.1.50');
  });

  test('needsLanIpForPhysicalDevice when using localhost fallback', () async {
    final service = AppConfigService();
    await service.load();

    expect(service.needsLanIpForPhysicalDevice, isTrue);
    expect(service.baseUrl, contains('localhost'));
  });

  test('needsLanIpForPhysicalDevice is false when LAN IP configured', () async {
    final service = AppConfigService();
    await service.load();
    await service.saveDevMachineIp('10.10.22.21');

    expect(service.needsLanIpForPhysicalDevice, isFalse);
    expect(service.baseUrl, 'http://10.10.22.21:5054');
  });

  test('clearDevMachineIp removes saved value', () async {
    final service = AppConfigService();
    await service.load();
    await service.saveDevMachineIp('10.0.0.8');
    await service.clearDevMachineIp();

    expect(service.devMachineIp.value, isEmpty);

    final reloaded = AppConfigService();
    await reloaded.load();
    expect(reloaded.devMachineIp.value, isEmpty);
  });
}
