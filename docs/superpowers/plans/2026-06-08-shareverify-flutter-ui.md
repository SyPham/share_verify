# ShareVerify Flutter UI Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Bootstrap the ShareVerify Flutter mobile app with Material Design 3 UI matching the Google Stitch design (project `14360683783372619451`), using GetX for state and mock data only.

**Architecture:** Mirror `inventory-mobile` folder layout (`lib/core/{screens,controllers,bindings,widgets,models,commons}`). A `ShellScreen` hosts bottom navigation (Kiểm Tra / Dashboard) with two tab bodies. Capture Evidence and Success are pushed routes off the verification flow. All colors, spacing, and typography come from the Stitch design tokens. No login, no backend.

**Tech Stack:** Flutter 3.4+, GetX 4.6+, google_fonts (Be Vietnam Pro), Material 3, flutter_test

---

## Design Source (Verified via Stitch MCP)

| Field | Value |
|---|---|
| **Stitch Project ID** | `14360683783372619451` |
| **Project Title** | AGM Travel Support Verifier |
| **Design Theme** | LIGHT, Be Vietnam Pro, roundness ROUND_EIGHT, custom color `#0052cc` |
| **Device Type** | MOBILE (780×1768–2180) |
| **Matching keywords** | AGM, Shareholder Verification, Travel Support, Quét QR CCCD, Chưa nhận hỗ trợ, Đã nhận hỗ trợ |

**Only one matching project found** — no user choice required.

### Screens Found in Design

| # | Stitch Title | Screen ID | Flutter Screen | Route |
|---|---|---|---|---|
| 1 | Xác Minh Cổ Đông | `e51f78a49f1d437487283eb64dcc86bc` | `VerificationScreen` | Tab 0 in `/shell` |
| 2 | Bảng Điều Khiển | `b40b80fe032344e5afd94a7af071bf39` | `DashboardScreen` | Tab 1 in `/shell` |
| 3 | Chụp Minh Chứng | `056af76ab0bd40289303261e51b1fed1` | `CaptureEvidenceScreen` | `/capture` |
| 4 | Thành Công | `429d0807d1e14c97ab7e422bdd8e7555` | `SuccessScreen` | `/success` |

### Screen Mapping Notes

- **3 main screens** (user spec) = Verification + Capture + Dashboard. `Thành Công` is a **confirmation result screen** in the Stitch design (shown after payment confirm); include it as a pushed route, not a bottom-nav tab.
- **Web/Admin Import Shareholder Excel** is **NOT present** in this Stitch project. Defer to a separate plan once an admin design exists.
- **No login screen** — `initialRoute` goes directly to `/shell`.
- Vietnamese labels must match design exactly (case-sensitive):
  - Verification status badge: `CHƯA NHẬN` (not "CHƯA NHẬN HỖ TRỢ")
  - Dashboard KPI labels: `Đã nhận hỗ trợ`, `Chưa nhận hỗ trợ`
  - Primary CTA: `XÁC NHẬN ĐÃ PHÁT TIỀN`
  - QR button: `Quét QR CCCD`

### Design Tokens (from Stitch HTML)

```dart
// lib/core/commons/palette.dart — exact hex from design
static const primary = Color(0xFF003D9B);
static const primaryContainer = Color(0xFF0052CC);
static const secondaryContainer = Color(0xFF0071E6);
static const tertiary = Color(0xFF004E32);
static const tertiaryContainer = Color(0xFF006844);
static const onTertiaryContainer = Color(0xFF7DE7B2);
static const error = Color(0xFFBA1A1A);
static const errorContainer = Color(0xFFFFDAD6);
static const onErrorContainer = Color(0xFF93000A);
static const surface = Color(0xFFF8F9FB);
static const onSurface = Color(0xFF191C1E);
static const onSurfaceVariant = Color(0xFF434654);
static const outlineVariant = Color(0xFFC3C6D6);
static const surfaceContainerLowest = Color(0xFFFFFFFF);
static const surfaceContainerHigh = Color(0xFFE7E8EA);
static const surfaceContainerLow = Color(0xFFF3F4F6);
static const primaryFixed = Color(0xFFDAE2FF);
static const secondaryFixed = Color(0xFFD7E2FF);

// Spacing
static const containerMargin = 20.0;
static const touchTarget = 56.0;
static const radiusXl = 12.0;
```

---

## File Structure

