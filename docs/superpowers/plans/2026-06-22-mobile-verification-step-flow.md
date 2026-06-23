# Mobile Verification 3-Step Flow Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Tái cấu trúc luồng Kiểm Tra trên Flutter thành 3 bước rõ ràng: (1) chọn hình thức nhận, (2) xác minh giấy tờ + ảnh chứng cứ + cảnh báo lần 2, (3) quét mã cổ đông và hiển thị kết quả.

**Architecture:** Giữ một `VerificationController` duy nhất, thêm `VerificationStep` enum (`attendance`, `identity`, `barcode`). `VerificationScreen` render theo step thay vì gộp tất cả trên một màn. Step 2 gọi API check identity như hiện tại; nếu `alreadyUsed` thì hiện **dialog** (không còn card inline), nhấn OK chuyển step 3. Quét QR CCCD sau khi parse thành công mở luôn màn chụp ảnh chứng cứ (`CaptureIntent.qrPrefilled` — đã có sẵn). Nhập tay giữ nút "Chụp ảnh chứng cứ", không tự mở camera. Step 3 nhúng `VerificationBarcodeSection` + `VerificationResultSection` ngay trong wizard; route `/verification/barcode` giữ redirect tương thích.

**Tech Stack:** Flutter 3.4+, GetX 4.6+, flutter_test, integration_test (optional)

**Repo:** `/Users/sypham/projects/becamex/share_verify`

---

## Bối cảnh hiện tại

| Thành phần | Hành vi hiện tại | Cần đổi |
|---|---|---|
| `VerificationScreen` | Gộp hình thức nhận + giấy tờ + nút quét MCD | Chỉ render theo `verificationStep` |
| `VerificationBarcodeScreen` | Màn riêng sau khi identity ready | Step 3 trong wizard; route redirect |
| `VerificationIdentityUsageWarning` | Card inline + nút quét MCD | Dialog popup ở step 2 |
| `onScanQrCccd` | Fill form, user tự bấm chụp ảnh | Mở capture `qrPrefilled` ngay |
| `ShellScreen` FAB | `goToBarcodeScreen()` khi ready | Chỉ hoạt động ở step 3 hoặc advance step |

---

## File Structure

```
lib/core/
├── models/
│   └── verification_step.dart              # NEW: enum VerificationStep
├── controllers/
│   └── verification_controller.dart        # step state, navigation, popup, QR flow
├── screens/
│   ├── shell/
│   │   └── shell_screen.dart               # FAB theo step
│   └── verification/
│       ├── verification_screen.dart        # wizard host + step indicator
│       ├── verification_barcode_screen.dart # redirect về shell step 3
│       └── components/
│           ├── verification_step_indicator.dart   # NEW: Bước 1/2/3
│           ├── verification_attendance_step.dart  # NEW: step 1 only
│           ├── verification_identity_step.dart    # NEW: step 2 wrapper
│           ├── verification_barcode_step.dart     # NEW: step 3 wrapper
│           ├── verification_identity_section.dart # đổi title → Bước 2
│           ├── verification_manual_identity_form.dart # ẩn/hiện evidence
│           ├── verification_identity_usage_warning.dart # deprecated inline; logic → dialog helper
│           └── verification_identity_usage_dialog.dart  # NEW: showDialog helper
test/
├── controllers/
│   └── verification_controller_step_test.dart     # NEW
└── widgets/
    └── verification_step_flow_test.dart           # NEW widget tests
```

---

### Task 1: VerificationStep model + controller step state

**Files:**
- Create: `lib/core/models/verification_step.dart`
- Modify: `lib/core/controllers/verification_controller.dart`
- Test: `test/controllers/verification_controller_step_test.dart`

- [ ] **Step 1: Write the failing test**

