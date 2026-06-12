# Kế hoạch triển khai Apple Vision OCR

> **Cho agent thực thi:** BẮT BUỘC dùng sub-skill `superpowers:subagent-driven-development` (khuyến nghị) hoặc `superpowers:executing-plans` để thực hiện từng task. Các bước dùng cú pháp checkbox (`- [ ]`) để theo dõi.

**Mục tiêu:** Hoàn thiện pipeline OCR on-device bằng Apple Vision (VNRecognizeTextRequest) cho ba loại giấy tờ — CCCD, CMND, Hộ chiếu — trên iOS, với điểm tin cậy và parser theo layout, làm fallback khi vietnam-ocr-api không khả dụng.

**Kiến trúc:** Tách logic Apple Vision ra module riêng (`AppleVisionOcrService`) với parser theo từng loại giấy tờ, tận dụng `TextBlock.confidence` và `boundingBox` từ plugin `vision_text_recognition`. Giữ chuỗi ưu tiên hiện tại: Remote API → Apple Vision (iOS) → ML Kit. `OcrService` chỉ điều phối, không chứa parser dài.

**Tech stack:** Flutter 3.4+, `vision_text_recognition ^1.0.2`, Apple Vision framework (iOS 15.5+), GetX, test package `flutter_test`.

---

## Hiện trạng (đọc trước khi code)

| Thành phần | Trạng thái |
|------------|------------|
| Plugin `vision_text_recognition` | Đã có trong `pubspec.yaml` |
| Gọi Vision trong `ocr_service.dart` | Có — `_extractIdentityWithAppleVision()` chỉ trên `Platform.isIOS` |
| Parser CCCD/CMND/Passport | Có — `parseRecognizedText()` dùng regex chung, CMND khá đầy đủ |
| `legacyIdentityNo` (GCMND hộ chiếu) | **Thiếu** — chỉ có khi gọi remote API |
| `idConfidence` / `nameConfidence` on-device | **Thiếu** — UI cảnh báo độ tin cậy thấp không hoạt động khi offline |
| Parser theo vùng ảnh (bounding box) | **Thiếu** — chưa dùng `getBlocksInRegion()` |
| macOS | Không trong phạm vi (chỉ iOS) |

---

## Cấu trúc file

| File | Trách nhiệm |
|------|-------------|
| `lib/core/services/apple_vision_ocr_service.dart` | Gọi Vision, gom candidate text, chọn parser theo `docType`, trả `OcrResult` |
| `lib/core/utils/vision_confidence_scorer.dart` | Tính `idConfidence` / `nameConfidence` từ `TextBlock.confidence` |
| `lib/core/utils/vision_cccd_parser.dart` | Trích 12 số CCCD, họ tên, ngày sinh từ `TextRecognitionResult` |
| `lib/core/utils/vision_cmnd_parser.dart` | Trích CMND 9 số + họ tên (delegate logic CMND hiện có + layout blocks) |
| `lib/core/utils/vision_passport_parser.dart` | Trích số hộ chiếu, GCMND/CMND, họ tên, ngày sinh theo vùng |
| `lib/core/utils/vision_text_layout.dart` | Bổ sung helper vùng đọc (header / cột phải / MRZ) |
| `lib/core/services/ocr_service.dart` | Rút gọn — delegate Vision sang `AppleVisionOcrService` |
| `test/utils/vision_*_parser_test.dart` | Unit test parser từng loại |
| `test/utils/vision_confidence_scorer_test.dart` | Unit test điểm tin cậy |
| `test/services/apple_vision_ocr_service_test.dart` | Test orchestration với mock Vision result |

---

### Task 1: VisionConfidenceScorer

**Files:**
- Create: `lib/core/utils/vision_confidence_scorer.dart`
- Test: `test/utils/vision_confidence_scorer_test.dart`

- [ ] **Bước 1: Viết test thất bại**

