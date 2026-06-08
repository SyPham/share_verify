class DashboardStats {
  final int totalShareholders;
  final int receivedCount;
  final int notReceivedCount;

  const DashboardStats({
    required this.totalShareholders,
    required this.receivedCount,
    required this.notReceivedCount,
  });

  double get completionPercent =>
      totalShareholders == 0 ? 0 : receivedCount / totalShareholders;
}
