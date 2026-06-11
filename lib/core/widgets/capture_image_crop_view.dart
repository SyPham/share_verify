import 'dart:typed_data';

import 'package:crop_your_image/crop_your_image.dart';
import 'package:flutter/material.dart';
import 'package:share_verify/core/commons/app_spacing.dart';

class CaptureImageCropView extends StatelessWidget {
  final Uint8List imageBytes;
  final CropController cropController;
  final double? aspectRatio;
  final ValueChanged<Uint8List> onCropped;
  final ValueChanged<Object> onCropError;

  const CaptureImageCropView({
    super.key,
    required this.imageBytes,
    required this.cropController,
    this.aspectRatio,
    required this.onCropped,
    required this.onCropError,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(SvSpacing.sm),
      child: Crop(
        image: imageBytes,
        controller: cropController,
        aspectRatio: aspectRatio,
        interactive: true,
        baseColor: Colors.black,
        maskColor: Colors.black.withValues(alpha: 0.45),
        radius: SvSpacing.radiusLg,
        onCropped: (result) {
          switch (result) {
            case CropSuccess(:final croppedImage):
              onCropped(croppedImage);
            case CropFailure(:final cause):
              onCropError(cause);
          }
        },
      ),
    );
  }
}