```dart
// test/utils/vision_confidence_scorer_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:share_verify/core/utils/vision_confidence_scorer.dart';
import 'package:vision_text_recognition/vision_text_recognition.dart';

void main() {
  group('VisionConfidenceScorer', () {
    test('returns average confidence of blocks matching identity value', () {
      final blocks = [
        TextBlock(
          text: '079090001234',
          confidence: 0.92,
          boundingBox: const BoundingBox(x: 0.1, y: 0.3, width: 0.4, height: 0.05),
        ),
        TextBlock(
          text: 'NGUYỄN VĂN A',
          confidence: 0.81,
          boundingBox: const BoundingBox(x: 0.1, y: 0.2, width: 0.5, height: 0.05),
        ),
      ];

      final scores = VisionConfidenceScorer.score(
        blocks: blocks,
        identityNo: '079090001234',
        fullName: 'NGUYỄN VĂN A',
      );

      expect(scores.idConfidence, closeTo(0.92, 0.001));
      expect(scores.nameConfidence, closeTo(0.81, 0.001));
    });

    test('returns null when no block matches extracted value', () {
      final blocks = [
        TextBlock(
          text: 'noise',
          confidence: 0.5,
          boundingBox: const BoundingBox(x: 0, y: 0, width: 0.1, height: 0.1),
        ),
      ];

      final scores = VisionConfidenceScorer.score(
        blocks: blocks,
        identityNo: '123456789',
        fullName: null,
      );

      expect(scores.idConfidence, isNull);
      expect(scores.nameConfidence, isNull);
    });
  });
}
```

- [ ] **Bước 2: Chạy test — xác nhận FAIL**

```bash
cd /Users/sypham/projects/becamex/share_verify
flutter test test/utils/vision_confidence_scorer_test.dart -v
```

Kỳ vọng: FAIL với `VisionConfidenceScorer` not defined.

- [ ] **Bước 3: Implement tối thiểu**

```dart
// lib/core/utils/vision_confidence_scorer.dart
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
```

- [ ] **Bước 4: Chạy test — xác nhận PASS**

```bash
flutter test test/utils/vision_confidence_scorer_test.dart -v
```

Kỳ vọng: All tests passed.

- [ ] **Bước 5: Commit**

```bash
git add lib/core/utils/vision_confidence_scorer.dart test/utils/vision_confidence_scorer_test.dart
git commit -m "feat(ocr): thêm VisionConfidenceScorer cho điểm tin cậy on-device"
```

---

### Task 2: VisionCccdParser

**Files:**
- Create: `lib/core/utils/vision_cccd_parser.dart`
- Test: `test/utils/vision_cccd_parser_test.dart`

- [ ] **Bước 1: Viết test thất bại**

```dart
// test/utils/vision_cccd_parser_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:share_verify/core/utils/vision_cccd_parser.dart';
import 'package:vision_text_recognition/vision_text_recognition.dart';

TextRecognitionResult _resultFromLines(List<String> lines) {
  final blocks = <TextBlock>[];
  for (var i = 0; i < lines.length; i++) {
    blocks.add(TextBlock(
      text: lines[i],
      confidence: 0.9,
      boundingBox: BoundingBox(x: 0.1, y: 0.1 + i * 0.08, width: 0.6, height: 0.05),
    ));
  }
  return TextRecognitionResult(
    fullText: lines.join('\n'),
    textBlocks: blocks,
    confidence: 0.9,
  );
}

void main() {
  group('VisionCccdParser', () {
    test('extracts 12-digit CCCD and Vietnamese name', () {
      final result = _resultFromLines([
        'CĂN CƯỚC CÔNG DÂN',
        'Họ và tên: NGUYỄN VĂN A',
        'Số: 079090001234',
      ]);

      final parsed = VisionCccdParser.parse(result);

      expect(parsed.identityNo, '079090001234');
      expect(parsed.fullName, 'NGUYỄN VĂN A');
    });

    test('extracts birth date from labeled line', () {
      final result = _resultFromLines([
        'Họ và tên: TRẦN THỊ B',
        'Ngày sinh: 15/08/1990',
        '079090009999',
      ]);

      final parsed = VisionCccdParser.parse(result);

      expect(parsed.birthDate, '15/08/1990');
      expect(parsed.identityNo, '079090009999');
    });

    test('prefers 12-digit over 9-digit when both present', () {
      final result = _resultFromLines([
        'NGUYỄN VĂN C',
        '123456789',
        '079090001234',
      ]);

      final parsed = VisionCccdParser.parse(result);

      expect(parsed.identityNo, '079090001234');
    });
  });
}
```