```dart
// test/controllers/verification_controller_step_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:share_verify/core/controllers/verification_controller.dart';
import 'package:share_verify/core/models/attendance_type.dart';
import 'package:share_verify/core/models/verification_step.dart';
import '../support/fake_repositories.dart';

void main() {
  setUp(() => Get.testMode = true);
  tearDown(Get.reset);

  VerificationController createController() => VerificationController(
        shareholderRepository: FakeShareholderRepository(),
        travelSupportRepository: FakeTravelSupportRepository(),
        barcodeScannerService: BarcodeScannerService(),
      );

  test('starts at attendance step', () {
    final c = createController();
    expect(c.verificationStep.value, VerificationStep.attendance);
  });

  test('advanceToIdentityStep moves from step 1 to step 2', () {
    final c = createController();
    c.advanceToIdentityStep();
    expect(c.verificationStep.value, VerificationStep.identity);
  });

  test('advanceToBarcodeStep requires identity ready', () async {
    final c = createController();
    c.verificationStep.value = VerificationStep.identity;
    await c.advanceToBarcodeStep();
    expect(c.verificationStep.value, VerificationStep.identity);
    expect(c.errorMessage.value, isNotNull);
  });

  test('goBackStep decrements step', () {
    final c = createController();
    c.verificationStep.value = VerificationStep.barcode;
    c.goBackStep();
    expect(c.verificationStep.value, VerificationStep.identity);
  });

  test('resetSelection returns to step 1', () async {
    final c = createController();
    c.verificationStep.value = VerificationStep.barcode;
    c.attendanceType.value = AttendanceType.proxy;
    c.resetSelection();
    expect(c.verificationStep.value, VerificationStep.attendance);
    expect(c.attendanceType.value, AttendanceType.direct);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd /Users/sypham/projects/becamex/share_verify && flutter test test/controllers/verification_controller_step_test.dart -v`

Expected: FAIL — `VerificationStep` / `verificationStep` not defined

- [ ] **Step 3: Write minimal implementation**

```dart
// lib/core/models/verification_step.dart
enum VerificationStep {
  attendance,
  identity,
  barcode,
}

extension VerificationStepX on VerificationStep {
  int get number => switch (this) {
        VerificationStep.attendance => 1,
        VerificationStep.identity => 2,
        VerificationStep.barcode => 3,
      };

  String get title => switch (this) {
        VerificationStep.attendance => 'Hình thức nhận',
        VerificationStep.identity => 'Xác minh giấy tờ',
        VerificationStep.barcode => 'Quét mã cổ đông',
      };
}
```

Thêm vào `verification_controller.dart`:

```dart
import 'package:share_verify/core/models/verification_step.dart';

// fields
final verificationStep = VerificationStep.attendance.obs;

bool get isOnAttendanceStep => verificationStep.value == VerificationStep.attendance;
bool get isOnIdentityStep => verificationStep.value == VerificationStep.identity;
bool get isOnBarcodeStep => verificationStep.value == VerificationStep.barcode;

void advanceToIdentityStep() {
  errorMessage.value = null;
  verificationStep.value = VerificationStep.identity;
}

Future<void> advanceToBarcodeStep() async {
  errorMessage.value = null;
  if (!isIdentityReady) {
    errorMessage.value =
        'Vui lòng chụp ảnh chứng cứ và nhập đủ thông tin trước khi quét mã cổ đông';
    return;
  }
  _resetBarcodeFlow();
  verificationStep.value = VerificationStep.barcode;
}

void goBackStep() {
  errorMessage.value = null;
  verificationStep.value = switch (verificationStep.value) {
    VerificationStep.barcode => VerificationStep.identity,
    VerificationStep.identity => VerificationStep.attendance,
    VerificationStep.attendance => VerificationStep.attendance,
  };
}

// Cập nhật _resetIdentityFlow:
void _resetIdentityFlow() {
  identityCheckResult.value = null;
  attendanceType.value = AttendanceType.direct;
  verificationStep.value = VerificationStep.attendance;
  _clearManualForm(resetIdentityType: true);
  isSubmitting.value = false;
  isCheckingIdentity.value = false;
}

// Cập nhật goToBarcodeScreen — delegate:
Future<void> goToBarcodeScreen() => advanceToBarcodeStep();
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/controllers/verification_controller_step_test.dart -v`

Expected: PASS (5 tests)

- [ ] **Step 5: Commit**

```bash
git add lib/core/models/verification_step.dart \
  lib/core/controllers/verification_controller.dart \
  test/controllers/verification_controller_step_test.dart
git commit -m "feat: add verification wizard step state to controller"
```

---

### Task 2: Step indicator + Step 1 attendance screen

**Files:**
- Create: `lib/core/screens/verification/components/verification_step_indicator.dart`
- Create: `lib/core/screens/verification/components/verification_attendance_step.dart`
- Modify: `lib/core/screens/verification/verification_screen.dart`
- Test: `test/widgets/verification_step_flow_test.dart`

