// ignore_for_file: avoid_print

import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:share_verify/core/models/ocr_result.dart';
import 'package:share_verify/core/utils/vision_text_layout.dart';
import 'package:vision_text_recognition/vision_text_recognition.dart';

/// Log OCR pipeline — hiện trong terminal `flutter run`, Xcode console, DevTools.
///
/// Bật khi không phải release build (debug + profile).
class OcrDebugLog {
  OcrDebugLog._();

  static bool _announced = false;

  static bool get enabled => !kReleaseMode;

  static void _emit(String message) {
    if (!enabled) return;

    if (!_announced) {
      _announced = true;
      const banner =
          '════════ ShareVerify OCR logging ON (debug/profile) ════════';
      print(banner);
      developer.log(banner, name: 'ShareVerify.OCR');
    }

    print(message);
    developer.log(message, name: 'ShareVerify.OCR');
  }

  static void started({
    required String docType,
    required int imageBytes,
    bool? remoteOcrEnabled,
    bool? openAiOcrEnabled,
  }) {
    if (!enabled) return;
    final remote = remoteOcrEnabled == null
        ? ''
        : ' · remoteOcr=${remoteOcrEnabled ? 'ON' : 'OFF'}';
    final openAi = openAiOcrEnabled == null
        ? ''
        : ' · openAiOcr=${openAiOcrEnabled ? 'ON' : 'OFF'}';
    _emit(
      '[ShareVerify OCR] ▶ extractIdentity($docType) · ${imageBytes ~/ 1024}KB$remote$openAi',
    );
  }

  static void message(String text) => _emit('[ShareVerify OCR] $text');

  static void pipeline({
    required String source,
    required String docType,
    required OcrResult result,
    String? note,
  }) {
    if (!enabled) return;

    final buffer = StringBuffer()
      ..writeln('[ShareVerify OCR] ── $source · $docType ──');

    if (note != null && note.isNotEmpty) {
      buffer.writeln('  note: $note');
    }

    buffer
      ..writeln('  identityNo: ${result.identityNo ?? '—'}')
      ..writeln('  fullName: ${result.fullName ?? '—'}')
      ..writeln('  birthDate: ${result.birthDate ?? '—'}');

    if (result.legacyIdentityNo != null && result.legacyIdentityNo!.isNotEmpty) {
      buffer.writeln('  legacyIdentityNo: ${result.legacyIdentityNo}');
    }

    buffer
      ..writeln(
        '  idConfidence: ${_formatConfidence(result.idConfidence)}',
      )
      ..writeln(
        '  nameConfidence: ${_formatConfidence(result.nameConfidence)}',
      );

    final usage = result.openAiUsage;
    if (usage != null) {
      buffer.writeln(
        '  openAiCost: ${usage.displayLabel} · ${usage.totalTokens} tokens (${usage.model})',
      );
    }

    _emit(buffer.toString().trimRight());
  }

  static void visionRaw(TextRecognitionResult result) {
    if (!enabled) return;

    _emit(
      '[ShareVerify OCR] Apple Vision raw · ${result.textBlocks.length} blocks · '
      'avg ${result.confidence.toStringAsFixed(2)}',
    );

    for (final block in result.blocksSortedByPosition) {
      final box = block.boundingBox;
      _emit(
        '  [${block.confidence.toStringAsFixed(2)}] '
        'y=${box.y.toStringAsFixed(2)} '
        '"${block.text}"',
      );
    }

    final lines = VisionTextLayout.blocksToLines(result.textBlocks);
    if (lines.isNotEmpty) {
      _emit('[ShareVerify OCR] Layout lines:\n$lines');
    }
  }

  static void mlKitRaw(String text) {
    if (!enabled) return;
    if (text.trim().isEmpty) {
      _emit('[ShareVerify OCR] ML Kit raw: (empty)');
      return;
    }
    _emit('[ShareVerify OCR] ML Kit raw:\n$text');
  }

  static String _formatConfidence(double? value) {
    if (value == null) return '—';
    return value.toStringAsFixed(2);
  }
}
