# Person-Based Travel Support Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Chuyển luồng xác minh ShareVerify sang quét mã thiệp mời (MCD) là bước đầu tiên, xác minh giấy tờ chỉ làm bằng chứng, và chặn trùng phụ cấp theo Person (không theo MCD hay số giấy tờ).

**Architecture:** Mở rộng backend .NET hiện có (Clean Architecture 4 lớp) bằng entity `Person` + `PersonShareholder`, đổi khóa chặn trùng `TravelSupport` từ `Mcd` sang `PersonId`. Flutter app (GetX) tái cấu trúc `VerificationController` theo 5 bước UI mới, tái sử dụng repositories/controllers hiện có.

**Tech Stack:** .NET 8, EF Core 8, PostgreSQL, FluentValidation, AutoMapper | Flutter 3.4+, GetX, Dio, mobile_scanner, google_mlkit_text_recognition (OCR)

---

## Phần 1 — Phân tích kiến trúc hiện tại

### Backend (.NET) — `/Users/sypham/projects/becamex/ShareVerify`

| Lớp | Vai trò |
|-----|---------|
| `ShareVerify.Domain` | Entities: `Shareholder`, `TravelSupport`, `EvidencePhoto`, `AuditLog` |
| `ShareVerify.Application` | DTOs, validators, interfaces, `ShareholderService`, `DashboardService` |
| `ShareVerify.Infrastructure` | EF Core, repositories, `TravelSupportService`, `ExcelImportService`, `PhotoService` |
| `ShareVerify.Api` | Controllers, middleware, DI |

**Luồng hiện tại:**
1. Client tìm cổ đông theo số giấy tờ (`GET /api/shareholders/search?keyword=`)
2. Hiển thị thông tin + trạng thái `TravelSupportReceived` (theo **MCD**)
3. `POST /api/travel-support/receive` — chặn trùng bằng unique index `IX_TravelSupport_Mcd`

**Hạn chế so với yêu cầu mới:**
- Không có entity `Person` / `PersonShareholder`
- Chặn trùng theo MCD → cùng một người với 2 MCD vẫn nhận 2 lần
- Không hỗ trợ ủy quyền (proxy attendance)
- Giấy tờ (`ReceiverIdentityNo`) được lưu nhưng không tách biệt vai trò "bằng chứng" vs "chặn trùng"
- Backend không có logic barcode — client phải tự parse

### Flutter — `/Users/sypham/projects/becamex/share_verify`

| Thành phần | Vai trò |
|------------|---------|
| `VerificationController` | Tìm cổ đông theo số giấy tờ, confirm payment |
| `CaptureController` | Chụp minh chứng (stub), upload + receive |
| `ShareholderRepository` | `findByKeyword()` — ưu tiên số giấy tờ |
| `TravelSupportRepository` | `receive()` — gửi `identityType: 'CCCD'` cứng |
| `VerificationScreen` | UI: QR CCCD → Tìm kiếm → Kết quả → Xác nhận |

**Luồng UI hiện tại (sai so với spec mới):**
```
Quét QR CCCD / Nhập số giấy tờ → Tìm cổ đông → Xác nhận phát tiền
```

**Luồng UI mới (yêu cầu):**
```
Quét mã thiệp mời (MCD) → Hiển thị cổ đông → Xác minh giấy tờ (4 cách)
→ Chọn Direct/Proxy → Trạng thái Person → Xác nhận phát tiền
```

**Stub chưa implement:** QR scanner thật, camera, OCR — chỉ có mock ID.

---

## Phần 2 — Tổng quan thay đổi

### 2.1 Thay đổi Database

| Hành động | Chi tiết |
|-----------|----------|
| **Tạo bảng `Person`** | `Id`, `FullName`, `IdentityNo?`, `IdentityType?`, `Phone?`, `CreatedAt` |
| **Tạo bảng `PersonShareholder`** | `Id`, `PersonId` (FK), `Mcd` — unique `(PersonId, Mcd)` và unique `Mcd` |
| **Sửa bảng `TravelSupport`** | Thêm `PersonId` (FK, **UNIQUE**), `AttendanceType`, `ProxyPersonName?`, `ProxyIdentityNo?`, `ProxyIdentityType?` |
| **Bỏ unique `TravelSupport.Mcd`** | Cho phép nhiều MCD thuộc cùng Person; chỉ 1 bản ghi TravelSupport/Person |
| **Migration dữ liệu cũ** | Tạo `Person` + `PersonShareholder` từ `TravelSupport` hiện có |

### 2.2 Thay đổi API

| Endpoint | Thay đổi |
|----------|----------|
| `GET /api/shareholders/{mcd}` | `TravelSupportReceived` → kiểm tra theo **PersonId** (không chỉ MCD) |
| `GET /api/shareholders/search` | Join `Person` → `TravelSupportReceived` theo Person |
| `POST /api/travel-support/receive` | Thêm fields proxy/attendance; logic Find-or-Create Person; chặn trùng `PersonId`; message 409: `"This person has already received the allowance."` |
| `GET /api/travel-support/recent` | Thêm `AttendanceType`, `ProxyPersonName` (optional) |
| `GET /api/dashboard/summary` | Không đổi logic (đếm `TravelSupport` records = số Person đã nhận) |

**DTO mới / sửa:**

```csharp
// ReceiveTravelSupportRequest — thêm fields
public string AttendanceType { get; set; }  // "Direct" | "Proxy"
public string? ProxyPersonName { get; set; }
public string? ProxyIdentityNo { get; set; }
public string? ProxyIdentityType { get; set; }

// ShareholderDetailDto — thêm
public bool AllowanceReceived { get; set; }  // person-level (thay thế logic cũ)
public long? PersonId { get; set; }
```

### 2.3 Files Backend cần tạo/sửa

**Tạo mới:**
- `ShareVerify.Domain/Entities/Person.cs`
- `ShareVerify.Domain/Entities/PersonShareholder.cs`
- `ShareVerify.Domain/Enums/AttendanceType.cs`
- `ShareVerify.Infrastructure/Data/Configurations/PersonConfiguration.cs`
- `ShareVerify.Infrastructure/Data/Configurations/PersonShareholderConfiguration.cs`
- `ShareVerify.Application/Interfaces/IPersonRepository.cs`
- `ShareVerify.Infrastructure/Repositories/PersonRepository.cs`
- `ShareVerify.Infrastructure/Migrations/20260608_AddPersonEntities.cs` (tên EF generate)
- `ShareVerify.Tests/` (project mới — unit tests)

