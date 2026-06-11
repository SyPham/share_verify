import 'package:flutter/services.dart';

/// Chuẩn hóa giá trị ngày sinh (OCR/QR) về dạng hiển thị `dd/MM/yyyy`.
String? formatDateOfBirthDisplay(String? value) {
  if (value == null) return null;

  final trimmed = value.trim();
  if (trimmed.isEmpty) return null;

  if (RegExp(r'^\d{2}/\d{2}/\d{4}$').hasMatch(trimmed)) {
    return trimmed;
  }

  final dmy = RegExp(r'^(\d{2})[\-./](\d{2})[\-./](\d{4})$').firstMatch(trimmed);
  if (dmy != null) {
    return '${dmy.group(1)}/${dmy.group(2)}/${dmy.group(3)}';
  }

  final dmyFlex =
      RegExp(r'^(\d{1,2})[\-./](\d{1,2})[\-./](\d{2,4})$').firstMatch(trimmed);
  if (dmyFlex != null) {
    final day = dmyFlex.group(1)!.padLeft(2, '0');
    final month = dmyFlex.group(2)!.padLeft(2, '0');
    var year = dmyFlex.group(3)!;
    if (year.length == 2) {
      year = (int.parse(year) >= 50 ? '19' : '20') + year;
    }
    return '$day/$month/$year';
  }

  final ymd = RegExp(r'^(\d{4})[\-./](\d{2})[\-./](\d{2})$').firstMatch(trimmed);
  if (ymd != null) {
    return '${ymd.group(3)}/${ymd.group(2)}/${ymd.group(1)}';
  }

  final digits = trimmed.replaceAll(RegExp(r'\D'), '');
  if (digits.length == 8) {
    return '${digits.substring(0, 2)}/${digits.substring(2, 4)}/${digits.substring(4)}';
  }

  if (digits.length == 4) {
    return '01/01/${digits.substring(0, 4)}';
  }

  if (digits.isNotEmpty) {
    return _formatDateDigits(digits);
  }

  return null;
}

String formatDateOfBirthForInput(String? value) {
  return formatDateOfBirthDisplay(value) ?? '';
}

bool isCompleteDateOfBirth(String value) {
  return RegExp(r'^\d{2}/\d{2}/\d{4}$').hasMatch(value.trim());
}

String _formatDateDigits(String digits) {
  final buffer = StringBuffer();
  for (var i = 0; i < digits.length && i < 8; i++) {
    if (i == 2 || i == 4) buffer.write('/');
    buffer.write(digits[i]);
  }
  return buffer.toString();
}

/// Mask nhập ngày sinh theo format `dd/MM/yyyy`.
class DdMmYyyyInputFormatter extends TextInputFormatter {
  const DdMmYyyyInputFormatter();

  static const _maxDigits = 8;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    if (digits.length > _maxDigits) {
      return oldValue;
    }

    final formatted = _formatDateDigits(digits);
    final isDeleting = newValue.text.length < oldValue.text.length;
    var selectionIndex = formatted.length;

    if (isDeleting) {
      selectionIndex = newValue.selection.end.clamp(0, formatted.length);
      if (selectionIndex > 0 &&
          selectionIndex <= formatted.length &&
          selectionIndex < oldValue.text.length &&
          oldValue.text[selectionIndex] == '/') {
        selectionIndex = (selectionIndex - 1).clamp(0, formatted.length);
      }
    }

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: selectionIndex),
    );
  }
}