```
share_verify/
├── pubspec.yaml
├── lib/
│   ├── main.dart
│   └── core/
│       ├── commons/
│       │   ├── palette.dart
│       │   ├── app_spacing.dart
│       │   ├── app_typography.dart
│       │   └── app_theme.dart
│       ├── config/app_setting.dart
│       ├── manager/init_application.dart
│       ├── route.dart
│       ├── bindings/
│       │   ├── shell_binding.dart
│       │   ├── verification_binding.dart
│       │   ├── capture_binding.dart
│       │   └── dashboard_binding.dart
│       ├── controllers/
│       │   ├── shell_controller.dart
│       │   ├── verification_controller.dart
│       │   ├── capture_controller.dart
│       │   └── dashboard_controller.dart
│       ├── models/
│       │   ├── shareholder.dart
│       │   ├── payment_status.dart
│       │   ├── activity_item.dart
│       │   └── dashboard_stats.dart
│       ├── mock/mock_data.dart
│       ├── screens/
│       │   ├── shell/shell_screen.dart
│       │   ├── verification/
│       │   │   ├── verification_screen.dart
│       │   │   └── components/
│       │   │       ├── verification_action_buttons.dart
│       │   │       ├── verification_search_section.dart
│       │   │       └── verification_result_section.dart
│       │   ├── capture/
│       │   │   ├── capture_evidence_screen.dart
│       │   │   └── components/capture_overlay_card.dart
│       │   ├── dashboard/
│       │   │   ├── dashboard_screen.dart
│       │   │   └── components/
│       │   │       ├── progress_ring_section.dart
│       │   │       └── recent_activity_list.dart
│       │   └── success/success_screen.dart
│       └── widgets/
│           ├── sv_app_bar.dart
│           ├── sv_bottom_nav.dart
│           ├── sv_primary_button.dart
│           ├── sv_outlined_button.dart
│           ├── sv_status_badge.dart
│           ├── sv_kpi_card.dart
│           ├── sv_result_info_row.dart
│           └── sv_fab_qr.dart
└── test/
    ├── widgets/sv_status_badge_test.dart
    ├── widgets/sv_kpi_card_test.dart
    └── controllers/verification_controller_test.dart
```

---

### Task 1: Bootstrap Flutter Project

**Files:**
- Create: `pubspec.yaml`, `lib/main.dart`, `analysis_options.yaml` (via flutter create)
- Reference: `/Users/sypham/projects/becamex/inventory-mobile/pubspec.yaml`

- [ ] **Step 1: Create Flutter project**

```bash
cd /Users/sypham/projects/becamex/share_verify
flutter create . --org com.becamex --project-name share_verify
```

- [ ] **Step 2: Add dependencies to `pubspec.yaml`**

Replace the `dependencies:` block with:

```yaml
dependencies:
  flutter:
    sdk: flutter
  cupertino_icons: ^1.0.8
  get: ^4.6.6
  google_fonts: ^6.2.1
  intl: ^0.19.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^5.0.0

environment:
  sdk: '>=3.4.0 <4.0.0'
```

- [ ] **Step 3: Install packages**

```bash
flutter pub get
```

Expected: `Got dependencies!` with no errors.

- [ ] **Step 4: Commit**

```bash
git init
git add pubspec.yaml pubspec.lock lib/main.dart android/ ios/ web/ linux/ macos/ windows/ test/ analysis_options.yaml .metadata .gitignore
git commit -m "chore: bootstrap ShareVerify Flutter project"
```

---

### Task 2: Design System (Palette, Typography, Theme)

**Files:**
- Create: `lib/core/commons/palette.dart`
- Create: `lib/core/commons/app_spacing.dart`
- Create: `lib/core/commons/app_typography.dart`
- Create: `lib/core/commons/app_theme.dart`

- [ ] **Step 1: Write palette**

```dart
// lib/core/commons/palette.dart
import 'package:flutter/material.dart';

class SvPalette {
  SvPalette._();

  static const primary = Color(0xFF003D9B);
  static const primaryContainer = Color(0xFF0052CC);
  static const onPrimary = Color(0xFFFFFFFF);
  static const onPrimaryContainer = Color(0xFFC4D2FF);
  static const secondary = Color(0xFF0059B8);
  static const secondaryContainer = Color(0xFF0071E6);
  static const onSecondaryContainer = Color(0xFFFEFCFF);
  static const tertiary = Color(0xFF004E32);
  static const tertiaryContainer = Color(0xFF006844);
  static const onTertiary = Color(0xFFFFFFFF);
  static const onTertiaryContainer = Color(0xFF7DE7B2);
  static const error = Color(0xFFBA1A1A);
  static const errorContainer = Color(0xFFFFDAD6);
  static const onErrorContainer = Color(0xFF93000A);
  static const surface = Color(0xFFF8F9FB);
  static const background = Color(0xFFF8F9FB);
  static const onSurface = Color(0xFF191C1E);
  static const onSurfaceVariant = Color(0xFF434654);
  static const onBackground = Color(0xFF191C1E);
  static const outline = Color(0xFF737685);
  static const outlineVariant = Color(0xFFC3C6D6);
  static const surfaceContainerLowest = Color(0xFFFFFFFF);
  static const surfaceContainerLow = Color(0xFFF3F4F6);
  static const surfaceContainer = Color(0xFFEDEEF0);
  static const surfaceContainerHigh = Color(0xFFE7E8EA);
  static const surfaceContainerHighest = Color(0xFFE1E2E4);
  static const primaryFixed = Color(0xFFDAE2FF);
  static const secondaryFixed = Color(0xFFD7E2FF);
}
```

- [ ] **Step 2: Write spacing + typography**

```dart
// lib/core/commons/app_spacing.dart
class SvSpacing {
  SvSpacing._();
  static const xs = 4.0;
  static const sm = 12.0;
  static const md = 20.0;
  static const lg = 32.0;
  static const containerMargin = 20.0;
  static const touchTarget = 56.0;
  static const radiusXl = 12.0;
  static const radiusLg = 8.0;
  static const bottomNavHeight = 80.0;
}
```