**Sửa:**
- `ShareVerify.Domain/Entities/TravelSupport.cs` — thêm PersonId, AttendanceType, proxy fields
- `ShareVerify.Infrastructure/Data/Configurations/TravelSupportConfiguration.cs` — unique PersonId, bỏ unique Mcd
- `ShareVerify.Infrastructure/Data/AppDbContext.cs` — DbSet Person, PersonShareholder
- `ShareVerify.Application/DTOs/TravelSupportDtos.cs` — request/response mới
- `ShareVerify.Application/DTOs/ShareholderDtos.cs` — AllowanceReceived, PersonId
- `ShareVerify.Application/Validators/ReceiveTravelSupportValidator.cs` — validate AttendanceType, proxy fields
- `ShareVerify.Application/Interfaces/ITravelSupportRepository.cs` — `ExistsByPersonIdAsync`, `GetByPersonIdAsync`
- `ShareVerify.Infrastructure/Repositories/TravelSupportRepository.cs` — implement methods mới
- `ShareVerify.Infrastructure/Repositories/ShareholderRepository.cs` — join Person cho status
- `ShareVerify.Infrastructure/Services/TravelSupportService.cs` — logic Person matching + receive
- `ShareVerify.Application/Services/ShareholderService.cs` — person-level status trong GetDetail
- `ShareVerify.Infrastructure/DependencyInjection.cs` — register IPersonRepository
- `ShareVerify.Application/Mappings/MappingProfile.cs` — map fields mới

### 2.4 Thay đổi UI Flutter

| Bước UI | Component | Thay đổi |
|---------|-----------|----------|
| 1. Quét mã thiệp mời | `VerificationBarcodeSection` (mới) | Nút quét barcode → parse MCD → `GET /api/shareholders/{mcd}` |
| 2. Hiển thị cổ đông | `VerificationResultSection` (sửa) | Hiển thị ngay sau quét; bỏ phụ thuộc tìm theo giấy tờ |
| 3. Xác minh giấy tờ | `VerificationIdentitySection` (mới) | 4 phương thức: QR CCCD, Chụp CCCD, Chụp Passport, Nhập tay |
| 4. Loại tham dự | `VerificationAttendanceSection` (mới) | Radio Direct / Proxy; form proxy khi chọn Proxy |
| 5. Trạng thái | `SvStatusBadge` (sửa) | Xanh `CHƯA NHẬN` / Đỏ `ĐÃ NHẬN` theo Person |
| 6. Xác nhận | `VerificationResultSection` (sửa) | Disable nút khi `status == received` |

### 2.5 Files Flutter cần tạo/sửa

**Tạo mới:**
- `lib/core/models/attendance_type.dart`
- `lib/core/models/identity_verification.dart`
- `lib/core/models/invitation_barcode.dart`
- `lib/core/utils/barcode_parser.dart`
- `lib/core/screens/verification/components/verification_barcode_section.dart`
- `lib/core/screens/verification/components/verification_identity_section.dart`
- `lib/core/screens/verification/components/verification_attendance_section.dart`
- `lib/core/screens/verification/components/verification_proxy_form.dart`
- `lib/core/services/barcode_scanner_service.dart` (wrapper mobile_scanner)
- `lib/core/services/ocr_service.dart` (wrapper ML Kit — stub OK giai đoạn 1)
- `test/utils/barcode_parser_test.dart`
- `test/controllers/verification_controller_barcode_test.dart`

**Sửa:**
- `pubspec.yaml` — thêm `mobile_scanner`, `image_picker`, `google_mlkit_text_recognition`
- `lib/core/controllers/verification_controller.dart` — state machine 5 bước
- `lib/core/controllers/capture_controller.dart` — nhận `IdentityVerification` + `AttendanceType`
- `lib/core/models/shareholder.dart` — thêm `personId`, `allowanceReceived`
- `lib/core/data/dto/shareholder_dtos.dart` — map fields mới
- `lib/core/data/dto/travel_support_dtos.dart` — attendance/proxy fields
- `lib/core/data/mappers/shareholder_mapper.dart`
- `lib/core/repositories/shareholder_repository.dart` — `findByMcd()`
- `lib/core/repositories/travel_support_repository.dart` — gửi identity + proxy từ session
- `lib/core/screens/verification/verification_screen.dart` — layout mới
- `lib/core/screens/verification/components/verification_action_buttons.dart` — đổi thành identity actions
- `lib/core/screens/verification/components/verification_search_section.dart` — chỉ dùng cho nhập tay giấy tờ
- `lib/core/screens/verification/components/verification_result_section.dart` — disable khi đã nhận
- `lib/core/screens/shell/shell_screen.dart` — FAB quét barcode thiệp mời (không phải CCCD)
- `lib/core/mock/mock_data.dart` — mock barcode + person status
- `test/support/fake_repositories.dart`
- `test/controllers/verification_controller_test.dart`
- `test/controllers/capture_controller_test.dart`

---

## Phần 3 — Logic nghiệp vụ chi tiết

### 3.1 Định dạng mã thiệp mời (barcode)

Barcode QR/Code128 chứa chuỗi JSON hoặc pipe-delimited:

```
{"mcd":"MCD001","name":"Nguyen Van A"}
```

hoặc fallback:

```
MCD001|Nguyen Van A
```

Parser Flutter (`barcode_parser.dart`) extract `mcd`, validate không rỗng, gọi API `GET /api/shareholders/{mcd}` để lấy đầy đủ thông tin (số CP, trạng thái Person).

### 3.2 Person Matching (backend)

```
ReceiveAsync(request):
  1. shareholder = GetByMcd(request.Mcd) → 404 nếu không có
  2. person = FindPersonForShareholder(shareholder):
       a. personShareholder = PersonShareholder.GetByMcd(mcd)
          → nếu có: return person
       b. person = Person.FindByFullName(normalize(shareholder.FullName))
          → nếu có: link PersonShareholder(mcd), return person
       c. person = new Person { FullName = shareholder.FullName }
          → link PersonShareholder(mcd), return person
  3. if TravelSupport.ExistsByPersonId(person.Id):
       → throw ConflictException("This person has already received the allowance.")
  4. Insert TravelSupport { PersonId, Mcd, AttendanceType, Receiver*, Proxy*, ... }
  5. Update Person.IdentityNo/IdentityType nếu Direct (lưu evidence, KHÔNG dùng match)
  6. AuditLog
```

**Lưu ý:** `ReceiverIdentityNo` / `IdentityType` chỉ lưu bằng chứng trên `TravelSupport`. Không dùng để tìm Person.

### 3.3 Proxy Attendance

- `AttendanceType = "Proxy"` → bắt buộc `ProxyPersonName`, `ProxyIdentityNo`, `ProxyIdentityType`
- `ReceiverName` = tên chủ sở hữu cổ phần (từ barcode/DB)
- Phụ cấp gắn `PersonId` của chủ sở hữu, không phải người ủy quyền
- Chặn trùng vẫn check `PersonId` chủ sở hữu

### 3.4 Trạng thái trên UI

