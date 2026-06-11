import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_verify/core/data/sources/ocr_remote_source.dart';
import 'package:share_verify/core/services/app_config_service.dart';
import 'package:share_verify/core/services/ocr_service.dart';

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
  });

  group('parseRecognizedText', () {
    test('extracts CCCD number and Vietnamese name from labeled text', () {
      const text = '''
CĂN CƯỚC CÔNG DÂN
Họ và tên: Nguyễn Văn A
Số: 001234567890
''';

      final result = OcrService.parseRecognizedText(text, docType: 'CCCD');

      expect(result.identityNo, '001234567890');
      expect(result.fullName, 'Nguyễn Văn A');
    });

    test('extracts CMND 9-digit number with spaces', () {
      const text = '''
CHỨNG MINH NHÂN DÂN
NGUYEN VAN B
123 456 789
''';

      final result = OcrService.parseRecognizedText(text, docType: 'CMND');

      expect(result.identityNo, '123456789');
      expect(result.fullName, 'NGUYEN VAN B');
    });

    test('extracts CMND 9-digit number', () {
      const text = '''
CHỨNG MINH NHÂN DÂN
Họ và tên: Trần Thị B
123456789
''';

      final result = OcrService.parseRecognizedText(text, docType: 'CMND');

      expect(result.identityNo, '123456789');
      expect(result.fullName, 'Trần Thị B');
    });

    test('extracts CMND inline layout with number above name', () {
      const text = '''
SỐ 174324001
Họ tên: NGUYỄN HOÀI LINH
''';

      final result = OcrService.parseRecognizedText(text, docType: 'CMND');

      expect(result.identityNo, '174324001');
      expect(result.fullName, 'NGUYỄN HOÀI LINH');
    });

    test('keeps CMND name as parsed when OCR reads without diacritics', () {
      const text = '''
SỐ 174324001
Họ tên: NGUYEN HOAI LINH
''';

      final result = OcrService.parseRecognizedText(text, docType: 'CMND');

      expect(result.identityNo, '174324001');
      expect(result.fullName, 'NGUYEN HOAI LINH');
    });

    test('extracts CMND name after dotted leader on label line', () {
      const text = '''
SỐ 174324001
Họ tên:........NGUYỄN HOÀI LINH
''';

      final result = OcrService.parseRecognizedText(text, docType: 'CMND');

      expect(result.identityNo, '174324001');
      expect(result.fullName, 'NGUYỄN HOÀI LINH');
    });

    test('extracts CMND name above Ho ten label from PaddleOCR output', () {
      const text = '''
GIAY CHUNG MINH NHAN DAN
99898611098
DO.THIHONG
Ho ten
''';

      final result = OcrService.parseRecognizedText(text, docType: 'CMND');

      expect(result.fullName, 'DO.THIHONG');
    });

    test('extracts CMND classic layout with separate labels', () {
      const text = '''
CONG HOA XA HOI CHU NGHIA VIET NAM
CHUNG MINH NHAN DAN
So
987654321
Ho ten
LE THI HONG
''';

      final result = OcrService.parseRecognizedText(text, docType: 'CMND');

      expect(result.identityNo, '987654321');
      expect(result.fullName, 'LE THI HONG');
    });

    test('extracts CMND name on line after label with inline number', () {
      const text = '''
CONG HOA XA HOI CHU NGHIA VIET NAM
CHUNG MINH NHAN DAN
Ho va ten
LE THI HONG
Ngay sinh 01/01/1990
So: 987654321
''';

      final result = OcrService.parseRecognizedText(text, docType: 'CMND');

      expect(result.identityNo, '987654321');
      expect(result.fullName, 'LE THI HONG');
    });

    test('extracts CMND name before id and birth date', () {
      const text = '''
CHUNG MINH NHAN DAN
TRAN VAN MINH
Sinh ngay: 15/08/1985
123456789
''';

      final result = OcrService.parseRecognizedText(text, docType: 'CMND');

      expect(result.identityNo, '123456789');
      expect(result.fullName, 'TRAN VAN MINH');
      expect(result.birthDate, '15/08/1985');
    });

    test('extracts CMND birth date from dashed label', () {
      const text = '''
SỐ 145064321
Họ tên: NGUYỄN BẢO NGỌC
Sinh ngày 07-09-1983
''';

      final result = OcrService.parseRecognizedText(text, docType: 'CMND');

      expect(result.birthDate, '07-09-1983');
    });

    test('extracts CMND birth year on next line after label', () {
      const text = '''
SỐ 174324001
Họ tên: NGUYỄN HOÀI LINH
Sinh ngày
1990
''';

      final result = OcrService.parseRecognizedText(text, docType: 'CMND');

      expect(result.birthDate, '1990');
    });

    test('extracts CMND split name across two lines', () {
      const text = '''
CHUNG MINH NHAN DAN
NGUYEN
VAN AN
123456789
''';

      final result = OcrService.parseRecognizedText(text, docType: 'CMND');

      expect(result.identityNo, '123456789');
      expect(result.fullName, 'NGUYEN VAN AN');
    });

    test('does not pick CMND header as name', () {
      const text = '''
CHUNG MINH NHAN DAN
PHAM THI LAN
987654321
''';

      final result = OcrService.parseRecognizedText(text, docType: 'CMND');

      expect(result.fullName, 'PHAM THI LAN');
    });

    test('extracts passport number and name', () {
      const text = '''
PASSPORT
Name: TRAN THI B
No: P12345678
''';

      final result = OcrService.parseRecognizedText(text, docType: 'PASSPORT');

      expect(result.identityNo, 'P12345678');
      expect(result.fullName, 'TRAN THI B');
    });

    test('falls back to second meaningful line for name', () {
      const text = '''
CĂN CƯỚC CÔNG DÂN
Nguyễn Văn C
001122334455
''';

      final result = OcrService.parseRecognizedText(text, docType: 'CCCD');

      expect(result.identityNo, '001122334455');
      expect(result.fullName, 'Nguyễn Văn C');
    });
  });

  group('extractIdentity remote OCR', () {
    test('uses remote OCR when enabled and skips local parser', () async {
      final appConfig = AppConfigService();
      await appConfig.load();
      await appConfig.saveUseRemoteOcr(true);

      final dio = Dio();
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            handler.resolve(
              Response<Map<String, dynamic>>(
                requestOptions: options,
                data: {
                  'success': true,
                  'documentType': 'CCCD',
                  'idNumber': '079090001234',
                  'fullName': 'NGUYỄN VĂN A',
                },
              ),
            );
          },
        ),
      );

      final service = OcrService(
        ocrRemote: OcrRemoteSource(appConfig: appConfig, dio: dio),
        appConfig: appConfig,
        recognizeText: (_, {required String docType}) async {
          throw StateError('local OCR should not run');
        },
      );

      final result = await service.extractIdentity(
        Uint8List.fromList([1, 2, 3]),
        docType: 'CCCD',
      );

      expect(result.identityNo, '079090001234');
      expect(result.fullName, 'NGUYỄN VĂN A');
    });
  });
}