```dart
// lib/core/commons/app_typography.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_verify/core/commons/palette.dart';

class SvTypography {
  static TextTheme textTheme(TextTheme base) =>
      GoogleFonts.beVietnamProTextTheme(base).copyWith(
        displayLarge: GoogleFonts.beVietnamPro(
          fontSize: 40, height: 48 / 40, fontWeight: FontWeight.w700,
          letterSpacing: -0.02 * 40, color: SvPalette.primary,
        ),
        headlineLarge: GoogleFonts.beVietnamPro(
          fontSize: 32, height: 40 / 32, fontWeight: FontWeight.w700,
          color: SvPalette.tertiary,
        ),
        headlineMedium: GoogleFonts.beVietnamPro(
          fontSize: 24, height: 32 / 24, fontWeight: FontWeight.w600,
          color: SvPalette.primary,
        ),
        headlineSmall: GoogleFonts.beVietnamPro(
          fontSize: 20, height: 28 / 20, fontWeight: FontWeight.w600,
          color: SvPalette.onSurface,
        ),
        bodyLarge: GoogleFonts.beVietnamPro(
          fontSize: 18, height: 28 / 18, fontWeight: FontWeight.w400,
        ),
        bodyMedium: GoogleFonts.beVietnamPro(
          fontSize: 16, height: 24 / 16, fontWeight: FontWeight.w400,
        ),
        labelLarge: GoogleFonts.beVietnamPro(
          fontSize: 14, height: 20 / 14, fontWeight: FontWeight.w600,
          letterSpacing: 0.1,
        ),
      );
}
```

- [ ] **Step 3: Write Material 3 theme**

```dart
// lib/core/commons/app_theme.dart
import 'package:flutter/material.dart';
import 'package:share_verify/core/commons/palette.dart';
import 'package:share_verify/core/commons/app_typography.dart';

class SvAppTheme {
  static ThemeData light() {
    const scheme = ColorScheme(
      brightness: Brightness.light,
      primary: SvPalette.primary,
      onPrimary: SvPalette.onPrimary,
      primaryContainer: SvPalette.primaryContainer,
      onPrimaryContainer: SvPalette.onPrimaryContainer,
      secondary: SvPalette.secondary,
      onSecondary: SvPalette.onPrimary,
      secondaryContainer: SvPalette.secondaryContainer,
      onSecondaryContainer: SvPalette.onSecondaryContainer,
      tertiary: SvPalette.tertiary,
      onTertiary: SvPalette.onTertiary,
      tertiaryContainer: SvPalette.tertiaryContainer,
      onTertiaryContainer: SvPalette.onTertiaryContainer,
      error: SvPalette.error,
      onError: SvPalette.onPrimary,
      errorContainer: SvPalette.errorContainer,
      onErrorContainer: SvPalette.onErrorContainer,
      surface: SvPalette.surface,
      onSurface: SvPalette.onSurface,
      onSurfaceVariant: SvPalette.onSurfaceVariant,
      outline: SvPalette.outline,
      outlineVariant: SvPalette.outlineVariant,
    );
    final base = ThemeData(useMaterial3: true, colorScheme: scheme);
    return base.copyWith(
      scaffoldBackgroundColor: SvPalette.background,
      textTheme: SvTypography.textTheme(base.textTheme),
    );
  }
}
```

- [ ] **Step 4: Verify analysis**

```bash
flutter analyze lib/core/commons/
```

Expected: `No issues found!`

- [ ] **Step 5: Commit**

```bash
git add lib/core/commons/
git commit -m "feat: add ShareVerify M3 design tokens from Stitch"
```

---

### Task 3: Domain Models + Mock Data

**Files:**
- Create: `lib/core/models/payment_status.dart`
- Create: `lib/core/models/shareholder.dart`
- Create: `lib/core/models/activity_item.dart`
- Create: `lib/core/models/dashboard_stats.dart`
- Create: `lib/core/mock/mock_data.dart`

- [ ] **Step 1: Write models**

```dart
// lib/core/models/payment_status.dart
enum PaymentStatus {
  notReceived,
  received;

  String get verificationBadgeLabel => switch (this) {
        PaymentStatus.notReceived => 'CHƯA NHẬN',
        PaymentStatus.received => 'ĐÃ NHẬN',
      };

  String get dashboardKpiLabel => switch (this) {
        PaymentStatus.notReceived => 'Chưa nhận hỗ trợ',
        PaymentStatus.received => 'Đã nhận hỗ trợ',
      };
}
```

```dart
// lib/core/models/shareholder.dart
import 'package:share_verify/core/models/payment_status.dart';

class Shareholder {
  final String code;
  final String fullName;
  final String idNumber;
  final int shares;
  final PaymentStatus status;

  const Shareholder({
    required this.code,
    required this.fullName,
    required this.idNumber,
    required this.shares,
    required this.status,
  });

  Shareholder copyWith({PaymentStatus? status}) => Shareholder(
        code: code,
        fullName: fullName,
        idNumber: idNumber,
        shares: shares,
        status: status ?? this.status,
      );
}
```

```dart
// lib/core/models/activity_item.dart
class ActivityItem {
  final String shareholderCode;
  final String fullName;
  final String timeLabel;
  final String statusLabel;

  const ActivityItem({
    required this.shareholderCode,
    required this.fullName,
    required this.timeLabel,
    required this.statusLabel,
  });
}
```

