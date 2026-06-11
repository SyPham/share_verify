import 'package:flutter/material.dart';
import 'package:share_verify/core/commons/palette.dart';

/// ISO ID-1 (CMND/CCCD): 85.6 × 53.98 mm.
const double kIdCardAspectRatio = 85.6 / 53.98;

/// Khung hướng dẫn đặt giấy tờ trên camera preview.
class DocumentScanFrame extends StatelessWidget {
  const DocumentScanFrame({
    super.key,
    required this.frameKey,
    this.aspectRatio = kIdCardAspectRatio,
  });

  final GlobalKey frameKey;
  final double aspectRatio;

  @visibleForTesting
  static Rect computeFrameRect(Size size, double aspectRatio) {
    const horizontalInset = 0.075;
    const verticalInset = 0.12;

    final maxWidth = size.width * (1 - 2 * horizontalInset);
    final maxHeight = size.height * (1 - 2 * verticalInset);

    var width = maxWidth;
    var height = width / aspectRatio;
    if (height > maxHeight) {
      height = maxHeight;
      width = height * aspectRatio;
    }

    final left = (size.width - width) / 2;
    final top = (size.height - height) / 2;
    return Rect.fromLTWH(left, top, width, height);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final frameRect = computeFrameRect(constraints.biggest, aspectRatio);

        return Stack(
          fit: StackFit.expand,
          children: [
            CustomPaint(
              size: constraints.biggest,
              painter: _ScanFrameMaskPainter(cutout: frameRect),
            ),
            Positioned(
              left: frameRect.left,
              top: frameRect.top,
              width: frameRect.width,
              height: frameRect.height,
              child: KeyedSubtree(
                key: frameKey,
                child: CustomPaint(
                  painter: _CornerAccentPainter(color: SvPalette.secondary),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ScanFrameMaskPainter extends CustomPainter {
  _ScanFrameMaskPainter({required this.cutout});

  final Rect cutout;

  @override
  void paint(Canvas canvas, Size size) {
    final overlay = Path()..addRect(Offset.zero & size);
    final hole = Path()
      ..addRRect(
        RRect.fromRectAndRadius(cutout, const Radius.circular(8)),
      );
    final mask = Path.combine(PathOperation.difference, overlay, hole);
    canvas.drawPath(mask, Paint()..color = Colors.black.withValues(alpha: 0.45));
  }

  @override
  bool shouldRepaint(covariant _ScanFrameMaskPainter oldDelegate) =>
      oldDelegate.cutout != cutout;
}

class _CornerAccentPainter extends CustomPainter {
  _CornerAccentPainter({required this.color});

  final Color color;
  static const _strokeWidth = 3.0;
  static const _cornerLength = 22.0;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = _strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final w = size.width;
    final h = size.height;
    const len = _cornerLength;

    canvas.drawLine(const Offset(0, 0), Offset(len, 0), paint);
    canvas.drawLine(const Offset(0, 0), Offset(0, len), paint);

    canvas.drawLine(Offset(w - len, 0), Offset(w, 0), paint);
    canvas.drawLine(Offset(w, 0), Offset(w, len), paint);

    canvas.drawLine(Offset(0, h - len), Offset(0, h), paint);
    canvas.drawLine(Offset(0, h), Offset(len, h), paint);

    canvas.drawLine(Offset(w - len, h), Offset(w, h), paint);
    canvas.drawLine(Offset(w, h - len), Offset(w, h), paint);
  }

  @override
  bool shouldRepaint(covariant _CornerAccentPainter oldDelegate) =>
      oldDelegate.color != color;
}
