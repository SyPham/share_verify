class OpenAiUsageInfo {
  final String model;
  final int promptTokens;
  final int completionTokens;
  final int totalTokens;
  final double? inputPricePer1M;
  final double? outputPricePer1M;
  final double costUsd;
  final double? costVnd;
  final double? usdToVnd;

  const OpenAiUsageInfo({
    required this.model,
    this.promptTokens = 0,
    this.completionTokens = 0,
    this.totalTokens = 0,
    this.inputPricePer1M,
    this.outputPricePer1M,
    this.costUsd = 0,
    this.costVnd,
    this.usdToVnd,
  });

  factory OpenAiUsageInfo.fromJson(Map<String, dynamic> json) {
    return OpenAiUsageInfo(
      model: json['model']?.toString() ?? '',
      promptTokens: _parseInt(json['promptTokens']),
      completionTokens: _parseInt(json['completionTokens']),
      totalTokens: _parseInt(json['totalTokens']),
      inputPricePer1M: _parseDouble(json['inputPricePer1M']),
      outputPricePer1M: _parseDouble(json['outputPricePer1M']),
      costUsd: _parseDouble(json['costUsd']) ?? 0,
      costVnd: _parseDouble(json['costVnd']),
      usdToVnd: _parseDouble(json['usdToVnd']),
    );
  }

  String get displayLabel {
    final vnd = costVnd;
    if (vnd != null && vnd > 0) {
      return '${_formatUsd(costUsd)} · ${_formatVnd(vnd)}';
    }
    return _formatUsd(costUsd);
  }

  static int parseInt(dynamic value) => _parseInt(value);

  static double? parseDouble(dynamic value) => _parseDouble(value);

  static int _parseInt(dynamic value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }

  static String _formatUsd(double value) {
    if (value >= 0.01) return '\$${value.toStringAsFixed(4)}';
    return '\$${value.toStringAsFixed(6)}';
  }

  static String _formatVnd(double value) {
    final rounded = value.round();
    final text = rounded.toString().replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (match) => '${match[1]}.',
    );
    return '$text đ';
  }
}

class OpenAiPricingModelInfo {
  final String model;
  final double inputPer1M;
  final double outputPer1M;
  final String description;

  const OpenAiPricingModelInfo({
    required this.model,
    required this.inputPer1M,
    required this.outputPer1M,
    this.description = '',
  });

  factory OpenAiPricingModelInfo.fromJson(Map<String, dynamic> json) {
    return OpenAiPricingModelInfo(
      model: json['model']?.toString() ?? '',
      inputPer1M: OpenAiUsageInfo._parseDouble(json['inputPer1M']) ?? 0,
      outputPer1M: OpenAiUsageInfo._parseDouble(json['outputPer1M']) ?? 0,
      description: json['description']?.toString() ?? '',
    );
  }
}

class OpenAiPricingInfo {
  final String currency;
  final double usdToVnd;
  final List<OpenAiPricingModelInfo> models;

  const OpenAiPricingInfo({
    required this.currency,
    required this.usdToVnd,
    required this.models,
  });

  factory OpenAiPricingInfo.fromJson(Map<String, dynamic> json) {
    final rawModels = json['models'];
    return OpenAiPricingInfo(
      currency: json['currency']?.toString() ?? 'USD',
      usdToVnd: OpenAiUsageInfo._parseDouble(json['usdToVnd']) ?? 0,
      models: rawModels is List
          ? rawModels
              .whereType<Map>()
              .map((item) => OpenAiPricingModelInfo.fromJson(
                    Map<String, dynamic>.from(item),
                  ))
              .toList()
          : const [],
    );
  }
}