```dart
// lib/core/models/dashboard_stats.dart
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
```

- [ ] **Step 2: Write mock data (matches Stitch HTML sample values)**

```dart
// lib/core/mock/mock_data.dart
import 'package:share_verify/core/models/activity_item.dart';
import 'package:share_verify/core/models/dashboard_stats.dart';
import 'package:share_verify/core/models/payment_status.dart';
import 'package:share_verify/core/models/shareholder.dart';

class MockData {
  static const eventTitle = 'ĐẠI HỘI CỔ ĐÔNG 2026';

  static final shareholders = <Shareholder>[
    const Shareholder(
      code: 'SH0001',
      fullName: 'Nguyễn Văn A',
      idNumber: '001234567890',
      shares: 10000,
      status: PaymentStatus.notReceived,
    ),
    const Shareholder(
      code: 'SH0002',
      fullName: 'Nguyễn Văn B',
      idNumber: '001234567891',
      shares: 5000,
      status: PaymentStatus.received,
    ),
    const Shareholder(
      code: 'SH0003',
      fullName: 'Trần Thị C',
      idNumber: '001234567892',
      shares: 8000,
      status: PaymentStatus.received,
    ),
    const Shareholder(
      code: 'SH0004',
      fullName: 'Lê Hoàng D',
      idNumber: '001234567893',
      shares: 3000,
      status: PaymentStatus.received,
    ),
  ];

  static const dashboardStats = DashboardStats(
    totalShareholders: 1200,
    receivedCount: 450,
    notReceivedCount: 750,
  );

  static const recentActivities = [
    ActivityItem(
      shareholderCode: 'SH0002',
      fullName: 'Nguyễn Văn B',
      timeLabel: '08:40',
      statusLabel: 'Thành công',
    ),
    ActivityItem(
      shareholderCode: 'SH0003',
      fullName: 'Trần Thị C',
      timeLabel: '08:35',
      statusLabel: 'Thành công',
    ),
    ActivityItem(
      shareholderCode: 'SH0004',
      fullName: 'Lê Hoàng D',
      timeLabel: '08:12',
      statusLabel: 'Thành công',
    ),
  ];

  static Shareholder? findByIdNumber(String idNumber) {
    final normalized = idNumber.trim();
    if (normalized.isEmpty) return null;
    for (final s in shareholders) {
      if (s.idNumber == normalized) return s;
    }
    return null;
  }
}
```

- [ ] **Step 3: Commit**

```bash
git add lib/core/models/ lib/core/mock/
git commit -m "feat: add shareholder models and mock data"
```

---

### Task 4: Reusable Widgets

**Files:**
- Create: `lib/core/widgets/sv_primary_button.dart`
- Create: `lib/core/widgets/sv_outlined_button.dart`
- Create: `lib/core/widgets/sv_status_badge.dart`
- Create: `lib/core/widgets/sv_kpi_card.dart`
- Create: `lib/core/widgets/sv_result_info_row.dart`
- Create: `lib/core/widgets/sv_bottom_nav.dart`
- Create: `lib/core/widgets/sv_app_bar.dart`
- Create: `lib/core/widgets/sv_fab_qr.dart`
- Test: `test/widgets/sv_status_badge_test.dart`
- Test: `test/widgets/sv_kpi_card_test.dart`

- [ ] **Step 1: Write failing widget test for status badge**

```dart
// test/widgets/sv_status_badge_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:share_verify/core/models/payment_status.dart';
import 'package:share_verify/core/widgets/sv_status_badge.dart';

void main() {
  testWidgets('shows CHƯA NHẬN for notReceived status', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: SvStatusBadge(status: PaymentStatus.notReceived)),
      ),
    );
    expect(find.text('CHƯA NHẬN'), findsOneWidget);
    expect(find.text('TRẠNG THÁI'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run test — expect FAIL**

```bash
flutter test test/widgets/sv_status_badge_test.dart
```

Expected: FAIL — `SvStatusBadge` not defined.

- [ ] **Step 3: Implement `SvStatusBadge`**

```dart
// lib/core/widgets/sv_status_badge.dart
import 'package:flutter/material.dart';
import 'package:share_verify/core/commons/palette.dart';
import 'package:share_verify/core/commons/app_spacing.dart';
import 'package:share_verify/core/models/payment_status.dart';

class SvStatusBadge extends StatelessWidget {
  final PaymentStatus status;