- [ ] **Bước 2: Chạy test — xác nhận FAIL**

```bash
flutter test test/utils/vision_cccd_parser_test.dart -v
```

- [ ] **Bước 3: Implement tối thiểu**

```dart
// lib/core/utils/vision_cccd_parser.dart
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
```

- [ ] **Bước 4: Chạy test — xác nhận PASS**

```bash
flutter test test/utils/vision_cccd_parser_test.dart -v
```

- [ ] **Bước 5: Commit**

```bash
git add lib/core/utils/vision_cccd_parser.dart test/utils/vision_cccd_parser_test.dart
git commit -m "feat(ocr): thêm VisionCccdParser cho CCCD on-device"
```

---

### Task 3: VisionCmndParser

**Files:**
- Create: `lib/core/utils/vision_cmnd_parser.dart`
- Test: `test/utils/vision_cmnd_parser_test.dart`

- [ ] **Bước 1: Viết test thất bại**

```dart
// test/utils/vision_cmnd_parser_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:share_verify/core/utils/vision_cmnd_parser.dart';
import 'package:vision_text_recognition/vision_text_recognition.dart';

TextRecognitionResult _cmndResult(String text) {
  final lines = text.split('\n').where((l) => l.trim().isNotEmpty).toList();
  final blocks = <TextBlock>[];
  for (var i = 0; i < lines.length; i++) {
    blocks.add(TextBlock(
      text: lines[i],
      confidence: 0.88,
      boundingBox: BoundingBox(x: 0.15, y: 0.15 + i * 0.07, width: 0.5, height: 0.04),
    ));
  }
  return TextRecognitionResult(
    fullText: text,
    textBlocks: blocks,
    confidence: 0.88,
  );
}

void main() {
  group('VisionCmndParser', () {
    test('extracts inline SỐ + Họ tên layout', () {
      const text = '''
SỐ 174324001
Họ tên: NGUYỄN HOÀI LINH
Sinh ngày 07-09-1983
''';
      final parsed = VisionCmndParser.parse(_cmndResult(text));

      expect(parsed.identityNo, '174324001');
      expect(parsed.fullName, 'NGUYỄN HOÀI LINH');
      expect(parsed.birthDate, '07-09-1983');
    });

    test('extracts classic separate label layout', () {
      const text = '''
So
987654321
Ho ten
LE THI HONG
''';
      final parsed = VisionCmndParser.parse(_cmndResult(text));

      expect(parsed.identityNo, '987654321');
      expect(parsed.fullName, 'LE THI HONG');
    });

    test('attaches confidence from matching blocks', () {
      const text = 'SỐ 174324001\nHọ tên: NGUYỄN HOÀI LINH';
      final parsed = VisionCmndParser.parse(_cmndResult(text));

      expect(parsed.idConfidence, isNotNull);
      expect(parsed.nameConfidence, isNotNull);
    });
  });
}
```

- [ ] **Bước 2: Chạy test — xác nhận FAIL**

```bash
flutter test test/utils/vision_cmnd_parser_test.dart -v
```

- [ ] **Bước 3: Implement tối thiểu**

