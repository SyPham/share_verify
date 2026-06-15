# Passport Legacy Identity (CMND/CCCD) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Mở rộng luồng CCCD+CMND đã có sang **Hộ chiếu (PASSPORT)**: khi số CMND/CCCD phụ (hộ chiếu cũ → CMND 9 số, hộ chiếu mới → CCCD 12 số) đã nhận cho MCD khác, user vẫn chụp ảnh chứng cứ + quét MCD mới thì **lưu PASSPORT + legacy + ảnh**; lần sau quét lại PASSPORT phải hiện **đủ MCD** (legacy + passport).

**Architecture:** Tái sử dụng field `ReceiverLegacyIdentityNo` và helper suy loại legacy theo độ dài số (`inferLegacyIdentityType` Flutter / `RegistrationNoHelper.InferIdentityType` .NET). Backend tổng quát hóa `BuildReceiveCheckQueries` và `ShouldAllowLegacy…Conflict` từ chỉ CCCD+CMND sang **CCCD hoặc PASSPORT** với legacy **CMND hoặc CCCD**. Flutter chỉ cần sửa autocomplete legacy + message merge; luồng `_autoReceive` / `_mergeIdentityCheckResults` đã dùng `inferLegacyIdentityType` nên phần lớn hoạt động sau khi backend mở rộng.

**Tech Stack:** Flutter 3.4+ (GetX), .NET 8, EF Core 8, PostgreSQL, xUnit, flutter_test

**Repos:**
- Flutter: `/Users/sypham/projects/becamex/share_verify`
- Backend: `/Users/sypham/projects/becamex/ShareVerify`

**Bối cảnh đã có (CCCD — không viết lại):**
- `verification_controller.dart`: `_autoReceive`, `_mergeIdentityCheckResults`, `_checkIdentityUsage` gọi check primary + legacy
- `TravelSupportService.cs`: `FindAllMatchingUsages`, `ExistsByMcdAsync`, `ShouldAllowLegacyCmndConflictOnCccdReceive` (chỉ CCCD)
- `identity_type_utils.dart`: `inferLegacyIdentityType`, `supportsLegacyIdentityField('PASSPORT')`

**Gap chính cần đóng:**
| Khu vực | Hiện tại | Cần |
|---------|----------|-----|
| Backend `BuildReceiveCheckQueries` | Chỉ thêm legacy query khi `IdentityType == CCCD`, luôn `CMND` | Thêm khi `PASSPORT`; legacy type = CMND hoặc CCCD |
| Backend `ShouldAllowLegacy…` | Chỉ CCCD primary + CMND legacy | PASSPORT primary + CMND/CCCD legacy |
| Backend lưu `ReceiverLegacyIdentityNo` | Normalize cứng `IdentityType.Cmnd` | Normalize theo `InferIdentityType(legacyNo)` |
| Flutter autocomplete legacy PASSPORT | `registrationNoAutocompleteIdentityType(..., legacy: true)` → `null` | Trả `CMND` hoặc `CCCD` theo số |
| Flutter merge message | Chỉ message CCCD+CMND | Thêm message PASSPORT+legacy |

---

## File map

| File | Trách nhiệm |
|------|-------------|
| `ShareVerify.Application/Helpers/LegacyIdentityHelper.cs` | **Create** — suy `CMND`/`CCCD` từ số legacy (wrap `RegistrationNoHelper.InferIdentityType`) |
| `ShareVerify.Infrastructure/Services/TravelSupportService.cs` | Tổng quát hóa receive check queries + allow-legacy-conflict + normalize legacy khi lưu |
| `ShareVerify/tests/.../TravelSupportServiceTests.cs` | Test receive/check passport + legacy CMND/CCCD |
| `ShareVerify/tests/.../LegacyIdentityHelperTests.cs` | **Create** — unit test helper |
| `share_verify/lib/core/utils/identity_type_utils.dart` | Autocomplete legacy cho PASSPORT |
| `share_verify/lib/core/controllers/verification_controller.dart` | Message merge passport |
| `share_verify/lib/core/controllers/capture_controller.dart` | Message merge passport (mirror) |
| `share_verify/test/utils/identity_type_utils_test.dart` | Test autocomplete legacy passport |
| `share_verify/test/controllers/verification_controller_test.dart` | Test receive passport + legacy used |