| Trạng thái API | Badge | Màu | Nút xác nhận |
|----------------|-------|-----|--------------|
| `allowanceReceived = false` | `CHƯA NHẬN` | Xanh (`tertiary`) | Enabled |
| `allowanceReceived = true` | `ĐÃ NHẬN` | Đỏ (`error`) | **Disabled** |

Message 409: `"Người này đã nhận phụ cấp."` (Flutter map từ API message)

---

## Phần 4 — Tasks triển khai

### Task 1: Tạo entity Person và PersonShareholder (Backend)

**Files:**
- Create: `ShareVerify.Domain/Entities/Person.cs`
- Create: `ShareVerify.Domain/Entities/PersonShareholder.cs`
- Create: `ShareVerify.Domain/Enums/AttendanceType.cs`
- Create: `ShareVerify.Infrastructure/Data/Configurations/PersonConfiguration.cs`
- Create: `ShareVerify.Infrastructure/Data/Configurations/PersonShareholderConfiguration.cs`
- Modify: `ShareVerify.Infrastructure/Data/AppDbContext.cs`

- [ ] **Step 1: Tạo enum AttendanceType**

```csharp
// ShareVerify.Domain/Enums/AttendanceType.cs
namespace ShareVerify.Domain.Enums;

public static class AttendanceType
{
    public const string Direct = "Direct";
    public const string Proxy = "Proxy";
    public static readonly string[] All = [Direct, Proxy];
}
```

- [ ] **Step 2: Tạo entity Person**

```csharp
// ShareVerify.Domain/Entities/Person.cs
namespace ShareVerify.Domain.Entities;

public class Person
{
    public long Id { get; set; }
    public string FullName { get; set; } = string.Empty;
    public string? IdentityNo { get; set; }
    public string? IdentityType { get; set; }
    public string? Phone { get; set; }
    public DateTime CreatedAt { get; set; }
    public ICollection<PersonShareholder> Shareholders { get; set; } = [];
    public ICollection<TravelSupport> TravelSupports { get; set; } = [];
}
```

- [ ] **Step 3: Tạo entity PersonShareholder**

```csharp
// ShareVerify.Domain/Entities/PersonShareholder.cs
namespace ShareVerify.Domain.Entities;

public class PersonShareholder
{
    public long Id { get; set; }
    public long PersonId { get; set; }
    public string Mcd { get; set; } = string.Empty;
    public Person Person { get; set; } = null!;
}
```

- [ ] **Step 4: Tạo EF configurations**

```csharp
// PersonConfiguration.cs
builder.ToTable("Person");
builder.HasKey(e => e.Id);
builder.Property(e => e.FullName).IsRequired().HasMaxLength(200);
builder.Property(e => e.IdentityNo).HasMaxLength(100);
builder.Property(e => e.IdentityType).HasMaxLength(20);
builder.Property(e => e.Phone).HasMaxLength(20);
builder.HasIndex(e => e.FullName);

// PersonShareholderConfiguration.cs
builder.ToTable("PersonShareholder");
builder.HasKey(e => e.Id);
builder.Property(e => e.Mcd).IsRequired().HasMaxLength(50);
builder.HasIndex(e => e.Mcd).IsUnique();
builder.HasIndex(e => new { e.PersonId, e.Mcd }).IsUnique();
builder.HasOne(e => e.Person).WithMany(p => p.Shareholders)
    .HasForeignKey(e => e.PersonId).OnDelete(DeleteBehavior.Cascade);
```

- [ ] **Step 5: Đăng ký DbSet trong AppDbContext**

```csharp
public DbSet<Person> Persons => Set<Person>();
public DbSet<PersonShareholder> PersonShareholders => Set<PersonShareholder>();
// OnModelCreating: ApplyConfiguration Person + PersonShareholder
```

- [ ] **Step 6: Commit**

```bash
cd /Users/sypham/projects/becamex/ShareVerify
git add src/ShareVerify.Domain/Entities/Person.cs \
        src/ShareVerify.Domain/Entities/PersonShareholder.cs \
        src/ShareVerify.Domain/Enums/AttendanceType.cs \
        src/ShareVerify.Infrastructure/Data/Configurations/PersonConfiguration.cs \
        src/ShareVerify.Infrastructure/Data/Configurations/PersonShareholderConfiguration.cs \
        src/ShareVerify.Infrastructure/Data/AppDbContext.cs
git commit -m "feat(domain): add Person and PersonShareholder entities"
```

---

### Task 2: Sửa TravelSupport — PersonId là khóa chặn trùng

**Files:**
- Modify: `ShareVerify.Domain/Entities/TravelSupport.cs`
- Modify: `ShareVerify.Infrastructure/Data/Configurations/TravelSupportConfiguration.cs`

- [ ] **Step 1: Thêm fields vào TravelSupport entity**

```csharp
public class TravelSupport
{
    // ... existing fields ...
    public long PersonId { get; set; }
    public string AttendanceType { get; set; } = AttendanceType.Direct;
    public string? ProxyPersonName { get; set; }
    public string? ProxyIdentityNo { get; set; }
    public string? ProxyIdentityType { get; set; }
    public Person Person { get; set; } = null!;
}
```

- [ ] **Step 2: Sửa TravelSupportConfiguration**

```csharp
// Bỏ: builder.HasIndex(e => e.Mcd).IsUnique();
// Thêm:
builder.Property(e => e.AttendanceType).IsRequired().HasMaxLength(20);
builder.Property(e => e.ProxyPersonName).HasMaxLength(200);
builder.Property(e => e.ProxyIdentityNo).HasMaxLength(100);
builder.Property(e => e.ProxyIdentityType).HasMaxLength(20);
builder.HasIndex(e => e.PersonId).IsUnique();
builder.HasIndex(e => e.Mcd);  // non-unique index for lookup
builder.HasOne(e => e.Person).WithMany(p => p.TravelSupports)
    .HasForeignKey(e => e.PersonId).OnDelete(DeleteBehavior.Restrict);
```

- [ ] **Step 3: Commit**

```bash
git add src/ShareVerify.Domain/Entities/TravelSupport.cs \
        src/ShareVerify.Infrastructure/Data/Configurations/TravelSupportConfiguration.cs
git commit -m "feat(domain): change TravelSupport duplicate key from Mcd to PersonId"
```

---

### Task 3: Migration EF Core + migrate dữ liệu cũ

**Files:**
- Create: migration via `dotnet ef migrations add`
- Modify: generated migration file (thêm SQL data migration)

- [ ] **Step 1: Tạo migration**

```bash
cd /Users/sypham/projects/becamex/ShareVerify/src/ShareVerify.Api
dotnet ef migrations add AddPersonEntities --project ../ShareVerify.Infrastructure
```

Expected: file mới trong `ShareVerify.Infrastructure/Migrations/`

- [ ] **Step 2: Thêm data migration vào Up() của migration**

