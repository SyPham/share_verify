class DashboardFormat {
  DashboardFormat._();

  /// Nhãn % cho card tiến độ chi trả.
  static String completionPercentLabel(double fraction) {
    final percent = fraction * 100;
    if (percent <= 0) return '0%';
    if (percent < 1) return '${percent.toStringAsFixed(2)}%';
    if (percent < 10) return '${percent.toStringAsFixed(1)}%';
    return '${percent.round()}%';
  }

  /// Giá trị tối thiểu cho vòng tròn khi tiến độ > 0 nhưng rất nhỏ.
  static double completionRingValue(double fraction) {
    if (fraction <= 0) return 0;
    if (fraction < 0.01) return 0.01;
    return fraction;
  }
}
