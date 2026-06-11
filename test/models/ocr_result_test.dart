import 'package:flutter_test/flutter_test.dart';
import 'package:share_verify/core/models/ocr_result.dart';
import 'package:share_verify/core/utils/date_input_utils.dart';

void main() {
  test('fromApiResponse parses confidence fields', () {
    final result = OcrResult.fromApiResponse(
      {
        'idNumber': '285558670',
        'fullName': 'LÊ THỊ TRANG',
        'idConfidence': 0.12,
        'nameConfidence': 0.796,
      },
      docType: 'CMND',
    );

    expect(result.identityNo, '285558670');
    expect(result.fullName, 'LÊ THỊ TRANG');
    expect(result.idConfidence, 0.12);
    expect(result.nameConfidence, 0.796);
    expect(result.hasLowIdConfidence, isTrue);
    expect(result.hasLowNameConfidence, isFalse);
  });

  test('fromApiResponse treats missing confidence as null', () {
    final result = OcrResult.fromApiResponse(
      {
        'idNumber': '174324001',
        'fullName': 'NGUYỄN HOÀI LINH',
      },
      docType: 'CMND',
    );

    expect(result.idConfidence, isNull);
    expect(result.nameConfidence, isNull);
    expect(result.hasLowIdConfidence, isFalse);
  });

  test('fromApiResponse maps passport number and GCMND separately', () {
    final result = OcrResult.fromApiResponse(
      {
        'passportNumber': 'B4815163',
        'idNumber': '012977636',
        'fullName': 'NGÔ THỊ THU HÀ',
        'birthDate': '1993-07-28',
      },
      docType: 'PASSPORT',
    );

    expect(result.identityNo, 'B4815163');
    expect(result.legacyIdentityNo, '012977636');
    expect(result.fullName, 'NGÔ THỊ THU HÀ');
  });

  test('fromApiResponse parses CMND birthDate', () {
    final result = OcrResult.fromApiResponse(
      {
        'idNumber': '145064321',
        'fullName': 'NGUYỄN BẢO NGỌC',
        'birthDate': '07-09-1983',
      },
      docType: 'CMND',
    );

    expect(result.birthDate, '07-09-1983');
    expect(formatDateOfBirthForInput(result.birthDate), '07/09/1983');
  });

  test('hasLowIdConfidence uses threshold 0.65', () {
    const high = OcrResult(identityNo: '174324001', idConfidence: 0.7);
    const low = OcrResult(identityNo: '100388670', idConfidence: 0.12);

    expect(high.hasLowIdConfidence, isFalse);
    expect(low.hasLowIdConfidence, isTrue);
  });
}