```csharp
// Sau khi tạo bảng, migrate dữ liệu TravelSupport cũ:
migrationBuilder.Sql("""
    INSERT INTO "Person" ("FullName", "CreatedAt")
    SELECT DISTINCT s."FullName", NOW() AT TIME ZONE 'UTC'
    FROM "TravelSupport" ts
    JOIN "Shareholder" s ON s."Mcd" = ts."Mcd";

    INSERT INTO "PersonShareholder" ("PersonId", "Mcd")
    SELECT p."Id", s."Mcd"
    FROM "Shareholder" s
    JOIN "Person" p ON p."FullName" = s."FullName";

    UPDATE "TravelSupport" ts
    SET "PersonId" = ps."PersonId",
        "AttendanceType" = 'Direct'
    FROM "PersonShareholder" ps
    WHERE ps."Mcd" = ts."Mcd";
""");
```

- [ ] **Step 3: Apply migration**

```bash
dotnet ef database update --project ../ShareVerify.Infrastructure
```

Expected: `Done.`

- [ ] **Step 4: Commit**

```bash
git add src/ShareVerify.Infrastructure/Migrations/
git commit -m "feat(db): add Person tables and migrate existing TravelSupport data"
```

---

### Task 4: PersonRepository

**Files:**
- Create: `ShareVerify.Application/Interfaces/IPersonRepository.cs`
- Create: `ShareVerify.Infrastructure/Repositories/PersonRepository.cs`
- Modify: `ShareVerify.Infrastructure/DependencyInjection.cs`

- [ ] **Step 1: Định nghĩa interface**

```csharp
public interface IPersonRepository
{
    Task<Person?> GetByIdAsync(long id, CancellationToken ct = default);
    Task<Person?> FindByFullNameAsync(string fullName, CancellationToken ct = default);
    Task<PersonShareholder?> GetLinkByMcdAsync(string mcd, CancellationToken ct = default);
    Task<Person> AddAsync(Person person, CancellationToken ct = default);
    Task LinkShareholderAsync(long personId, string mcd, CancellationToken ct = default);
    Task<bool> HasReceivedAllowanceAsync(long personId, CancellationToken ct = default);
}
```

- [ ] **Step 2: Implement PersonRepository**

```csharp
public async Task<Person?> FindByFullNameAsync(string fullName, CancellationToken ct = default)
{
    var normalized = fullName.Trim();
    return await _context.Persons
        .FirstOrDefaultAsync(p => p.FullName == normalized, ct);
}

public async Task<bool> HasReceivedAllowanceAsync(long personId, CancellationToken ct = default)
{
    return await _context.TravelSupports.AnyAsync(t => t.PersonId == personId, ct);
}

public async Task LinkShareholderAsync(long personId, string mcd, CancellationToken ct = default)
{
    var exists = await _context.PersonShareholders
        .AnyAsync(ps => ps.Mcd == mcd, ct);
    if (!exists)
    {
        await _context.PersonShareholders.AddAsync(new PersonShareholder
        {
            PersonId = personId,
            Mcd = mcd,
        }, ct);
    }
}
```

- [ ] **Step 3: Register DI**

```csharp
services.AddScoped<IPersonRepository, PersonRepository>();
```

- [ ] **Step 4: Commit**

```bash
git add src/ShareVerify.Application/Interfaces/IPersonRepository.cs \
        src/ShareVerify.Infrastructure/Repositories/PersonRepository.cs \
        src/ShareVerify.Infrastructure/DependencyInjection.cs
git commit -m "feat(infra): add PersonRepository with allowance check"
```

---

### Task 5: Cập nhật TravelSupportRepository

**Files:**
- Modify: `ShareVerify.Application/Interfaces/ITravelSupportRepository.cs`
- Modify: `ShareVerify.Infrastructure/Repositories/TravelSupportRepository.cs`

- [ ] **Step 1: Thêm methods vào interface**

```csharp
Task<bool> ExistsByPersonIdAsync(long personId, CancellationToken ct = default);
Task<TravelSupport?> GetByPersonIdAsync(long personId, CancellationToken ct = default);
```

- [ ] **Step 2: Implement**

```csharp
public Task<bool> ExistsByPersonIdAsync(long personId, CancellationToken ct = default)
    => _context.TravelSupports.AnyAsync(t => t.PersonId == personId, ct);

public Task<TravelSupport?> GetByPersonIdAsync(long personId, CancellationToken ct = default)
    => _context.TravelSupports.FirstOrDefaultAsync(t => t.PersonId == personId, ct);
```

- [ ] **Step 3: Commit**

```bash
git add src/ShareVerify.Application/Interfaces/ITravelSupportRepository.cs \
        src/ShareVerify.Infrastructure/Repositories/TravelSupportRepository.cs
git commit -m "feat(infra): add person-based queries to TravelSupportRepository"
```

---

### Task 6: Cập nhật DTOs và Validator

**Files:**
- Modify: `ShareVerify.Application/DTOs/TravelSupportDtos.cs`
- Modify: `ShareVerify.Application/DTOs/ShareholderDtos.cs`
- Modify: `ShareVerify.Application/Validators/ReceiveTravelSupportValidator.cs`

- [ ] **Step 1: Mở rộng ReceiveTravelSupportRequest**

```csharp
public class ReceiveTravelSupportRequest
{
    public string Mcd { get; set; } = string.Empty;
    public string AttendanceType { get; set; } = "Direct";
    public string? ReceiverName { get; set; }
    public string? ReceiverIdentityNo { get; set; }
    public string? IdentityType { get; set; }
    public string? ProxyPersonName { get; set; }
    public string? ProxyIdentityNo { get; set; }
    public string? ProxyIdentityType { get; set; }
    public decimal ReceiveAmount { get; set; }
    public string? OperatorName { get; set; }
    public string? DeviceId { get; set; }
    public string? PhotoPath { get; set; }
}
```

- [ ] **Step 2: Thêm AllowanceReceived vào ShareholderDetailDto**

```csharp
public class ShareholderDetailDto
{
    // ... existing ...
    public long? PersonId { get; set; }
    public bool AllowanceReceived { get; set; }
}
```

- [ ] **Step 3: Cập nhật validator**

```csharp
RuleFor(x => x.AttendanceType)
    .Must(v => AttendanceType.All.Contains(v))
    .WithMessage("AttendanceType must be Direct or Proxy.");

When(x => x.AttendanceType == AttendanceType.Proxy, () =>
{
    RuleFor(x => x.ProxyPersonName).NotEmpty().MaximumLength(200);
    RuleFor(x => x.ProxyIdentityNo).NotEmpty().MaximumLength(100);
    RuleFor(x => x.ProxyIdentityType)
        .Must(v => v != null && IdentityType.All.Contains(v));
});

RuleFor(x => x.ReceiverIdentityNo).NotEmpty().When(x => x.AttendanceType == AttendanceType.Direct);
RuleFor(x => x.IdentityType).NotEmpty().When(x => x.AttendanceType == AttendanceType.Direct);
```

