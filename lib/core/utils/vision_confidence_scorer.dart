import 'package:vision_text_recognition/vision_text_recognition.dart';

class VisionConfidenceScores {
  final double? idConfidence;
  final double? nameConfidence;

  const VisionConfidenceScores({this.idConfidence, this.nameConfidence});
}

class VisionConfidenceScorer {
  VisionConfidenceScorer._();

  static VisionConfidenceScores score({
    required List<TextBlock> blocks,
    String? identityNo,
    String? fullName,
  }) {
    return VisionConfidenceScores(
      idConfidence: _matchConfidence(blocks, identityNo),
      nameConfidence: _matchConfidence(blocks, fullName),
    );
  }

  static double? _matchConfidence(List<TextBlock> blocks, String? value) {
    if (value == null || value.trim().isEmpty) return null;

    final normalized = _compact(value);
    final matches = <double>[];

    for (final block in blocks) {
      final blockText = block.normalizedText;
      if (blockText.isEmpty) continue;

      final blockCompact = _compact(blockText);
      if (blockCompact.contains(normalized) ||
          normalized.contains(blockCompact) ||
          _fuzzyNameMatch(blockText, value)) {
        matches.add(block.confidence);
      }
    }

    if (matches.isEmpty) return null;
    return matches.reduce((a, b) => a + b) / matches.length;
  }

  static String _compact(String value) =>
      value.replaceAll(RegExp(r'[\s.\-]'), '').toUpperCase();

  static bool _fuzzyNameMatch(String blockText, String name) {
    final blockWords = blockText.toUpperCase().split(RegExp(r'\s+'));
    final nameWords = name.toUpperCase().split(RegExp(r'\s+'));
    if (nameWords.isEmpty) return false;
    final hit = nameWords.where((w) => blockWords.contains(w)).length;
    return hit >= (nameWords.length * 0.6).ceil();
  }
}
