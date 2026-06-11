import 'dart:typed_data';

import 'package:share_verify/core/models/ocr_result.dart';
import 'package:share_verify/core/utils/vision_cccd_parser.dart';
import 'package:share_verify/core/utils/vision_cmnd_parser.dart';
import 'package:share_verify/core/utils/vision_passport_parser.dart';
import 'package:vision_text_recognition/vision_text_recognition.dart';

abstract class AppleVisionRecognizer {
  Future<TextRecognitionResult> recognize(Uint8List imageBytes);
}

class PluginAppleVisionRecognizer implements AppleVisionRecognizer {
  PluginAppleVisionRecognizer({TextRecognitionConfig? config})
      : _config = config ?? AppleVisionOcrService.defaultConfig;

  final TextRecognitionConfig _config;

  @override
  Future<TextRecognitionResult> recognize(Uint8List imageBytes) {
    return VisionTextRecognition.recognizeTextWithConfig(imageBytes, _config);
  }
}

class AppleVisionOcrService {
  AppleVisionOcrService({AppleVisionRecognizer? recognizer})
      : _recognizer = recognizer ?? PluginAppleVisionRecognizer();

  final AppleVisionRecognizer _recognizer;

  static const defaultConfig = TextRecognitionConfig(
    recognitionLevel: RecognitionLevel.accurate,
    usesLanguageCorrection: true,
    automaticallyDetectsLanguage: true,
    preferredLanguages: ['vi-VN', 'vi', 'en-US'],
    minimumTextHeight: 0.008,
    revision: 3,
  );

  Future<OcrResult> extractIdentity(
    Uint8List imageBytes, {
    required String docType,
  }) async {
    final visionResult = await _recognizer.recognize(imageBytes);
    if (visionResult.textBlocks.isEmpty) return const OcrResult();

    return switch (docType.toUpperCase()) {
      'CCCD' => VisionCccdParser.parse(visionResult),
      'CMND' => VisionCmndParser.parse(visionResult),
      'PASSPORT' => VisionPassportParser.parse(visionResult),
      _ => VisionCccdParser.parse(visionResult),
    };
  }
}
