import 'package:share_verify/core/models/open_ai_usage_info.dart';

class OpenAiStatsSummary {
  final int requestCount;
  final int totalPromptTokens;
  final int totalCompletionTokens;
  final int totalTokens;
  final double totalCostUsd;
  final double totalCostVnd;
  final double usdToVnd;

  const OpenAiStatsSummary({
    this.requestCount = 0,
    this.totalPromptTokens = 0,
    this.totalCompletionTokens = 0,
    this.totalTokens = 0,
    this.totalCostUsd = 0,
    this.totalCostVnd = 0,
    this.usdToVnd = 0,
  });

  factory OpenAiStatsSummary.fromJson(Map<String, dynamic> json) {
    return OpenAiStatsSummary(
      requestCount: OpenAiUsageInfo.parseInt(json['requestCount']),
      totalPromptTokens: OpenAiUsageInfo.parseInt(json['totalPromptTokens']),
      totalCompletionTokens:
          OpenAiUsageInfo.parseInt(json['totalCompletionTokens']),
      totalTokens: OpenAiUsageInfo.parseInt(json['totalTokens']),
      totalCostUsd: OpenAiUsageInfo.parseDouble(json['totalCostUsd']) ?? 0,
      totalCostVnd: OpenAiUsageInfo.parseDouble(json['totalCostVnd']) ?? 0,
      usdToVnd: OpenAiUsageInfo.parseDouble(json['usdToVnd']) ?? 0,
    );
  }

  String get costLabel => _formatCost(totalCostUsd, totalCostVnd);
}

class OpenAiStatsModelBreakdown {
  final String model;
  final int requestCount;
  final int totalTokens;
  final double totalCostUsd;
  final double totalCostVnd;

  const OpenAiStatsModelBreakdown({
    required this.model,
    this.requestCount = 0,
    this.totalTokens = 0,
    this.totalCostUsd = 0,
    this.totalCostVnd = 0,
  });

  factory OpenAiStatsModelBreakdown.fromJson(Map<String, dynamic> json) {
    return OpenAiStatsModelBreakdown(
      model: json['model']?.toString() ?? '',
      requestCount: OpenAiUsageInfo.parseInt(json['requestCount']),
      totalTokens: OpenAiUsageInfo.parseInt(json['totalTokens']),
      totalCostUsd: OpenAiUsageInfo.parseDouble(json['totalCostUsd']) ?? 0,
      totalCostVnd: OpenAiUsageInfo.parseDouble(json['totalCostVnd']) ?? 0,
    );
  }
}

class OpenAiStatsRecentEntry {
  final String? savedAt;
  final String model;
  final int promptTokens;
  final int completionTokens;
  final int totalTokens;
  final double costUsd;
  final double? costVnd;
  final String? idNumber;
  final String? fullName;

  const OpenAiStatsRecentEntry({
    this.savedAt,
    required this.model,
    this.promptTokens = 0,
    this.completionTokens = 0,
    this.totalTokens = 0,
    this.costUsd = 0,
    this.costVnd,
    this.idNumber,
    this.fullName,
  });

  factory OpenAiStatsRecentEntry.fromJson(Map<String, dynamic> json) {
    return OpenAiStatsRecentEntry(
      savedAt: json['savedAt']?.toString(),
      model: json['model']?.toString() ?? '',
      promptTokens: OpenAiUsageInfo.parseInt(json['promptTokens']),
      completionTokens: OpenAiUsageInfo.parseInt(json['completionTokens']),
      totalTokens: OpenAiUsageInfo.parseInt(json['totalTokens']),
      costUsd: OpenAiUsageInfo.parseDouble(json['costUsd']) ?? 0,
      costVnd: OpenAiUsageInfo.parseDouble(json['costVnd']),
      idNumber: json['idNumber']?.toString(),
      fullName: json['fullName']?.toString(),
    );
  }

  String get costLabel => _formatCost(costUsd, costVnd ?? 0);
}

class OpenAiStatsInfo {
  final String source;
  final OpenAiStatsSummary summary;
  final List<OpenAiStatsModelBreakdown> byModel;
  final List<OpenAiStatsRecentEntry> recent;

  const OpenAiStatsInfo({
    required this.source,
    required this.summary,
    this.byModel = const [],
    this.recent = const [],
  });

  factory OpenAiStatsInfo.fromJson(Map<String, dynamic> json) {
    final rawByModel = json['byModel'];
    final rawRecent = json['recent'];
    return OpenAiStatsInfo(
      source: json['source']?.toString() ?? 'server',
      summary: OpenAiStatsSummary.fromJson(
        Map<String, dynamic>.from(json['summary'] as Map? ?? const {}),
      ),
      byModel: rawByModel is List
          ? rawByModel
              .whereType<Map>()
              .map((item) => OpenAiStatsModelBreakdown.fromJson(
                    Map<String, dynamic>.from(item),
                  ))
              .toList()
          : const [],
      recent: rawRecent is List
          ? rawRecent
              .whereType<Map>()
              .map((item) => OpenAiStatsRecentEntry.fromJson(
                    Map<String, dynamic>.from(item),
                  ))
              .toList()
          : const [],
    );
  }
}