- [ ] **Step 4: Commit**

```bash
git add src/ShareVerify.Application/DTOs/ \
        src/ShareVerify.Application/Validators/ReceiveTravelSupportValidator.cs
git commit -m "feat(api): extend receive DTO with attendance and proxy fields"
```

---

### Task 7: PersonService — Find-or-Create logic

**Files:**
- Create: `ShareVerify.Application/Interfaces/IPersonService.cs`
- Create: `ShareVerify.Application/Services/PersonService.cs`
- Modify: `ShareVerify.Infrastructure/DependencyInjection.cs`

- [ ] **Step 1: Viết failing test**

Tạo project test trước:

```bash
cd /Users/sypham/projects/becamex/ShareVerify
dotnet new xunit -n ShareVerify.Tests -o tests/ShareVerify.Tests
dotnet sln add tests/ShareVerify.Tests/ShareVerify.Tests.csproj
cd tests/ShareVerify.Tests
dotnet add reference ../../src/ShareVerify.Application/ShareVerify.Application.csproj
dotnet add reference ../../src/ShareVerify.Domain/ShareVerify.Domain.csproj
dotnet add package Moq
dotnet add package FluentAssertions
```

```csharp
// tests/ShareVerify.Tests/Services/PersonServiceTests.cs
[Fact]
public async Task FindOrCreateForShareholder_LinksSecondMcdToSamePerson()
{
    // Arrange: Person "Nguyen Van A" exists with MCD001
    // Act: FindOrCreateForShareholder(shareholder MCD002, "Nguyen Van A")
    // Assert: same PersonId, new PersonShareholder link for MCD002
}
```

- [ ] **Step 2: Run test — expect FAIL**

```bash
cd /Users/sypham/projects/becamex/ShareVerify/tests/ShareVerify.Tests
dotnet test --filter "LinksSecondMcdToSamePerson" -v n
```

Expected: FAIL — `PersonService` not found

- [ ] **Step 3: Implement PersonService**

```csharp
public async Task<Person> FindOrCreateForShareholderAsync(Shareholder shareholder, CancellationToken ct = default)
{
    var link = await _personRepository.GetLinkByMcdAsync(shareholder.Mcd, ct);
    if (link is not null)
        return (await _personRepository.GetByIdAsync(link.PersonId, ct))!;

    var person = await _personRepository.FindByFullNameAsync(shareholder.FullName, ct);
    if (person is null)
    {
        person = await _personRepository.AddAsync(new Person
        {
            FullName = shareholder.FullName,
            CreatedAt = DateTime.UtcNow,
        }, ct);
        await _unitOfWork.SaveChangesAsync(ct);
    }

    await _personRepository.LinkShareholderAsync(person.Id, shareholder.Mcd, ct);
    await _unitOfWork.SaveChangesAsync(ct);
    return person;
}
```

- [ ] **Step 4: Run test — expect PASS**

```bash
dotnet test --filter "LinksSecondMcdToSamePerson" -v n
```

- [ ] **Step 5: Commit**

```bash
git add tests/ShareVerify.Tests/ src/ShareVerify.Application/Services/PersonService.cs \
        src/ShareVerify.Application/Interfaces/IPersonService.cs \
        ShareVerify.sln
git commit -m "feat(app): add PersonService find-or-create by shareholder name"
```

---

### Task 8: Sửa TravelSupportService.ReceiveAsync

**Files:**
- Modify: `ShareVerify.Infrastructure/Services/TravelSupportService.cs`

- [ ] **Step 1: Viết failing integration test**

```csharp
[Fact]
public async Task ReceiveAsync_SecondMcdSamePerson_Returns409()
{
    // Setup: Person "Nguyen Van A" received via MCD001
    // Act: POST receive MCD002 same name
    // Assert: ConflictException message contains "already received the allowance"
}
```

- [ ] **Step 2: Run test — expect FAIL**

```bash
dotnet test --filter "SecondMcdSamePerson" -v n
```

- [ ] **Step 3: Implement ReceiveAsync mới**

```csharp
public async Task ReceiveAsync(ReceiveTravelSupportRequest request, CancellationToken ct = default)
{
    var shareholder = await _shareholderRepository.GetByMcdAsync(request.Mcd, ct)
        ?? throw new NotFoundException($"Shareholder with MCD '{request.Mcd}' not found.");

    var person = await _personService.FindOrCreateForShareholderAsync(shareholder, ct);

    if (await _travelSupportRepository.ExistsByPersonIdAsync(person.Id, ct))
    {
        throw new ConflictException("This person has already received the allowance.");
    }

    await _unitOfWork.ExecuteInTransactionAsync(async () =>
    {
        var travelSupport = new TravelSupport
        {
            PersonId = person.Id,
            Mcd = request.Mcd,
            AttendanceType = request.AttendanceType,
            ReceiverName = request.ReceiverName,
            ReceiverIdentityNo = request.ReceiverIdentityNo,
            IdentityType = request.IdentityType,
            ProxyPersonName = request.ProxyPersonName,
            ProxyIdentityNo = request.ProxyIdentityNo,
            ProxyIdentityType = request.ProxyIdentityType,
            ReceiveAmount = request.ReceiveAmount,
            ReceiveTime = DateTime.UtcNow,
            PhotoPath = request.PhotoPath,
            OperatorName = request.OperatorName,
            DeviceId = request.DeviceId,
            CreatedAt = DateTime.UtcNow,
        };
        await _travelSupportRepository.AddAsync(travelSupport, ct);
        // ... audit log ...
    }, ct);
}
```

- [ ] **Step 4: Run test — expect PASS**

```bash
dotnet test --filter "SecondMcdSamePerson" -v n
```

- [ ] **Step 5: Commit**

```bash
git add src/ShareVerify.Infrastructure/Services/TravelSupportService.cs tests/
git commit -m "feat(api): receive allowance by PersonId with proactive 409 check"
```

---

### Task 9: Sửa ShareholderService — person-level status

**Files:**
- Modify: `ShareVerify.Application/Services/ShareholderService.cs`
- Modify: `ShareVerify.Infrastructure/Repositories/ShareholderRepository.cs`

- [ ] **Step 1: Sửa GetDetailAsync**

```csharp
var link = await _personRepository.GetLinkByMcdAsync(mcd, ct);
Person? person = null;
if (link is not null)
    person = await _personRepository.GetByIdAsync(link.PersonId, ct);
else
    person = await _personRepository.FindByFullNameAsync(shareholder.FullName, ct);

var allowanceReceived = person is not null
    && await _personRepository.HasReceivedAllowanceAsync(person.Id, ct);

var travelSupport = person is not null
    ? await _travelSupportRepository.GetByPersonIdAsync(person.Id, ct)
    : null;

return new ShareholderDetailDto
{
    // ... existing fields ...
    PersonId = person?.Id,
    AllowanceReceived = allowanceReceived,
    TravelSupport = travelSupport is null ? null : _mapper.Map<TravelSupportInfoDto>(travelSupport),
};
```