- [ ] **Step 1: Write the failing widget test**

```dart
// test/widgets/verification_step_flow_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:share_verify/core/controllers/verification_controller.dart';
import 'package:share_verify/core/models/verification_step.dart';
import 'package:share_verify/core/screens/verification/verification_screen.dart';
import '../support/fake_repositories.dart';
import '../support/pump_app.dart';

void main() {
  setUp(() {
    Get.testMode = true;
    Get.put(VerificationController(
      shareholderRepository: FakeShareholderRepository(),
      travelSupportRepository: FakeTravelSupportRepository(),
      barcodeScannerService: BarcodeScannerService(),
    ));
  });
  tearDown(Get.reset);

  testWidgets('step 1 shows attendance only and continue button', (tester) async {
    await pumpApp(tester, const VerificationScreen());
    expect(find.text('Bước 1: Hình thức nhận'), findsOneWidget);
    expect(find.text('Trực tiếp'), findsOneWidget);
    expect(find.text('Ủy quyền'), findsOneWidget);
    expect(find.text('Quét QR CCCD'), findsNothing);
    expect(find.text('Tiếp tục'), findsOneWidget);
  });

  testWidgets('continue advances to step 2 identity section', (tester) async {
    await pumpApp(tester, const VerificationScreen());
    await tester.tap(find.text('Tiếp tục'));
    await tester.pumpAndSettle();
    final c = Get.find<VerificationController>();
    expect(c.verificationStep.value, VerificationStep.identity);
    expect(find.textContaining('Bước 2:'), findsOneWidget);
    expect(find.text('Quét QR CCCD'), findsOneWidget);
  });
}
```

Nếu chưa có `pump_app.dart`, tạo helper tối thiểu:

```dart
// test/support/pump_app.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

Future<void> pumpApp(WidgetTester tester, Widget child) async {
  await tester.pumpWidget(
    GetMaterialApp(home: child),
  );
  await tester.pumpAndSettle();
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/widgets/verification_step_flow_test.dart -v`

Expected: FAIL — vẫn thấy "Quét QR CCCD" ở step 1

- [ ] **Step 3: Implement step indicator + attendance step + refactor screen**

```dart
// lib/core/screens/verification/components/verification_step_indicator.dart
import 'package:flutter/material.dart';
import 'package:share_verify/core/commons/app_spacing.dart';
import 'package:share_verify/core/models/verification_step.dart';

class VerificationStepIndicator extends StatelessWidget {
  final VerificationStep current;

  const VerificationStepIndicator({super.key, required this.current});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: VerificationStep.values.map((step) {
        final isActive = step.number <= current.number;
        final isCurrent = step == current;
        return Expanded(
          child: Column(
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: isActive
                    ? theme.colorScheme.primary
                    : theme.colorScheme.surfaceContainerHigh,
                child: Text(
                  '${step.number}',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: isActive
                        ? theme.colorScheme.onPrimary
                        : theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: SvSpacing.xs),
              Text(
                step.title,
                textAlign: TextAlign.center,
                maxLines: 2,
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
                  color: isCurrent
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
```

```dart
// lib/core/screens/verification/components/verification_attendance_step.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:share_verify/core/commons/app_spacing.dart';
import 'package:share_verify/core/controllers/verification_controller.dart';
import 'package:share_verify/core/screens/verification/components/verification_attendance_section.dart';
import 'package:share_verify/core/widgets/sv_primary_button.dart';

class VerificationAttendanceStep extends GetView<VerificationController> {
  const VerificationAttendanceStep({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Bước 1: Hình thức nhận',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: SvSpacing.md),
        Obx(
          () => VerificationAttendanceSection(
            attendanceType: controller.attendanceType.value,
            onAttendanceTypeChanged: controller.onAttendanceTypeChanged,
          ),
        ),
        const SizedBox(height: SvSpacing.lg),
        SvPrimaryButton(
          label: 'Tiếp tục',
          icon: Icons.arrow_forward,
          onPressed: controller.advanceToIdentityStep,
          height: 56,
        ),
      ],
    );
  }
}
```

Refactor `verification_screen.dart` body:

