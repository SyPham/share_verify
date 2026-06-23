import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:share_verify/core/controllers/verification_controller.dart';
import 'package:share_verify/core/data/dto/travel_support_dtos.dart';
import 'package:share_verify/core/repositories/shareholder_repository.dart';
import '../support/fake_repositories.dart';
import 'package:share_verify/core/models/verification_step.dart';
import 'package:share_verify/core/screens/verification/components/verification_identity_usage_dialog.dart';
import 'package:share_verify/core/services/barcode_scanner_service.dart';
import '../support/fake_repositories.dart';

void main() {
  setUp(() => Get.testMode = true);
  tearDown(Get.reset);

  testWidgets('OK on identity usage dialog advances to evidence step', (tester) async {
    final c = VerificationController(
      shareholderRepository: FakeShareholderRepository(),
      travelSupportRepository: FakeTravelSupportRepository(),
      barcodeScannerService: BarcodeScannerService(),
    );
    Get.put(FakeShareholderRepository());
    Get.put(c);

    c.verificationStep.value = VerificationStep.identity;
    c.manualNameController.text = 'Nguyễn Văn A';
    c.manualIdController.text = '001234567890';
    c.identityCheckResult.value = const IdentityCheckResultDto(
      alreadyUsed: true,
      usedForMcds: ['MCD001'],
      usedForShareholders: [
        IdentityCheckUsedShareholderDto(
          mcd: 'MCD001',
          fullName: 'Nguyễn Văn A',
          shares: 1000,
        ),
      ],
      message: 'Người này đã nhận phụ cấp trước đó.',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            return Scaffold(
              body: ElevatedButton(
                onPressed: () async {
                  final accepted = await VerificationIdentityUsageDialog.show(
                    context,
                    check: c.identityCheckResult.value!,
                  );
                  if (accepted) {
                    c.advanceToEvidenceStep(force: true);
                  }
                },
                child: const Text('Show'),
              ),
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('Show'));
    await tester.pumpAndSettle();

    expect(find.text('Giấy tờ đã được sử dụng'), findsOneWidget);
    expect(find.text('MCD001'), findsOneWidget);
    expect(find.text('Nguyễn Văn A'), findsOneWidget);
    expect(find.text('1000 CP'), findsOneWidget);

    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    expect(c.verificationStep.value, VerificationStep.evidence);
  });
}
