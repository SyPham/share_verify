import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:share_verify/core/utils/camera_image_crop.dart';

void main() {
  group('CameraImageCrop.mapWidgetRectToImage', () {
    test('maps centered widget rect with cover-fit scaling', () {
      const widgetSize = Size(400, 800);
      const imageSize = Size(1200, 1600);

      final crop = CameraImageCrop.mapWidgetRectToImage(
        const Rect.fromLTWH(20, 240, 360, 192),
        widgetSize: widgetSize,
        imageSize: imageSize,
      );

      expect(crop.width, greaterThan(0));
      expect(crop.height, greaterThan(0));
      expect(crop.left, greaterThanOrEqualTo(0));
      expect(crop.top, greaterThanOrEqualTo(0));
      expect(crop.right, lessThanOrEqualTo(imageSize.width));
      expect(crop.bottom, lessThanOrEqualTo(imageSize.height));
    });
  });
}
