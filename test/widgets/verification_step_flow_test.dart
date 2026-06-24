import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:share_verify/core/controllers/verification_controller.dart';
import 'package:share_verify/core/models/attendance_type.dart';
import 'package:share_verify/core/models/verification_step.dart';
import 'package:share_verify/core/screens/verification/components/verification_step_navigation_controls.dart';
import 'package:share_verify/core/screens/verification/verification_screen.dart';
import 'package:share_verify/core/services/app_config_service.dart';
import 'package:share_verify/core/services/barcode_scanner_service.dart';
import 'package:share_verify/core/widgets/sv_primary_button.dart';
import '../support/fake_repositories.dart';
import '../support/pump_app.dart';

void main() {
  setUp(() {
    Get.testMode = true;
    Get.put(AppConfigService());
    Get.put(VerificationController(
      shareholderRepository: FakeShareholderRepository(),
      travelSupportRepository: FakeTravelSupportRepository(),
      barcodeScannerService: BarcodeScannerService(),
    ));
  });
  tearDown(Get.reset);

  testWidgets('step 2 identity actions fit on narrow screens', (tester) async {
    final c = Get.find<VerificationController>();
    c.advanceToIdentityStep();

    for (final width in [320.0, 360.0]) {
      await tester.binding.setSurfaceSize(Size(width, 640));
      await pumpApp(tester, const VerificationScreen());
      await tester.pumpAndSettle(const Duration(milliseconds: 500));
      expect(tester.takeException(), isNull);
      expect(find.text('Quét QR CCCD'), findsOneWidget);
      expect(find.text('Chụp CMND'), findsOneWidget);
      expect(find.text('Chụp Hộ chiếu'), findsOneWidget);
    }
  });

  testWidgets('step 1 shows attendance only and continue button', (tester) async {
    await pumpApp(tester, const VerificationScreen());
    expect(find.text('Bước 1/4'), findsOneWidget);
    expect(find.text('Trực tiếp'), findsOneWidget);
    expect(find.text('Ủy quyền'), findsOneWidget);
    expect(find.text('Quét QR CCCD'), findsNothing);
    expect(find.text('Tiếp tục'), findsOneWidget);
    expect(find.byKey(VerificationStepNavigationControls.backKey), findsOneWidget);
    expect(find.byKey(VerificationStepNavigationControls.forwardKey), findsOneWidget);
  });

  testWidgets('step 1 disables back and enables forward nav', (tester) async {
    await pumpApp(tester, const VerificationScreen());
    final back = tester.widget<IconButton>(
      find.byKey(VerificationStepNavigationControls.backKey),
    );
    final forward = tester.widget<IconButton>(
      find.byKey(VerificationStepNavigationControls.forwardKey),
    );
    expect(back.onPressed, isNull);
    expect(forward.onPressed, isNotNull);
  });

  testWidgets('forward nav advances from step 1 to step 2', (tester) async {
    await pumpApp(tester, const VerificationScreen());
    await tester.tap(find.byKey(VerificationStepNavigationControls.forwardKey));
    await tester.pumpAndSettle();
    final c = Get.find<VerificationController>();
    expect(c.verificationStep.value, VerificationStep.identity);
  });

  testWidgets('step 2 disables forward until identity info is ready', (tester) async {
    final c = Get.find<VerificationController>();
    c.advanceToIdentityStep();
    await pumpApp(tester, const VerificationScreen());
    await tester.pumpAndSettle(const Duration(milliseconds: 500));

    final forward = tester.widget<IconButton>(
      find.byKey(VerificationStepNavigationControls.forwardKey),
    );
    expect(forward.onPressed, isNull);

    c.manualNameController.text = 'Nguyễn Văn A';
    c.manualIdController.text = '001234567890';
    await tester.pumpAndSettle(const Duration(milliseconds: 500));

    final forwardReady = tester.widget<IconButton>(
      find.byKey(VerificationStepNavigationControls.forwardKey),
    );
    expect(forwardReady.onPressed, isNotNull);
  });

  testWidgets('back nav returns from step 2 to step 1', (tester) async {
    final c = Get.find<VerificationController>();
    c.advanceToIdentityStep();
    await pumpApp(tester, const VerificationScreen());
    await tester.pumpAndSettle(const Duration(milliseconds: 500));

    await tester.tap(find.byKey(VerificationStepNavigationControls.backKey));
    await tester.pumpAndSettle();

    expect(c.verificationStep.value, VerificationStep.attendance);
    expect(find.text('Bước 1/4'), findsOneWidget);
  });

  testWidgets('continue advances to step 2 identity section', (tester) async {
    await pumpApp(tester, const VerificationScreen());
    final continueButton = find.widgetWithText(SvPrimaryButton, 'Tiếp tục');
    await tester.ensureVisible(continueButton);
    await tester.tap(continueButton);
    await tester.pumpAndSettle();
    final c = Get.find<VerificationController>();
    expect(c.verificationStep.value, VerificationStep.identity);
    expect(find.text('Bước 2/4'), findsOneWidget);
    expect(find.text('Quét QR CCCD'), findsOneWidget);
  });

  testWidgets('step 2 does not show evidence capture button', (tester) async {
    final c = Get.find<VerificationController>();
    c.advanceToIdentityStep();
    await pumpApp(tester, const VerificationScreen());
    expect(find.widgetWithText(SvPrimaryButton, 'Chụp ảnh chứng cứ'), findsNothing);
    expect(find.text('Tiếp tục chụp ảnh chứng cứ'), findsNothing);
  });


  testWidgets('step 2 shows continue after QR prefill', (tester) async {
    final c = Get.find<VerificationController>();
    c.advanceToIdentityStep();
    c.manualFormPrefillSource.value = ManualFormPrefillSource.qr;
    c.manualIdentityType.value = 'CCCD';
    c.manualNameController.text = 'Nguyễn Văn A';
    c.manualIdController.text = '001234567890';
    c.manualIdentityFormRevision.value++;
    await pumpApp(tester, const VerificationScreen());
    await tester.pumpAndSettle(const Duration(milliseconds: 500));
    expect(find.text('Tiếp tục chụp ảnh chứng cứ'), findsOneWidget);
  });

  testWidgets('step 2 shows continue after identity info is filled', (tester) async {
    final c = Get.find<VerificationController>();
    c.advanceToIdentityStep();
    c.manualNameController.text = 'Nguyễn Văn A';
    c.manualIdController.text = '001234567890';
    await pumpApp(tester, const VerificationScreen());
    await tester.pumpAndSettle(const Duration(milliseconds: 500));
    expect(find.text('Tiếp tục chụp ảnh chứng cứ'), findsOneWidget);
  });

  testWidgets('processNextPerson keeps proxy on step 1', (tester) async {
    final c = Get.find<VerificationController>();
    c.attendanceType.value = AttendanceType.proxy;
    c.manualNameController.text = 'Nguyễn Văn A';
    c.manualIdController.text = '001234567890';
    c.manualPhotoPath.value = 'uploads/test.jpg';
    c.verificationStep.value = VerificationStep.barcode;
    await c.onBarcodeScanned('SH0001');
    await pumpApp(tester, const VerificationScreen());
    await tester.pumpAndSettle(const Duration(milliseconds: 500));

    await c.processNextPerson();
    await tester.pumpAndSettle();

    expect(c.verificationStep.value, VerificationStep.attendance);
    expect(c.attendanceType.value, AttendanceType.proxy);
    expect(
      find.text(
        'Lưu thông tin giấy tờ của người được ủy quyền đến nhận (họ tên, số giấy tờ, loại, ảnh).',
      ),
      findsOneWidget,
    );
  });

  testWidgets('step 3 shows evidence capture button', (tester) async {
    final c = Get.find<VerificationController>();
    c.verificationStep.value = VerificationStep.evidence;
    c.manualNameController.text = 'Nguyễn Văn A';
    c.manualIdController.text = '001234567890';
    await pumpApp(tester, const VerificationScreen());
    expect(find.text('Bước 3/4'), findsOneWidget);
    expect(find.widgetWithText(SvPrimaryButton, 'Chụp ảnh chứng cứ'), findsOneWidget);
    await tester.pumpAndSettle(const Duration(milliseconds: 500));
  });

  testWidgets('step 4 shows barcode scan and identity summary', (tester) async {
    final c = Get.find<VerificationController>();
    c.manualNameController.text = 'Nguyễn Văn A';
    c.manualIdController.text = '001234567890';
    c.manualPhotoPath.value = 'uploads/test.jpg';
    c.verificationStep.value = VerificationStep.barcode;
    await pumpApp(tester, const VerificationScreen());
    await tester.pumpAndSettle(const Duration(milliseconds: 500));
    expect(find.text('Bước 4/4'), findsOneWidget);
    expect(find.text('Nhập trực tiếp mã MCD trên thiệp mời'), findsNothing);
    expect(find.text('Xác nhận mã cổ đông'), findsNothing);
  });


}