class OpenAiUsageRecord {
  final String recordedAt;
  final String model;
  final String docType;
  final int promptTokens;
  final int completionTokens;
  final int totalTokens;
  final double costUsd;
  final double? costVnd;
  final String? identityNo;
  final String? fullName;

  const OpenAiUsageRecord({
    required this.recordedAt,
    required this.model,
    required this.docType,
    this.promptTokens = 0,
    this.completionTokens = 0,
    this.totalTokens = 0,
    this.costUsd = 0,
    this.costVnd,
    this.identityNo,
    this.fullName,
  });

  factory OpenAiUsageRecord.fromJson(Map<String, dynamic> json) {
    return OpenAiUsageRecord(
      recordedAt: json['recordedAt']?.toString() ?? '',
      model: json['model']?.toString() ?? '',
      docType: json['docType']?.toString() ?? 'CMND',
      promptTokens: OpenAiUsageInfo.parseInt(json['promptTokens']),
      completionTokens: OpenAiUsageInfo.parseInt(json['completionTokens']),
      totalTokens: OpenAiUsageInfo.parseInt(json['totalTokens']),
      costUsd: OpenAiUsageInfo.parseDouble(json['costUsd']) ?? 0,
      costVnd: OpenAiUsageInfo.parseDouble(json['costVnd']),
      identityNo: json['identityNo']?.toString(),
      fullName: json['fullName']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'recordedAt': recordedAt,
        'model': model,
        'docType': docType,
        'promptTokens': promptTokens,
        'completionTokens': completionTokens,
        'totalTokens': totalTokens,
        'costUsd': costUsd,
        if (costVnd != null) 'costVnd': costVnd,
        if (identityNo != null) 'identityNo': identityNo,
        if (fullName != null) 'fullName': fullName,
      };

  factory OpenAiUsageRecord.fromUsage({
    required OpenAiUsageInfo usage,
    required String docType,
    String? identityNo,
    String? fullName,
    DateTime? recordedAt,
  }) {
    return OpenAiUsageRecord(
      recordedAt: (recordedAt ?? DateTime.now()).toIso8601String(),
      model: usage.model,
      docType: docType,
      promptTokens: usage.promptTokens,
      completionTokens: usage.completionTokens,
      totalTokens: usage.totalTokens,
      costUsd: usage.costUsd,
      costVnd: usage.costVnd,
      identityNo: identityNo,
      fullName: fullName,
    );
  }

  OpenAiStatsRecentEntry toRecentEntry() {
    return OpenAiStatsRecentEntry(
      savedAt: recordedAt,
      model: model,
      promptTokens: promptTokens,
      completionTokens: completionTokens,
      totalTokens: totalTokens,
      costUsd: costUsd,
      costVnd: costVnd,
      idNumber: identityNo,
      fullName: fullName,
    );
  }
}

OpenAiStatsInfo buildLocalOpenAiStats(List<OpenAiUsageRecord> records) {
  final byModel = <String, OpenAiStatsModelBreakdown>{};
  var totalPrompt = 0;
  var totalCompletion = 0;
  var totalCostUsd = 0.0;
  var totalCostVnd = 0.0;
  var usdToVnd = 0.0;

  for (final record in records) {
    totalPrompt += record.promptTokens;
    totalCompletion += record.completionTokens;
    totalCostUsd += record.costUsd;
    totalCostVnd += record.costVnd ?? 0;

    final bucket = byModel.putIfAbsent(
      record.model,
      () => OpenAiStatsModelBreakdown(model: record.model),
    );
    byModel[record.model] = OpenAiStatsModelBreakdown(
      model: record.model,
      requestCount: bucket.requestCount + 1,
      totalTokens: bucket.totalTokens + record.totalTokens,
      totalCostUsd: bucket.totalCostUsd + record.costUsd,
      totalCostVnd: bucket.totalCostVnd + (record.costVnd ?? 0),
    );
  }

  if (records.isNotEmpty && totalCostUsd > 0 && totalCostVnd > 0) {
    usdToVnd = totalCostVnd / totalCostUsd;
  }

  final recent = records
      .map((record) => record.toRecentEntry())
      .toList(growable: false);

  return OpenAiStatsInfo(
    source: 'device',
    summary: OpenAiStatsSummary(
      requestCount: records.length,
      totalPromptTokens: totalPrompt,
      totalCompletionTokens: totalCompletion,
      totalTokens: totalPrompt + totalCompletion,
      totalCostUsd: totalCostUsd,
      totalCostVnd: totalCostVnd,
      usdToVnd: usdToVnd,
    ),
    byModel: byModel.values.toList()
      ..sort((a, b) => b.totalCostUsd.compareTo(a.totalCostUsd)),
    recent: recent,
  );
}

String _formatCost(double usd, double vnd) {
  final usdText = usd >= 0.01
      ? '\$${usd.toStringAsFixed(4)}'
      : '\$${usd.toStringAsFixed(6)}';
  if (vnd > 0) {
    final rounded = vnd.round();
    final text = rounded.toString().replaceAllMapped(
          RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
          (match) => '${match[1]}.',
        );
    return '$usdText · $text đ';
  }
  return usdText;
}
