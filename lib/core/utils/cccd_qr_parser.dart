import 'dart:convert';

/// Parses Vietnamese CCCD QR payload (pipe-delimited or JSON).
class CccdQrData {
  final String identityNo;
  final String fullName;
  final String? dateOfBirth;
  final String? cmndNo;

  const CccdQrData({
    required this.identityNo,
    required this.fullName,
    this.dateOfBirth,
    this.cmndNo,
  });
}

class CccdQrParser {
  static final RegExp _cccdPattern = RegExp(r'\b\d{12}\b');

  static CccdQrData? parse(String raw) {
    var trimmed = raw.trim();
    if (trimmed.isEmpty) return null;

    // Một số QR trả về kèm prefix hoặc URL.
    trimmed = _stripWrapping(trimmed);

    if (trimmed.startsWith('{')) {
      return _parseJson(trimmed);
    }

    if (trimmed.contains('|')) {
      return _parsePipe(trimmed);
    }

    return _parseLoose(trimmed);
  }

  static String _stripWrapping(String raw) {
    var value = raw;
    if (value.startsWith('\uFEFF')) {
      value = value.substring(1);
    }

    final queryIndex = value.indexOf('?');
    if (queryIndex != -1 && value.contains('=')) {
      final params = Uri.splitQueryString(value.substring(queryIndex + 1));
      for (final key in ['data', 'q', 'payload', 'cccd']) {
        final candidate = params[key];
        if (candidate != null && candidate.isNotEmpty) {
          return Uri.decodeComponent(candidate);
        }
      }
    }

    return value;
  }

  static CccdQrData? _parseJson(String raw) {
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      final id = (map['id'] ??
              map['identityNo'] ??
              map['cccd'] ??
              map['soDinhDanh'] ??
              map['personalId'])
          ?.toString();
      final name = (map['name'] ??
              map['fullName'] ??
              map['hoTen'] ??
              map['hoVaTen'])
          ?.toString();
      if (id == null || id.isEmpty || name == null || name.isEmpty) return null;
      final cmnd = (map['cmnd'] ??
              map['cmndNo'] ??
              map['oldId'] ??
              map['legacyId'])
          ?.toString()
          .trim();
      return CccdQrData(
        identityNo: id.trim(),
        fullName: name.trim(),
        cmndNo: _normalizeCmnd(cmnd),
      );
    } catch (_) {
      return null;
    }
  }

  static CccdQrData? _parsePipe(String raw) {
    final parts = raw.split('|').map((p) => p.trim()).toList();
    if (parts.length < 2) return null;

    final identityNo = _findIdentityNo(parts);
    final cmndNo = _findCmndNo(parts, identityNo);
    final fullName = _findFullName(parts, identityNo);
    final dateOfBirth = _findDateOfBirth(parts);
    if (identityNo == null || fullName == null) return null;

    return CccdQrData(
      identityNo: identityNo,
      fullName: fullName,
      dateOfBirth: dateOfBirth,
      cmndNo: cmndNo,
    );
  }

  static CccdQrData? _parseLoose(String raw) {
    final idMatch = _cccdPattern.firstMatch(raw);
    if (idMatch == null) return null;

    final identityNo = idMatch.group(0)!;
    final withoutId = raw.replaceFirst(identityNo, ' ').trim();
    if (withoutId.isEmpty) return null;

    final name = withoutId
        .replaceAll(RegExp(r'[|;,]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    if (name.isEmpty || RegExp(r'^\d+$').hasMatch(name)) return null;
    return CccdQrData(identityNo: identityNo, fullName: name);
  }

  static String? _findCmndNo(List<String> parts, String? cccdNo) {
    for (final part in parts) {
      final normalized = part.replaceAll(RegExp(r'\s'), '');
      if (normalized.isEmpty) continue;
      if (cccdNo != null && normalized == cccdNo) continue;
      if (RegExp(r'^\d{9}$').hasMatch(normalized)) return normalized;
    }
    return null;
  }

  static String? _normalizeCmnd(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    final normalized = raw.replaceAll(RegExp(r'\s'), '');
    return RegExp(r'^\d{9}$').hasMatch(normalized) ? normalized : null;
  }

  static String? _findIdentityNo(List<String> parts) {
    for (final part in parts) {
      final normalized = part.replaceAll(RegExp(r'\s'), '');
      if (RegExp(r'^\d{12}$').hasMatch(normalized)) return normalized;
      if (RegExp(r'^\d{9}$').hasMatch(normalized)) return normalized;
    }
    return null;
  }

  static String? _findDateOfBirth(List<String> parts) {
    for (final part in parts) {
      if (RegExp(r'^\d{2}/\d{2}/\d{4}$').hasMatch(part)) {
        return part;
      }
      if (RegExp(r'^\d{8}$').hasMatch(part)) {
        final day = part.substring(0, 2);
        final month = part.substring(2, 4);
        final year = part.substring(4, 8);
        return '$day/$month/$year';
      }
    }
    return null;
  }

  static String? _findFullName(List<String> parts, String? identityNo) {
    for (final part in parts) {
      if (part.isEmpty) continue;
      final normalized = part.replaceAll(RegExp(r'\s'), '');
      if (identityNo != null && normalized == identityNo) continue;
      if (RegExp(r'^\d+$').hasMatch(normalized)) continue;
      if (RegExp(r'^\d{2}/\d{2}/\d{4}$').hasMatch(part)) continue;
      if (part.length < 3) continue;
      if (RegExp(r'[A-Za-zÀ-ỹ]').hasMatch(part)) return part;
    }
    return null;
  }
}