---

### Task 1: Backend helper — suy loại legacy CMND/CCCD

**Files:**
- Create: `ShareVerify/src/ShareVerify.Application/Helpers/LegacyIdentityHelper.cs`
- Create: `ShareVerify/tests/ShareVerify.Tests/Helpers/LegacyIdentityHelperTests.cs`

- [ ] **Step 1: Write the failing test**

```csharp
// ShareVerify/tests/ShareVerify.Tests/Helpers/LegacyIdentityHelperTests.cs
using FluentAssertions;
using ShareVerify.Application.Helpers;
using ShareVerify.Domain.Enums;

namespace ShareVerify.Tests.Helpers;

public class LegacyIdentityHelperTests
{
    [Theory]
    [InlineData("123456789", IdentityType.Cmnd)]
    [InlineData("001234567890", IdentityType.Cccd)]
    [InlineData("079-090-001-234", IdentityType.Cccd)]
    public void InferLegacyIdentityType_ReturnsCmndOrCccd(string legacyNo, string expected)
    {
        LegacyIdentityHelper.InferLegacyIdentityType(legacyNo)
            .Should().Be(expected);
    }

    [Fact]
    public void InferLegacyIdentityType_ReturnsNullForInvalidLength()
    {
        LegacyIdentityHelper.InferLegacyIdentityType("12345").Should().BeNull();
        LegacyIdentityHelper.InferLegacyIdentityType(null).Should().BeNull();
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd /Users/sypham/projects/becamex/ShareVerify && dotnet test tests/ShareVerify.Tests/ShareVerify.Tests.csproj --filter "FullyQualifiedName~LegacyIdentityHelperTests" -v n`

Expected: FAIL — `LegacyIdentityHelper` not found

- [ ] **Step 3: Write minimal implementation**

```csharp
// ShareVerify/src/ShareVerify.Application/Helpers/LegacyIdentityHelper.cs
using ShareVerify.Domain.Enums;

namespace ShareVerify.Application.Helpers;

public static class LegacyIdentityHelper
{
    /// <summary>
    /// Hộ chiếu cũ → CMND (9 số). Hộ chiếu mới → CCCD (12 số).
    /// CCCD kèm CMND phụ → CMND (9 số).
    /// </summary>
    public static string? InferLegacyIdentityType(string? legacyIdentityNo)
        => RegistrationNoHelper.InferIdentityType(legacyIdentityNo);
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `dotnet test tests/ShareVerify.Tests/ShareVerify.Tests.csproj --filter "FullyQualifiedName~LegacyIdentityHelperTests" -v n`

Expected: PASS (2 tests)

- [ ] **Step 5: Commit**

```bash
git add src/ShareVerify.Application/Helpers/LegacyIdentityHelper.cs \
        tests/ShareVerify.Tests/Helpers/LegacyIdentityHelperTests.cs