```dart
// Thay Column children bằng:
Obx(() {
  final step = controller.verificationStep.value;
  return Column(
    children: [
      VerificationStepIndicator(current: step),
      const SizedBox(height: SvSpacing.lg),
      switch (step) {
        VerificationStep.attendance => const VerificationAttendanceStep(),
        VerificationStep.identity => const VerificationIdentityStep(),
        VerificationStep.barcode => const VerificationBarcodeStep(),
      },
      // error banner giữ nguyên
    ],
  );
}),
```

Tạm thời stub `VerificationIdentityStep` / `VerificationBarcodeStep` là `SizedBox.shrink()` để compile; Task 3/4 sẽ điền nội dung.

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/widgets/verification_step_flow_test.dart -v`

Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add lib/core/screens/verification/components/verification_step_indicator.dart \
  lib/core/screens/verification/components/verification_attendance_step.dart \
  lib/core/screens/verification/verification_screen.dart \
  test/widgets/verification_step_flow_test.dart \
  test/support/pump_app.dart
git commit -m "feat: add step 1 attendance screen with step indicator"
```

---

### Task 3: Step 2 identity — scan buttons, manual form, evidence visibility

**Files:**
- Create: `lib/core/screens/verification/components/verification_identity_step.dart`
- Modify: `lib/core/screens/verification/components/verification_identity_section.dart`
- Modify: `lib/core/screens/verification/components/verification_manual_identity_form.dart`
- Modify: `lib/core/controllers/verification_controller.dart` (`onScanQrCccd`)
- Test: extend `test/widgets/verification_step_flow_test.dart`

- [ ] **Step 1: Write failing tests**

```dart
testWidgets('step 2 hides evidence capture until scan prefill', (tester) async {
  final c = Get.find<VerificationController>();
  c.verificationStep.value = VerificationStep.identity;
  await pumpApp(tester, const VerificationScreen());
  expect(find.text('Chụp ảnh chứng cứ'), findsNothing);
});

test('showEvidenceCaptureSection true after QR prefill source', () {
  final c = createController();
  c.verificationStep.value = VerificationStep.identity;
  c.manualFormPrefillSource.value = ManualFormPrefillSource.qr;
  expect(c.showEvidenceCaptureSection, isTrue);
});

test('showEvidenceCaptureSection false for pure manual entry', () {
  final c = createController();
  c.verificationStep.value = VerificationStep.identity;
  expect(c.showEvidenceCaptureSection, isFalse);
});
```

- [ ] **Step 2: Run tests — expect FAIL**

Run: `flutter test test/widgets/verification_step_flow_test.dart test/controllers/verification_controller_step_test.dart -v`

- [ ] **Step 3: Implement**

Controller getter:

```dart
bool get showEvidenceCaptureSection =>
    manualFormPrefillSource.value != null || manualPhotoPath.value != null;
```

`verification_identity_section.dart` — đổi title:

```dart
final title = isProxy
    ? 'Bước 2: Xác minh giấy tờ người ủy quyền'
    : 'Bước 2: Xác minh giấy tờ người nhận';
```

`verification_manual_identity_form.dart` — bọc khối evidence:

```dart
Obx(() {
  if (!controller.showEvidenceCaptureSection) {
    return const SizedBox.shrink();
  }
  // ... EvidencePhotoPreview + Chụp ảnh chứng cứ + Xóa và nhập lại
}),
```

`verification_identity_step.dart`:

```dart
class VerificationIdentityStep extends GetView<VerificationController> {
  const VerificationIdentityStep({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: controller.goBackStep,
            icon: const Icon(Icons.arrow_back),
            label: const Text('Quay lại'),
          ),
        ),
        const VerificationIdentitySection(),
        const SizedBox(height: SvSpacing.md),
        Obx(() {
          if (controller.isCheckingIdentity.value) {
            return const LinearProgressIndicator();
          }
          if (!controller.isIdentityReady || controller.hasIdentityUsageWarning) {
            return const SizedBox.shrink();
          }
          return SvPrimaryButton(
            label: 'Tiếp tục quét mã cổ đông',
            icon: Icons.arrow_forward,
            onPressed: controller.advanceToBarcodeStep,
            height: 56,
          );
        }),
      ],
    );
  }
}
```

**Đổi luồng QR CCCD** — sau parse thành công mở capture chứng cứ ngay:

