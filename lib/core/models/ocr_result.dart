class OcrResult {
  final String? identityNo;
  final String? fullName;
  final String? birthDate;
  final String? legacyIdentityNo;
  final double? idConfidence;
  final double? nameConfidence;
  /// Toàn bộ văn bản OCR thô — dùng để xem/sao chép khi parse sai.
  final String? rawText;
  /// Nguồn OCR: `OCR API`, `Apple Vision`, `ML Kit`, …
  final String? ocrSource;

  /// Ngưỡng từ API — dưới mức này số giấy tờ có thể đọc sai (mực mờ, mất nét).
  static const lowConfidenceThreshold = 0.65;

  const OcrResult({
    this.identityNo,
    this.fullName,
    this.birthDate,
    this.legacyIdentityNo,
    this.idConfidence,
    this.nameConfidence,
    this.rawText,
    this.ocrSource,
  });

  bool get hasRawText => rawText != null && rawText!.trim().isNotEmpty;

  OcrResult copyWith({
    String? identityNo,
    String? fullName,
    String? birthDate,
    String? legacyIdentityNo,
    double? idConfidence,
    double? nameConfidence,
    String? rawText,
    String? ocrSource,
  }) {
    return OcrResult(
      identityNo: identityNo ?? this.identityNo,
      fullName: fullName ?? this.fullName,
      birthDate: birthDate ?? this.birthDate,
      legacyIdentityNo: legacyIdentityNo ?? this.legacyIdentityNo,
      idConfidence: idConfidence ?? this.idConfidence,
      nameConfidence: nameConfidence ?? this.nameConfidence,
      rawText: rawText ?? this.rawText,
      ocrSource: ocrSource ?? this.ocrSource,
    );
  }

  bool get hasIdentityNo => identityNo != null && identityNo!.isNotEmpty;
  bool get hasFullName => fullName != null && fullName!.isNotEmpty;
  bool get hasBirthDate => birthDate != null && birthDate!.isNotEmpty;

  bool get hasLowIdConfidence =>
      idConfidence != null && idConfidence! < lowConfidenceThreshold;

  bool get hasLowNameConfidence =>
      nameConfidence != null && nameConfidence! < lowConfidenceThreshold;

  factory OcrResult.fromApiResponse(
    Map<String, dynamic> data, {
    required String docType,
  }) {
    final idNumber = data['idNumber']?.toString();
    final passportNumber = data['passportNumber']?.toString();
    final fullName = data['fullName']?.toString();

    final isPassport = docType.toUpperCase() == 'PASSPORT';
    final identityNo = isPassport
        ? (passportNumber?.isNotEmpty == true ? passportNumber : idNumber)
        : idNumber;
    final legacyIdentityNo = isPassport && idNumber?.isNotEmpty == true
        ? idNumber
        : null;

    final trimmedName = fullName?.trim();
    final birthDate = data['birthDate']?.toString().trim();

    final rawText = (data['rawText'] ?? data['raw_text'])?.toString().trim();

    return OcrResult(
      identityNo: identityNo?.trim().isEmpty == true ? null : identityNo?.trim(),
      fullName: trimmedName?.isEmpty == true ? null : trimmedName,
      birthDate: birthDate?.isEmpty == true ? null : birthDate,
      legacyIdentityNo: legacyIdentityNo?.trim().isEmpty == true
          ? null
          : legacyIdentityNo?.trim(),
      idConfidence: _parseConfidence(data['idConfidence']),
      nameConfidence: _parseConfidence(data['nameConfidence']),
      rawText: rawText?.isEmpty == true ? null : rawText,
      ocrSource: 'OCR API',
    );
  }

  static double? _parseConfidence(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }
}