```dart
// lib/core/utils/vision_cmnd_parser.dart
import 'package:share_verify/core/models/ocr_result.dart';
import 'package:share_verify/core/services/ocr_service.dart';
import 'package:share_verify/core/utils/vision_confidence_scorer.dart';
import 'package:share_verify/core/utils/vision_text_layout.dart';
import 'package:vision_text_recognition/vision_text_recognition.dart';

class VisionCmndParser {
  VisionCmndParser._();

  static OcrResult parse(TextRecognitionResult visionResult) {
    final lineText = VisionTextLayout.blocksToLines(visionResult.textBlocks);
    final sortedText =
        visionResult.blocksSortedByPosition.map((b) => b.text.trim()).join('\n');

    final candidates = <String>{
      lineText,
      sortedText,
      visionResult.getConfidentText(0.45),
      visionResult.fullText,
    }..removeWhere((t) => t.trim().isEmpty);

    OcrResult? best;
    var bestScore = -1;

    for (final text in candidates) {
      final parsed = OcrService.parseRecognizedText(text, docType: 'CMND');
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
    if (r.hasIdentityNo) s += 20;
    if (r.hasFullName) s += 10;
    if (r.hasBirthDate) s += 5;
    return s;
  }
}
```

- [ ] **Bước 4: Chạy test — xác nhận PASS**

```bash
flutter test test/utils/vision_cmnd_parser_test.dart -v
```

- [ ] **Bước 5: Commit**

```bash
git add lib/core/utils/vision_cmnd_parser.dart test/utils/vision_cmnd_parser_test.dart
git commit -m "feat(ocr): thêm VisionCmndParser cho CMND on-device"
```

---

### Task 4: VisionPassportParser (số hộ chiếu + GCMND)

**Files:**
- Create: `lib/core/utils/vision_passport_parser.dart`
- Modify: `lib/core/utils/vision_text_layout.dart`
- Test: `test/utils/vision_passport_parser_test.dart`

- [ ] **Bước 1: Viết test thất bại**

```dart
// test/utils/vision_passport_parser_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:share_verify/core/utils/vision_passport_parser.dart';
import 'package:vision_text_recognition/vision_text_recognition.dart';

TextBlock _block(String text, {double x = 0.1, double y = 0.1}) {
  return TextBlock(
    text: text,
    confidence: 0.87,
    boundingBox: BoundingBox(x: x, y: y, width: 0.3, height: 0.04),
  );
}

void main() {
  group('VisionPassportParser', () {
    test('extracts passport number, GCMND, name, birth date', () {
      final visionResult = TextRecognitionResult(
        fullText: '',
        confidence: 0.87,
        textBlocks: [
          _block('Họ và tên / Full name', y: 0.25),
          _block('LÊ THỊ MỸ LINH', y: 0.30),
          _block('Ngày sinh / Date of birth', y: 0.38),
          _block('05/08/1996', y: 0.43),
          _block('Số hộ chiếu / Passport No.', x: 0.55, y: 0.15),
          _block('C0161180', x: 0.55, y: 0.20),
          _block('Số GCMND / ID Card No.', x: 0.55, y: 0.30),
          _block('241528670', x: 0.55, y: 0.35),
        ],
      );

      final parsed = VisionPassportParser.parse(visionResult);

      expect(parsed.identityNo, 'C0161180');
      expect(parsed.legacyIdentityNo, '241528670');
      expect(parsed.fullName, 'LÊ THỊ MỸ LINH');
      expect(parsed.birthDate, '05/08/1996');
    });

    test('disambiguates passport number from 9-digit GCMND by position', () {
      final visionResult = TextRecognitionResult(
        fullText: '',
        confidence: 0.8,
        textBlocks: [
          _block('TRAN VAN A', y: 0.3),
          _block('241528670', x: 0.6, y: 0.35),
          _block('C0161180', x: 0.6, y: 0.18),
        ],
      );

      final parsed = VisionPassportParser.parse(visionResult);

      expect(parsed.identityNo, 'C0161180');
      expect(parsed.legacyIdentityNo, '241528670');
    });
  });
}
```

- [ ] **Bước 2: Chạy test — xác nhận FAIL**

```bash
flutter test test/utils/vision_passport_parser_test.dart -v
```

- [ ] **Bước 3a: Bổ sung helper vùng trong vision_text_layout.dart**

Thêm vào cuối class `VisionTextLayout`:

```dart
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
```

- [ ] **Bước 3b: Implement VisionPassportParser**

