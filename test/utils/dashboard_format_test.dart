import 'package:flutter_test/flutter_test.dart';
import 'package:share_verify/core/utils/dashboard_format.dart';

void main() {
  test('completionPercentLabel formats small and large values', () {
    expect(DashboardFormat.completionPercentLabel(0), '0%');
    expect(DashboardFormat.completionPercentLabel(0.0004), '0.04%');
    expect(DashboardFormat.completionPercentLabel(0.37), '37%');
    expect(DashboardFormat.completionPercentLabel(0.085), '8.5%');
  });

  test('completionRingValue keeps tiny progress visible', () {
    expect(DashboardFormat.completionRingValue(0), 0);
    expect(DashboardFormat.completionRingValue(0.0004), 0.01);
    expect(DashboardFormat.completionRingValue(0.37), 0.37);
  });
}
