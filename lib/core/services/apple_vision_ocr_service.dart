import 'package:flutter/foundation.dart';
import 'package:share_verify/core/models/ocr_result.dart';
import 'package:share_verify/core/utils/ocr_debug_log.dart';
import 'package:share_verify/core/utils/vision_cccd_parser.dart';
import 'package:share_verify/core/utils/vision_cmnd_parser.dart';
import 'package:share_verify/core/utils/vision_passport_parser.dart';
import 'package:share_verify/core/utils/vision_text_layout.dart';
import 'package:vision_text_recognition/vision_text_recognition.dart';

abstract class AppleVisionRecognizer {
  Future<TextRecognitionResult> recognize(Uint8List imageBytes);
}

/// Cấu hình Vision ưu tiên tiếng Việt trên giấy tờ VN.
TextRecognitionConfig appleVisionVietnameseConfig({int? revision}) {
  return TextRecognitionConfig(
    recognitionLevel: RecognitionLevel.accurate,
    usesLanguageCorrection: true,
    automaticallyDetectsLanguage: false,
    preferredLanguages: const ['vi-VN', 'vi'],
    minimumTextHeight: 0.006,
    revision: revision,
  );
}

class PluginAppleVisionRecognizer implements AppleVisionRecognizer {
  PluginAppleVisionRecognizer({TextRecognitionConfig? config})
      : _config = config ?? appleVisionVietnameseConfig(revision: 2);

  final TextRecognitionConfig _config;

  @override
  Future<TextRecognitionResult> recognize(Uint8List imageBytes) {
    return VisionTextRecognition.recognizeTextWithConfig(imageBytes, _config);
  }
}

/// Thử revision 3 → 2 → 1 → mặc định — tránh lỗi Revision3 trên iOS < 17.
class ResilientPluginAppleVisionRecognizer implements AppleVisionRecognizer {
  static const _revisions = <int?>[3, 2, 1, null];

  @override
  Future<TextRecognitionResult> recognize(Uint8List imageBytes) async {
    Object? lastError;

    for (final revision in _revisions) {
      final label = revision?.toString() ?? 'default';
      try {
        OcrDebugLog.message('Apple Vision try revision $label');
        final result = await VisionTextRecognition.recognizeTextWithConfig(
          imageBytes,
          appleVisionVietnameseConfig(revision: revision),
        );
        if (result.textBlocks.isNotEmpty) {
          OcrDebugLog.message(
            'Apple Vision OK · revision $label · '
            '${result.textBlocks.length} blocks',
          );
          return result;
        }
        OcrDebugLog.message('Apple Vision revision $label · no blocks');
      } catch (error) {
        lastError = error;
        OcrDebugLog.message('Apple Vision revision $label failed: $error');
      }
    }

    throw lastError ?? StateError('Apple Vision: no text recognized');
  }
}

class AppleVisionOcrService {
  AppleVisionOcrService({AppleVisionRecognizer? recognizer})
      : _recognizer =
            recognizer ?? ResilientPluginAppleVisionRecognizer();

  final AppleVisionRecognizer _recognizer;

  /// @deprecated Dùng [appleVisionVietnameseConfig].
  static final defaultConfig = appleVisionVietnameseConfig(revision: 2);

  Future<OcrResult> extractIdentity(
    Uint8List imageBytes, {
    required String docType,
  }) async {
    final visionResult = await _recognizer.recognize(imageBytes);
    OcrDebugLog.visionRaw(visionResult);

    if (visionResult.textBlocks.isEmpty) {
      OcrDebugLog.message('Apple Vision · $docType · no text blocks');
      return const OcrResult();
    }

    final parsed = switch (docType.toUpperCase()) {
      'CCCD' => VisionCccdParser.parse(visionResult),
      'CMND' => VisionCmndParser.parse(visionResult),
      'PASSPORT' => VisionPassportParser.parse(visionResult),
      _ => VisionCccdParser.parse(visionResult),
    };

    final rawText = _visionRawText(visionResult);

    final withRaw = parsed.copyWith(
      rawText: rawText,
      ocrSource: 'Apple Vision',
    );

    OcrDebugLog.pipeline(
      source: 'Apple Vision',
      docType: docType,
      result: withRaw,
    );

    return withRaw;
  }

  static String? _visionRawText(TextRecognitionResult visionResult) {
    final lineText = VisionTextLayout.blocksToLines(visionResult.textBlocks);
    if (lineText.trim().isNotEmpty) return lineText;
    final full = visionResult.fullText.trim();
    return full.isEmpty ? null : full;
  }
}
