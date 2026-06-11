import 'package:flutter_test/flutter_test.dart';
import 'package:share_verify/core/utils/document_frame_specs.dart';

void main() {
  test('CMND aspect ratio matches 65x90mm card', () {
    expect(
      DocumentFrameSpecs.cmndAspectRatio,
      closeTo(65 / 90, 0.001),
    );
  });
}