  const SvStatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: SvPalette.tertiary,
        borderRadius: BorderRadius.circular(SvSpacing.radiusLg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'TRẠNG THÁI',
            style: theme.textTheme.labelLarge?.copyWith(
              color: SvPalette.onTertiary.withValues(alpha: 0.8),
              fontSize: 14,
            ),
          ),
          Text(
            status.verificationBadgeLabel,
            style: theme.textTheme.headlineSmall?.copyWith(
              color: SvPalette.onTertiary,
              fontWeight: FontWeight.w800,
              fontSize: 20,
            ),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 4: Implement `SvKpiCard` + test**

```dart
// test/widgets/sv_kpi_card_test.dart
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
```

```dart
// lib/core/widgets/sv_kpi_card.dart
import 'package:flutter/material.dart';
import 'package:share_verify/core/commons/app_spacing.dart';

class SvKpiCard extends StatelessWidget {
  final String label;
  final String value;
  final Color backgroundColor;
  final Color foregroundColor;
  final Color progressColor;
  final double progress;
  final IconData icon;

  const SvKpiCard({
    super.key,
    required this.label,
    required this.value,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.progress,
    required this.icon,
    this.progressColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(SvSpacing.md),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(SvSpacing.radiusXl),
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: foregroundColor),
              const SizedBox(width: 4),
              Text(
                label,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: foregroundColor.withValues(alpha: 0.9),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: theme.textTheme.headlineLarge?.copyWith(color: foregroundColor),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: progressColor.withValues(alpha: 0.3),
              valueColor: AlwaysStoppedAnimation(progressColor),
            ),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 5: Implement remaining widgets**

`SvPrimaryButton` — height 56, `borderRadius: 12`, label style `button-text` 18px w600:

```dart
// lib/core/widgets/sv_primary_button.dart
import 'package:flutter/material.dart';
import 'package:share_verify/core/commons/app_spacing.dart';
import 'package:share_verify/core/commons/palette.dart';

class SvPrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double? height;

  const SvPrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.backgroundColor,
    this.foregroundColor,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: height ?? SvSpacing.touchTarget,
      child: FilledButton.icon(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: backgroundColor ?? SvPalette.primary,
          foregroundColor: foregroundColor ?? SvPalette.onPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(SvSpacing.radiusXl),
          ),
        ),
        icon: icon != null ? Icon(icon) : const SizedBox.shrink(),
        label: Text(label, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
      ),
    );
  }
}
```

`SvBottomNav` — two tabs: `Kiểm Tra` (fact_check), `Dashboard` (dashboard); active tab gets `secondaryContainer` pill background per design.

`SvAppBar` — two variants:
- Verification: icon `corporate_fare`, title `ĐẠI HỘI CỔ ĐÔNG 2026`, subtitle live clock
- Dashboard: menu icon, title `Xác minh Trợ cấp`

`SvResultInfoRow` — icon circle + label + value (used in result card).

`SvFabQr` — 56×56 primary rounded-2xl FAB with `qr_code_scanner`.

- [ ] **Step 6: Run widget tests**

```bash
flutter test test/widgets/
```

Expected: All tests PASS.

- [ ] **Step 7: Commit**

```bash
git add lib/core/widgets/ test/widgets/
git commit -m "feat: add reusable ShareVerify UI widgets"
```

---

### Task 5: GetX Controllers

**Files:**
- Create: `lib/core/controllers/shell_controller.dart`
- Create: `lib/core/controllers/verification_controller.dart`
- Create: `lib/core/controllers/capture_controller.dart`
- Create: `lib/core/controllers/dashboard_controller.dart`
- Test: `test/controllers/verification_controller_test.dart`

- [ ] **Step 1: Write failing controller test**

```dart
// test/controllers/verification_controller_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:share_verify/core/controllers/verification_controller.dart';
import 'package:share_verify/core/models/payment_status.dart';

void main() {
  setUp(() => Get.testMode = true);
  tearDown(Get.reset);

  test('searchByIdNumber finds SH0001 mock shareholder', () {
    final c = VerificationController();
    c.idNumberInput.value = '001234567890';
    c.searchByIdNumber();
    expect(c.selectedShareholder.value?.code, 'SH0001');
    expect(c.selectedShareholder.value?.status, PaymentStatus.notReceived);
  });

  test('searchByIdNumber clears result when not found', () {
    final c = VerificationController();
    c.idNumberInput.value = '999';
    c.searchByIdNumber();
    expect(c.selectedShareholder.value, isNull);
  });
}
```

- [ ] **Step 2: Run test — expect FAIL**

```bash
flutter test test/controllers/verification_controller_test.dart
```

- [ ] **Step 3: Implement controllers**

```dart
// lib/core/controllers/shell_controller.dart
import 'package:get/get.dart';

class ShellController extends GetxController {
  final tabIndex = 0.obs;

  void switchTab(int index) => tabIndex.value = index;
}
```

```dart
// lib/core/controllers/verification_controller.dart
import 'package:get/get.dart';
import 'package:share_verify/core/mock/mock_data.dart';
import 'package:share_verify/core/models/shareholder.dart';
import 'package:share_verify/core/screens/capture/capture_evidence_screen.dart';

class VerificationController extends GetxController {
  final idNumberInput = ''.obs;
  final selectedShareholder = Rxn<Shareholder>();
  final isSearching = false.obs;

  void searchByIdNumber() {
    isSearching.value = true;
    selectedShareholder.value = MockData.findByIdNumber(idNumberInput.value);
    isSearching.value = false;
  }

  void onScanQr() {
    // Mock: auto-fill SH0001 CCCD
    idNumberInput.value = '001234567890';
    searchByIdNumber();
  }

  void onCaptureId() {
    if (selectedShareholder.value != null) {
      Get.toNamed(
        CaptureEvidenceScreen.routeName,
        arguments: selectedShareholder.value,
      );
    }
  }

  void onManualEntry() {
    // Focus handled in UI; no-op for mock
  }