- [ ] **Step 2: Sửa SearchAsync join — TravelSupportReceived theo Person**

Trong `ShareholderRepository.SearchAsync`, thay left join `TravelSupport` on Mcd bằng:

```csharp
join ps in _context.PersonShareholders on s.Mcd equals ps.Mcd into psGroup
from ps in psGroup.DefaultIfEmpty()
join ts in _context.TravelSupports on ps.PersonId equals ts.PersonId into tsGroup
from ts in tsGroup.DefaultIfEmpty()
// TravelSupportReceived = ts != null
```

- [ ] **Step 3: Manual test API**

```bash
curl http://localhost:5054/api/shareholders/MCD001
```

Expected: JSON có `"allowanceReceived": true/false` theo Person

- [ ] **Step 4: Commit**

```bash
git add src/ShareVerify.Application/Services/ShareholderService.cs \
        src/ShareVerify.Infrastructure/Repositories/ShareholderRepository.cs
git commit -m "feat(api): return person-level allowance status in shareholder endpoints"
```

---

### Task 10: Barcode parser (Flutter)

**Files:**
- Create: `lib/core/utils/barcode_parser.dart`
- Create: `lib/core/models/invitation_barcode.dart`
- Test: `test/utils/barcode_parser_test.dart`

- [ ] **Step 1: Viết failing test**

```dart
// test/utils/barcode_parser_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:share_verify/core/utils/barcode_parser.dart';

void main() {
  test('parseJsonBarcode extracts mcd and name', () {
    const raw = '{"mcd":"MCD001","name":"Nguyen Van A"}';
    final result = BarcodeParser.parse(raw);
    expect(result.mcd, 'MCD001');
    expect(result.name, 'Nguyen Van A');
  });

  test('parsePipeBarcode extracts mcd and name', () {
    const raw = 'MCD002|Tran Thi B';
    final result = BarcodeParser.parse(raw);
    expect(result.mcd, 'MCD002');
    expect(result.name, 'Tran Thi B');
  });

  test('parseRawMcd returns mcd only', () {
    final result = BarcodeParser.parse('MCD003');
    expect(result.mcd, 'MCD003');
    expect(result.name, isNull);
  });
}
```

- [ ] **Step 2: Run test — expect FAIL**

```bash
cd /Users/sypham/projects/becamex/share_verify
flutter test test/utils/barcode_parser_test.dart
```

Expected: FAIL — `BarcodeParser` not defined

- [ ] **Step 3: Implement**

```dart
// lib/core/models/invitation_barcode.dart
class InvitationBarcode {
  final String mcd;
  final String? name;
  const InvitationBarcode({required this.mcd, this.name});
}

// lib/core/utils/barcode_parser.dart
import 'dart:convert';
import 'package:share_verify/core/models/invitation_barcode.dart';

class BarcodeParser {
  static InvitationBarcode parse(String raw) {
    final trimmed = raw.trim();
    if (trimmed.startsWith('{')) {
      final map = jsonDecode(trimmed) as Map<String, dynamic>;
      return InvitationBarcode(
        mcd: map['mcd'] as String,
        name: map['name'] as String?,
      );
    }
    if (trimmed.contains('|')) {
      final parts = trimmed.split('|');
      return InvitationBarcode(mcd: parts[0].trim(), name: parts[1].trim());
    }
    return InvitationBarcode(mcd: trimmed);
  }
}
```

- [ ] **Step 4: Run test — expect PASS**

```bash
flutter test test/utils/barcode_parser_test.dart
```

- [ ] **Step 5: Commit**

```bash
git add lib/core/utils/barcode_parser.dart lib/core/models/invitation_barcode.dart test/utils/
git commit -m "feat(flutter): add invitation barcode parser"
```

---

### Task 11: Models và DTOs Flutter

**Files:**
- Create: `lib/core/models/attendance_type.dart`
- Create: `lib/core/models/identity_verification.dart`
- Modify: `lib/core/models/shareholder.dart`
- Modify: `lib/core/data/dto/shareholder_dtos.dart`
- Modify: `lib/core/data/dto/travel_support_dtos.dart`
- Modify: `lib/core/data/mappers/shareholder_mapper.dart`

- [ ] **Step 1: Tạo AttendanceType enum**

```dart
enum AttendanceType { direct, proxy }

extension AttendanceTypeApi on AttendanceType {
  String get apiValue => this == AttendanceType.direct ? 'Direct' : 'Proxy';
}
```

- [ ] **Step 2: Tạo IdentityVerification model**

```dart
class IdentityVerification {
  final String identityNo;
  final String identityType; // CCCD | CMND | PASSPORT
  final String receiverName;
  final String? photoPath;
  const IdentityVerification({
    required this.identityNo,
    required this.identityType,
    required this.receiverName,
    this.photoPath,
  });
}
```

- [ ] **Step 3: Mở rộng Shareholder model**

```dart
class Shareholder {
  final String code;
  final String fullName;
  final String idNumber;
  final int shares;
  final PaymentStatus status;
  final int? personId;
  // ...
}
```

- [ ] **Step 4: Cập nhật DTOs và mapper**

```dart
// shareholder_dtos.dart — thêm personId, allowanceReceived
// travel_support_dtos.dart — thêm attendanceType, proxyPersonName, proxyIdentityNo, proxyIdentityType
// shareholder_mapper.dart:
status: dto.allowanceReceived ? PaymentStatus.received : PaymentStatus.notReceived,
personId: dto.personId,
```

- [ ] **Step 5: Commit**

```bash
git add lib/core/models/ lib/core/data/
git commit -m "feat(flutter): add identity and attendance models with updated DTOs"
```

---

### Task 12: ShareholderRepository.findByMcd

**Files:**
- Modify: `lib/core/repositories/shareholder_repository.dart`
- Modify: `lib/core/data/sources/shareholder_remote_source.dart`
- Modify: `lib/core/mock/mock_data.dart`

- [ ] **Step 1: Thêm method findByMcd**

```dart
// shareholder_repository.dart
Future<Shareholder?> findByMcd(String mcd) async {
  final normalized = mcd.trim();
  if (normalized.isEmpty) return null;
  if (AppSetting.useMockData) return MockData.findByMcd(normalized);
  final dto = await _remoteSource!.getDetail(normalized);
  return ShareholderMapper.fromDetailDto(dto);
}
```

- [ ] **Step 2: Cập nhật mock**

