class DashboardSummaryDto {
  final int totalShareholders;
  final int receivedCount;
  final int notReceivedCount;
  final double completionRate;

  const DashboardSummaryDto({
    required this.totalShareholders,
    required this.receivedCount,
    required this.notReceivedCount,
    required this.completionRate,
  });

  factory DashboardSummaryDto.fromJson(Map<String, dynamic> json) {
    return DashboardSummaryDto(
      totalShareholders: _readInt(json['totalShareholders']),
      receivedCount: _readInt(json['receivedCount']),
      notReceivedCount: _readInt(json['notReceivedCount']),
      completionRate: _readDouble(json['completionRate']),
    );
  }

  static int _readInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return 0;
  }

  static double _readDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return 0;
  }
}
