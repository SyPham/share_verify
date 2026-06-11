/// Suy ra loại giấy tờ phụ (CMND/CCCD) từ số định danh trên hộ chiếu.
String inferLegacyIdentityType(String identityNo) {
  final digits = identityNo.replaceAll(RegExp(r'\D'), '');
  if (digits.length >= 12) return 'CCCD';
  return 'CMND';
}

bool supportsLegacyIdentityField(String identityType) {
  final upper = identityType.toUpperCase();
  return upper == 'CCCD' || upper == 'PASSPORT';
}

String legacyIdentityFieldLabel(String identityType, {bool fromQr = false}) {
  if (fromQr) return 'Số CMND (từ QR)';
  if (identityType.toUpperCase() == 'PASSPORT') {
    return 'Số CMND / CCCD';
  }
  return 'Số CMND';
}

bool supportsRegistrationNoAutocomplete(
  String identityType, {
  bool legacy = false,
}) {
  final upper = identityType.toUpperCase();
  if (legacy) {
    return upper == 'CCCD' || upper == 'PASSPORT';
  }
  return upper == 'CCCD' || upper == 'CMND';
}

String? registrationNoAutocompleteIdentityType(
  String identityType, {
  bool legacy = false,
}) {
  final upper = identityType.toUpperCase();
  if (legacy) {
    if (upper == 'CCCD') return 'CMND';
    return null;
  }
  if (upper == 'CMND') return 'CMND';
  if (upper == 'CCCD') return 'CCCD';
  return null;
}
