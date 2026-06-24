import 'dart:io';

class AppSetting {
  AppSetting._();

  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 30);

  static const String operatorName = 'ShareVerify Mobile';
  static const String deviceId = 'shareverify-mobile';

  /// IP từ `--dart-define=DEV_MACHINE_IP=...` khi build (giá trị khởi tạo).
  static const String devMachineIpFromEnvironment =
      String.fromEnvironment('DEV_MACHINE_IP', defaultValue: '');

  /// OCR CMND / Hộ chiếu qua OpenAI (mặc định bật).
  /// Tắt khi build: `--dart-define=USE_OPENAI_OCR=false`
  static const bool defaultUseOpenAiOcr =
      bool.fromEnvironment('USE_OPENAI_OCR', defaultValue: true);

  /// Model OpenAI gửi kèm request (để trống = dùng OPENAI_MODEL trên server).
  static const String defaultOpenAiModel =
      String.fromEnvironment('OPENAI_MODEL', defaultValue: '');

  static const int apiPort = 5054;

  /// Cổng Vietnam OCR API (FastAPI + CMND identity-card pipeline).
  static const int ocrApiPort = 8000;

  /// Số tiền phụ cấp đi lại trên mỗi cổ phần (VND).
  static const num travelSupportAmountPerShare = 1000;

  /// Tối thiểu khi không tính được từ số cổ phần.
  static const num minTravelSupportAmount = 1;

  /// Fallback khi chưa có [AppConfigService] (ví dụ unit test).
  static String get defaultBaseUrl {
    const override = String.fromEnvironment('API_BASE_URL');
    if (override.isNotEmpty) return override;

    final fromBuild = devMachineIpFromEnvironment.trim();
    if (fromBuild.isNotEmpty) {
      return 'http://$fromBuild:$apiPort';
    }

    if (Platform.isAndroid) {
      return 'http://10.0.2.2:$apiPort';
    }

    return 'http://localhost:$apiPort';
  }
}