```dart
// lib/core/utils/vision_passport_parser.dart
import 'package:share_verify/core/models/ocr_result.dart';
import 'package:share_verify/core/services/ocr_service.dart';
import 'package:share_verify/core/utils/vision_confidence_scorer.dart';
import 'package:share_verify/core/utils/vision_text_layout.dart';
import 'package:vision_text_recognition/vision_text_recognition.dart';

class VisionPassportParser {
  VisionPassportParser._();

  static final _passportNoPattern = RegExp(r'\b([A-HJ-NP-Z])(\d{7,8})\b');
  static final _gcmndPattern = RegExp(r'\b\d{9}\b');

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

    final identityParsed = OcrService.parseRecognizedText(
      identityRegionText.isNotEmpty ? identityRegionText : fullText,
      docType: 'PASSPORT',
    );

    final fullName = identityParsed.fullName;
    final birthDate = identityParsed.birthDate;

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
```

- [ ] **Bước 4: Chạy test — xác nhận PASS**

```bash
flutter test test/utils/vision_passport_parser_test.dart -v
```

- [ ] **Bước 5: Commit**

```bash
git add lib/core/utils/vision_passport_parser.dart lib/core/utils/vision_text_layout.dart test/utils/vision_passport_parser_test.dart
git commit -m "feat(ocr): thêm VisionPassportParser với tách vùng số HC và GCMND"
```

---

### Task 5: AppleVisionOcrService (orchestrator)

**Files:**
- Create: `lib/core/services/apple_vision_ocr_service.dart`
- Test: `test/services/apple_vision_ocr_service_test.dart`

- [ ] **Bước 1: Viết test thất bại**

```dart
// test/services/apple_vision_ocr_service_test.dart
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:share_verify/core/services/apple_vision_ocr_service.dart';
import 'package:vision_text_recognition/vision_text_recognition.dart';

class _FakeVision implements AppleVisionRecognizer {
  final TextRecognitionResult result;

  _FakeVision(this.result);

  @override
  Future<TextRecognitionResult> recognize(Uint8List imageBytes) async => result;
}

void main() {
  group('AppleVisionOcrService', () {
    test('routes CCCD to VisionCccdParser', () async {
      final service = AppleVisionOcrService(
        recognizer: _FakeVision(TextRecognitionResult(
          fullText: 'Họ và tên: NGUYỄN VĂN A\n079090001234',
          textBlocks: [
            TextBlock(
              text: 'Họ và tên: NGUYỄN VĂN A',
              confidence: 0.9,
              boundingBox: const BoundingBox(x: 0.1, y: 0.2, width: 0.5, height: 0.05),
            ),
            TextBlock(
              text: '079090001234',
              confidence: 0.95,
              boundingBox: const BoundingBox(x: 0.1, y: 0.3, width: 0.4, height: 0.05),
            ),
          ],
          confidence: 0.9,
        )),
      );

      final parsed = await service.extractIdentity(
        Uint8List.fromList([1]),
        docType: 'CCCD',
      );

      expect(parsed.identityNo, '079090001234');
      expect(parsed.fullName, 'NGUYỄN VĂN A');
      expect(parsed.idConfidence, isNotNull);
    });

    test('routes PASSPORT to VisionPassportParser', () async {
      final service = AppleVisionOcrService(
        recognizer: _FakeVision(TextRecognitionResult(
          fullText: '',
          textBlocks: [
            TextBlock(
              text: 'C0161180',
              confidence: 0.9,
              boundingBox: const BoundingBox(x: 0.55, y: 0.18, width: 0.2, height: 0.04),
            ),
            TextBlock(
              text: 'LÊ THỊ MỸ LINH',
              confidence: 0.85,
              boundingBox: const BoundingBox(x: 0.1, y: 0.3, width: 0.4, height: 0.04),
            ),
          ],
          confidence: 0.88,
        )),
      );

      final parsed = await service.extractIdentity(
        Uint8List.fromList([1]),
        docType: 'PASSPORT',
      );

      expect(parsed.identityNo, 'C0161180');
      expect(parsed.fullName, 'LÊ THỊ MỸ LINH');
    });
  });
}
```

- [ ] **Bước 2: Chạy test — xác nhận FAIL**

