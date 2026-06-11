import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:share_verify/core/widgets/document_scan_frame.dart';

void main() {
  group('DocumentScanFrame.computeFrameRect', () {
    test('fits landscape ID card within viewport', () {
      const size = Size(400, 800);
      final rect = DocumentScanFrame.computeFrameRect(size, kIdCardAspectRatio);

      expect(rect.width, greaterThan(0));
      expect(rect.height, greaterThan(0));
      expect(rect.left, greaterThanOrEqualTo(0));
      expect(rect.top, greaterThanOrEqualTo(0));
      expect(rect.right, lessThanOrEqualTo(size.width));
      expect(rect.bottom, lessThanOrEqualTo(size.height));
      expect(rect.width / rect.height, closeTo(kIdCardAspectRatio, 0.01));
    });
  });
}
