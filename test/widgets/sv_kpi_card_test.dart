import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:share_verify/core/commons/palette.dart';
import 'package:share_verify/core/widgets/sv_kpi_card.dart';

void main() {
  testWidgets('shows KPI label and value', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SvKpiCard(
            label: 'Đã nhận hỗ trợ',
            value: '450',
            backgroundColor: SvPalette.tertiaryContainer,
            foregroundColor: SvPalette.onTertiary,
            progress: 0.375,
            icon: Icons.check_circle,
          ),
        ),
      ),
    );
    expect(find.text('Đã nhận hỗ trợ'), findsOneWidget);
    expect(find.text('450'), findsOneWidget);
  });
}
