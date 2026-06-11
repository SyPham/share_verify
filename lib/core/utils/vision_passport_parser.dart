import 'package:share_verify/core/models/ocr_result.dart';
import 'package:share_verify/core/services/ocr_service.dart';
import 'package:share_verify/core/utils/vision_confidence_scorer.dart';
import 'package:share_verify/core/utils/vision_text_layout.dart';
import 'package:vision_text_recognition/vision_text_recognition.dart';

class VisionPassportParser {
  VisionPassportParser._();

  static final _passportNoPattern = RegExp(r'\b([A-HJ-NP-Z])(\d{7,8})\b');
  static final _gcmndPattern = RegExp(r'\b\d{9}\b');
  static final _labelPattern = RegExp(
    r'(họ và tên|họ tên|full name|ngày sinh|date of birth|passport|gcmnd|id card)',
    caseSensitive: false,
  );

  static OcrResult parse(TextRecognitionResult visionResult) {
    final blocks = visionResult.textBlocks;
    final r = VisionTextLayout.passportNumberRegion;
    final legacyR = VisionTextLayout.passportLegacyIdRegion;
    final idR = VisionTextLayout.passportIdentityRegion;

    final passportRegionText = VisionTextLayout.blocksInRegion(
      blocks, x: r.x, y: r.y, w: r.w, h: r.h,
    );
    final legacyRegionText = VisionTextLayout.blocksInRegion(
      blocks, x: legacyR.x, y: legacyR.y, w: legacyR.w, h: legacyR.h,
    );
    final identityRegionText = VisionTextLayout.blocksInRegion(
      blocks, x: idR.x, y: idR.y, w: idR.w, h: idR.h,
    );

    final fullText = VisionTextLayout.blocksToLines(blocks);

    final passportNo = _extractPassportNumber(passportRegionText) ??
        _extractPassportNumber(fullText);
    final legacyNo = _extractGcmnd(legacyRegionText, exclude: passportNo) ??
        _extractGcmnd(fullText, exclude: passportNo);

    final fullName = _extractFullName(blocks, identityRegionText, fullText);
    final birthDate = _extractBirthDate(identityRegionText, fullText);

    final scores = VisionConfidenceScorer.score(
      blocks: blocks,
      identityNo: passportNo,
      fullName: fullName,
    );

    return OcrResult(
      identityNo: passportNo,
      fullName: fullName,
      birthDate: birthDate,
      legacyIdentityNo: legacyNo,
      idConfidence: scores.idConfidence,
      nameConfidence: scores.nameConfidence,
    );
  }

  static String? _extractFullName(
    List<TextBlock> blocks,
    String regionText,
    String fullText,
  ) {
    final idR = VisionTextLayout.passportIdentityRegion;
    final regionBlocks = blocks.where((block) {
      final box = block.boundingBox;
      return box.x < idR.x + idR.w &&
          box.x + box.width > idR.x &&
          box.y < idR.y + idR.h &&
          box.y + box.height > idR.y;
    }).toList()
      ..sort((a, b) => a.boundingBox.y.compareTo(b.boundingBox.y));

    String? best;
    var bestScore = -1;

    for (final block in regionBlocks) {
      final line = block.text.trim();
      if (line.isEmpty || _isLabelOnlyLine(line)) continue;

      final parsed = OcrService.parseRecognizedText(line, docType: 'PASSPORT');
      if (!parsed.hasFullName) continue;

      final name = parsed.fullName!;
      if (_isLabelOnlyLine(name)) continue;

      final score = name.length +
          RegExp(r'[À-ỹ]').allMatches(name).length * 2;
      if (score > bestScore) {
        bestScore = score;
        best = name;
      }
    }

    if (best != null) return best;

    final fallbackText = regionText.isNotEmpty ? regionText : fullText;
    return OcrService.parseRecognizedText(
      fallbackText,
      docType: 'PASSPORT',
    ).fullName;
  }

  static String? _extractBirthDate(String regionText, String fullText) {
    final text = regionText.isNotEmpty ? regionText : fullText;
    return OcrService.parseRecognizedText(text, docType: 'PASSPORT').birthDate;
  }

  static bool _isLabelOnlyLine(String line) {
    if (_labelPattern.hasMatch(line) &&
        !RegExp(r'^[A-ZÀ-Ỹ][A-ZÀ-Ỹ\s]{4,}$').hasMatch(line.trim())) {
      return true;
    }
    return line.trim().startsWith('/');
  }

  static String? _extractPassportNumber(String text) {
    for (final match in _passportNoPattern.allMatches(text.toUpperCase())) {
      return '${match.group(1)}${match.group(2)}';
    }
    return null;
  }

  static String? _extractGcmnd(String text, {String? exclude}) {
    for (final match in _gcmndPattern.allMatches(text)) {
      final value = match.group(0)!;
      if (value == exclude) continue;
      return value;
    }
    return null;
  }
}
