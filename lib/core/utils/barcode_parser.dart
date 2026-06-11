import 'dart:convert';

import 'package:share_verify/core/models/invitation_barcode.dart';

class BarcodeParser {
  static InvitationBarcode parse(String raw) {
    final trimmed = raw.trim();
    if (trimmed.startsWith('{')) {
      final map = jsonDecode(trimmed) as Map<String, dynamic>;
      return InvitationBarcode(
        mcd: map['mcd'] as String,
        name: map['name'] as String?,
      );
    }
    if (trimmed.contains('|')) {
      final parts = trimmed.split('|');
      return InvitationBarcode(mcd: parts[0].trim(), name: parts[1].trim());
    }
    return InvitationBarcode(mcd: trimmed);
  }
}
