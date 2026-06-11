class OcrResult {
  final String? identityNo;
  final String? fullName;
  final String? birthDate;
  final String? legacyIdentityNo;
  final double? idConfidence;
  final double? nameConfidence;

  /// Ngưỡng từ API — dưới mức này số giấy tờ có thể đọc sai (mực mờ, mất nét).
  static const lowConfidenceThreshold = 0.65;

  const OcrResult({
    this.identityNo,
    this.fullName,
    this.birthDate,
    this.legacyIdentityNo,
    this.idConfidence,
    this.nameConfidence,
  });

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

    return OcrResult(
      identityNo: identityNo?.trim().isEmpty == true ? null : identityNo?.trim(),
      fullName: trimmedName?.isEmpty == true ? null : trimmedName,
      birthDate: birthDate?.isEmpty == true ? null : birthDate,
      legacyIdentityNo: legacyIdentityNo?.trim().isEmpty == true
          ? null
          : legacyIdentityNo?.trim(),
      idConfidence: _parseConfidence(data['idConfidence']),
      nameConfidence: _parseConfidence(data['nameConfidence']),
    );
  }

  static double? _parseConfidence(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }
}