git commit -m "feat: add LegacyIdentityHelper for CMND/CCCD inference"
```

---

### Task 2: Backend — mở rộng `BuildReceiveCheckQueries` cho PASSPORT

**Files:**
- Modify: `ShareVerify/src/ShareVerify.Infrastructure/Services/TravelSupportService.cs` (method `BuildReceiveCheckQueries`, ~281-308)
- Test: `ShareVerify/tests/ShareVerify.Tests/Services/TravelSupportServiceTests.cs`

- [ ] **Step 1: Write the failing test**

Thêm vào `TravelSupportServiceTests.cs`:

```csharp
[Fact]
public async Task ReceiveAsync_PassportWithUsedLegacyCmnd_AllowsReceiveWhenPassportNotUsed()
{
    var person = new Person { Id = 2, FullName = "Le Thi B" };
    var shareholder = new Shareholder { Mcd = "MCD-B", FullName = "Le Thi B" };
    var history = new List<TravelSupport>
    {
        new()
        {
            PersonId = 1,
            Mcd = "MCD-A",
            ReceiverName = "LE THI B",
            ReceiverIdentityNo = "123456789",
            IdentityType = IdentityType.Cmnd,
            ReceiveTime = DateTime.UtcNow,
        },
    };

    var shareholderRepository = new Mock<IShareholderRepository>();
    shareholderRepository
        .Setup(r => r.GetByMcdAsync("MCD-B", It.IsAny<CancellationToken>()))
        .ReturnsAsync(shareholder);

    var personService = new Mock<IPersonService>();
    personService
        .Setup(s => s.FindOrCreateForShareholderAsync(shareholder, It.IsAny<CancellationToken>()))
        .ReturnsAsync(person);

    var travelSupportRepository = new Mock<ITravelSupportRepository>();
    travelSupportRepository
        .Setup(r => r.ExistsByMcdAsync("MCD-B", It.IsAny<CancellationToken>()))
        .ReturnsAsync(false);
    travelSupportRepository
        .Setup(r => r.GetIdentityHistoryAsync(It.IsAny<CancellationToken>()))
        .ReturnsAsync(history);
    travelSupportRepository
        .Setup(r => r.AddAsync(It.IsAny<TravelSupport>(), It.IsAny<CancellationToken>()))
        .Returns(Task.CompletedTask);

    var unitOfWork = new Mock<IUnitOfWork>();
    unitOfWork
        .Setup(u => u.ExecuteInTransactionAsync(It.IsAny<Func<Task>>(), It.IsAny<CancellationToken>()))
        .Returns<Func<Task>, CancellationToken>((action, _) => action());

    var auditLogRepository = new Mock<IAuditLogRepository>();
    auditLogRepository
        .Setup(r => r.AddAsync(It.IsAny<AuditLog>(), It.IsAny<CancellationToken>()))
        .Returns(Task.CompletedTask);

    var service = new TravelSupportService(
        shareholderRepository.Object,
        travelSupportRepository.Object,
        auditLogRepository.Object,
        unitOfWork.Object,
        new Mock<IMapper>().Object,
        personService.Object,
        new Mock<IPersonRepository>().Object);

    var request = new ReceiveTravelSupportRequest
    {
        Mcd = "MCD-B",
        ReceiverName = "LE THI B",
        ReceiverIdentityNo = "C1234567",
        IdentityType = IdentityType.Passport,
        ReceiverLegacyIdentityNo = "123456789",
        AttendanceType = AttendanceType.Direct,
        PhotoPath = "uploads/passport.jpg",
        ReceiveAmount = 100000,
    };

    await service.ReceiveAsync(request);

    travelSupportRepository.Verify(
        r => r.AddAsync(
            It.Is<TravelSupport>(ts =>
                ts.Mcd == "MCD-B"
                && ts.IdentityType == IdentityType.Passport
                && ts.ReceiverIdentityNo == "C1234567"
                && ts.ReceiverLegacyIdentityNo == "123456789"
                && ts.PhotoPath == "uploads/passport.jpg"),
            It.IsAny<CancellationToken>()),
        Times.Once);
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `dotnet test tests/ShareVerify.Tests/ShareVerify.Tests.csproj --filter "ReceiveAsync_PassportWithUsedLegacyCmnd" -v n`

Expected: FAIL — `ConflictException` (legacy CMND block) hoặc verify `Times.Never`

- [ ] **Step 3: Refactor `BuildReceiveCheckQueries`**

Thay block chỉ-CCCD (~289-306) bằng:

```csharp
if (!string.Equals(request.AttendanceType, AttendanceType.Proxy, StringComparison.OrdinalIgnoreCase)
    && !string.IsNullOrWhiteSpace(request.ReceiverLegacyIdentityNo))
{
    var primaryType = request.IdentityType ?? string.Empty;
    if (string.Equals(primaryType, IdentityType.Cccd, StringComparison.OrdinalIgnoreCase)
        || string.Equals(primaryType, IdentityType.Passport, StringComparison.OrdinalIgnoreCase))
    {
        var legacyType = LegacyIdentityHelper.InferLegacyIdentityType(
            request.ReceiverLegacyIdentityNo);
        if (legacyType is not null)
        {
            queries.Add(new IdentityCheckRequest
            {
                IdentityNo = request.ReceiverLegacyIdentityNo,
                IdentityType = legacyType,
                FullName = request.ReceiverName,
                DateOfBirth = request.ReceiverDateOfBirth,
            });
        }
    }
}
```

- [ ] **Step 4: Run test — still fails until Task 3**

Expected: vẫn FAIL (legacy conflict chưa được skip)

- [ ] **Step 5: Commit (optional partial — có thể gộp Task 3)**

---

### Task 3: Backend — tổng quát hóa `ShouldAllowLegacyConflictOnPrimaryReceive`

**Files:**
- Modify: `ShareVerify/src/ShareVerify.Infrastructure/Services/TravelSupportService.cs`
  - Rename/refactor `ShouldAllowLegacyCmndConflictOnCccdReceive` → `ShouldAllowLegacyIdentityConflictOnPrimaryReceive`
  - Update `EnsureIdentityNotAlreadyUsedAsync` call site
  - Fix normalize legacy khi lưu (~71-73)

- [ ] **Step 1: Write failing test for PASSPORT + legacy CCCD**

```csharp
[Fact]
public async Task ReceiveAsync_PassportWithUsedLegacyCccd_AllowsReceiveWhenPassportNotUsed()
{
    // history: MCD-A received with CCCD 001234567890
    // request: PASSPORT C1234567 + legacy 001234567890 for MCD-B
    // Expect: AddAsync once, no ConflictException
}
```

(Copy structure từ test Task 2 Step 1; đổi history sang `IdentityType.Cccd`, legacy 12 số.)

- [ ] **Step 2: Run test — verify FAIL**

Run: `dotnet test ... --filter "PassportWithUsedLegacyCccd" -v n`

- [ ] **Step 3: Replace `ShouldAllowLegacyCmndConflictOnCccdReceive`**

```csharp
private static bool ShouldAllowLegacyIdentityConflictOnPrimaryReceive(
    IdentityCheckRequest query,
    ReceiveTravelSupportRequest request,
    IReadOnlyList<TravelSupport> history)
{
    if (!string.Equals(request.AttendanceType, AttendanceType.Direct, StringComparison.OrdinalIgnoreCase))
        return false;

    var primaryType = request.IdentityType ?? string.Empty;
    if (!string.Equals(primaryType, IdentityType.Cccd, StringComparison.OrdinalIgnoreCase)
        && !string.Equals(primaryType, IdentityType.Passport, StringComparison.OrdinalIgnoreCase))
    {
        return false;
    }

    if (string.IsNullOrWhiteSpace(request.ReceiverLegacyIdentityNo))
        return false;

    var legacyType = LegacyIdentityHelper.InferLegacyIdentityType(
        request.ReceiverLegacyIdentityNo);
    if (legacyType is null)
        return false;

    if (!string.Equals(query.IdentityType, legacyType, StringComparison.OrdinalIgnoreCase))
        return false;

    var legacyNormalized = PersonIdentityNormalizer.NormalizeIdentityNo(
        request.ReceiverLegacyIdentityNo, legacyType);
    var queryNormalized = PersonIdentityNormalizer.NormalizeIdentityNo(
        query.IdentityNo, legacyType);
    if (legacyNormalized is null || queryNormalized is null
        || !string.Equals(legacyNormalized, queryNormalized, StringComparison.Ordinal))
    {
        return false;
    }

    var primaryQuery = new IdentityCheckRequest
    {
        IdentityNo = request.ReceiverIdentityNo,
        IdentityType = primaryType,
        FullName = request.ReceiverName,
        DateOfBirth = request.ReceiverDateOfBirth,
    };

    return FindMatchingUsage(primaryQuery, history) is null;
}
```

Cập nhật `EnsureIdentityNotAlreadyUsedAsync`:

```csharp
if (ShouldAllowLegacyIdentityConflictOnPrimaryReceive(query, request, history))
    continue;
```

- [ ] **Step 4: Fix legacy normalize khi persist**

Trong `ReceiveAsync`, thay:

```csharp
ReceiverLegacyIdentityNo = NormalizeIdentityNoForStorage(
    request.ReceiverLegacyIdentityNo,
    IdentityType.Cmnd),
```

bằng:

```csharp
ReceiverLegacyIdentityNo = NormalizeLegacyIdentityNoForStorage(
    request.ReceiverLegacyIdentityNo),
```

Thêm helper private:

```csharp
private static string? NormalizeLegacyIdentityNoForStorage(string? legacyIdentityNo)
{
    if (string.IsNullOrWhiteSpace(legacyIdentityNo))
        return legacyIdentityNo;

    var legacyType = LegacyIdentityHelper.InferLegacyIdentityType(legacyIdentityNo);
    return legacyType is null
        ? legacyIdentityNo.Trim()
        : NormalizeIdentityNoForStorage(legacyIdentityNo, legacyType);
}
```

- [ ] **Step 5: Run all TravelSupportService tests**

Run: `dotnet test tests/ShareVerify.Tests/ShareVerify.Tests.csproj --filter "FullyQualifiedName~TravelSupportServiceTests" -v n`

Expected: PASS (bao gồm test CCCD cũ + 2 test passport mới)

- [ ] **Step 6: Commit**

```bash
git add src/ShareVerify.Infrastructure/Services/TravelSupportService.cs \
        tests/ShareVerify.Tests/Services/TravelSupportServiceTests.cs
git commit -m "feat: allow passport receive when legacy CMND/CCCD already used for other MCD"
```

---

### Task 4: Backend — `CheckIdentityAsync` trả đủ MCD cho legacy passport

**Files:**
- Modify: `ShareVerify/tests/ShareVerify.Tests/Services/TravelSupportServiceTests.cs`
- Verify: `TravelSupportService.FindAllMatchingUsages` + `MatchesReceiver` (legacy field) — **không cần sửa nếu test pass**

- [ ] **Step 1: Write failing test**

```csharp
[Fact]
public async Task CheckIdentityAsync_PassportLegacyCmndMatchesMultipleRecords_ReturnsAllMcds()
{
    var history = new List<TravelSupport>
    {
        new()
        {
            PersonId = 1,
            Mcd = "MCD-A",
            ReceiverIdentityNo = "123456789",
            IdentityType = IdentityType.Cmnd,
            ReceiveTime = new DateTime(2026, 6, 10, 8, 0, 0, DateTimeKind.Utc),
        },
        new()
        {
            PersonId = 2,
            Mcd = "MCD-B",
            ReceiverIdentityNo = "C1234567",
            IdentityType = IdentityType.Passport,
            ReceiverLegacyIdentityNo = "123456789",
            ReceiveTime = new DateTime(2026, 6, 11, 8, 0, 0, DateTimeKind.Utc),
        },
    };

    // setup mocks giống CheckIdentityAsync_LegacyCmndMatchesMultipleRecords_ReturnsAllMcds
    var result = await service.CheckIdentityAsync(new IdentityCheckRequest
    {
        IdentityNo = "123456789",
        IdentityType = IdentityType.Cmnd,
    });

    result.AlreadyUsed.Should().BeTrue();
    result.UsedForMcds.Should().BeEquivalentTo(["MCD-A", "MCD-B"]);
}
```

- [ ] **Step 2: Run test**

Run: `dotnet test ... --filter "PassportLegacyCmndMatchesMultipleRecords" -v n`

Expected: PASS ngay (logic `FindAllMatchingUsages` đã có) — nếu FAIL thì sửa `MatchesReceiver` cho passport legacy

- [ ] **Step 3: Commit test only (nếu pass)**

```bash
git commit -m "test: passport legacy CMND check returns all MCDs"
```

---

### Task 5: Flutter — autocomplete legacy cho PASSPORT

**Files:**
- Modify: `share_verify/lib/core/utils/identity_type_utils.dart` (~34-47)
- Test: `share_verify/test/utils/identity_type_utils_test.dart`

- [ ] **Step 1: Write the failing test**

Thay test `registrationNoAutocompleteIdentityType maps legacy CMND for CCCD`:

```dart
test('registrationNoAutocompleteIdentityType maps legacy type by digit length', () {
  expect(registrationNoAutocompleteIdentityType('CCCD'), 'CCCD');
  expect(registrationNoAutocompleteIdentityType('PASSPORT'), 'PASSPORT');
  expect(
    registrationNoAutocompleteIdentityType('CCCD', legacy: true),
    'CMND',
  );
  expect(
    registrationNoAutocompleteIdentityType('PASSPORT', legacy: true),
    isNull,
  );
  expect(
    registrationNoAutocompleteIdentityType(
      'PASSPORT',
      legacy: true,
      legacyIdentityNo: '123456789',
    ),
    'CMND',
  );
  expect(
    registrationNoAutocompleteIdentityType(
      'PASSPORT',
      legacy: true,
      legacyIdentityNo: '001234567890',
    ),
    'CCCD',
  );
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd /Users/sypham/projects/becamex/share_verify && flutter test test/utils/identity_type_utils_test.dart -v`

Expected: FAIL — named param `legacyIdentityNo` chưa tồn tại / legacy PASSPORT vẫn null

- [ ] **Step 3: Implement**

```dart
String? registrationNoAutocompleteIdentityType(
  String identityType, {
  bool legacy = false,
  String? legacyIdentityNo,
}) {
  final upper = identityType.toUpperCase();
  if (legacy) {
    if (upper == 'CCCD') return 'CMND';
    if (upper == 'PASSPORT') {
      return inferLegacyIdentityType(legacyIdentityNo ?? '');
    }
    return null;
  }
  if (upper == 'CMND') return 'CMND';
  if (upper == 'CCCD') return 'CCCD';
  if (upper == 'PASSPORT') return 'PASSPORT';
  return null;
}
```

**Lưu ý:** `inferLegacyIdentityType` trả `String` ('CMND'/'CCCD'), không nullable — cần wrapper:

```dart
String? inferLegacyIdentityTypeOrNull(String? value) {
  if (value == null || value.trim().isEmpty) return null;
  final digits = value.replaceAll(RegExp(r'\D'), '');
  if (digits.length == 12) return 'CCCD';
  if (digits.length == 9) return 'CMND';
  return null;
}
```

Dùng `inferLegacyIdentityTypeOrNull` trong autocomplete (tách khỏi hàm hiện có hoặc đổi return type — ưu tiên thêm hàm mới để không break call sites).

- [ ] **Step 4: Cập nhật call site autocomplete**

File: `share_verify/lib/core/widgets/registration_no_autocomplete_field.dart` hoặc nơi gọi `registrationNoAutocompleteIdentityType` cho legacy field — truyền `legacyIdentityNo: controller.text` khi type PASSPORT.

File: `share_verify/lib/core/screens/verification/components/verification_manual_identity_form.dart` — legacy CMND/CCCD field cho PASSPORT.

File: `share_verify/lib/core/screens/capture/components/capture_identity_review_fields.dart` — tương tự.

- [ ] **Step 5: Run tests**

Run: `flutter test test/utils/identity_type_utils_test.dart test/widgets/capture_identity_review_fields_test.dart -v`

Expected: PASS

- [ ] **Step 6: Commit**

```bash
git add lib/core/utils/identity_type_utils.dart \
        lib/core/widgets/registration_no_autocomplete_field.dart \
        lib/core/screens/verification/components/verification_manual_identity_form.dart \
        lib/core/screens/capture/components/capture_identity_review_fields.dart \
        test/utils/identity_type_utils_test.dart
git commit -m "feat: passport legacy autocomplete uses CMND or CCCD by length"
```

---

### Task 6: Flutter — message merge cho PASSPORT + legacy

**Files:**
- Modify: `share_verify/lib/core/controllers/verification_controller.dart` (`_mergeIdentityCheckResults`)
- Modify: `share_verify/lib/core/controllers/capture_controller.dart` (mirror)
- Test: `share_verify/test/controllers/verification_controller_test.dart`

- [ ] **Step 1: Write failing test**

```dart
test('passport with used legacy CMND shows warning and persists receive', () async {
  travelSupportRepository.checkIdentityResult = const IdentityCheckResultDto(
    alreadyUsed: true,
    usedForMcd: 'SH0002',
    usedForMcds: ['SH0002'],
    message: 'Số CMND đã được sử dụng',
  );

  final c = createController();
  await c.applyCaptureResult(
    const IdentityVerification(
      identityNo: 'C1234567',
      identityType: 'PASSPORT',
      receiverName: 'Lê Thị B',
      legacyIdentityNo: '123456789',
      photoPath: 'uploads/passport.jpg',
    ),
  );

  expect(c.hasIdentityUsageWarning, isTrue);

  await c.onBarcodeScanned('SH0001');

  expect(travelSupportRepository.receiveCallCount, 1);
  expect(travelSupportRepository.lastIdentity?.identityType, 'PASSPORT');
  expect(travelSupportRepository.lastIdentity?.legacyIdentityNo, '123456789');
});
```

- [ ] **Step 2: Run test**

Run: `flutter test test/controllers/verification_controller_test.dart --name "passport with used legacy" -v`

Expected: PASS nếu `_autoReceive` đã gọi (logic hiện tại) — test document behavior

- [ ] **Step 3: Update merge message**

Trong `_mergeIdentityCheckResults` (cả 2 controller), thay:

```dart
final isCccdWithLegacy = primaryIdentityType?.toUpperCase() == 'CCCD';
```

bằng:

```dart
String? legacyUsedMessage(String? primaryType) {
  return switch (primaryType?.toUpperCase()) {
    'CCCD' =>
      'Số CMND đã được sử dụng. Số CCCD này coi như đã nhận phụ cấp.',
    'PASSPORT' =>
      'Số CMND/CCCD phụ đã được sử dụng. Hộ chiếu này coi như đã nhận phụ cấp.',
    _ => null,
  };
}
```

Dùng `legacyUsedMessage(primaryIdentityType)` trong nhánh `!primary.alreadyUsed && legacy.alreadyUsed`.

- [ ] **Step 4: Run controller tests**

Run: `flutter test test/controllers/verification_controller_test.dart test/controllers/capture_controller_test.dart -v`

Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add lib/core/controllers/verification_controller.dart \
        lib/core/controllers/capture_controller.dart \
        test/controllers/verification_controller_test.dart
git commit -m "feat: passport legacy identity warning messages and receive flow"
```

---

### Task 7: Manual QA checklist

- [ ] **Restart API** sau khi deploy backend: `dotnet run` (project `ShareVerify.Api`)

- [ ] **Scenario A — Hộ chiếu cũ + CMND 9 số đã nhận MCD A**
  1. Nhập/chụp PASSPORT + legacy CMND (9 số) đã tồn tại history MCD A
  2. Cảnh báo hiện MCD A
  3. Chụp ảnh chứng cứ → Quét MCD B
  4. Expect: màn success, MCD B status = received, DB có record PASSPORT + legacy CMND + photoPath

- [ ] **Scenario B — Hộ chiếu mới + CCCD 12 số đã nhận MCD A**
  1. Legacy = CCCD 12 số đã dùng cho MCD A
  2. PASSPORT mới + ảnh → quét MCD B
  3. Expect: lưu thành công

- [ ] **Scenario C — Quét lại PASSPORT**
  1. Sau A hoặc B, quét/chụp lại cùng PASSPORT + legacy
  2. Expect: cảnh báo hiện **cả MCD A và MCD B** trong `usedForMcds`

- [ ] **Scenario D — Regression CCCD**
  1. Chạy lại scenario CCCD+CMND từ plan trước
  2. Expect: không regress

---

## Self-review

| Yêu cầu spec | Task |
|--------------|------|
| Hộ chiếu cũ → CMND legacy | Task 1, 5 (`inferLegacyIdentityTypeOrNull` 9 số) |
| Hộ chiếu mới → CCCD legacy | Task 1, 5 (12 số) |
| Lưu PASSPORT + MCD + chứng cứ khi legacy đã dùng | Task 2, 3 |
| Hiện đủ MCD khi quét lại PASSPORT | Task 4 |
| UI/autocomplete/message Flutter | Task 5, 6 |
| QA | Task 7 |

**Placeholder scan:** Không có TBD/TODO/similar-to.

**Type consistency:** `LegacyIdentityHelper.InferLegacyIdentityType` (.NET) ↔ `inferLegacyIdentityTypeOrNull` (Flutter) — cùng rule 9=CMND, 12=CCCD.

---

## Execution Handoff

Plan complete and saved to `docs/superpowers/plans/2026-06-12-passport-legacy-identity-receive.md`. Two execution options:

**1. Subagent-Driven (recommended)** — dispatch a fresh subagent per task, review between tasks, fast iteration

**2. Inline Execution** — execute tasks in this session using executing-plans, batch execution with checkpoints

Which approach?