```dart
// mock_data.dart
static Shareholder? findByMcd(String mcd) {
  try {
    return shareholders.firstWhere((s) => s.code == mcd);
  } catch (_) {
    return null;
  }
}
```

- [ ] **Step 3: Commit**

```bash
git add lib/core/repositories/shareholder_repository.dart lib/core/mock/mock_data.dart
git commit -m "feat(flutter): add findByMcd repository method for barcode flow"
```

---

### Task 13: Refactor VerificationController — state machine 5 bước

**Files:**
- Modify: `lib/core/controllers/verification_controller.dart`
- Test: `test/controllers/verification_controller_barcode_test.dart`

- [ ] **Step 1: Viết failing tests**

```dart
test('onBarcodeScanned loads shareholder by mcd', () async { ... });
test('confirmPayment blocked when allowance already received', () async { ... });
test('confirmPayment sends proxy fields when attendance is proxy', () async { ... });
test('identity verification does not affect duplicate check', () async { ... });
```

- [ ] **Step 2: Run tests — expect FAIL**

```bash
flutter test test/controllers/verification_controller_barcode_test.dart
```

- [ ] **Step 3: Implement controller state**

```dart
class VerificationController extends GetxController {
  // Step 1: barcode
  final scannedBarcode = Rxn<InvitationBarcode>();
  final selectedShareholder = Rxn<Shareholder>();

  // Step 2: identity
  final identityVerification = Rxn<IdentityVerification>();

  // Step 3: attendance
  final attendanceType = AttendanceType.direct.obs;
  final proxyPersonName = ''.obs;
  final proxyIdentityNo = ''.obs;
  final proxyIdentityType = 'CCCD'.obs;

  Future<void> onBarcodeScanned(String raw) async {
    final barcode = BarcodeParser.parse(raw);
    scannedBarcode.value = barcode;
    isSearching.value = true;
    try {
      selectedShareholder.value = await _shareholderRepository.findByMcd(barcode.mcd);
      if (selectedShareholder.value == null) {
        errorMessage.value = 'Không tìm thấy cổ đông với mã ${barcode.mcd}';
      }
    } finally {
      isSearching.value = false;
    }
  }

  void setIdentityVerification(IdentityVerification verification) {
    identityVerification.value = verification;
  }

  bool get canConfirmPayment =>
      selectedShareholder.value != null &&
      identityVerification.value != null &&
      selectedShareholder.value!.status != PaymentStatus.received &&
      (attendanceType.value == AttendanceType.direct ||
          (proxyPersonName.value.isNotEmpty && proxyIdentityNo.value.isNotEmpty));

  Future<void> confirmPayment() async {
    if (!canConfirmPayment || isSubmitting.value) return;
    // ... gọi travelSupportRepository.receive với identity + proxy ...
  }
}
```

- [ ] **Step 4: Run tests — expect PASS**

```bash
flutter test test/controllers/
```

- [ ] **Step 5: Commit**

```bash
git add lib/core/controllers/verification_controller.dart test/controllers/
git commit -m "feat(flutter): refactor verification flow to barcode-first with person status"
```

---

### Task 14: Cập nhật TravelSupportRepository.receive

**Files:**
- Modify: `lib/core/repositories/travel_support_repository.dart`

- [ ] **Step 1: Mở rộng receive signature**

```dart
Future<void> receive({
  required Shareholder shareholder,
  required IdentityVerification identity,
  required AttendanceType attendanceType,
  String? proxyPersonName,
  String? proxyIdentityNo,
  String? proxyIdentityType,
  String? photoPath,
  num receiveAmount = 0,
});
```

- [ ] **Step 2: Gửi đúng payload API**

```dart
await source.receive(
  ReceiveTravelSupportRequest(
    mcd: shareholder.code,
    attendanceType: attendanceType.apiValue,
    receiverName: identity.receiverName,
    receiverIdentityNo: identity.identityNo,
    identityType: identity.identityType,
    proxyPersonName: attendanceType == AttendanceType.proxy ? proxyPersonName : null,
    proxyIdentityNo: attendanceType == AttendanceType.proxy ? proxyIdentityNo : null,
    proxyIdentityType: attendanceType == AttendanceType.proxy ? proxyIdentityType : null,
    receiveAmount: receiveAmount,
    operatorName: AppSetting.operatorName,
    deviceId: AppSetting.deviceId,
    photoPath: photoPath ?? identity.photoPath,
  ),
);
```

- [ ] **Step 3: Commit**

```bash
git add lib/core/repositories/travel_support_repository.dart \
        lib/core/data/dto/travel_support_dtos.dart
git commit -m "feat(flutter): send identity evidence and proxy data in receive request"
```

---

### Task 15: UI Components mới

**Files:**
- Create: `verification_barcode_section.dart`
- Create: `verification_identity_section.dart`
- Create: `verification_attendance_section.dart`
- Create: `verification_proxy_form.dart`
- Modify: `verification_screen.dart`
- Modify: `verification_result_section.dart`
- Modify: `verification_action_buttons.dart`
- Modify: `shell_screen.dart`

- [ ] **Step 1: Tạo VerificationBarcodeSection**

```dart
// Nút chính: "Quét Mã Thiệp Mời" — icon barcode_scanner
// Callback: onScanBarcode
// Hiển thị MCD + tên sau khi quét
```

- [ ] **Step 2: Tạo VerificationIdentitySection**

```dart
// 4 nút:
// - Quét QR CCCD
// - Chụp CCCD (OCR)
// - Chụp Hộ Chiếu (OCR)
// - Nhập số giấy tờ (reuse VerificationSearchSection)
// Hiển thị identity đã xác minh: số + loại + tên
```

- [ ] **Step 3: Tạo VerificationAttendanceSection + ProxyForm**

```dart
// SegmentedButton: Trực tiếp | Ủy quyền
// Khi Proxy: hiện form ProxyPersonName, ProxyIdentityNo, ProxyIdentityType dropdown
```

- [ ] **Step 4: Sửa VerificationResultSection**

```dart
// SvStatusBadge: xanh CHƯA NHẬN / đỏ ĐÃ NHẬN
// SvPrimaryButton onPressed:
//   isSubmitting || shareholder.status == PaymentStatus.received ? null : onConfirmPayment
// Label: 'XÁC NHẬN ĐÃ PHÁT TIỀN'
```

- [ ] **Step 5: Sửa VerificationScreen layout**

```dart
Column(
  children: [
    VerificationBarcodeSection(...),          // Bước 1
    if (selectedShareholder != null) ...[
      VerificationResultSection(...),         // Bước 2 - hiển thị cổ đông
      VerificationIdentitySection(...),       // Bước 3
      VerificationAttendanceSection(...),     // Bước 4
      // Bước 5-6: status trong ResultSection + confirm button
    ],
  ],
)
```

- [ ] **Step 6: Đổi FAB shell_screen → quét thiệp mời**

