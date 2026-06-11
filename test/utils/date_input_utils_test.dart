import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:share_verify/core/utils/date_input_utils.dart';

void main() {
  group('formatDateOfBirthDisplay', () {
    test('keeps dd/MM/yyyy', () {
      expect(formatDateOfBirthDisplay('15/08/1990'), '15/08/1990');
    });

    test('converts yyyy-MM-dd', () {
      expect(formatDateOfBirthDisplay('1990-08-15'), '15/08/1990');
    });

    test('converts 8 digits', () {
      expect(formatDateOfBirthDisplay('15081990'), '15/08/1990');
    });

    test('converts year only to 01/01/yyyy', () {
      expect(formatDateOfBirthDisplay('1985'), '01/01/1985');
    });
  });

  group('DdMmYyyyInputFormatter', () {
    const formatter = DdMmYyyyInputFormatter();

    TextEditingValue format(String old, String text, {int offset = -1}) {
      final end = offset < 0 ? text.length : offset;
      return formatter.formatEditUpdate(
        TextEditingValue(text: old),
        TextEditingValue(
          text: text,
          selection: TextSelection.collapsed(offset: end),
        ),
      );
    }

    test('formats digits with slashes', () {
      expect(format('', '15081990').text, '15/08/1990');
    });

    test('limits to 8 digits', () {
      expect(format('15/08/1990', '150819901').text, '15/08/1990');
    });

    test('accepts pasted value with separators', () {
      expect(format('', '15-08-1990').text, '15/08/1990');
    });
  });

  group('isCompleteDateOfBirth', () {
    test('validates complete date', () {
      expect(isCompleteDateOfBirth('15/08/1990'), isTrue);
      expect(isCompleteDateOfBirth('15/08/199'), isFalse);
      expect(isCompleteDateOfBirth(''), isFalse);
    });
  });
}