  void confirmPayment() {
    final sh = selectedShareholder.value;
    if (sh == null) return;
    Get.toNamed('/success', arguments: sh);
  }
}
```

```dart
// lib/core/controllers/capture_controller.dart
import 'package:get/get.dart';
import 'package:share_verify/core/models/shareholder.dart';

class CaptureController extends GetxController {
  late final Shareholder shareholder;
  final hasCaptured = true.obs; // mock: always has preview

  @override
  void onInit() {
    shareholder = Get.arguments as Shareholder;
    super.onInit();
  }

  void retake() => hasCaptured.value = false;

  void confirm() => Get.toNamed('/success', arguments: shareholder);
}
```

```dart
// lib/core/controllers/dashboard_controller.dart
import 'package:get/get.dart';
import 'package:share_verify/core/mock/mock_data.dart';
import 'package:share_verify/core/models/activity_item.dart';
import 'package:share_verify/core/models/dashboard_stats.dart';

class DashboardController extends GetxController {
  final stats = MockData.dashboardStats.obs;
  final activities = MockData.recentActivities.obs;

  int get receivedCount => stats.value.receivedCount;
  int get notReceivedCount => stats.value.notReceivedCount;
  int get total => stats.value.totalShareholders;
  double get completionFraction => stats.value.completionPercent;
  int get completionPercentDisplay => (completionFraction * 100).round();

  List<ActivityItem> get recentActivities => activities;
}
```

- [ ] **Step 4: Run controller test — expect PASS**

```bash
flutter test test/controllers/verification_controller_test.dart
```

- [ ] **Step 5: Commit**

```bash
git add lib/core/controllers/ test/controllers/
git commit -m "feat: add GetX controllers with mock search flow"
```

---

### Task 6: Bindings + Routes + Main Entry

**Files:**
- Create: `lib/core/bindings/shell_binding.dart`
- Create: `lib/core/bindings/verification_binding.dart`
- Create: `lib/core/bindings/capture_binding.dart`
- Create: `lib/core/bindings/dashboard_binding.dart`
- Create: `lib/core/route.dart`
- Create: `lib/core/manager/init_application.dart`
- Create: `lib/core/config/app_setting.dart`
- Modify: `lib/main.dart`

- [ ] **Step 1: Write bindings (mirror inventory-mobile pattern)**

```dart
// lib/core/bindings/shell_binding.dart
import 'package:get/get.dart';
import 'package:share_verify/core/controllers/capture_controller.dart';
import 'package:share_verify/core/controllers/dashboard_controller.dart';
import 'package:share_verify/core/controllers/shell_controller.dart';
import 'package:share_verify/core/controllers/verification_controller.dart';

class ShellBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ShellController>(() => ShellController());
    Get.lazyPut<VerificationController>(() => VerificationController());
    Get.lazyPut<DashboardController>(() => DashboardController());
  }
}

class CaptureBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<CaptureController>(() => CaptureController());
  }
}
```

- [ ] **Step 2: Write routes**

```dart
// lib/core/route.dart
import 'package:get/get.dart';
import 'package:share_verify/core/bindings/shell_binding.dart';
import 'package:share_verify/core/screens/capture/capture_evidence_screen.dart';
import 'package:share_verify/core/screens/shell/shell_screen.dart';
import 'package:share_verify/core/screens/success/success_screen.dart';

class AppRoutes {
  static List<GetPage> pages() => [
        GetPage(
          name: ShellScreen.routeName,
          page: () => const ShellScreen(),
          binding: ShellBinding(),
        ),
        GetPage(
          name: CaptureEvidenceScreen.routeName,
          page: () => const CaptureEvidenceScreen(),
          binding: CaptureBinding(),
        ),
        GetPage(
          name: SuccessScreen.routeName,
          page: () => const SuccessScreen(),
        ),
      ];
}
```

- [ ] **Step 3: Write `main.dart`**

```dart
// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:share_verify/core/commons/app_theme.dart';
import 'package:share_verify/core/manager/init_application.dart';
import 'package:share_verify/core/route.dart';
import 'package:share_verify/core/screens/shell/shell_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  await InitApplication().runInit();
  runApp(const ShareVerifyApp());
}

class ShareVerifyApp extends StatelessWidget {
  const ShareVerifyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'ShareVerify',
      theme: SvAppTheme.light(),
      initialRoute: ShellScreen.routeName,
      getPages: AppRoutes.pages(),
    );
  }
}
```

```dart
// lib/core/manager/init_application.dart
class InitApplication {
  Future<void> runInit() async {
    // Reserved for future app init; no login, no Firebase.
  }
}
```

- [ ] **Step 4: Verify app compiles**

```bash
flutter analyze
flutter build apk --debug
```

Expected: No analysis errors; build succeeds.

- [ ] **Step 5: Commit**

```bash
git add lib/main.dart lib/core/route.dart lib/core/bindings/ lib/core/manager/ lib/core/config/
git commit -m "feat: wire GetX routes and app entry without login"
```

---

### Task 7: Shell Screen (Bottom Navigation)

**Files:**
- Create: `lib/core/screens/shell/shell_screen.dart`

- [ ] **Step 1: Implement shell with Obx tab switching**

```dart
// lib/core/screens/shell/shell_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:share_verify/core/controllers/shell_controller.dart';
import 'package:share_verify/core/screens/dashboard/dashboard_screen.dart';
import 'package:share_verify/core/screens/verification/verification_screen.dart';
import 'package:share_verify/core/widgets/sv_bottom_nav.dart';
import 'package:share_verify/core/widgets/sv_fab_qr.dart';
import 'package:share_verify/core/controllers/verification_controller.dart';