```dart
Future<void> onScanQrCccd() async {
  final context = Get.context;
  if (context == null) return;
  errorMessage.value = null;

  final raw = await _barcodeScannerService.scanCccdQr(context);
  if (raw == null) return;

  final qrData = CccdQrParser.parse(raw);
  if (qrData == null) {
    errorMessage.value =
        'Không đọc được thông tin từ QR CCCD. Hãy thử chụp CCCD hoặc nhập tay.';
    return;
  }

  final result = await _navigateToCapture(
    identityType: 'CCCD',
    intent: CaptureIntent.qrPrefilled,
    prefillName: qrData.fullName,
    prefillIdentityNo: qrData.identityNo,
    prefillCmndNo: qrData.cmndNo,
  );
  if (result == null) return;
  if (!Get.isRegistered<VerificationController>()) return;
  await Get.find<VerificationController>().applyCaptureResult(result);
}
```

`applyCaptureResult` sau khi check identity gọi `_maybeShowIdentityUsageDialog()` (Task 4).

- [ ] **Step 4: Run tests — expect PASS**

- [ ] **Step 5: Commit**

```bash
git commit -m "feat: step 2 identity with conditional evidence capture and QR prefilled flow"
```

---

### Task 4: Popup cảnh báo lần 2 ở Step 2

**Files:**
- Create: `lib/core/screens/verification/components/verification_identity_usage_dialog.dart`
- Modify: `lib/core/controllers/verification_controller.dart`
- Modify: `lib/core/screens/verification/components/verification_identity_step.dart`
- Remove usage from: `verification_screen.dart`, `verification_barcode_screen.dart` (inline card)
- Test: `test/controllers/verification_controller_step_test.dart`

- [ ] **Step 1: Write failing test**

```dart
test('_shouldPromptIdentityUsageDialog when already used on identity step', () {
  final c = createController();
  c.verificationStep.value = VerificationStep.identity;
  c.identityCheckResult.value = const IdentityCheckResultDto(
    alreadyUsed: true,
    usedForMcd: 'MCD001',
    message: 'Người này đã nhận phụ cấp trước đó.',
  );
  expect(c.shouldPromptIdentityUsageDialog, isTrue);
});

test('_shouldPromptIdentityUsageDialog false on barcode step', () {
  final c = createController();
  c.verificationStep.value = VerificationStep.barcode;
  c.identityCheckResult.value = const IdentityCheckResultDto(alreadyUsed: true);
  expect(c.shouldPromptIdentityUsageDialog, isFalse);
});
```

- [ ] **Step 2: Run — FAIL**

- [ ] **Step 3: Implement dialog helper + controller hook**

```dart
// verification_identity_usage_dialog.dart
import 'package:flutter/material.dart';
import 'package:share_verify/core/data/dto/travel_support_dtos.dart';

class VerificationIdentityUsageDialog {
  static Future<bool> show(
    BuildContext context, {
    required IdentityCheckResultDto check,
    required List<String> mcds,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        icon: Icon(Icons.warning_amber_rounded, color: Theme.of(ctx).colorScheme.error),
        title: const Text('Giấy tờ đã được sử dụng'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(check.message ?? 'Người này đã nhận phụ cấp trước đó.'),
              if (mcds.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Text('Mã cổ đông đã nhận:', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(mcds.join(', ')),
              ],
              const SizedBox(height: 12),
              const Text(
                'Bạn vẫn có thể tiếp tục quét mã cổ đông khác.',
                style: TextStyle(fontSize: 13),
              ),
            ],
          ),
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('OK'),
          ),
        ],
      ),
    ).then((v) => v ?? false);
  }
}
```

Controller:

```dart
final _identityUsageDialogShown = false.obs;

bool get shouldPromptIdentityUsageDialog =>
    isOnIdentityStep &&
    hasIdentityUsageWarning &&
    isIdentityReady &&
    !_identityUsageDialogShown.value;

Future<void> _maybeShowIdentityUsageDialog() async {
  if (!shouldPromptIdentityUsageDialog) return;
  final context = Get.context;
  if (context == null) return;

  _identityUsageDialogShown.value = true;
  final accepted = await VerificationIdentityUsageDialog.show(
    context,
    check: identityCheckResult.value!,
    mcds: usedShareholderCodes,
  );
  if (accepted) {
    await advanceToBarcodeStep();
  } else {
    _identityUsageDialogShown.value = false;
  }
}

// Gọi cuối _checkIdentityUsage và _previewManualIdentityCheck (trong finally sau set result)
// Reset flag trong _clearManualForm / resetManualIdentityForm / onAttendanceTypeChanged
```

