import 'package:flutter_test/flutter_test.dart';
import 'package:share_verify/core/utils/vision_cmnd_parser.dart';
import 'package:vision_text_recognition/vision_text_recognition.dart';

TextRecognitionResult _cmndResult(String text) {
  final lines = text.split('\n').where((l) => l.trim().isNotEmpty).toList();
  final blocks = <TextBlock>[];
  for (var i = 0; i < lines.length; i++) {
    blocks.add(TextBlock(
      text: lines[i],
      confidence: 0.88,
      boundingBox: BoundingBox(x: 0.15, y: 0.15 + i * 0.07, width: 0.5, height: 0.04),
    ));
  }
  return TextRecognitionResult(
    fullText: text,
    textBlocks: blocks,
    confidence: 0.88,
  );
}

void main() {
  group('VisionCmndParser', () {
    test('extracts inline SỐ + Họ tên layout', () {
      const text = '''
SỐ 174324001
Họ tên: NGUYỄN HOÀI LINH
Sinh ngày 07-09-1983
''';
      final parsed = VisionCmndParser.parse(_cmndResult(text));

      expect(parsed.identityNo, '174324001');
      expect(parsed.fullName, 'NGUYỄN HOÀI LINH');
      expect(parsed.birthDate, '07-09-1983');
    });

    test('extracts classic separate label layout', () {
      const text = '''
So
987654321
Ho ten
LE THI HONG
''';
      final parsed = VisionCmndParser.parse(_cmndResult(text));

      expect(parsed.identityNo, '987654321');
      expect(parsed.fullName, 'LE THI HONG');
    });

    test('attaches confidence from matching blocks', () {
      const text = 'SỐ 174324001\nHọ tên: NGUYỄN HOÀI LINH';
      final parsed = VisionCmndParser.parse(_cmndResult(text));

      expect(parsed.idConfidence, isNotNull);
      expect(parsed.nameConfidence, isNotNull);
    });
  });
}
