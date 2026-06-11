import 'package:share_verify/core/models/shareholder.dart';

enum CaptureMode {
  evidence,
  identity,
}

enum CaptureIntent {
  /// Chụp ảnh + OCR lấy họ tên và số giấy tờ.
  ocr,

  /// QR CCCD đã cung cấp dữ liệu — chụp ảnh minh chứng + xem lại thông tin QR.
  qrPrefilled,

  /// QR/chụp chỉ cần ảnh minh chứng (legacy).
  photoEvidenceOnly,
}

class CaptureRouteArgs {
  final Shareholder? shareholder;
  final CaptureMode mode;
  final String identityType;
  final CaptureIntent intent;
  final String? prefillName;
  final String? prefillIdentityNo;
  final String? prefillDateOfBirth;
  final String? prefillCmndNo;

  const CaptureRouteArgs({
    this.shareholder,
    this.mode = CaptureMode.identity,
    this.identityType = 'CCCD',
    this.intent = CaptureIntent.ocr,
    this.prefillName,
    this.prefillIdentityNo,
    this.prefillDateOfBirth,
    this.prefillCmndNo,
  });
}
