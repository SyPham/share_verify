import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:share_verify/core/data/sources/ocr_remote_source.dart';
import 'package:share_verify/core/services/apple_vision_ocr_service.dart';
import 'package:share_verify/core/models/ocr_result.dart';
import 'package:share_verify/core/services/app_config_service.dart';
import 'package:share_verify/core/utils/ocr_debug_log.dart';
import 'package:share_verify/core/utils/vision_text_layout.dart';

typedef OcrTextRecognizer = Future<String> Function(
  Uint8List imageBytes, {
  required String docType,
});

class OcrService {
  OcrService({
    OcrTextRecognizer? recognizeText,
    OcrRemoteSource? ocrRemote,
    AppConfigService? appConfig,
    AppleVisionOcrService? appleVision,
  })  : _recognizeTextOverride = recognizeText,
        _ocrRemote = ocrRemote,
        _appConfig = appConfig,
        _appleVision = appleVision;

  final OcrTextRecognizer? _recognizeTextOverride;
  final OcrRemoteSource? _ocrRemote;
  final AppConfigService? _appConfig;
  final AppleVisionOcrService? _appleVision;
  TextRecognizer? _textRecognizerInstance;


  Future<OcrResult> extractIdentity(
    Uint8List imageBytes, {
    required String docType,
  }) async {
    OcrDebugLog.started(
      docType: docType,
      imageBytes: imageBytes.length,
      remoteOcrEnabled: _appConfig?.useRemoteOcr.value,
      openAiOcrEnabled: _appConfig?.useOpenAiOcr.value,
    );

    final remote = await _tryRemoteOcr(imageBytes, docType: docType);
    if (remote != null) return remote;

    if (_appleVision != null || (!kIsWeb && Platform.isIOS)) {
      try {
        final vision = _appleVision ?? AppleVisionOcrService();
        return await vision.extractIdentity(imageBytes, docType: docType);
      } catch (error) {
        debugPrint('Apple Vision OCR failed, falling back to ML Kit: $error');
        final text = await _recognizeWithMlKit(imageBytes);
        OcrDebugLog.mlKitRaw(text);
        final parsed = parseRecognizedText(text, docType: docType).copyWith(
          rawText: text,
          ocrSource: 'ML Kit (fallback)',
        );
        OcrDebugLog.pipeline(
          source: 'ML Kit (fallback)',
          docType: docType,
          result: parsed,
          note: error.toString(),
        );
        return parsed;
      }
    }

    if (_recognizeTextOverride != null) {
      final text = await _recognizeText(imageBytes, docType: docType);
      final parsed = parseRecognizedText(text, docType: docType).copyWith(
        rawText: text,
        ocrSource: 'Local override',
      );
      OcrDebugLog.pipeline(
        source: 'Local override',
        docType: docType,
        result: parsed,
      );
      return parsed;
    }

    final text = await _recognizeText(imageBytes, docType: docType);
    OcrDebugLog.mlKitRaw(text);
    final parsed = parseRecognizedText(text, docType: docType).copyWith(
      rawText: text,
      ocrSource: 'ML Kit',
    );
    OcrDebugLog.pipeline(
      source: 'ML Kit',
      docType: docType,
      result: parsed,
    );
    return parsed;
  }

  Future<OcrResult?> _tryRemoteOcr(
    Uint8List imageBytes, {
    required String docType,
  }) async {
    final remote = _ocrRemote;
    final config = _appConfig;
    if (remote == null || config == null || !config.useRemoteOcr.value) {
      if (config != null && !config.useRemoteOcr.value) {
        OcrDebugLog.message(
          'OCR API disabled in Settings → on-device ($docType)',
        );
      }
      return null;
    }

    final doc = docType.toUpperCase();
    final useOpenAi =
        config.useOpenAiOcr.value && (doc == 'CMND' || doc == 'PASSPORT');
    final apiLabel = useOpenAi
        ? 'OpenAI OCR API (vietnam-ocr-api)'
        : 'OCR API (vietnam-ocr-api)';
    OcrDebugLog.message('Calling $apiLabel · $docType');

    try {
      final result = await remote.extractIdentity(imageBytes, docType: docType);
      if (result.hasIdentityNo || result.hasFullName) {
        OcrDebugLog.pipeline(
          source: result.ocrSource ?? apiLabel,
          docType: docType,
          result: result,
        );
        return result;
      }
      OcrDebugLog.message(
        'OCR API · $docType · empty result → trying on-device',
      );
    } catch (error) {
      OcrDebugLog.message('OCR API failed → on-device: $error');
    }
    return null;
  }


