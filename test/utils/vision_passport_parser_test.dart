import 'package:flutter_test/flutter_test.dart';
import 'package:share_verify/core/utils/vision_passport_parser.dart';
import 'package:vision_text_recognition/vision_text_recognition.dart';

TextBlock _block(String text, {double x = 0.1, double y = 0.1}) {
  return TextBlock(
    text: text,
    confidence: 0.87,
    boundingBox: BoundingBox(x: x, y: y, width: 0.3, height: 0.04),
  );
}

void main() {
  group('VisionPassportParser', () {
    test('extracts passport number, GCMND, name, birth date', () {
      final visionResult = TextRecognitionResult(
        fullText: '',
        confidence: 0.87,
        textBlocks: [
          _block('Họ và tên / Full name', y: 0.25),
          _block('LÊ THỊ MỸ LINH', y: 0.30),
          _block('Ngày sinh / Date of birth', y: 0.38),
          _block('05/08/1996', y: 0.43),
          _block('Số hộ chiếu / Passport No.', x: 0.55, y: 0.15),
          _block('C0161180', x: 0.55, y: 0.20),
          _block('Số GCMND / ID Card No.', x: 0.55, y: 0.30),
          _block('241528670', x: 0.55, y: 0.35),
        ],
      );

      final parsed = VisionPassportParser.parse(visionResult);

      expect(parsed.identityNo, 'C0161180');
      expect(parsed.legacyIdentityNo, '241528670');
      expect(parsed.fullName, 'LÊ THỊ MỸ LINH');
      expect(parsed.birthDate, '05/08/1996');
    });

    test('disambiguates passport number from 9-digit GCMND by position', () {
      final visionResult = TextRecognitionResult(
        fullText: '',
        confidence: 0.8,
        textBlocks: [
          _block('TRAN VAN A', y: 0.3),
          _block('241528670', x: 0.6, y: 0.35),
          _block('C0161180', x: 0.6, y: 0.18),
        ],
      );

      final parsed = VisionPassportParser.parse(visionResult);

      expect(parsed.identityNo, 'C0161180');
      expect(parsed.legacyIdentityNo, '241528670');
    });
  });
}