class ShellScreen extends GetView<ShellController> {
  static const routeName = '/shell';

  const ShellScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final verificationController = Get.find<VerificationController>();
    return Obx(() => Scaffold(
          body: IndexedStack(
            index: controller.tabIndex.value,
            children: const [
              VerificationScreen(),
              DashboardScreen(),
            ],
          ),
          floatingActionButton: controller.tabIndex.value == 0
              ? SvFabQr(onPressed: verificationController.onScanQr)
              : null,
          floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
          bottomNavigationBar: SvBottomNav(
            currentIndex: controller.tabIndex.value,
            onTap: controller.switchTab,
          ),
        ));
  }
}
```

- [ ] **Step 2: Manual smoke test**

```bash
flutter run -d chrome
```

Expected: App opens on Verification tab; tapping Dashboard switches tabs; FAB visible only on Kiểm Tra tab.

- [ ] **Step 3: Commit**

```bash
git add lib/core/screens/shell/
git commit -m "feat: add shell screen with Kiểm Tra and Dashboard tabs"
```

---

### Task 8: Verification Screen (Xác Minh Cổ Đông)

**Files:**
- Create: `lib/core/screens/verification/verification_screen.dart`
- Create: `lib/core/screens/verification/components/verification_action_buttons.dart`
- Create: `lib/core/screens/verification/components/verification_search_section.dart`
- Create: `lib/core/screens/verification/components/verification_result_section.dart`

**Design sections to implement (top → bottom):**
1. App bar: `ĐẠI HỘI CỔ ĐÔNG 2026` + live clock
2. Primary button: `Quét QR CCCD`
3. Two secondary buttons: `Chụp CCCD / Hộ Chiếu`, `Nhập Tay`
4. Search card: label `Số giấy tờ`, placeholder `Nhập CCCD / CMND / Passport`, button `Tìm Kiếm`
5. Result card (visible after search): `Mã cổ đông` SH0001, badge `CHƯA NHẬN`, rows `Họ và tên`, `Số cổ phần sở hữu` with `CP` suffix
6. CTA: `XÁC NHẬN ĐÃ PHÁT TIỀN`
7. Footer hint: `Vui lòng kiểm tra kỹ CCCD trước khi xác nhận.`

- [ ] **Step 1: Build `VerificationScreen` using `GetView<VerificationController>`**

Use `Obx` for `selectedShareholder` — show result section only when non-null.

Padding: horizontal `SvSpacing.containerMargin`, vertical gaps `SvSpacing.lg` between sections.

- [ ] **Step 2: Wire button actions**

| Button | Action |
|---|---|
| Quét QR CCCD | `controller.onScanQr()` |
| Chụp CCCD / Hộ Chiếu | `controller.onCaptureId()` (navigate to capture) |
| Nhập Tay | focus text field |
| Tìm Kiếm | `controller.searchByIdNumber()` |
| XÁC NHẬN ĐÃ PHÁT TIỀN | `controller.confirmPayment()` → `/success` |

- [ ] **Step 3: Live clock in app bar**

Use `StreamBuilder` or `Timer.periodic` updating every second, format `HH:mm:ss - dd/MM/yyyy` (Vietnamese locale via `intl`).

- [ ] **Step 4: Verify on device**

```bash
flutter run
```

Test: enter `001234567890` → search → see Nguyễn Văn A / SH0001 / CHƯA NHẬN.

- [ ] **Step 5: Commit**

```bash
git add lib/core/screens/verification/
git commit -m "feat: implement shareholder verification screen from Stitch"
```

---

### Task 9: Capture Evidence Screen (Chụp Minh Chứng)

**Files:**
- Create: `lib/core/screens/capture/capture_evidence_screen.dart`
- Create: `lib/core/screens/capture/components/capture_overlay_card.dart`

**Design sections:**
1. App bar: back arrow, title `Chụp Minh Chứng`, help icon
2. Camera preview placeholder (dark background, scanner frame corners)
3. Overlay card: `Mã Cổ Đông` SH0001, `Họ và Tên` Nguyễn Văn A, `Thông tin đã khớp`
4. Buttons: `Chụp Lại`, `Xác Nhận`
5. Hint: `Đảm bảo ảnh chụp rõ nét khuôn mặt và thẻ căn cước/hộ chiếu của cổ đông.`
6. No bottom nav on this screen (per design)

- [ ] **Step 1: Implement screen with `GetView<CaptureController>`**

Use `Stack` for camera placeholder + overlay card at bottom.

Camera placeholder: `Container(color: Colors.black)` with centered border frame (85% width, 60% height, white/50% border, primary corner accents).

- [ ] **Step 2: Wire navigation**

- Back → `Get.back()`
- `Chụp Lại` → `controller.retake()`
- `Xác Nhận` → `controller.confirm()` → `/success`

- [ ] **Step 3: Commit**

```bash
git add lib/core/screens/capture/
git commit -m "feat: implement capture evidence screen from Stitch"
```

---

### Task 10: Dashboard Screen (Bảng Điều Khiển)

**Files:**
- Create: `lib/core/screens/dashboard/dashboard_screen.dart`
- Create: `lib/core/screens/dashboard/components/progress_ring_section.dart`
- Create: `lib/core/screens/dashboard/components/recent_activity_list.dart`

**Design sections:**
1. App bar: menu, `Xác minh Trợ cấp`, account icon
2. Progress ring: `Tiến độ chi trả`, `37%`, `Hoàn thành`
3. Row: `Tổng số cổ đông` → `1,200`
4. KPI grid (2 cols): `Đã nhận hỗ trợ` 450, `Chưa nhận hỗ trợ` 750
5. `Hoạt động gần đây` + `Xem tất cả`
6. Activity rows: Nguyễn Văn B/SH0002, Trần Thị C/SH0003, Lê Hoàng D/SH0004

- [ ] **Step 1: Implement `ProgressRingSection`**

Use `CustomPaint` or `CircularProgressIndicator` with `value: 0.37` (450/1200). Center text `37%` + `Hoàn thành`.

- [ ] **Step 2: Implement KPI cards using `SvKpiCard`**

| Card | bg | label | value | progress |
|---|---|---|---|---|
| Received | `tertiaryContainer` | `Đã nhận hỗ trợ` | `450` | 450/1200 = 0.375 |
| Not received | `errorContainer` | `Chưa nhận hỗ trợ` | `750` | 750/1200 = 0.625 |

- [ ] **Step 3: Implement activity list from `DashboardController.recentActivities`**

- [ ] **Step 4: Commit**

```bash
git add lib/core/screens/dashboard/
git commit -m "feat: implement dashboard screen with KPI cards and activity list"
```

---

### Task 11: Success Screen (Thành Công)

**Files:**
- Create: `lib/core/screens/success/success_screen.dart`

**Design sections:**
1. Green check icon in `tertiaryContainer` circle
2. Title: `ĐÃ GHI NHẬN HỖ TRỢ THÀNH CÔNG`
3. Subtitle: `Thông tin trợ cấp đã được cập nhật vào hệ thống quản lý cổ đông.`
4. Detail card: `Mã cổ đông`, `Họ tên`, `Thời gian` (mock `08:45, 25/05/2024`)
5. Badge: `Hoàn tất xác minh`
6. Buttons: `Kiểm Tra Người Tiếp Theo`, `Về Trang Chủ`

- [ ] **Step 1: Read `Shareholder` from `Get.arguments`**

- [ ] **Step 2: Wire buttons**

| Button | Action |
|---|---|
| Kiểm Tra Người Tiếp Theo | `Get.offAllNamed('/shell')` + clear verification state |
| Về Trang Chủ | `Get.offAllNamed('/shell')` |

- [ ] **Step 3: Commit**

```bash
git add lib/core/screens/success/
git commit -m "feat: implement success confirmation screen from Stitch"
```

---

### Task 12: Final Verification

- [ ] **Step 1: Run all tests**

```bash
flutter test
```

Expected: All tests PASS.

- [ ] **Step 2: Run analyzer**

```bash
flutter analyze
```

Expected: No issues.

- [ ] **Step 3: Portrait layout check**

```bash
flutter run
```

Manual checklist:
- [ ] No login screen appears
- [ ] Bottom nav labels: `Kiểm Tra`, `Dashboard`
- [ ] All Vietnamese labels match design exactly
- [ ] Verification → Capture → Success flow works with mock data
- [ ] Dashboard shows 37% progress, 450/750 KPIs, 3 activity rows
- [ ] Only 4 screens exist (+ shell); no extra screens invented

- [ ] **Step 4: Final commit if any fixups**

```bash
git add -A
git commit -m "chore: finalize ShareVerify UI MVP"
```

---

## Spec Coverage Self-Review

| Requirement | Task |
|---|---|
| Stitch design as source of truth | Tasks 2, 8–11 (tokens from downloaded HTML) |
| 3 main mobile screens | Tasks 8, 9, 10 (+ shell Task 7) |
| No login | Task 6 (`initialRoute: /shell`) |
| GetX state | Tasks 5, 6 |
| inventory-mobile structure | File structure section + bindings/routes pattern |
| Reusable widgets (buttons, badges, KPI, result) | Task 4 |
| Mock data only | Task 3 |
| Vietnamese labels exact | Task 3 enums + Task 8–11 |
| Mobile portrait | Task 6 `setPreferredOrientations` |
| Material Design 3 | Task 2 `useMaterial3: true` |
| Web Admin Import Excel | **Not in Stitch project — deferred** |

## Out of Scope (This Plan)

- Backend API integration
- Real QR scanner / camera plugins
- Admin web Import Shareholder Excel (no Stitch screen)
- Login / authentication
- i18n / `.tr` translations (labels are hardcoded Vietnamese per design)

---

## Execution Handoff

Plan complete and saved to `docs/superpowers/plans/2026-06-08-shareverify-flutter-ui.md`.

**Two execution options:**

1. **Subagent-Driven (recommended)** — dispatch a fresh subagent per task, review between tasks, fast iteration
2. **Inline Execution** — execute tasks in this session using executing-plans, batch execution with checkpoints

**Which approach?**