  Future<String?> extractIdNumber(
    Uint8List imageBytes, {
    required String docType,
  }) async {
    final result = await extractIdentity(imageBytes, docType: docType);
    return result.identityNo;
  }

  Future<String> _recognizeText(
    Uint8List imageBytes, {
    required String docType,
  }) async {
    final override = _recognizeTextOverride;
    if (override != null) {
      return override(imageBytes, docType: docType);
    }

    if (!kIsWeb && Platform.isIOS) {
      try {
        final recognizer = ResilientPluginAppleVisionRecognizer();
        final result = await recognizer.recognize(imageBytes);
        if (result.textBlocks.isNotEmpty) {
          return VisionTextLayout.blocksToLines(result.textBlocks);
        }
        return result.fullText;
      } catch (error) {
        debugPrint('Apple Vision OCR failed, falling back to ML Kit: $error');
        return _recognizeWithMlKit(imageBytes);
      }
    }

    return _recognizeWithMlKit(imageBytes);
  }


  Future<String> _recognizeWithMlKit(Uint8List imageBytes) async {
    final file = File(
      '${Directory.systemTemp.path}/sv_ocr_${DateTime.now().microsecondsSinceEpoch}.jpg',
    );

    try {
      await file.writeAsBytes(imageBytes, flush: true);
      final inputImage = InputImage.fromFilePath(file.path);
      final recognized = await _recognizer.processImage(inputImage);
      return recognized.text;
    } finally {
      if (await file.exists()) {
        await file.delete();
      }
    }
  }

  TextRecognizer get _recognizer {
    _textRecognizerInstance ??=
        TextRecognizer(script: TextRecognitionScript.latin);
    return _textRecognizerInstance!;
  }

  void dispose() {
    _textRecognizerInstance?.close();
    _textRecognizerInstance = null;
  }

  static OcrResult parseRecognizedText(
    String text, {
    required String docType,
  }) {
    final normalized = _normalizeOcrText(text);
    final identityNo = _extractIdentityNo(normalized, docType: docType);
    final fullName = _extractFullName(
      normalized,
      docType: docType,
      identityNo: identityNo,
    );

    return OcrResult(
      identityNo: identityNo,
      fullName: fullName,
      birthDate: _extractBirthDate(normalized, docType: docType),
      rawText: text.trim().isEmpty ? null : text,
    );
  }

  static String? _extractBirthDate(String text, {required String docType}) {
    final lines = _normalizedLines(text);

    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      final labeled = RegExp(
        r'(?:Sinh\s*ngày|Sinh\s*ngay|Ngày\s*sinh|Ngay\s*sinh|Date\s*of\s*birth)\s*[:\.]?\s*(.*)$',
        caseSensitive: false,
      ).firstMatch(line);

      if (labeled != null) {
        final inline = labeled.group(1)?.trim() ?? '';
        final inlineDate = _normalizeBirthDateToken(inline, docType: docType);
        if (inlineDate != null) return inlineDate;

        if (i + 1 < lines.length) {
          final nextDate =
              _normalizeBirthDateToken(lines[i + 1], docType: docType);
          if (nextDate != null) return nextDate;
        }
        continue;
      }

      if (_looksLikeBirthDateLine(line, docType: docType)) {
        final parsed = _normalizeBirthDateToken(line, docType: docType);
        if (parsed != null) return parsed;
      }
    }

