import 'package:flutter_test/flutter_test.dart';
import 'package:share_verify/core/utils/barcode_parser.dart';

void main() {
  test('parseJsonBarcode extracts mcd and name', () {
    const raw = '{"mcd":"MCD001","name":"Nguyen Van A"}';
    final result = BarcodeParser.parse(raw);
    expect(result.mcd, 'MCD001');
    expect(result.name, 'Nguyen Van A');
  });

  test('parsePipeBarcode extracts mcd and name', () {
    const raw = 'MCD002|Tran Thi B';
    final result = BarcodeParser.parse(raw);
    expect(result.mcd, 'MCD002');
    expect(result.name, 'Tran Thi B');
  });

  test('parseRawMcd returns mcd only', () {
    final result = BarcodeParser.parse('MCD003');
    expect(result.mcd, 'MCD003');
    expect(result.name, isNull);
  });
}
