import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_verify/core/models/open_ai_stats.dart';
import 'package:share_verify/core/models/open_ai_usage_info.dart';

class OpenAiUsageStore {
  static const _prefsKey = 'openai_usage_records';
  static const _maxRecords = 200;

  Future<List<OpenAiUsageRecord>> loadRecords() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw == null || raw.isEmpty) return const [];

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      return decoded
          .whereType<Map>()
          .map((item) => OpenAiUsageRecord.fromJson(
                Map<String, dynamic>.from(item),
              ))
          .toList();
    } catch (_) {
      return const [];
    }
  }

  Future<void> addRecord(OpenAiUsageRecord record) async {
    final records = await loadRecords();
    final updated = [record, ...records];
    final trimmed = updated.length > _maxRecords
        ? updated.sublist(0, _maxRecords)
        : updated;
    await _save(trimmed);
  }

  Future<void> addUsage({
    required OpenAiUsageInfo usage,
    required String docType,
    String? identityNo,
    String? fullName,
  }) async {
    await addRecord(
      OpenAiUsageRecord.fromUsage(
        usage: usage,
        docType: docType,
        identityNo: identityNo,
        fullName: fullName,
      ),
    );
  }

  Future<OpenAiStatsInfo> loadLocalStats() async {
    final records = await loadRecords();
    return buildLocalOpenAiStats(records);
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefsKey);
  }

  Future<void> _save(List<OpenAiUsageRecord> records) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(records.map((item) => item.toJson()).toList());
    await prefs.setString(_prefsKey, encoded);
  }
}