    return null;
  }

  static bool _looksLikeBirthDateLine(String line, {required String docType}) {
    if (_normalizeId(line, docType: docType) != null) return false;
    return RegExp(r'\d{1,2}[/.-]\d{1,2}[/.-]\d{2,4}').hasMatch(line) ||
        RegExp(r'^\d{4}$').hasMatch(line.trim());
  }

  static String? _normalizeBirthDateToken(
    String value, {
    String? docType,
  }) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return null;

    if (RegExp(r'^\d{4}$').hasMatch(trimmed)) return trimmed;

    final match = RegExp(
      r'(\d{1,2})[/.-](\d{1,2})[/.-](\d{2,4})',
    ).firstMatch(trimmed);
    if (match == null) return null;

    if (docType?.toUpperCase() == 'CMND') {
      return _formatDdMmYyyy(
        match.group(1)!,
        match.group(2)!,
        match.group(3)!,
      );
    }

    return match.group(0);
  }

  static String _formatDdMmYyyy(String day, String month, String yearPart) {
    final d = int.parse(day);
    final m = int.parse(month);
    var y = int.parse(yearPart);
    if (y < 100) {
      y += y >= 50 ? 1900 : 2000;
    }
    return '${d.toString().padLeft(2, '0')}-'
        '${m.toString().padLeft(2, '0')}-'
        '$y';
  }

  static String? _extractIdentityNo(String text, {required String docType}) {
    if (docType.toUpperCase() == 'CMND') {
      return _extractCmndIdentityNo(text);
    }

    final labeled = _labeledValuePattern.firstMatch(text);
    if (labeled != null) {
      final value = _normalizeId(labeled.group(1)!, docType: docType);
      if (value != null) return value;
    }

    final patterns = _idPatternsFor(docType);
    for (final pattern in patterns) {
      for (final match in pattern.allMatches(text)) {
        final value = _normalizeId(match.group(0)!, docType: docType);
        if (value != null) return value;
      }
    }

    return null;
  }

  /// Cụm 9 chữ số CMND — ưu tiên khi quét toàn bộ text OCR.
  static final RegExp _cmndNineDigitCluster = RegExp(
    r'\b\d{3}[\s.\-]?\d{3}[\s.\-]?\d{3}\b',
  );

  static final RegExp _cmndNineDigits = RegExp(r'\b\d{9}\b');

  static String? _extractCmndIdentityNo(String text) {
    for (final pattern in [_cmndNineDigitCluster, _cmndNineDigits]) {
      for (final match in pattern.allMatches(text)) {
        final value = _normalizeId(match.group(0)!, docType: 'CMND');
        if (value != null) return value;
      }
    }

    final lines = _normalizedLines(text);

    // Layout CMND: "SỐ 174324001" trên cùng một dòng.
    for (final line in lines) {
      final inline = _cmndInlineNumberPattern.firstMatch(line);
      if (inline != null) {
        final value = _normalizeId(inline.group(1)!, docType: 'CMND');
        if (value != null) return value;
      }
    }

    // Nhãn "SỐ" một dòng, số CMND ở dòng kế tiếp.
    for (var i = 0; i < lines.length - 1; i++) {
      if (!_isCmndNumberLabel(lines[i])) continue;
      final value = _normalizeId(lines[i + 1], docType: 'CMND');
      if (value != null) return value;
    }

    for (var i = lines.length - 1; i >= 0; i--) {
      final value = _normalizeId(lines[i], docType: 'CMND');
      if (value != null) return value;
    }

    return null;
  }

  static final RegExp _cmndInlineNumberPattern = RegExp(
    r'^(?:Số\s*CMND|Số|So|SỐ|No\.?)\s*[:\s#]*(.+)',
    caseSensitive: false,
  );

  static final RegExp _labeledValuePattern = RegExp(
    r'(?:Số\s*CMND|Số|So|No\.?|Number|ID|CMND|CCCD|Passport)[:\s#]*([A-Z0-9][A-Z0-9\s.\-]{4,20})',
    caseSensitive: false,
  );

  static List<RegExp> _idPatternsFor(String docType) {
    switch (docType.toUpperCase()) {
      case 'PASSPORT':
        return [
          RegExp(r'\b[A-Z]{1,2}\d{6,9}\b'),
          RegExp(r'\b\d{8,9}\b'),
        ];
      case 'CMND':
        return [
          RegExp(r'\b\d{3}[\s.\-]?\d{3}[\s.\-]?\d{3}\b'),
          RegExp(r'\b\d{9}\b'),
        ];
      case 'CCCD':
      default:
        return [
          RegExp(r'\b\d{12}\b'),
          RegExp(r'\b\d{9}\b'),
        ];
    }
  }

  static String? _normalizeId(String raw, {required String docType}) {
    final compact = raw.replaceAll(RegExp(r'[\s\-]'), '').toUpperCase();
    if (compact.isEmpty) return null;

    switch (docType.toUpperCase()) {
      case 'PASSPORT':
        if (RegExp(r'^[A-Z]{1,2}\d{6,9}$').hasMatch(compact)) return compact;
        if (RegExp(r'^\d{8,9}$').hasMatch(compact)) return compact;
        return null;
      case 'CMND':
        final digitsOnly = compact.replaceAll(RegExp(r'[^0-9]'), '');
        if (RegExp(r'^\d{9}$').hasMatch(digitsOnly)) return digitsOnly;
        return null;
      case 'CCCD':
      default:
        if (RegExp(r'^\d{12}$').hasMatch(compact)) return compact;
        if (RegExp(r'^\d{9}$').hasMatch(compact)) return compact;
        return null;
    }
  }

  static String? _extractFullName(
    String text, {
    required String docType,
    String? identityNo,
  }) {
    if (docType.toUpperCase() == 'CMND') {
      return _extractCmndFullName(text, identityNo: identityNo);
    }

    return _extractGenericFullName(text, docType: docType);
  }

  static String? _extractCmndFullName(String text, {String? identityNo}) {
    final lines = _normalizedLines(text);

    // "Họ tên: NGUYỄN HOÀI LINH" / "Hộ tên:.NGUYỄN HOÀI LINH" (OCR hay nhầm Hộ).
    for (final line in lines) {
      final fromLine = _extractCmndNameFromLabeledLine(line);
      if (fromLine != null) return _formatDisplayName(fromLine);
    }

    for (final pattern in _cmndInlineNamePatterns) {
      final match = pattern.firstMatch(text);
      final raw = match?.group(1)?.trim();
      if (raw == null || raw.isEmpty) continue;
      final name = _cleanCmndCapturedName(raw);
      if (name != null) return name;
    }

    // CMND cũ: tên in TRÊN nhãn "Họ tên:" (PaddleOCR thường đọc layout này).
    for (var i = 1; i < lines.length; i++) {
      if (!_isCmndNameLabel(lines[i])) continue;
      final prevLine = _stripDateSuffix(lines[i - 1]);
      if (_isCmndNameValueLine(prevLine)) {
        return _formatDisplayName(prevLine);
      }
    }

    // Nhãn "Họ tên" một dòng, tên viết hoa ở dòng kế tiếp.
    for (var i = 0; i < lines.length - 1; i++) {
      if (!_isCmndNameLabel(lines[i])) continue;

      final merged = _tryMergeNameLines(lines, i + 1, stopAtNumberLabel: true);
      if (merged != null) return _formatDisplayName(merged);

      final nextLine = _stripDateSuffix(lines[i + 1]);
      if (_isCmndNameValueLine(nextLine)) {
        return _formatDisplayName(nextLine);
      }
    }

    final idLineIndex = _findCmndIdLineIndex(lines, identityNo);
    if (idLineIndex != null) {
      // Trên CMND thật, Họ tên nằm dưới dòng SỐ.
      for (var offset = 1; offset <= 3; offset++) {
        final idx = idLineIndex + offset;
        if (idx >= lines.length) break;

        final fromLine = _extractNameFromCmndLine(lines[idx]);
        if (fromLine != null) return _formatDisplayName(fromLine);

        final merged = _tryMergeNameLines(lines, idx);
        if (merged != null) return _formatDisplayName(merged);
      }

      final searchStart = (idLineIndex - 5).clamp(0, idLineIndex);
      String? bestMerged;
      var bestMergedScore = 0;

      for (var start = searchStart; start < idLineIndex; start++) {
        final merged = _tryMergeNameLines(lines, start);
        if (merged == null) continue;

        final score = _scoreCmndName(merged) + (idLineIndex - start);
        if (score > bestMergedScore) {
          bestMergedScore = score;
          bestMerged = merged;
        }
      }

      if (bestMerged != null) return _formatDisplayName(bestMerged);
    }

    return _bestCmndNameCandidate(lines);
  }

  static final List<RegExp> _cmndInlineNamePatterns = [
    RegExp(
      r'(?:Họ và tên|Họ tên|Hộ tên|Ho va ten|Họ, chữ đệm và tên khai sinh|Ho ten)\s*[:\s.]+(.+)$',
      caseSensitive: false,
    ),
    RegExp(
      r'(?:Full name|Name)\s*[:\s.]+(.+)$',
      caseSensitive: false,
    ),
  ];

  static String? _cleanCmndCapturedName(String raw) {
    var name = _sanitizeCapturedName(_stripDateSuffix(_cleanName(raw)));
    name = name.replaceAll(RegExp(r'\s*-\s*$'), '').trim();
    if (!_isPlausibleCmndName(name)) return null;
    return _formatDisplayName(name);
  }

  static String? _extractCmndNameFromLabeledLine(String line) {
    for (final pattern in _cmndInlineNamePatterns) {
      final match = pattern.firstMatch(line);
      final raw = match?.group(1)?.trim();
      if (raw == null || raw.isEmpty) continue;
      final name = _cleanCmndCapturedName(raw);
      if (name != null) return name;
    }
    return null;
  }

  static String? _extractNameFromCmndLine(String line) {
    final labeled = _extractCmndNameFromLabeledLine(line);
    if (labeled != null) return labeled;

    final single = _stripDateSuffix(line);
    return _isCmndNameValueLine(single) ? single : null;
  }

  static String? _extractGenericFullName(String text, {required String docType}) {
    final namePatterns = [
      RegExp(
        r'(?:Họ và tên|Họ tên|Ho va ten|Họ, chữ đệm và tên khai sinh|Full name|Name)[:\s]+(.+)',
        caseSensitive: false,
      ),
      if (docType.toUpperCase() == 'PASSPORT')
        RegExp(r'(?:Surname|Given names?)[:\s]+(.+)', caseSensitive: false),
    ];

    for (final pattern in namePatterns) {
      final match = pattern.firstMatch(text);
      final value = match?.group(1)?.trim();
      if (value != null && value.isNotEmpty && !_looksLikeNoise(value)) {
        return _formatDisplayName(value);
      }
    }

    final lines = _normalizedLines(text);
    for (final line in lines) {
      if (_looksLikeNoise(line)) continue;
      if (_containsLongDigitSequence(line)) continue;
      if (_looksLikeName(line)) {
        return _formatDisplayName(line);
      }
    }

    return null;
  }

  static List<String> _normalizedLines(String text) {
    return text
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();
  }

  static bool _isCmndNameLabel(String line) {
    final normalized = _normalizeCmndLabel(line);
    const labels = [
      'họ và tên',
      'ho va ten',
      'họ tên',
      'hộ tên',
      'ho ten',
      'họ, chữ đệm và tên khai sinh',
      'ho, chu dem va ten khai sinh',
      'full name',
      'name',
    ];
    return labels.contains(normalized);
  }

  static bool _isCmndNumberLabel(String line) {
    final normalized = _normalizeCmndLabel(line);
    const labels = [
      'số',
      'so',
      'số cmnd',
      'so cmnd',
      'no',
      'number',
    ];
    return labels.contains(normalized);
  }

  static String _normalizeCmndLabel(String line) {
    return line
        .toLowerCase()
        .replaceAll(RegExp(r'[:\s.]+$'), '')
        .trim();
  }

  static bool _isCmndNameValueLine(String line) {
    if (line.isEmpty) return false;
    if (_isCmndNameLabel(line) || _isCmndNumberLabel(line)) return false;
    if (_looksLikeNoise(line) || _containsDate(line)) return false;
    if (_containsLongDigitSequence(line)) return false;
    if (_isPlausibleCmndName(line)) return true;

    final words =
        line.split(RegExp(r'\s+')).where((word) => word.isNotEmpty).toList();
    if (words.length < 2 || words.length > 5) return false;

    return words.every(_isUppercaseNameWord);
  }

  static bool _isUppercaseNameWord(String word) {
    if (RegExp(r'\d').hasMatch(word)) return false;
    return RegExp(r'^[\p{Lu}\p{M}.\-]+$', unicode: true).hasMatch(word) ||
        RegExp(r'^[A-ZÀ-Ỹ.\-]+$').hasMatch(word);
  }

  static String? _tryMergeNameLines(
    List<String> lines,
    int start, {
    bool stopAtNumberLabel = false,
  }) {
    if (start < 0 || start >= lines.length) return null;

    final parts = <String>[];
    for (var i = start; i < lines.length && parts.length < 4; i++) {
      final line = _stripDateSuffix(lines[i]);
      if (line.isEmpty ||
          _looksLikeNoise(line) ||
          _containsDate(line) ||
          _containsLongDigitSequence(line) ||
          _isCmndNameLabel(line) ||
          (stopAtNumberLabel && _isCmndNumberLabel(line))) {
        break;
      }
      if (!_isNameFragment(line)) break;
      parts.add(line);

      final merged = parts.join(' ');
      final wordCount =
          merged.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;
      final hasNextFragment = _hasNextNameFragment(lines, i);

      if (_isPlausibleCmndName(merged) &&
          (wordCount >= 2 || !hasNextFragment)) {
        return merged;
      }
    }

    return null;
  }

  static bool _hasNextNameFragment(List<String> lines, int index) {
    if (index + 1 >= lines.length) return false;

    final next = _stripDateSuffix(lines[index + 1]);
    return next.isNotEmpty &&
        !_looksLikeNoise(next) &&
        !_containsDate(next) &&
        !_containsLongDigitSequence(next) &&
        !_isCmndNameLabel(next) &&
        _isNameFragment(next);
  }

  static int? _findCmndIdLineIndex(List<String> lines, String? identityNo) {
    if (identityNo != null) {
      for (var i = 0; i < lines.length; i++) {
        final normalized = _normalizeId(lines[i], docType: 'CMND');
        if (normalized == identityNo) return i;
      }
    }

    for (var i = 0; i < lines.length - 1; i++) {
      if (!_isCmndNumberLabel(lines[i])) continue;
      if (_normalizeId(lines[i + 1], docType: 'CMND') != null) return i + 1;
    }

    for (var i = lines.length - 1; i >= 0; i--) {
      if (_normalizeId(lines[i], docType: 'CMND') != null) return i;
    }
    return null;
  }

  static String? _bestCmndNameCandidate(List<String> lines) {
    String? best;
    var bestScore = 0;

    for (var i = 0; i < lines.length; i++) {
      final merged = _tryMergeNameLines(lines, i);
      if (merged != null) {
        final score = _scoreCmndName(merged) + 2;
        if (score > bestScore) {
          bestScore = score;
          best = merged;
        }
      }

      final single = _stripDateSuffix(lines[i]);
      if (_isPlausibleCmndName(single)) {
        final score = _scoreCmndName(single);
        if (score > bestScore) {
          bestScore = score;
          best = single;
        }
      }
    }

    return best == null ? null : _formatDisplayName(best);
  }

  static int _scoreCmndName(String value) {
    var score = 0;
    final words =
        value.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();

    if (words.length >= 2 && words.length <= 5) score += 4;
    if (words.length == 1) score -= 2;

    if (RegExp(r'^[A-Za-zÀ-ỹ\s.\-]+$').hasMatch(value)) score += 3;
    if (_isMostlyUppercaseName(value)) score += 3;

    final upper = value.toUpperCase();
    const particles = [
      'THỊ',
      'THI',
      'VĂN',
      'VAN',
      'VĂN',
      'HỮU',
      'HUU',
      'ĐỨC',
      'DUC',
      'MINH',
      'ANH',
      'LINH',
    ];
    for (final particle in particles) {
      if (upper.contains(particle)) score += 1;
    }

    if (_looksLikeNoise(value)) score -= 10;
    if (_containsDate(value)) score -= 8;
    if (_containsLongDigitSequence(value)) score -= 10;
    if (value.length > 40) score -= 5;

    return score;
  }

  static bool _isPlausibleCmndName(String value) {
    if (value.isEmpty || value.length < 3) return false;
    if (_looksLikeNoise(value)) return false;
    if (_containsDate(value)) return false;
    if (_containsLongDigitSequence(value)) return false;
    if (_isCmndNameLabel(value)) return false;

    final words =
        value.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    if (words.isEmpty || words.length > 6) return false;
    if (words.length == 1 && words.first.length < 4) return false;

    return _isValidNameWords(words, allowSingleLetterSuffix: true);
  }

  static bool _isNameFragment(String value) {
    final words =
        value.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    if (words.isEmpty || words.length > 3) return false;
    return _isValidNameWords(words, allowSingleLetterSuffix: true);
  }

  static bool _isValidNameWords(
    List<String> words, {
    required bool allowSingleLetterSuffix,
  }) {
    final longWords = words.where((w) => w.length >= 2).length;
    if (longWords == 0) return false;

    for (var i = 0; i < words.length; i++) {
      final word = words[i];
      if (RegExp(r'\d').hasMatch(word)) return false;
      if (!_isNameWordCharacters(word)) return false;

      final isLast = i == words.length - 1;
      if (word.length == 1 && !(allowSingleLetterSuffix && isLast)) {
        return false;
      }
    }

    return true;
  }

  static String _stripDateSuffix(String value) {
    return value
        .replaceAll(
          RegExp(r'\s+\d{1,2}[/.-]\d{1,2}[/.-]\d{2,4}.*$'),
          '',
        )
        .replaceAll(
          RegExp(
            r'^(?:Sinh ngày|Sinh ngay|Ngày sinh|Ngay sinh|Date of birth)[:\s]*',
            caseSensitive: false,
          ),
          '',
        )
        .trim();
  }

  static bool _containsDate(String value) =>
      RegExp(r'\d{1,2}[/.-]\d{1,2}[/.-]\d{2,4}').hasMatch(value);

  static bool _isMostlyUppercaseName(String value) {
    final letters = value.replaceAll(RegExp(r'[^A-Za-zÀ-ỹ]'), '');
    if (letters.isEmpty) return false;
    final uppercaseCount =
        letters.split('').where((char) => char == char.toUpperCase()).length;
    return uppercaseCount >= letters.length * 0.8;
  }

  static String _normalizeOcrText(String text) {
    return text.replaceAll('\r', '').replaceAll(RegExp(r'[·…]'), '.');
  }

  static String _sanitizeCapturedName(String value) {
    return value
        .replaceAll(RegExp(r'^[.\s\-_]+'), '')
        .replaceAll(RegExp(r'[.\s\-_]+$'), '')
        .trim();
  }

  static bool _isNameWordCharacters(String word) {
    return RegExp(r'^[\p{L}\p{M}.\-]+$', unicode: true).hasMatch(word) ||
        RegExp(r'^[A-Za-zÀ-ỹ.\-]+$').hasMatch(word);
  }

  static String _formatDisplayName(String value) {
    return _sanitizeCapturedName(_cleanName(value));
  }

  static bool _looksLikeNoise(String value) {
    final lower = value.toLowerCase();
    const noise = [
      'căn cước',
      'can cuoc',
      'công dân',
      'cong dan',
      'chứng minh',
      'chung minh',
      'nhân dân',
      'nhan dan',
      'cộng hòa',
      'cong hoa',
      'xa hoi',
      'xã hội',
      'chu nghia',
      'chủ nghĩa',
      'doc lap',
      'độc lập',
      'tu do',
      'tự do',
      'hanh phuc',
      'hạnh phúc',
      'passport',
      'việt nam',
      'viet nam',
      'socialist',
      'republic',
      'cmnd',
      'cccd',
      'đặc điểm',
      'dac diem',
      'ngày sinh',
      'ngay sinh',
      'sinh ngày',
      'sinh ngay',
      'quốc tịch',
      'quoc tich',
      'cục cảnh',
      'cuc canh',
      'cư trú',
      'cu tru',
      'qlhc',
      'independence',
      'freedom',
      'happiness',
    ];
    return noise.any(lower.contains);
  }

  static bool _containsLongDigitSequence(String value) =>
      RegExp(r'\d{6,}').hasMatch(value);

  static bool _looksLikeName(String value) {
    if (value.length < 3) return false;
    if (!RegExp(r'[A-Za-zÀ-ỹ]').hasMatch(value)) return false;
    final letters = RegExp(r'[A-Za-zÀ-ỹ]').allMatches(value).length;
    return letters >= value.replaceAll(RegExp(r'\s'), '').length * 0.6;
  }

  static String _cleanName(String value) {
    final singleLine = value.split('\n').first.trim();
    return singleLine.replaceAll(RegExp(r'\s{2,}'), ' ');
  }
}
