import 'package:flutter/services.dart';

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
  return upper == 'CCCD' || upper == 'CMND' || upper == 'PASSPORT';
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
  if (upper == 'PASSPORT') return 'PASSPORT';
  return null;
}

bool isNumericIdentityType(String identityType) {
  final upper = identityType.toUpperCase();
  return upper == 'CCCD' || upper == 'CMND';
}

final numericIdentityInputFormatters = [
  FilteringTextInputFormatter.digitsOnly,
];

String compactIdentityNumber(String value) {
  return value
      .replaceAll(' ', '')
      .replaceAll('-', '')
      .replaceAll('.', '')
      .toUpperCase();
}

bool isCompleteIdentityNumber(String identityType, String value) {
  final upper = identityType.toUpperCase();
  final compact = compactIdentityNumber(value);
  final digits = value.replaceAll(RegExp(r'\D'), '');

  return switch (upper) {
    'CMND' => digits.length == 9,
    'CCCD' => digits.length == 12,
    'PASSPORT' => RegExp(r'^[A-HJ-NP-Z]\d{7,8}$').hasMatch(compact),
    _ => false,
  };
}
