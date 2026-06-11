import 'package:flutter_test/flutter_test.dart';
import 'package:share_verify/core/utils/vision_confidence_scorer.dart';
import 'package:vision_text_recognition/vision_text_recognition.dart';

void main() {
  group('VisionConfidenceScorer', () {
    test('returns average confidence of blocks matching identity value', () {
      final blocks = [
        TextBlock(
          text: '079090001234',
          confidence: 0.92,
          boundingBox: const BoundingBox(x: 0.1, y: 0.3, width: 0.4, height: 0.05),
        ),
        TextBlock(
          text: 'NGUYỄN VĂN A',
          confidence: 0.81,
          boundingBox: const BoundingBox(x: 0.1, y: 0.2, width: 0.5, height: 0.05),
        ),
      ];

      final scores = VisionConfidenceScorer.score(
        blocks: blocks,
        identityNo: '079090001234',
        fullName: 'NGUYỄN VĂN A',
      );

      expect(scores.idConfidence, closeTo(0.92, 0.001));
      expect(scores.nameConfidence, closeTo(0.81, 0.001));
    });

    test('returns null when no block matches extracted value', () {
      final blocks = [
        TextBlock(
          text: 'noise',
          confidence: 0.5,
          boundingBox: const BoundingBox(x: 0, y: 0, width: 0.1, height: 0.1),
        ),
      ];

      final scores = VisionConfidenceScorer.score(
        blocks: blocks,
        identityNo: '123456789',
        fullName: null,
      );

      expect(scores.idConfidence, isNull);
      expect(scores.nameConfidence, isNull);
    });
  });
}
