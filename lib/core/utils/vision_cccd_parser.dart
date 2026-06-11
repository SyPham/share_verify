import 'package:share_verify/core/models/ocr_result.dart';
import 'package:share_verify/core/services/ocr_service.dart';
import 'package:share_verify/core/utils/vision_confidence_scorer.dart';
import 'package:share_verify/core/utils/vision_text_layout.dart';
import 'package:vision_text_recognition/vision_text_recognition.dart';

class VisionCccdParser {
  VisionCccdParser._();

  static OcrResult parse(TextRecognitionResult visionResult) {
    final candidates = <String>{
      VisionTextLayout.blocksToLines(visionResult.textBlocks),
      visionResult.getConfidentText(0.5),
      visionResult.fullText,
    }..removeWhere((t) => t.trim().isEmpty);

    OcrResult? best;
    var bestScore = -1;

    for (final text in candidates) {
      final parsed = OcrService.parseRecognizedText(text, docType: 'CCCD');
      final score = _score(parsed);
      if (score > bestScore) {
        bestScore = score;
        best = parsed;
      }
    }

    final result = best ?? const OcrResult();
    final scores = VisionConfidenceScorer.score(
      blocks: visionResult.textBlocks,
      identityNo: result.identityNo,
      fullName: result.fullName,
    );

    return OcrResult(
      identityNo: result.identityNo,
      fullName: result.fullName,
      birthDate: result.birthDate,
      idConfidence: scores.idConfidence,
      nameConfidence: scores.nameConfidence,
    );
  }

  static int _score(OcrResult r) {
    var s = 0;
    if (r.hasIdentityNo) {
      s += 20;
      if (r.identityNo!.length == 12) s += 5;
    }
    if (r.hasFullName) s += 10;
    if (r.hasBirthDate) s += 5;
    return s;
  }
}
