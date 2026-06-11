import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';

class CameraImageCrop {
  static Future<Uint8List> cropFromPreview({
    required Uint8List imageBytes,
    required GlobalKey frameKey,
    required GlobalKey previewKey,
  }) async {
    final frameBox = frameKey.currentContext?.findRenderObject() as RenderBox?;
    final previewBox = previewKey.currentContext?.findRenderObject() as RenderBox?;
    if (frameBox == null || previewBox == null) return imageBytes;

    final frameOrigin = frameBox.localToGlobal(Offset.zero);
    final previewOrigin = previewBox.localToGlobal(Offset.zero);
    final widgetRect = Rect.fromLTWH(
      frameOrigin.dx - previewOrigin.dx,
      frameOrigin.dy - previewOrigin.dy,
      frameBox.size.width,
      frameBox.size.height,
    );

    final codec = await ui.instantiateImageCodec(imageBytes);
    final frame = await codec.getNextFrame();
    final image = frame.image;

    try {
      final cropRect = _mapWidgetRectToImage(
        widgetRect,
        widgetSize: previewBox.size,
        imageSize: Size(
          image.width.toDouble(),
          image.height.toDouble(),
        ),
      );

      return _cropImage(image, cropRect);
    } finally {
      image.dispose();
    }
  }

  @visibleForTesting
  static Rect mapWidgetRectToImage(
    Rect widgetRect, {
    required Size widgetSize,
    required Size imageSize,
  }) {
    return _mapWidgetRectToImage(widgetRect, widgetSize: widgetSize, imageSize: imageSize);
  }

  static Rect _mapWidgetRectToImage(
    Rect widgetRect, {
    required Size widgetSize,
    required Size imageSize,
  }) {
    final scale = math.max(
      imageSize.width / widgetSize.width,
      imageSize.height / widgetSize.height,
    );

    final displayedWidth = imageSize.width / scale;
    final displayedHeight = imageSize.height / scale;
    final offsetX = (widgetSize.width - displayedWidth) / 2;
    final offsetY = (widgetSize.height - displayedHeight) / 2;

    final left =
        ((widgetRect.left - offsetX) * scale).clamp(0.0, imageSize.width - 1);
    final top =
        ((widgetRect.top - offsetY) * scale).clamp(0.0, imageSize.height - 1);
    final right = ((widgetRect.right - offsetX) * scale)
        .clamp(left + 1, imageSize.width);
    final bottom = ((widgetRect.bottom - offsetY) * scale)
        .clamp(top + 1, imageSize.height);

    return Rect.fromLTRB(left, top, right, bottom);
  }

  static Future<Uint8List> _cropImage(ui.Image image, Rect cropRect) async {
    final width = cropRect.width.round();
    final height = cropRect.height.round();

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.drawImageRect(
      image,
      cropRect,
      Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
      Paint()..filterQuality = ui.FilterQuality.high,
    );

    final picture = recorder.endRecording();
    final cropped = await picture.toImage(width, height);
    picture.dispose();

    try {
      final byteData =
          await cropped.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) {
        throw StateError('Không crop được ảnh');
      }
      return byteData.buffer.asUint8List();
    } finally {
      cropped.dispose();
    }
  }
}
