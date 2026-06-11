/// Kích thước khung chụp giấy tờ (tỷ lệ width / height, khổ dọc).
class DocumentFrameSpecs {
  DocumentFrameSpecs._();

  /// CMND cũ: 65mm × 90mm.
  static const double cmndAspectRatio = 65 / 90;

  /// CCCD (ISO 7810): 53.98mm × 85.6mm.
  static const double cccdAspectRatio = 53.98 / 85.6;
}