```bash
flutter test test/services/apple_vision_ocr_service_test.dart -v
```

- [ ] **Bước 3: Implement tối thiểu**

```dart
// lib/core/services/apple_vision_ocr_service.dart
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
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
    if (!visionResult.hasText) return const OcrResult();

    return switch (docType.toUpperCase()) {
      'CCCD' => VisionCccdParser.parse(visionResult),
      'CMND' => VisionCmndParser.parse(visionResult),
      'PASSPORT' => VisionPassportParser.parse(visionResult),
      _ => VisionCccdParser.parse(visionResult),
    };
  }
}
```

- [ ] **Bước 4: Chạy test — xác nhận PASS**

```bash
flutter test test/services/apple_vision_ocr_service_test.dart -v
```

- [ ] **Bước 5: Commit**

```bash
git add lib/core/services/apple_vision_ocr_service.dart test/services/apple_vision_ocr_service_test.dart
git commit -m "feat(ocr): thêm AppleVisionOcrService điều phối parser theo loại giấy tờ"
```

---

### Task 6: Tích hợp vào OcrService

**Files:**
- Modify: `lib/core/services/ocr_service.dart`
- Modify: `test/services/ocr_service_test.dart`

- [ ] **Bước 1: Viết test thất bại — on-device trả confidence**

Thêm vào `test/services/ocr_service_test.dart`:

```dart
  group('extractIdentity Apple Vision fallback', () {
    test('uses injected vision service when remote disabled', () async {
      final appConfig = AppConfigService();
      await appConfig.load();
      await appConfig.saveUseRemoteOcr(false);

      final visionService = AppleVisionOcrService(
        recognizer: _FakeVisionForOcr(TextRecognitionResult(
          fullText: 'SỐ 174324001\nHọ tên: NGUYỄN HOÀI LINH',
          textBlocks: [
            TextBlock(
              text: 'SỐ 174324001',
              confidence: 0.91,
              boundingBox: const BoundingBox(x: 0.1, y: 0.2, width: 0.3, height: 0.04),
            ),
            TextBlock(
              text: 'Họ tên: NGUYỄN HOÀI LINH',
              confidence: 0.84,
              boundingBox: const BoundingBox(x: 0.1, y: 0.28, width: 0.5, height: 0.04),
            ),
          ],
          confidence: 0.87,
        )),
      );

      final service = OcrService(
        appConfig: appConfig,
        appleVision: visionService,
        recognizeText: (_, {required String docType}) async {
          throw StateError('ML Kit should not run when vision succeeds');
        },
      );

      final result = await service.extractIdentity(
        Uint8List.fromList([1, 2, 3]),
        docType: 'CMND',
      );

      expect(result.identityNo, '174324001');
      expect(result.fullName, 'NGUYỄN HOÀI LINH');
      expect(result.idConfidence, isNotNull);
      expect(result.nameConfidence, isNotNull);
    });
  });
```

(Cần thêm class `_FakeVisionForOcr` implements `AppleVisionRecognizer` trong cùng file test, import `apple_vision_ocr_service.dart`.)

- [ ] **Bước 2: Chạy test — xác nhận FAIL**

```bash
flutter test test/services/ocr_service_test.dart --name "uses injected vision service" -v
```

- [ ] **Bước 3: Refactor ocr_service.dart**

Thay `_extractIdentityWithAppleVision` bằng delegate:

```dart
// Thêm import
import 'package:share_verify/core/services/apple_vision_ocr_service.dart';

// Thêm field constructor
  AppleVisionOcrService? appleVision,

// Trong constructor initializer list:
        _appleVision = appleVision;

  final AppleVisionOcrService? _appleVision;

// Xóa _iosVisionConfig và _extractIdentityWithAppleVision, _recognizeWithAppleVision
// Thay extractIdentity iOS branch:

    if (!kIsWeb && Platform.isIOS) {
      try {
        final vision = _appleVision ?? AppleVisionOcrService();
        return await vision.extractIdentity(imageBytes, docType: docType);
      } catch (error) {
        debugPrint('Apple Vision OCR failed, falling back to ML Kit: $error');
        final text = await _recognizeWithMlKit(imageBytes);
        return parseRecognizedText(text, docType: docType);
      }
    }

// _recognizeText iOS branch — giữ ML Kit fallback, hoặc gọi vision rồi blocksToLines
```