Xóa `VerificationIdentityUsageWarning` khỏi `VerificationScreen` và `VerificationBarcodeScreen`. File component có thể giữ lại nhưng không import nữa (hoặc xóa nếu unused).

- [ ] **Step 4: Widget test dialog (optional smoke)**

```dart
testWidgets('identity usage dialog OK advances to step 3', (tester) async {
  // setup identity ready + alreadyUsed, pump, verify dialog, tap OK, step == barcode
});
```

- [ ] **Step 5: Run tests + commit**

```bash
git commit -m "feat: show second-time identity warning as dialog on step 2"
```

---

### Task 5: Step 3 barcode + thông báo kết quả

**Files:**
- Create: `lib/core/screens/verification/components/verification_barcode_step.dart`
- Modify: `lib/core/screens/verification/verification_barcode_screen.dart`
- Modify: `lib/core/screens/shell/shell_screen.dart`
- Test: extend widget + controller tests

- [ ] **Step 1: Write failing widget test**

```dart
testWidgets('step 3 shows barcode scan and identity summary', (tester) async {
  final c = Get.find<VerificationController>();
  c.verificationStep.value = VerificationStep.barcode;
  // seed complete identity via manual controllers + photo path
  await pumpApp(tester, const VerificationScreen());
  expect(find.text('Bước 3: Quét mã cổ đông'), findsOneWidget);
  expect(find.text('Quét Mã Thiệp Mời'), findsOneWidget);
});
```

- [ ] **Step 2: Run — FAIL**

- [ ] **Step 3: Implement barcode step**

```dart
// verification_barcode_step.dart
class VerificationBarcodeStep extends GetView<VerificationController> {
  const VerificationBarcodeStep({super.key});

  @override
  Widget build(BuildContext context) {
    final identity = controller.effectivePendingIdentity;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: controller.goBackStep,
            icon: const Icon(Icons.arrow_back),
            label: const Text('Quay lại'),
          ),
        ),
        Text(
          'Bước 3: Quét mã cổ đông',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: SvSpacing.md),
        if (identity != null) VerificationIdentitySummary(identity: identity),
        const SizedBox(height: SvSpacing.md),
        const VerificationBarcodeSection(),
        Obx(() {
          final shareholder = controller.selectedShareholder.value;
          if (shareholder == null) return const SizedBox.shrink();
          return Column(
            children: [
              const SizedBox(height: SvSpacing.lg),
              VerificationResultSection(
                shareholder: shareholder,
                isSubmitting: controller.isSubmitting.value,
                isLoadingRecipients: controller.isLoadingRecipients.value,
                onViewRecipients: () => controller.onViewRecipientInfo(context),
                onProcessNextPerson: controller.processNextPerson,
              ),
            ],
          );
        }),
      ],
    );
  }
}
```

`verification_barcode_screen.dart` — redirect về shell step 3:

```dart
@override
Widget build(BuildContext context) {
  WidgetsBinding.instance.addPostFrameCallback((_) {
    final c = Get.find<VerificationController>();
    if (c.isIdentityReady) {
      c.verificationStep.value = VerificationStep.barcode;
    }
    Get.until((route) => route.settings.name == ShellScreen.routeName);
  });
  return const Scaffold(body: Center(child: CircularProgressIndicator()));
}
```

`shell_screen.dart` FAB:

```dart
floatingActionButton: controller.tabIndex.value == 0
    ? Obx(() {
        final c = verificationController;
        final onStep3 = c.isOnBarcodeStep;
        final ready = c.isIdentityReady && !c.isSubmitting.value;
        return SvFabQr(
          onPressed: onStep3
              ? c.onScanInvitationBarcode
              : ready
                  ? c.advanceToBarcodeStep
                  : () {
                      c.errorMessage.value =
                          'Vui lòng hoàn thành bước xác minh giấy tờ trước';
                    },
          icon: Icons.qr_code_2,
        );
      })
    : null,
```

`processNextPerson` đã gọi `resetSelection()` → về step 1.

- [ ] **Step 4: Run full test suite**

Run: `flutter test -v`

Expected: all pass

- [ ] **Step 5: Commit**

```bash
git commit -m "feat: step 3 inline barcode scan with result notification"
```

---

