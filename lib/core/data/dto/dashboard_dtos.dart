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
      totalShareholders: json['totalShareholders'] as int? ?? 0,
      receivedCount: json['receivedCount'] as int? ?? 0,
      notReceivedCount: json['notReceivedCount'] as int? ?? 0,
      completionRate: (json['completionRate'] as num?)?.toDouble() ?? 0,
    );
  }
}
