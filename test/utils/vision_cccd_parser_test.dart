import 'package:flutter_test/flutter_test.dart';
import 'package:share_verify/core/utils/vision_cccd_parser.dart';
import 'package:vision_text_recognition/vision_text_recognition.dart';

TextRecognitionResult _resultFromLines(List<String> lines) {
  final blocks = <TextBlock>[];
  for (var i = 0; i < lines.length; i++) {
    blocks.add(TextBlock(
      text: lines[i],
      confidence: 0.9,
      boundingBox: BoundingBox(x: 0.1, y: 0.1 + i * 0.08, width: 0.6, height: 0.05),
    ));
  }
  return TextRecognitionResult(
    fullText: lines.join('\n'),
    textBlocks: blocks,
    confidence: 0.9,
  );
}

void main() {
  group('VisionCccdParser', () {
    test('extracts 12-digit CCCD and Vietnamese name', () {
      final result = _resultFromLines([
        'CĂN CƯỚC CÔNG DÂN',
        'Họ và tên: NGUYỄN VĂN A',
        'Số: 079090001234',
      ]);

      final parsed = VisionCccdParser.parse(result);

      expect(parsed.identityNo, '079090001234');
      expect(parsed.fullName, 'NGUYỄN VĂN A');
    });

    test('extracts birth date from labeled line', () {
      final result = _resultFromLines([
        'Họ và tên: TRẦN THỊ B',
        'Ngày sinh: 15/08/1990',
        '079090009999',
      ]);

      final parsed = VisionCccdParser.parse(result);

      expect(parsed.birthDate, '15/08/1990');
      expect(parsed.identityNo, '079090009999');
    });

    test('prefers 12-digit over 9-digit when both present', () {
      final result = _resultFromLines([
        'NGUYỄN VĂN C',
        '123456789',
        '079090001234',
      ]);

      final parsed = VisionCccdParser.parse(result);

      expect(parsed.identityNo, '079090001234');
    });
  });
}
