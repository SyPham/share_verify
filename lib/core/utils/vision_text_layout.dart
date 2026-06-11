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

  /// Vùng header phải — thường chứa số hộ chiếu trên trang thông tin VN.
  static const passportNumberRegion = (x: 0.45, y: 0.0, w: 0.55, h: 0.35);

  /// Vùng giữa-trái — họ tên và ngày sinh.
  static const passportIdentityRegion = (x: 0.0, y: 0.2, w: 0.65, h: 0.55);

  /// Vùng cột phải giữa — GCMND / CMND.
  static const passportLegacyIdRegion = (x: 0.45, y: 0.25, w: 0.55, h: 0.35);

  static String blocksInRegion(
    List<TextBlock> blocks, {
    required double x,
    required double y,
    required double w,
    required double h,
  }) {
    final filtered = blocks.where((block) {
      final box = block.boundingBox;
      return box.x < x + w &&
          box.x + box.width > x &&
          box.y < y + h &&
          box.y + box.height > y;
    }).toList();
    return blocksToLines(filtered);
  }
}
