import 'package:crop_your_image/crop_your_image.dart';
import 'package:flutter/material.dart';

/// Khung crop mặc định khi OCR CMND qua OpenAI — dải ngang ngắn (số + họ tên).
abstract final class OpenAiCmndCrop {
  /// Chiều rộng so với ảnh hiển thị.
  static const bandWidthFactor = 0.92;

  /// Chiều cao dải crop — thấp hơn khung vuông mặc định.
  static const bandHeightFactor = 0.22;

  /// Vị trí từ trên xuống (vùng số CMND + họ tên thường nằm giữa thẻ).
  static const bandTopFactor = 0.28;

  static InitialRectBuilder get initialRectBuilder =>
      InitialRectBuilder.withBuilder(buildInitialRect);

  static Rect buildInitialRect(Rect viewportRect, Rect imageRect) {
    final width = imageRect.width * bandWidthFactor;
    final height = imageRect.height * bandHeightFactor;
    final left = imageRect.left + (imageRect.width - width) / 2;
    final top = imageRect.top + imageRect.height * bandTopFactor;

    final maxTop = imageRect.bottom - height;
    final clampedTop = top.clamp(imageRect.top, maxTop);

    return Rect.fromLTWH(left, clampedTop, width, height);
  }
}
