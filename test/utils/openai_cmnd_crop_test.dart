import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:share_verify/core/utils/openai_cmnd_crop.dart';

void main() {
  test('buildInitialRect is a wide short horizontal band', () {
    const imageRect = Rect.fromLTWH(20, 40, 300, 400);

    final cropRect = OpenAiCmndCrop.buildInitialRect(Rect.zero, imageRect);

    expect(cropRect.width, closeTo(300 * OpenAiCmndCrop.bandWidthFactor, 0.01));
    expect(
      cropRect.height,
      closeTo(400 * OpenAiCmndCrop.bandHeightFactor, 0.01),
    );
    expect(cropRect.width / cropRect.height, greaterThan(3));
    expect(cropRect.top, greaterThanOrEqualTo(imageRect.top));
    expect(cropRect.bottom, lessThanOrEqualTo(imageRect.bottom));
  });
}
