import 'package:flutter_test/flutter_test.dart';
import 'package:share_verify/core/utils/cccd_qr_parser.dart';

void main() {
  test('parse pipe-delimited CCCD QR', () {
    const raw =
        '001234567890|123456789|NGUYEN VAN A|01011990|Nam|Ha Noi|01012021';
    final data = CccdQrParser.parse(raw);

    expect(data?.identityNo, '001234567890');
    expect(data?.cmndNo, '123456789');
    expect(data?.fullName, 'NGUYEN VAN A');
    expect(data?.dateOfBirth, '01/01/1990');
  });

  test('parse JSON CCCD QR', () {
    const raw =
        '{"identityNo":"001234567890","fullName":"Nguyen Van A"}';
    final data = CccdQrParser.parse(raw);

    expect(data?.identityNo, '001234567890');
    expect(data?.fullName, 'Nguyen Van A');
  });

  test('parses Vietnamese name with diacritics in pipe format', () {
    const raw =
        '001234567890|123456789|Nguyễn Văn A|01011990|Nam|Hà Nội|01012021';
    final data = CccdQrParser.parse(raw);

    expect(data?.identityNo, '001234567890');
    expect(data?.fullName, 'Nguyễn Văn A');
  });

  test('returns null for invalid payload', () {
    expect(CccdQrParser.parse(''), isNull);
    expect(CccdQrParser.parse('invalid'), isNull);
  });
}
