import 'package:vision_text_recognition/vision_text_recognition.dart';

class VisionTextLayout {
  VisionTextLayout._();

  /// Gom các text block cùng hàng (theo trục Y) thành từng dòng.
  static String blocksToLines(List<TextBlock> blocks, {double lineThreshold = 0.03}) {
    if (blocks.isEmpty) return '';

    final sorted = List<TextBlock>.from(blocks)
      ..sort((a, b) {
        final yDiff = a.boundingBox.y.compareTo(b.boundingBox.y);
        if (yDiff.abs() > lineThreshold) return yDiff;
        return a.boundingBox.x.compareTo(b.boundingBox.x);
      });

    final lines = <String>[];
    final currentWords = <String>[];
    double? currentLineY;

    for (final block in sorted) {
      final text = block.text.trim();
      if (text.isEmpty) continue;

      final y = block.boundingBox.y;
      final sameLine =
          currentLineY == null || (y - currentLineY).abs() <= lineThreshold;

      if (sameLine) {
        currentWords.add(text);
        currentLineY ??= y;
      } else {
        if (currentWords.isNotEmpty) {
          lines.add(currentWords.join(' '));
        }
        currentWords
          ..clear()
          ..add(text);
        currentLineY = y;
      }
    }

    if (currentWords.isNotEmpty) {
      lines.add(currentWords.join(' '));
    }

    return lines.join('\n');
  }
}
