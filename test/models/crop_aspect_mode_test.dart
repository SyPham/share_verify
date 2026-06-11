import 'package:flutter_test/flutter_test.dart';
import 'package:share_verify/core/models/crop_aspect_mode.dart';

void main() {
  group('CropAspectMode', () {
    test('aspectRatio values', () {
      expect(CropAspectMode.free.aspectRatio, isNull);
      expect(CropAspectMode.square.aspectRatio, 1);
      expect(CropAspectMode.landscape.aspectRatio, closeTo(4 / 3, 0.001));
      expect(CropAspectMode.portrait.aspectRatio, closeTo(3 / 4, 0.001));
    });

    test('landscape is wider than tall', () {
      final ratio = CropAspectMode.landscape.aspectRatio!;
      expect(ratio, greaterThan(1));
    });

    test('portrait is taller than wide', () {
      final ratio = CropAspectMode.portrait.aspectRatio!;
      expect(ratio, lessThan(1));
    });
  });
}
