class DashboardStats {
  final int totalShareholders;
  final int receivedCount;
  final int notReceivedCount;

  /// Phần trăm hoàn thành 0–100 từ API (`completionRate`).
  final double completionRatePercent;

  const DashboardStats({
    required this.totalShareholders,
    required this.receivedCount,
    required this.notReceivedCount,
    this.completionRatePercent = 0,
  });

  /// Tiến độ 0–1 cho progress ring / KPI bar.
  double get completionFraction {
    if (completionRatePercent > 0) {
      return (completionRatePercent / 100).clamp(0.0, 1.0);
    }
    if (totalShareholders == 0) return 0;
    return receivedCount / totalShareholders;
  }
}