- [ ] **Bước 4: Chạy toàn bộ test OCR**

```bash
flutter test test/services/ocr_service_test.dart test/services/apple_vision_ocr_service_test.dart test/utils/ -v
```

Kỳ vọng: All tests passed.

- [ ] **Bước 5: Commit**

```bash
git add lib/core/services/ocr_service.dart test/services/ocr_service_test.dart
git commit -m "refactor(ocr): delegate Apple Vision sang AppleVisionOcrService"
```

---

### Task 7: Kiểm tra thủ công trên iOS Simulator / thiết bị

**Files:** Không đổi code — chỉ xác minh end-to-end.

- [ ] **Bước 1: Tắt Remote OCR trong Settings**

Mở app → Cài đặt → tắt "OCR API (vietnam-ocr-api)".

- [ ] **Bước 2: Test CCCD**

Chụp/crop ảnh CCCD mẫu → màn hình review phải điền số 12 chữ số + họ tên. Nếu độ tin cậy < 0.65, hiện cảnh báo vàng.

- [ ] **Bước 3: Test CMND**

Chụp CMND (ảnh full, không crop) → số 9 chữ số + họ tên. Kiểm tra ngày sinh nếu có trên ảnh.

- [ ] **Bước 4: Test Passport**

Chụp trang thông tin hộ chiếu → số hộ chiếu (C + 7–8 số), trường CMND/CCCD phụ điền GCMND 9 số.

- [ ] **Bước 5: Test fallback ML Kit**

Tạm thời inject recognizer throw trong `AppleVisionOcrService` (hoặc dùng ảnh corrupt) → app vẫn parse được qua ML Kit, không crash.

---

### Task 8: Chạy toàn bộ test suite

- [ ] **Bước 1: Chạy flutter test**

```bash
cd /Users/sypham/projects/becamex/share_verify
flutter test -v
```

Kỳ vọng: 0 failures.

- [ ] **Bước 2: Chạy flutter analyze**

```bash
flutter analyze lib/core/services/apple_vision_ocr_service.dart lib/core/utils/vision_*.dart lib/core/services/ocr_service.dart
```

Kỳ vọng: No issues found.

- [ ] **Bước 3: Commit nếu có fix lint**

```bash
git add -A
git commit -m "chore(ocr): pass analyze và full test suite cho Apple Vision OCR"
```

---

## Tự kiểm tra kế hoạch

### 1. Phủ spec

| Yêu cầu | Task |
|---------|------|
| CCCD OCR | Task 2, 5, 6, 7 |
| CMND OCR | Task 3, 5, 6, 7 |
| Passport OCR | Task 4, 5, 6, 7 |
| Apple Vision integration | Task 5, 6 |
| Điểm tin cậy on-device | Task 1, 2–4 |
| Fallback khi API lỗi | Task 6 (giữ chuỗi hiện tại) |

### 2. Không có placeholder

Đã kiểm — mọi bước có code/test/lệnh cụ thể.

### 3. Nhất quán kiểu

- `OcrResult.identityNo` / `legacyIdentityNo` / `idConfidence` / `nameConfidence` dùng xuyên suốt.
- `docType` luôn `'CCCD' | 'CMND' | 'PASSPORT'`.
- `AppleVisionRecognizer` interface dùng cho test inject.

---

## Phạm vi ngoài (YAGNI)

- macOS Apple Vision — plugin chưa target macOS trong app hiện tại.
- Custom Swift `MethodChannel` — plugin `vision_text_recognition` đủ cho VNRecognizeTextRequest revision 3.
- Backend CCCD pipeline — vietnam-ocr-api vẫn dùng pipeline CMND; không đổi trong plan này.
- MRZ đọc từ dải machine-readable — có thể thêm sau nếu cần độ chính xác CCCD chip cao hơn.