### Task 6: Dọn dẹp + regression tests

**Files:**
- Modify: `test/controllers/verification_controller_test.dart`
- Delete or deprecate unused inline warning usages

- [ ] **Step 1: Update existing controller tests**

Thay `goToBarcodeScreen` expectations bằng `verificationStep == VerificationStep.barcode`.

```dart
test('advanceToBarcodeStep when manual form has photo', () async {
  final c = createController();
  c.verificationStep.value = VerificationStep.identity;
  c.manualNameController.text = 'Nguyễn Văn A';
  c.manualIdController.text = '001234567890';
  c.manualPhotoPath.value = 'uploads/test.jpg';
  await c.advanceToBarcodeStep();
  expect(c.verificationStep.value, VerificationStep.barcode);
});
```

- [ ] **Step 2: Run full tests**

Run: `flutter test -v`

- [ ] **Step 3: Manual smoke test checklist**

1. Mở app → tab Kiểm Tra → chỉ thấy Bước 1
2. Chọn Ủy quyền → Tiếp tục → Bước 2 với tiêu đề người ủy quyền
3. Quét QR CCCD thành công → mở camera chứng cứ ngay
4. Nhập tay họ tên + số → không thấy nút chụp cho đến khi... *(theo `showEvidenceCaptureSection`: chỉ khi chưa scan — user bấm vào form manual thì cần nút "Chụp ảnh chứng cứ" luôn hiện ở cuối form manual; điều chỉnh: manual path luôn hiện nút, chỉ **không auto-mở camera**)*

**Điều chỉnh quan trọng cho nhập tay:** `showEvidenceCaptureSection` chỉ ẩn khối preview trước khi có ảnh; **nút "Chụp ảnh chứng cứ" luôn hiển thị** trong form nhập tay. Chỉ ẩn `EvidencePhotoPreview` khi chưa có ảnh. Scan/OCR path hiện preview + khung ngay sau khi có dữ liệu.

Cập nhật Task 3 implementation note:

```dart
// manual form: luôn show nút chụp; preview chỉ khi hasPhoto
// showEvidenceCaptureSection chỉ điều khiển auto-open camera sau QR, không ẩn nút
```

Thêm vào controller:

```dart
Future<void> _autoOpenEvidenceCaptureIfNeeded() async {
  if (manualFormPrefillSource.value == ManualFormPrefillSource.qr &&
      (manualPhotoPath.value == null || manualPhotoPath.value!.isEmpty)) {
    await onCaptureManualPhoto();
  }
}
// Gọi sau _fillManualFormFromQr nếu không dùng full-screen capture qrPrefilled
```

Ưu tiên flow `qrPrefilled` full-screen (Task 3) vì đã có sẵn — không cần `_autoOpenEvidenceCaptureIfNeeded`.

- [ ] **Step 4: Commit**

```bash
git commit -m "test: update verification flow regression tests for 3-step wizard"
```

---

## Self-Review

### 1. Spec coverage

| Yêu cầu | Task |
|---|---|
| Step 1: Chọn ủy quyền / trực tiếp | Task 1, 2 |
| Step 2: Nút quét CCCD, CMND, HC + nhập tay + chụp ảnh | Task 3 |
| Quét thành công → hiện khung chụp chứng cứ ngay | Task 3 (`qrPrefilled` + OCR capture) |
| Nhập tay → tự bấm nút chụp chứng cứ | Task 3 (không auto-open) |
| Kiểm tra lần 2 → popup ở step 2, OK → step 3 | Task 4 |
| Step 3: Quét MCD + thông báo | Task 5 |

### 2. Placeholder scan

Không có TBD / implement later.

### 3. Type consistency

- `VerificationStep` dùng xuyên suốt controller + UI
- `goToBarcodeScreen` delegate `advanceToBarcodeStep` — không breaking API cho FAB/tests cũ
- `IdentityCheckResultDto` / `usedShareholderCodes` giữ nguyên từ controller hiện tại

---

## Execution Handoff

Plan complete and saved to `docs/superpowers/plans/2026-06-22-mobile-verification-step-flow.md`.

**Two execution options:**

**1. Subagent-Driven (recommended)** — dispatch a fresh subagent per task, review between tasks, fast iteration

**2. Inline Execution** — execute tasks in this session using executing-plans, batch execution with checkpoints

**Which approach?**
