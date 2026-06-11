import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:share_verify/core/services/apple_vision_ocr_service.dart';
import 'package:vision_text_recognition/vision_text_recognition.dart';

class _FakeVision implements AppleVisionRecognizer {
  final TextRecognitionResult result;

  _FakeVision(this.result);

  @override
  Future<TextRecognitionResult> recognize(Uint8List imageBytes) async => result;
}

void main() {
  group('AppleVisionOcrService', () {
    test('routes CCCD to VisionCccdParser', () async {
      final service = AppleVisionOcrService(
        recognizer: _FakeVision(TextRecognitionResult(
          fullText: 'Họ và tên: NGUYỄN VĂN A\n079090001234',
          textBlocks: [
            TextBlock(
              text: 'Họ và tên: NGUYỄN VĂN A',
              confidence: 0.9,
              boundingBox: const BoundingBox(x: 0.1, y: 0.2, width: 0.5, height: 0.05),
            ),
            TextBlock(
              text: '079090001234',
              confidence: 0.95,
              boundingBox: const BoundingBox(x: 0.1, y: 0.3, width: 0.4, height: 0.05),
            ),
          ],
          confidence: 0.9,
        )),
      );

      final parsed = await service.extractIdentity(
        Uint8List.fromList([1]),
        docType: 'CCCD',
      );

      expect(parsed.identityNo, '079090001234');
      expect(parsed.fullName, 'NGUYỄN VĂN A');
      expect(parsed.idConfidence, isNotNull);
    });

    test('routes PASSPORT to VisionPassportParser', () async {
      final service = AppleVisionOcrService(
        recognizer: _FakeVision(TextRecognitionResult(
          fullText: '',
          textBlocks: [
            TextBlock(
              text: 'C0161180',
              confidence: 0.9,
              boundingBox: const BoundingBox(x: 0.55, y: 0.18, width: 0.2, height: 0.04),
            ),
            TextBlock(
              text: 'LÊ THỊ MỸ LINH',
              confidence: 0.85,
              boundingBox: const BoundingBox(x: 0.1, y: 0.3, width: 0.4, height: 0.04),
            ),
          ],
          confidence: 0.88,
        )),
      );

      final parsed = await service.extractIdentity(
        Uint8List.fromList([1]),
        docType: 'PASSPORT',
      );

      expect(parsed.identityNo, 'C0161180');
      expect(parsed.fullName, 'LÊ THỊ MỸ LINH');
    });
  });
}