```dart
// SvFabQr onPressed → controller.onScanInvitationBarcode()
// Icon: Icons.qr_code_2 (thay vì qr_code_scanner CCCD)
```

- [ ] **Step 7: Commit**

```bash
git add lib/core/screens/
git commit -m "feat(flutter): restructure verification UI for barcode-first 5-step flow"
```

---

### Task 16: Tích hợp mobile_scanner (barcode thật)

**Files:**
- Modify: `pubspec.yaml`
- Create: `lib/core/services/barcode_scanner_service.dart`
- Modify: `verification_controller.dart`

- [ ] **Step 1: Thêm dependency**

```yaml
# pubspec.yaml
dependencies:
  mobile_scanner: ^6.0.2
```

```bash
flutter pub get
```

- [ ] **Step 2: Tạo BarcodeScannerService**

```dart
class BarcodeScannerService {
  Future<String?> scan(BuildContext context) async {
    // Push full-screen MobileScanner overlay
    // Return first barcode.rawValue
    // Mock fallback khi useMockData: return '{"mcd":"MCD001","name":"Nguyen Van A"}'
  }
}
```

- [ ] **Step 3: Wire vào controller**

```dart
Future<void> onScanInvitationBarcode() async {
  final raw = await _barcodeScannerService.scan(Get.context!);
  if (raw != null) await onBarcodeScanned(raw);
}
```

- [ ] **Step 4: Manual test**

```bash
flutter run --dart-define=USE_MOCK_DATA=true
```

Tap "Quét Mã Thiệp Mời" → hiển thị cổ đông MCD001

- [ ] **Step 5: Commit**

```bash
git add pubspec.yaml lib/core/services/barcode_scanner_service.dart
git commit -m "feat(flutter): integrate mobile_scanner for invitation barcode"
```

---

### Task 17: Tích hợp OCR + camera (identity evidence)

**Files:**
- Modify: `pubspec.yaml`
- Create: `lib/core/services/ocr_service.dart`
- Modify: `capture_controller.dart`, `capture_evidence_screen.dart`

- [ ] **Step 1: Thêm dependencies**

```yaml
image_picker: ^1.1.2
google_mlkit_text_recognition: ^0.14.0
```

- [ ] **Step 2: Tạo OcrService**

```dart
class OcrService {
  Future<String?> extractIdNumber(Uint8List imageBytes, {required String docType}) async {
    // ML Kit text recognition
    // Regex extract 9-12 digit ID number
    // Return null if not found
  }
}
```

- [ ] **Step 3: Sửa CaptureController nhận callback thay vì tự receive**

```dart
// Capture screen trả về IdentityVerification qua Get.back(result: ...)
// VerificationController.handleCaptureResult(IdentityVerification)
```

- [ ] **Step 4: Commit**

```bash
git add pubspec.yaml lib/core/services/ocr_service.dart lib/core/controllers/capture_controller.dart
git commit -m "feat(flutter): add OCR identity capture as evidence only"
```

---

### Task 18: Cập nhật error messages và tests

**Files:**
- Modify: `verification_controller.dart`, `capture_controller.dart`
- Modify: `test/controllers/verification_controller_test.dart`
- Modify: `test/controllers/capture_controller_test.dart`
- Modify: `test/support/fake_repositories.dart`

- [ ] **Step 1: Đổi message 409**

```dart
errorMessage.value = 'Người này đã nhận phụ cấp.';
```

- [ ] **Step 2: Cập nhật fake repositories**

```dart
class FakeTravelSupportRepository {
  final Set<int> receivedPersonIds = {};
  // receive() throws ApiException(statusCode: 409) if personId already received
}
```

- [ ] **Step 3: Run full test suite**

```bash
cd /Users/sypham/projects/becamex/share_verify
flutter test

cd /Users/sypham/projects/becamex/ShareVerify/tests/ShareVerify.Tests
dotnet test
```

Expected: All PASS

- [ ] **Step 4: Commit**

```bash
git add test/ lib/core/controllers/
git commit -m "test: update verification tests for person-based duplicate prevention"
```

---

### Task 19: End-to-end verification

- [ ] **Step 1: Start backend**

```bash
cd /Users/sypham/projects/becamex/ShareVerify/src/ShareVerify.Api
dotnet run
```

- [ ] **Step 2: Start Flutter với API thật**

```bash
cd /Users/sypham/projects/becamex/share_verify
flutter run --dart-define=USE_MOCK_DATA=false --dart-define=API_BASE_URL=http://localhost:5054
```

- [ ] **Step 3: Test Case 1 — cùng người, 2 MCD**

1. Quét MCD001 → xác minh giấy tờ → Direct → Xác nhận → Success
2. Quét MCD002 (cùng tên) → badge ĐÃ NHẬN đỏ → nút disabled
3. Thử confirm → 409 "Người này đã nhận phụ cấp."

- [ ] **Step 4: Test Case 2 — proxy bị chặn**

1. MCD001 đã nhận (bước 3)
2. Quét MCD001 → chọn Proxy → nhập proxy → confirm → 409

- [ ] **Step 5: Test Case 3 — khác giấy tờ, cùng người**

1. Nhận với CCCD lần 1
2. Thử lại với Passport → vẫn ĐÃ NHẬN (identity không ảnh hưởng)

- [ ] **Step 6: Commit final nếu có fix**

```bash
git commit -m "fix: address e2e issues from person-based flow testing"
```

---

## Phần 5 — Self-Review

### Spec coverage

| Yêu cầu | Task |
|---------|------|
| Barcode thiệp mời là bước đầu | Task 10, 13, 15, 16 |
| 4 phương thức xác minh giấy tờ | Task 15, 17 |
| Giấy tờ chỉ là bằng chứng | Task 8 (không match Person bằng IdentityNo) |
| Entity Person + PersonShareholder | Task 1, 4 |
| UNIQUE(PersonId) trên TravelSupport | Task 2, 3 |
| Proxy attendance | Task 6, 8, 13, 15 |
| 409 Conflict message | Task 8, 18 |
| UI: status xanh/đỏ, disable button | Task 15 |
| POST /api/travel-support/receive logic mới | Task 8 |

### Placeholder scan

Không có TBD/TODO/implement later trong plan.

### Type consistency

- Backend: `AttendanceType` = `"Direct"` / `"Proxy"` (string constants)
- Flutter: `AttendanceType.direct` / `.proxy` → API via `.apiValue`
- `PersonId` (long backend) ↔ `personId` (int? Flutter)
- `AllowanceReceived` (backend) ↔ `PaymentStatus` (Flutter mapper)

---

## Thứ tự triển khai đề xuất

```
Backend (Task 1→9) ──► Flutter models/repos (Task 10→14) ──► Flutter UI (Task 15→17) ──► Tests + E2E (Task 18→19)
```

Backend phải xong trước để Flutter test với API thật.
