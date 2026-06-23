import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:share_verify/core/models/verification_step.dart';
import 'package:share_verify/core/screens/verification/components/verification_step_indicator.dart';

void main() {
  testWidgets('shows only current and completed steps as active', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            padding: EdgeInsets.all(20),
            child: VerificationStepIndicator(
              current: VerificationStep.evidence,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Bước 3/4'), findsOneWidget);
    expect(find.text('Chụp ảnh chứng cứ'), findsWidgets);
    expect(find.byIcon(Icons.check_rounded), findsNWidgets(2));
    expect(find.text('3'), findsOneWidget);
    expect(find.text('4'), findsOneWidget);
  });

  testWidgets('highlights current step number on first step', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: VerificationStepIndicator(
            current: VerificationStep.attendance,
          ),
        ),
      ),
    );

    expect(find.text('Bước 1/4'), findsOneWidget);
    expect(find.text('1'), findsOneWidget);
    expect(find.byIcon(Icons.check_rounded), findsNothing);
  });
}
