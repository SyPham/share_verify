# Dashboard Redesign Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Redesign the mobile dashboard to four tappable KPI cards with drill-down navigation, backed by extended ShareVerify APIs for filtered shareholder lists, person-grouped recipients, warning counts, and multi-check-in recipient details.

**Architecture:** Extend existing .NET APIs with query params (Approach 1 from spec) — no new microservices. Flutter app reuses GetX controller/list-screen patterns from `RecipientsListScreen`, replaces dashboard layout, and adds shareholder list/detail screens. Backend tasks land first; Flutter data layer can be built against DTOs while API work is in flight, but integration testing requires a running API.

**Tech Stack:** .NET 9, EF Core, xUnit, FluentAssertions, Moq, EF InMemory (new) | Flutter 3.4+, GetX, Dio

**Spec:** `docs/superpowers/specs/2026-06-23-dashboard-redesign-design.md`

**Worktree:** Run in a dedicated worktree (`superpowers:using-git-worktrees`) before implementation.

---

## File Structure

### Backend (`/Users/sypham/projects/becamex/ShareVerify`)

| Action | Path | Responsibility |
|--------|------|----------------|
| Modify | `src/ShareVerify.Application/DTOs/DashboardDtos.cs` | Add `WarningCount` |
| Modify | `src/ShareVerify.Application/Services/DashboardService.cs` | Compute `warningCount` |
| Modify | `src/ShareVerify.Application/Interfaces/IShareholderRepository.cs` | Add `ListAsync` + `ShareholderListOptions` |
| Modify | `src/ShareVerify.Infrastructure/Repositories/ShareholderRepository.cs` | Implement `ListAsync` |
| Modify | `src/ShareVerify.Application/Interfaces/IShareholderService.cs` | Add `ListAsync` |
| Modify | `src/ShareVerify.Application/Services/ShareholderService.cs` | Pagination guardrails + mapping |
| Modify | `src/ShareVerify.Api/Controllers/ShareholdersController.cs` | `GET /api/shareholders/list` |
| Modify | `src/ShareVerify.Application/Interfaces/IRecipientRepository.cs` | Extend `SearchAsync` signature, new result types |
| Modify | `src/ShareVerify.Infrastructure/Repositories/RecipientRepository.cs` | `groupBy=person`, `minLinkedMcd`, multi check-in detail |
| Modify | `src/ShareVerify.Application/DTOs/RecipientDtos.cs` | `RecipientCheckInDto`, new `RecipientDetailDto` shape |
| Modify | `src/ShareVerify.Application/Interfaces/IRecipientService.cs` | New search/detail params |
| Modify | `src/ShareVerify.Application/Services/RecipientService.cs` | Pass-through + mapping |
| Modify | `src/ShareVerify.Api/Controllers/RecipientsController.cs` | New query params |
| Create | `tests/ShareVerify.Tests/Infrastructure/TestDbContextFactory.cs` | InMemory seed helper |
| Create | `tests/ShareVerify.Tests/Services/DashboardServiceTests.cs` | `warningCount` tests |
| Create | `tests/ShareVerify.Tests/Repositories/ShareholderRepositoryListTests.cs` | List endpoint query tests |
| Create | `tests/ShareVerify.Tests/Repositories/RecipientRepositoryTests.cs` | groupBy + detail tests |
| Modify | `tests/ShareVerify.Tests/ShareVerify.Tests.csproj` | Add `Microsoft.EntityFrameworkCore.InMemory` |

### Flutter (`/Users/sypham/projects/becamex/share_verify`)

| Action | Path | Responsibility |
|--------|------|----------------|
| Modify | `lib/core/models/dashboard_stats.dart` | Add `warningCount`, drop unused completion helpers from dashboard usage |
| Modify | `lib/core/data/dto/dashboard_dtos.dart` | Parse `warningCount` |
| Modify | `lib/core/data/mappers/dashboard_mapper.dart` | Map `warningCount` |
| Modify | `lib/core/controllers/dashboard_controller.dart` | Remove recent activity, expose `warningCount` |
| Modify | `lib/core/repositories/dashboard_repository.dart` | Remove `getRecentActivity` |
| Modify | `lib/core/widgets/sv_kpi_card.dart` | Optional progress bar, optional `onTap` |
| Modify | `lib/core/screens/dashboard/dashboard_screen.dart` | 4-card grid, navigation |
| Create | `lib/core/screens/dashboard/received_support_screen.dart` | 2-tab received view |
| Create | `lib/core/screens/dashboard/warning_recipients_screen.dart` | Warning list (`minLinkedMcd: 2`) |
| Create | `lib/core/screens/shareholders/shareholders_list_screen.dart` | Paginated shareholder list |
| Create | `lib/core/screens/shareholders/shareholder_detail_screen.dart` | Shareholder detail |
| Create | `lib/core/screens/shareholders/components/shareholder_list_tile.dart` | List tile |
| Create | `lib/core/screens/shareholders/components/shareholder_detail_body.dart` | Detail body |
| Create | `lib/core/controllers/shareholders_list_controller.dart` | List state + pagination |
| Create | `lib/core/controllers/shareholder_detail_controller.dart` | Detail fetch |
| Create | `lib/core/bindings/shareholders_binding.dart` | GetX bindings |
| Create | `lib/core/bindings/dashboard_drilldown_binding.dart` | Received + warning bindings |
| Modify | `lib/core/repositories/shareholder_repository.dart` | `listShareholders` |
| Modify | `lib/core/data/sources/shareholder_remote_source.dart` | `GET /api/shareholders/list` |
| Modify | `lib/core/repositories/recipient_repository.dart` | `groupByPerson`, `minLinkedMcd` |
| Modify | `lib/core/data/sources/recipient_remote_source.dart` | New query params |
| Modify | `lib/core/data/dto/recipient_dtos.dart` | `RecipientCheckInDto`, new detail shape |
| Modify | `lib/core/models/recipient_detail.dart` | `List<RecipientCheckIn> checkIns` |
| Create | `lib/core/models/recipient_check_in.dart` | Check-in model |
| Modify | `lib/core/data/mappers/recipient_mapper.dart` | Map new detail shape |
| Modify | `lib/core/screens/recipients/components/recipient_detail_body.dart` | Multi-block check-in layout |
| Modify | `lib/core/controllers/recipients_list_controller.dart` | Optional `groupByPerson` / `minLinkedMcd` |
| Modify | `lib/core/route.dart` | Register new routes |
| Delete | `lib/core/screens/dashboard/components/recent_activity_list.dart` | Removed from dashboard |
| Delete | `lib/core/screens/dashboard/components/progress_ring_section.dart` | Removed from dashboard |
| Delete | `lib/core/utils/dashboard_format.dart` | No remaining references |
| Delete | `lib/core/models/activity_item.dart` | No longer used |
| Delete | `lib/core/data/mappers/activity_mapper.dart` | No longer used |
| Modify | `test/support/fake_repositories.dart` | New API signatures |
| Modify | `test/fixtures/test_data.dart` | `warningCount`, remove activities |
| Modify | `test/controllers/dashboard_controller_test.dart` | Updated expectations |
| Modify | `test/data/dashboard_dtos_test.dart` | `warningCount` parsing |
| Modify | `test/widgets/sv_kpi_card_test.dart` | Progress hidden by default |
| Create | `test/widgets/dashboard_screen_test.dart` | 4 cards, no progress ring |
| Create | `test/widgets/recipient_detail_body_test.dart` | Multiple check-in blocks |
| Delete | `test/utils/dashboard_format_test.dart` | File removed |

---

## Part 1 — Backend (ShareVerify)

### Task 1: EF InMemory test infrastructure

**Files:**
- Modify: `tests/ShareVerify.Tests/ShareVerify.Tests.csproj`
- Create: `tests/ShareVerify.Tests/Infrastructure/TestDbContextFactory.cs`

- [ ] **Step 1: Add InMemory package**

Add to `ShareVerify.Tests.csproj`:

```xml
<PackageReference Include="Microsoft.EntityFrameworkCore.InMemory" Version="9.0.0" />
```

- [ ] **Step 2: Create test DB factory**

```csharp
using Microsoft.EntityFrameworkCore;
using ShareVerify.Domain.Entities;
using ShareVerify.Domain.Enums;
using ShareVerify.Infrastructure.Data;

namespace ShareVerify.Tests.Infrastructure;

public static class TestDbContextFactory
{
    public static AppDbContext Create(string dbName)
    {
        var options = new DbContextOptionsBuilder<AppDbContext>()
            .UseInMemoryDatabase(dbName)
            .Options;
        return new AppDbContext(options);
    }

    public static async Task SeedDashboardScenarioAsync(AppDbContext context)
    {
        var personOneMcd = new Person { Id = 1, FullName = "Person One" };
        var personTwoMcd = new Person { Id = 2, FullName = "Person Two" };
        var personSingle = new Person { Id = 3, FullName = "Person Single" };

        context.Persons.AddRange(personOneMcd, personTwoMcd, personSingle);

        context.Shareholders.AddRange(
            new Shareholder { Mcd = "MCD001", FullName = "Shareholder A", TotalShares = 1000 },
            new Shareholder { Mcd = "MCD002", FullName = "Shareholder B", TotalShares = 2000 },
            new Shareholder { Mcd = "MCD003", FullName = "Shareholder C", TotalShares = 3000 },
            new Shareholder { Mcd = "MCD004", FullName = "Shareholder D", TotalShares = 4000 });

        context.TravelSupports.AddRange(
            new TravelSupport
            {
                PersonId = 1, Mcd = "MCD001", ReceiverName = "Person One",
                ReceiveAmount = 100, ReceiveTime = DateTime.UtcNow.AddHours(-2),
                AttendanceType = AttendanceType.Direct,
            },
            new TravelSupport
            {
                PersonId = 1, Mcd = "MCD002", ReceiverName = "Person One",
                ReceiveAmount = 200, ReceiveTime = DateTime.UtcNow.AddHours(-1),
                AttendanceType = AttendanceType.Direct,
            },
            new TravelSupport
            {
                PersonId = 3, Mcd = "MCD003", ReceiverName = "Person Single",
                ReceiveAmount = 300, ReceiveTime = DateTime.UtcNow,
                AttendanceType = AttendanceType.Direct,
            });

        await context.SaveChangesAsync();
    }
}
```

- [ ] **Step 3: Verify build**

Run: `cd /Users/sypham/projects/becamex/ShareVerify && dotnet build tests/ShareVerify.Tests`
Expected: Build succeeded

- [ ] **Step 4: Commit**

```bash
cd /Users/sypham/projects/becamex/ShareVerify
git add tests/ShareVerify.Tests/ShareVerify.Tests.csproj tests/ShareVerify.Tests/Infrastructure/TestDbContextFactory.cs
git commit -m "test: add EF InMemory factory for repository tests"
```

---

### Task 2: Dashboard `warningCount`

**Files:**
- Modify: `src/ShareVerify.Application/DTOs/DashboardDtos.cs`
- Modify: `src/ShareVerify.Application/Interfaces/ITravelSupportRepository.cs`
- Modify: `src/ShareVerify.Infrastructure/Repositories/TravelSupportRepository.cs`
- Modify: `src/ShareVerify.Application/Services/DashboardService.cs`
- Create: `tests/ShareVerify.Tests/Services/DashboardServiceTests.cs`

- [ ] **Step 1: Write failing test**

```csharp
using FluentAssertions;
using Moq;
using ShareVerify.Application.Interfaces;
using ShareVerify.Application.Services;

namespace ShareVerify.Tests.Services;

public class DashboardServiceTests
{
    [Fact]
    public async Task GetSummaryAsync_CountsPersonsWithTwoOrMoreDistinctMcds()
    {
        var shareholderRepo = new Mock<IShareholderRepository>();
        shareholderRepo.Setup(r => r.CountAsync(It.IsAny<CancellationToken>())).ReturnsAsync(4);

        var travelSupportRepo = new Mock<ITravelSupportRepository>();
        travelSupportRepo.Setup(r => r.CountAsync(It.IsAny<CancellationToken>())).ReturnsAsync(3);
        travelSupportRepo
            .Setup(r => r.CountPersonsWithMultipleMcdsAsync(2, It.IsAny<CancellationToken>()))
            .ReturnsAsync(1);

        var service = new DashboardService(shareholderRepo.Object, travelSupportRepo.Object);
        var summary = await service.GetSummaryAsync();

        summary.WarningCount.Should().Be(1);
        summary.ReceivedCount.Should().Be(3);
        summary.NotReceivedCount.Should().Be(1);
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd /Users/sypham/projects/becamex/ShareVerify && dotnet test tests/ShareVerify.Tests --filter "FullyQualifiedName~DashboardServiceTests" -v n`
Expected: FAIL — `WarningCount` / `CountPersonsWithMultipleMcdsAsync` not defined

- [ ] **Step 3: Implement**

`DashboardDtos.cs` — add property:

```csharp
public int WarningCount { get; set; }
```

`ITravelSupportRepository.cs` — add:

```csharp
Task<int> CountPersonsWithMultipleMcdsAsync(int minDistinctMcd, CancellationToken cancellationToken = default);
```

`TravelSupportRepository.cs` — implement:

```csharp
public async Task<int> CountPersonsWithMultipleMcdsAsync(
    int minDistinctMcd,
    CancellationToken cancellationToken = default)
{
    return await _context.TravelSupports
        .AsNoTracking()
        .GroupBy(ts => ts.PersonId)
        .Where(g => g.Select(ts => ts.Mcd).Distinct().Count() >= minDistinctMcd)
        .CountAsync(cancellationToken);
}
```

`DashboardService.cs` — extend `GetSummaryAsync`:

```csharp
var warningCount = await _travelSupportRepository.CountPersonsWithMultipleMcdsAsync(2, cancellationToken);

return new DashboardSummaryDto
{
    TotalShareholders = totalShareholders,
    ReceivedCount = receivedCount,
    NotReceivedCount = notReceivedCount,
    CompletionRate = completionRate,
    WarningCount = warningCount,
};
```

- [ ] **Step 4: Run test to verify it passes**

Run: `cd /Users/sypham/projects/becamex/ShareVerify && dotnet test tests/ShareVerify.Tests --filter "FullyQualifiedName~DashboardServiceTests" -v n`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add src/ShareVerify.Application/DTOs/DashboardDtos.cs \
  src/ShareVerify.Application/Interfaces/ITravelSupportRepository.cs \
  src/ShareVerify.Infrastructure/Repositories/TravelSupportRepository.cs \
  src/ShareVerify.Application/Services/DashboardService.cs \
  tests/ShareVerify.Tests/Services/DashboardServiceTests.cs
git commit -m "feat: add warningCount to dashboard summary"
```

---

### Task 3: Shareholder list endpoint

**Files:**
- Modify: `src/ShareVerify.Application/Interfaces/IShareholderRepository.cs`
- Modify: `src/ShareVerify.Infrastructure/Repositories/ShareholderRepository.cs`
- Modify: `src/ShareVerify.Application/Interfaces/IShareholderService.cs`
- Modify: `src/ShareVerify.Application/Services/ShareholderService.cs`
- Modify: `src/ShareVerify.Api/Controllers/ShareholdersController.cs`
- Create: `tests/ShareVerify.Tests/Repositories/ShareholderRepositoryListTests.cs`

- [ ] **Step 1: Write failing repository test**

```csharp
using FluentAssertions;
using ShareVerify.Infrastructure.Repositories;
using ShareVerify.Tests.Infrastructure;

namespace ShareVerify.Tests.Repositories;

public class ShareholderRepositoryListTests
{
    [Fact]
    public async Task ListAsync_ReceivedTrue_ReturnsOnlyShareholdersWithTravelSupport()
    {
        await using var context = TestDbContextFactory.Create(nameof(ListAsync_ReceivedTrue));
        await TestDbContextFactory.SeedDashboardScenarioAsync(context);
        var repo = new ShareholderRepository(context);

        var result = await repo.ListAsync(received: true, keyword: string.Empty, page: 1, pageSize: 20);

        result.Items.Select(i => i.Mcd).Should().BeEquivalentTo(["MCD001", "MCD002", "MCD003"]);
        result.TotalCount.Should().Be(3);
    }

    [Fact]
    public async Task ListAsync_ReceivedFalse_ReturnsShareholdersWithoutTravelSupport()
    {
        await using var context = TestDbContextFactory.Create(nameof(ListAsync_ReceivedFalse));
        await TestDbContextFactory.SeedDashboardScenarioAsync(context);
        var repo = new ShareholderRepository(context);

        var result = await repo.ListAsync(received: false, keyword: string.Empty, page: 1, pageSize: 20);

        result.Items.Should().ContainSingle(i => i.Mcd == "MCD004");
        result.TotalCount.Should().Be(1);
    }

    [Fact]
    public async Task ListAsync_Keyword_FiltersByMcdOrName()
    {
        await using var context = TestDbContextFactory.Create(nameof(ListAsync_Keyword));
        await TestDbContextFactory.SeedDashboardScenarioAsync(context);
        var repo = new ShareholderRepository(context);

        var result = await repo.ListAsync(received: true, keyword: "MCD002", page: 1, pageSize: 20);

        result.Items.Should().ContainSingle(i => i.Mcd == "MCD002");
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd /Users/sypham/projects/becamex/ShareVerify && dotnet test tests/ShareVerify.Tests --filter "FullyQualifiedName~ShareholderRepositoryListTests" -v n`
Expected: FAIL — `ListAsync` not defined

- [ ] **Step 3: Implement repository**

`IShareholderRepository.cs` — add:

```csharp
Task<PagedSearchResult<ShareholderSearchResult>> ListAsync(
    bool received,
    string keyword,
    int page,
    int pageSize,
    CancellationToken cancellationToken = default);
```

`ShareholderRepository.cs` — implement (direct join on `Mcd`, not `PersonShareholders`):

```csharp
public async Task<PagedSearchResult<ShareholderSearchResult>> ListAsync(
    bool received,
    string keyword,
    int page,
    int pageSize,
    CancellationToken cancellationToken = default)
{
    var query = from s in _context.Shareholders.AsNoTracking()
                join ts in _context.TravelSupports.AsNoTracking()
                    on s.Mcd equals ts.Mcd into tsGroup
                from ts in tsGroup.DefaultIfEmpty()
                select new { Shareholder = s, TravelSupport = ts };

    query = received
        ? query.Where(x => x.TravelSupport != null)
        : query.Where(x => x.TravelSupport == null);

    if (!string.IsNullOrWhiteSpace(keyword))
    {
        var normalized = keyword.Trim().ToLower();
        query = query.Where(x =>
            x.Shareholder.Mcd.ToLower().Contains(normalized)
            || x.Shareholder.FullName.ToLower().Contains(normalized)
            || (x.Shareholder.RegistrationNo != null
                && x.Shareholder.RegistrationNo.ToLower().Contains(normalized)));
    }

    var projected = query.Select(x => new ShareholderSearchResult
    {
        Mcd = x.Shareholder.Mcd,
        FullName = x.Shareholder.FullName,
        RegistrationNo = x.Shareholder.RegistrationNo,
        Phone = x.Shareholder.Phone,
        TotalShares = x.Shareholder.TotalShares,
        TravelSupportReceived = x.TravelSupport != null,
        ReceiveTime = x.TravelSupport != null ? x.TravelSupport.ReceiveTime : null,
    });

    var totalCount = await projected.CountAsync(cancellationToken);
    var items = await projected
        .OrderBy(x => x.Mcd)
        .Skip((page - 1) * pageSize)
        .Take(pageSize)
        .ToListAsync(cancellationToken);

    return new PagedSearchResult<ShareholderSearchResult>
    {
        Items = items,
        TotalCount = totalCount,
        Page = page,
        PageSize = pageSize,
    };
}
```

- [ ] **Step 4: Implement service + controller**

`IShareholderService.cs`:

```csharp
Task<PagedResultDto<ShareholderSearchDto>> ListAsync(
    bool received,
    string keyword,
    int page,
    int pageSize,
    CancellationToken cancellationToken = default);
```

`ShareholderService.cs`:

```csharp
public async Task<PagedResultDto<ShareholderSearchDto>> ListAsync(
    bool received,
    string keyword,
    int page,
    int pageSize,
    CancellationToken cancellationToken = default)
{
    var safePage = page < 1 ? 1 : page;
    var safePageSize = pageSize switch { < 1 => 20, > 100 => 100, _ => pageSize };

    var result = await _shareholderRepository.ListAsync(
        received,
        keyword?.Trim() ?? string.Empty,
        safePage,
        safePageSize,
        cancellationToken);

    return new PagedResultDto<ShareholderSearchDto>
    {
        Items = _mapper.Map<List<ShareholderSearchDto>>(result.Items),
        TotalCount = result.TotalCount,
        Page = result.Page,
        PageSize = result.PageSize,
    };
}
```

`ShareholdersController.cs` — add before `{mcd}` route:

```csharp
[HttpGet("list")]
public async Task<IActionResult> List(
    [FromQuery] bool received,
    [FromQuery] string? keyword,
    [FromQuery] int page = 1,
    [FromQuery] int pageSize = 20,
    CancellationToken cancellationToken = default)
{
    var results = await _shareholderService.ListAsync(
        received,
        keyword ?? string.Empty,
        page,
        pageSize,
        cancellationToken);
    return Ok(results);
}
```

- [ ] **Step 5: Run tests**

Run: `cd /Users/sypham/projects/becamex/ShareVerify && dotnet test tests/ShareVerify.Tests --filter "FullyQualifiedName~ShareholderRepositoryListTests" -v n`
Expected: PASS

- [ ] **Step 6: Commit**

```bash
git add src/ShareVerify.Application/Interfaces/IShareholderRepository.cs \
  src/ShareVerify.Infrastructure/Repositories/ShareholderRepository.cs \
  src/ShareVerify.Application/Interfaces/IShareholderService.cs \
  src/ShareVerify.Application/Services/ShareholderService.cs \
  src/ShareVerify.Api/Controllers/ShareholdersController.cs \
  tests/ShareVerify.Tests/Repositories/ShareholderRepositoryListTests.cs
git commit -m "feat: add paginated shareholder list endpoint"
```

---

### Task 4: Recipient search `groupBy=person` and `minLinkedMcd`

**Files:**
- Modify: `src/ShareVerify.Application/Interfaces/IRecipientRepository.cs`
- Modify: `src/ShareVerify.Infrastructure/Repositories/RecipientRepository.cs`
- Modify: `src/ShareVerify.Application/Interfaces/IRecipientService.cs`
- Modify: `src/ShareVerify.Application/Services/RecipientService.cs`
- Modify: `src/ShareVerify.Api/Controllers/RecipientsController.cs`
- Modify: `tests/ShareVerify.Tests/Repositories/RecipientRepositoryTests.cs` (create)

- [ ] **Step 1: Write failing test**

```csharp
using FluentAssertions;
using ShareVerify.Infrastructure.Repositories;
using ShareVerify.Tests.Infrastructure;

namespace ShareVerify.Tests.Repositories;

public class RecipientRepositoryTests
{
    [Fact]
    public async Task SearchAsync_GroupByPerson_ReturnsOneRowPerPersonWithDistinctMcdCount()
    {
        await using var context = TestDbContextFactory.Create(nameof(SearchAsync_GroupByPerson));
        await TestDbContextFactory.SeedDashboardScenarioAsync(context);
        var repo = new RecipientRepository(context);

        var result = await repo.SearchAsync(
            keyword: string.Empty,
            page: 1,
            pageSize: 20,
            groupByPerson: true,
            minLinkedMcd: null);

        result.Items.Should().HaveCount(2);
        var warningPerson = result.Items.Single(i => i.PersonId == 1);
        warningPerson.LinkedMcdCount.Should().Be(2);
        warningPerson.PrimaryMcd.Should().Be("MCD002"); // latest receive time
    }

    [Fact]
    public async Task SearchAsync_MinLinkedMcd_FiltersToWarningPersonsOnly()
    {
        await using var context = TestDbContextFactory.Create(nameof(SearchAsync_MinLinkedMcd));
        await TestDbContextFactory.SeedDashboardScenarioAsync(context);
        var repo = new RecipientRepository(context);

        var result = await repo.SearchAsync(
            keyword: string.Empty,
            page: 1,
            pageSize: 20,
            groupByPerson: true,
            minLinkedMcd: 2);

        result.Items.Should().ContainSingle(i => i.PersonId == 1);
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd /Users/sypham/projects/becamex/ShareVerify && dotnet test tests/ShareVerify.Tests --filter "FullyQualifiedName~RecipientRepositoryTests" -v n`
Expected: FAIL

- [ ] **Step 3: Extend interface**

`IRecipientRepository.cs` — update `SearchAsync`:

```csharp
Task<PagedSearchResult<RecipientSearchResult>> SearchAsync(
    string keyword,
    int page,
    int pageSize,
    bool groupByPerson = false,
    int? minLinkedMcd = null,
    CancellationToken cancellationToken = default);
```

- [ ] **Step 4: Implement grouped search branch**

At the start of `RecipientRepository.SearchAsync`, add early branch:

```csharp
if (groupByPerson)
{
    var groupedQuery = _context.TravelSupports
        .AsNoTracking()
        .Include(ts => ts.Person)
        .GroupBy(ts => ts.PersonId)
        .Select(g => new
        {
            PersonId = g.Key,
            Latest = g.OrderByDescending(ts => ts.ReceiveTime).First(),
            DistinctMcdCount = g.Select(ts => ts.Mcd).Distinct().Count(),
        });

    if (minLinkedMcd is > 0)
    {
        groupedQuery = groupedQuery.Where(x => x.DistinctMcdCount >= minLinkedMcd.Value);
    }

    if (!string.IsNullOrWhiteSpace(keyword))
    {
        var normalized = keyword.Trim().ToLower();
        groupedQuery = groupedQuery.Where(x =>
            x.Latest.ReceiverName != null && x.Latest.ReceiverName.ToLower().Contains(normalized)
            || x.Latest.Person.FullName.ToLower().Contains(normalized)
            || x.Latest.Mcd.ToLower().Contains(normalized));
    }

    var totalCount = await groupedQuery.CountAsync(cancellationToken);
    var rows = await groupedQuery
        .OrderByDescending(x => x.Latest.ReceiveTime)
        .Skip((page - 1) * pageSize)
        .Take(pageSize)
        .ToListAsync(cancellationToken);

    var items = rows.Select(row => new RecipientSearchResult
    {
        PersonId = row.PersonId,
        DisplayName = row.Latest.ReceiverName ?? row.Latest.Person.FullName,
        IdentityNo = row.Latest.ReceiverIdentityNo ?? row.Latest.Person.IdentityNo,
        IdentityType = row.Latest.IdentityType ?? row.Latest.Person.IdentityType,
        PrimaryMcd = row.Latest.Mcd,
        ReceiveAmount = row.Latest.ReceiveAmount,
        ReceiveTime = row.Latest.ReceiveTime,
        AttendanceType = row.Latest.AttendanceType,
        ProxyPersonName = row.Latest.ProxyPersonName,
        LinkedMcdCount = row.DistinctMcdCount,
    }).ToList();

    return new PagedSearchResult<RecipientSearchResult>
    {
        Items = items,
        TotalCount = totalCount,
        Page = page,
        PageSize = pageSize,
    };
}
```

Keep existing per-check-in logic in the `else` path (current method body).

- [ ] **Step 5: Wire service + controller**

`IRecipientService.cs`:

```csharp
Task<PagedResultDto<RecipientListItemDto>> SearchAsync(
    string keyword,
    int page,
    int pageSize,
    bool groupByPerson = false,
    int? minLinkedMcd = null,
    CancellationToken cancellationToken = default);
```

`RecipientService.SearchAsync` — pass `groupByPerson` and `minLinkedMcd` to repository.

`RecipientsController.Search` — add query params:

```csharp
[FromQuery] bool groupByPerson = false,
[FromQuery] int? minLinkedMcd = null,
```

- [ ] **Step 6: Run tests**

Run: `cd /Users/sypham/projects/becamex/ShareVerify && dotnet test tests/ShareVerify.Tests --filter "FullyQualifiedName~RecipientRepositoryTests" -v n`
Expected: PASS

- [ ] **Step 7: Commit**

```bash
git add src/ShareVerify.Application/Interfaces/IRecipientRepository.cs \
  src/ShareVerify.Infrastructure/Repositories/RecipientRepository.cs \
  src/ShareVerify.Application/Interfaces/IRecipientService.cs \
  src/ShareVerify.Application/Services/RecipientService.cs \
  src/ShareVerify.Api/Controllers/RecipientsController.cs \
  tests/ShareVerify.Tests/Repositories/RecipientRepositoryTests.cs
git commit -m "feat: add person-grouped recipient search with minLinkedMcd filter"
```

---

### Task 5: Recipient detail multi-check-in response

**Files:**
- Modify: `src/ShareVerify.Application/DTOs/RecipientDtos.cs`
- Modify: `src/ShareVerify.Application/Interfaces/IRecipientRepository.cs`
- Modify: `src/ShareVerify.Infrastructure/Repositories/RecipientRepository.cs`
- Modify: `src/ShareVerify.Application/Services/RecipientService.cs`
- Modify: `tests/ShareVerify.Tests/Repositories/RecipientRepositoryTests.cs`

- [ ] **Step 1: Write failing test**

Add to `RecipientRepositoryTests`:

```csharp
[Fact]
public async Task GetDetailAsync_ReturnsAllCheckInsOrderedByReceiveTimeDesc()
{
    await using var context = TestDbContextFactory.Create(nameof(GetDetailAsync_CheckIns));
    await TestDbContextFactory.SeedDashboardScenarioAsync(context);
    var repo = new RecipientRepository(context);

    var detail = await repo.GetDetailAsync(1);

    detail.Should().NotBeNull();
    detail!.CheckIns.Should().HaveCount(2);
    detail.CheckIns[0].Mcd.Should().Be("MCD002");
    detail.CheckIns[1].Mcd.Should().Be("MCD001");
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd /Users/sypham/projects/becamex/ShareVerify && dotnet test tests/ShareVerify.Tests --filter "GetDetailAsync_ReturnsAllCheckIns" -v n`
Expected: FAIL — `CheckIns` not on result

- [ ] **Step 3: Add DTOs and result types**

`RecipientDtos.cs`:

```csharp
public class RecipientCheckInDto
{
    public string Mcd { get; set; } = string.Empty;
    public string ShareholderFullName { get; set; } = string.Empty;
    public decimal TotalShares { get; set; }
    public TravelSupportInfoDto TravelSupport { get; set; } = new();
}

public class RecipientDetailDto
{
    public long PersonId { get; set; }
    public string PersonFullName { get; set; } = string.Empty;
    public string? IdentityNo { get; set; }
    public string? IdentityType { get; set; }
    public List<RecipientCheckInDto> CheckIns { get; set; } = [];
}
```

`IRecipientRepository.cs` — replace `RecipientDetailResult`:

```csharp
public class RecipientCheckInResult
{
    public string Mcd { get; set; } = string.Empty;
    public string ShareholderFullName { get; set; } = string.Empty;
    public decimal TotalShares { get; set; }
    public Domain.Entities.TravelSupport TravelSupport { get; set; } = null!;
}

public class RecipientDetailResult
{
    public long PersonId { get; set; }
    public string PersonFullName { get; set; } = string.Empty;
    public string? IdentityNo { get; set; }
    public string? IdentityType { get; set; }
    public List<RecipientCheckInResult> CheckIns { get; set; } = [];
}
```

- [ ] **Step 4: Rewrite `GetDetailAsync`**

```csharp
public async Task<RecipientDetailResult?> GetDetailAsync(
    long personId,
    CancellationToken cancellationToken = default)
{
    var person = await _context.Persons
        .AsNoTracking()
        .FirstOrDefaultAsync(p => p.Id == personId, cancellationToken);

    if (person is null)
    {
        return null;
    }

    var travelSupports = await _context.TravelSupports
        .AsNoTracking()
        .Where(ts => ts.PersonId == personId)
        .OrderByDescending(ts => ts.ReceiveTime)
        .ToListAsync(cancellationToken);

    if (travelSupports.Count == 0)
    {
        return null;
    }

    var mcds = travelSupports.Select(ts => ts.Mcd).Distinct().ToList();
    var shareholders = await _context.Shareholders
        .AsNoTracking()
        .Where(s => mcds.Contains(s.Mcd))
        .ToDictionaryAsync(s => s.Mcd, cancellationToken);

    var checkIns = travelSupports.Select(ts =>
    {
        shareholders.TryGetValue(ts.Mcd, out var shareholder);
        return new RecipientCheckInResult
        {
            Mcd = ts.Mcd,
            ShareholderFullName = shareholder?.FullName ?? ts.Mcd,
            TotalShares = shareholder?.TotalShares ?? 0,
            TravelSupport = ts,
        };
    }).ToList();

    var first = travelSupports[0];
    return new RecipientDetailResult
    {
        PersonId = personId,
        PersonFullName = person.FullName,
        IdentityNo = first.ReceiverIdentityNo ?? person.IdentityNo,
        IdentityType = first.IdentityType ?? person.IdentityType,
        CheckIns = checkIns,
    };
}
```

- [ ] **Step 5: Update `RecipientService.GetDetailAsync`**

```csharp
return new RecipientDetailDto
{
    PersonId = detail.PersonId,
    PersonFullName = detail.PersonFullName,
    IdentityNo = detail.IdentityNo,
    IdentityType = detail.IdentityType,
    CheckIns = detail.CheckIns.Select(checkIn => new RecipientCheckInDto
    {
        Mcd = checkIn.Mcd,
        ShareholderFullName = checkIn.ShareholderFullName,
        TotalShares = checkIn.TotalShares,
        TravelSupport = _mapper.Map<TravelSupportInfoDto>(checkIn.TravelSupport),
    }).ToList(),
};
```

- [ ] **Step 6: Run tests**

Run: `cd /Users/sypham/projects/becamex/ShareVerify && dotnet test tests/ShareVerify.Tests -v n`
Expected: All PASS

- [ ] **Step 7: Commit**

```bash
git add src/ShareVerify.Application/DTOs/RecipientDtos.cs \
  src/ShareVerify.Application/Interfaces/IRecipientRepository.cs \
  src/ShareVerify.Infrastructure/Repositories/RecipientRepository.cs \
  src/ShareVerify.Application/Services/RecipientService.cs \
  tests/ShareVerify.Tests/Repositories/RecipientRepositoryTests.cs
git commit -m "feat: return multi-check-in recipient detail"
```

---

## Part 2 — Flutter (share_verify)

### Task 6: Dashboard data layer — `warningCount` and remove recent activity

**Files:**
- Modify: `lib/core/data/dto/dashboard_dtos.dart`
- Modify: `lib/core/models/dashboard_stats.dart`
- Modify: `lib/core/data/mappers/dashboard_mapper.dart`
- Modify: `lib/core/repositories/dashboard_repository.dart`
- Modify: `lib/core/controllers/dashboard_controller.dart`
- Modify: `test/data/dashboard_dtos_test.dart`
- Modify: `test/fixtures/test_data.dart`
- Modify: `test/controllers/dashboard_controller_test.dart`
- Modify: `test/support/fake_repositories.dart`

- [ ] **Step 1: Write failing DTO test**

Add to `test/data/dashboard_dtos_test.dart`:

```dart
test('DashboardSummaryDto parses warningCount', () {
  final dto = DashboardSummaryDto.fromJson({
    'totalShareholders': 1801,
    'receivedCount': 1234,
    'notReceivedCount': 567,
    'completionRate': 68.52,
    'warningCount': 42,
  });

  expect(dto.warningCount, 42);
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd /Users/sypham/projects/becamex/share_verify && flutter test test/data/dashboard_dtos_test.dart --plain-name "parses warningCount"`
Expected: FAIL — `warningCount` getter missing

- [ ] **Step 3: Implement**

`dashboard_dtos.dart` — add field + parse:

```dart
final int warningCount;

const DashboardSummaryDto({
  // ...existing...
  this.warningCount = 0,
});

// in fromJson:
warningCount: _readInt(json['warningCount']),
```

`dashboard_stats.dart` — add:

```dart
final int warningCount;

const DashboardStats({
  required this.receivedCount,
  required this.notReceivedCount,
  required this.warningCount,
  this.totalShareholders = 0,
  this.completionRatePercent = 0,
});
```

`dashboard_mapper.dart`:

```dart
return DashboardStats(
  totalShareholders: dto.totalShareholders,
  receivedCount: dto.receivedCount,
  notReceivedCount: dto.notReceivedCount,
  warningCount: dto.warningCount,
  completionRatePercent: completionRatePercent,
);
```

`dashboard_repository.dart` — remove `getRecentActivity` and `TravelSupportRemoteSource` dependency.

`dashboard_controller.dart`:

```dart
@override
Future<void> refresh() async {
  isLoading.value = true;
  errorMessage.value = null;
  try {
    stats.value = await _dashboardRepository.getSummary();
  } catch (error) {
    errorMessage.value = ApiClient.messageFrom(error);
  } finally {
    isLoading.value = false;
  }
}

int get warningCount => stats.value.warningCount;
```

Remove `activities`, `recentActivities`, and `ActivityItem` import.

`test_data.dart`:

```dart
static const dashboardStats = DashboardStats(
  receivedCount: 450,
  notReceivedCount: 750,
  warningCount: 12,
);
```

`fake_repositories.dart` — remove `getRecentActivity` from `FakeDashboardRepository`.

`dashboard_controller_test.dart`:

```dart
test('refresh loads dashboard stats with warningCount', () async {
  final controller = DashboardController(
    dashboardRepository: FakeDashboardRepository(),
  );

  await controller.refresh();

  expect(controller.receivedCount, 450);
  expect(controller.warningCount, 12);
  expect(controller.isLoading.value, isFalse);
  expect(controller.errorMessage.value, isNull);
});
```

- [ ] **Step 4: Run tests**

Run: `cd /Users/sypham/projects/becamex/share_verify && flutter test test/data/dashboard_dtos_test.dart test/controllers/dashboard_controller_test.dart`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
cd /Users/sypham/projects/becamex/share_verify
git add lib/core/data/dto/dashboard_dtos.dart lib/core/models/dashboard_stats.dart \
  lib/core/data/mappers/dashboard_mapper.dart lib/core/repositories/dashboard_repository.dart \
  lib/core/controllers/dashboard_controller.dart test/data/dashboard_dtos_test.dart \
  test/fixtures/test_data.dart test/controllers/dashboard_controller_test.dart \
  test/support/fake_repositories.dart
git commit -m "feat: add warningCount to dashboard stats, remove recent activity"
```

---

### Task 7: `SvKpiCard` — hide progress bar, add tap

**Files:**
- Modify: `lib/core/widgets/sv_kpi_card.dart`
- Modify: `test/widgets/sv_kpi_card_test.dart`

- [ ] **Step 1: Write failing widget test**

```dart
testWidgets('hides progress bar by default', (tester) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SvKpiCard(
          label: 'Đã nhận hỗ trợ',
          value: '450',
          backgroundColor: SvPalette.tertiaryContainer,
          foregroundColor: SvPalette.onTertiary,
          icon: Icons.check_circle,
        ),
      ),
    ),
  );
  expect(find.byType(LinearProgressIndicator), findsNothing);
});

testWidgets('invokes onTap when provided', (tester) async {
  var tapped = false;
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SvKpiCard(
          label: 'Cảnh báo',
          value: '12',
          backgroundColor: SvPalette.errorContainer,
          foregroundColor: SvPalette.onErrorContainer,
          icon: Icons.warning_amber,
          onTap: () => tapped = true,
        ),
      ),
    ),
  );
  await tester.tap(find.byType(SvKpiCard));
  expect(tapped, isTrue);
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd /Users/sypham/projects/becamex/share_verify && flutter test test/widgets/sv_kpi_card_test.dart`
Expected: FAIL — progress still shown, `onTap` missing

- [ ] **Step 3: Implement**

```dart
class SvKpiCard extends StatelessWidget {
  final String label;
  final String value;
  final Color backgroundColor;
  final Color foregroundColor;
  final IconData icon;
  final VoidCallback? onTap;
  final bool showProgress;
  final double progress;
  final Color progressColor;

  const SvKpiCard({
    super.key,
    required this.label,
    required this.value,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.icon,
    this.onTap,
    this.showProgress = false,
    this.progress = 0,
    this.progressColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final card = Container(
      // ...existing decoration...
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ...label + value rows...
          if (showProgress) ...[
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
        ],
      ),
    );

    if (onTap == null) return card;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(SvSpacing.radiusXl),
        child: card,
      ),
    );
  }
}
```

- [ ] **Step 4: Run tests**

Run: `cd /Users/sypham/projects/becamex/share_verify && flutter test test/widgets/sv_kpi_card_test.dart`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add lib/core/widgets/sv_kpi_card.dart test/widgets/sv_kpi_card_test.dart
git commit -m "feat: make SvKpiCard tappable with optional progress bar"
```

---

### Task 8: Dashboard screen — 4-card grid

**Files:**
- Modify: `lib/core/screens/dashboard/dashboard_screen.dart`
- Create: `test/widgets/dashboard_screen_test.dart`
- Modify: `lib/core/bindings/shell_binding.dart` (if dashboard needs new route imports only)

- [ ] **Step 1: Write failing widget test**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:share_verify/core/controllers/dashboard_controller.dart';
import 'package:share_verify/core/screens/dashboard/dashboard_screen.dart';
import '../support/fake_repositories.dart';
import '../support/pump_app.dart';

void main() {
  setUp(() {
    Get.testMode = true;
    Get.put(DashboardController(dashboardRepository: FakeDashboardRepository()));
  });
  tearDown(Get.reset);

  testWidgets('renders four KPI cards without progress ring', (tester) async {
    await pumpApp(tester, const DashboardScreen());
    await tester.pumpAndSettle();

    expect(find.text('Đã nhận hỗ trợ'), findsOneWidget);
    expect(find.text('Chưa nhận hỗ trợ'), findsOneWidget);
    expect(find.text('Cảnh báo'), findsOneWidget);
    expect(find.text('Cổ đông đã check-in'), findsOneWidget);
    expect(find.text('Tổng số cổ đông'), findsNothing);
    expect(find.text('Hoạt động gần đây'), findsNothing);
    expect(find.byType(LinearProgressIndicator), findsNothing);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd /Users/sypham/projects/becamex/share_verify && flutter test test/widgets/dashboard_screen_test.dart`
Expected: FAIL

- [ ] **Step 3: Rewrite `dashboard_screen.dart`**

Replace body content with 2×2 `GridView` of four `SvKpiCard` widgets:

```dart
GridView.count(
  crossAxisCount: 2,
  crossAxisSpacing: SvSpacing.sm,
  mainAxisSpacing: SvSpacing.sm,
  childAspectRatio: 1.55,
  shrinkWrap: true,
  physics: const NeverScrollableScrollPhysics(),
  children: [
    SvKpiCard(
      label: 'Đã nhận hỗ trợ',
      value: controller.receivedCount.toString(),
      backgroundColor: colorScheme.tertiaryContainer,
      foregroundColor: colorScheme.onTertiaryContainer,
      icon: Icons.check_circle,
      onTap: () => Get.toNamed(ReceivedSupportScreen.routeName),
    ),
    SvKpiCard(
      label: 'Chưa nhận hỗ trợ',
      value: controller.notReceivedCount.toString(),
      backgroundColor: colorScheme.errorContainer,
      foregroundColor: colorScheme.onErrorContainer,
      icon: Icons.pending_actions,
      onTap: () => Get.toNamed(
        ShareholdersListScreen.routeName,
        arguments: const ShareholdersListArgs(received: false),
      ),
    ),
    SvKpiCard(
      label: 'Cảnh báo',
      value: controller.warningCount.toString(),
      backgroundColor: colorScheme.secondaryContainer,
      foregroundColor: colorScheme.onSecondaryContainer,
      icon: Icons.warning_amber,
      onTap: () => Get.toNamed(WarningRecipientsScreen.routeName),
    ),
    SvKpiCard(
      label: 'Cổ đông đã check-in',
      value: controller.receivedCount.toString(),
      backgroundColor: colorScheme.primaryContainer,
      foregroundColor: colorScheme.onPrimaryContainer,
      icon: Icons.groups,
      onTap: () => Get.toNamed(
        ShareholdersListScreen.routeName,
        arguments: const ShareholdersListArgs(received: true),
      ),
    ),
  ],
),
```

Remove imports for `ProgressRingSection`, `RecentActivityList`, `DashboardFormat`, `RecipientsListScreen`.

Update loading guard: `if (controller.isLoading.value && controller.stats.value.receivedCount == 0 && controller.stats.value.notReceivedCount == 0)`

- [ ] **Step 4: Run tests**

Run: `cd /Users/sypham/projects/becamex/share_verify && flutter test test/widgets/dashboard_screen_test.dart`
Expected: PASS (routes may not exist yet — stub route names as constants in test or skip navigation assertions)

- [ ] **Step 5: Commit**

```bash
git add lib/core/screens/dashboard/dashboard_screen.dart test/widgets/dashboard_screen_test.dart
git commit -m "feat: redesign dashboard with four tappable KPI cards"
```

---

### Task 9: Shareholder list API client + repository

**Files:**
- Modify: `lib/core/data/sources/shareholder_remote_source.dart`
- Modify: `lib/core/repositories/shareholder_repository.dart`
- Modify: `test/support/fake_repositories.dart`

- [ ] **Step 1: Write failing unit test** (add `test/repositories/shareholder_repository_list_test.dart`)

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:share_verify/core/data/sources/shareholder_remote_source.dart';
import 'package:share_verify/core/network/api_client.dart';
import 'package:share_verify/core/repositories/shareholder_repository.dart';

class _FakeApiClient extends ApiClient {
  _FakeApiClient() : super(baseUrl: 'http://test');

  Map<String, dynamic>? lastQuery;

  @override
  Future<ApiResponse<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    lastQuery = queryParameters;
    return ApiResponse(
      data: {
        'items': [
          {
            'mcd': 'MCD001',
            'fullName': 'Nguyễn Văn A',
            'totalShares': 1000,
            'travelSupportReceived': true,
            'receiveTime': '2026-06-20T08:30:00Z',
          }
        ],
        'totalCount': 1,
        'page': 1,
        'pageSize': 20,
      } as T,
    );
  }
}

void main() {
  test('listShareholders calls /api/shareholders/list with received flag', () async {
    final client = _FakeApiClient();
    final repo = ShareholderRepositoryImpl(
      remoteSource: ShareholderRemoteSource(client),
    );

    final page = await repo.listShareholders(received: true);

    expect(client.lastQuery?['received'], 'true');
    expect(page.items, hasLength(1));
    expect(page.items.first.mcd, 'MCD001');
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd /Users/sypham/projects/becamex/share_verify && flutter test test/repositories/shareholder_repository_list_test.dart`
Expected: FAIL — `listShareholders` not defined

- [ ] **Step 3: Implement**

`shareholder_remote_source.dart`:

```dart
Future<ShareholderSearchPageDto> list({
  required bool received,
  String keyword = '',
  int page = 1,
  int pageSize = 20,
}) async {
  final response = await _client.get<Map<String, dynamic>>(
    '/api/shareholders/list',
    queryParameters: {
      'received': received.toString(),
      'keyword': keyword,
      'page': page,
      'pageSize': pageSize,
    },
  );
  return ShareholderSearchPageDto.fromJson(response.data ?? {});
}
```

`shareholder_repository.dart` — add to abstract class + impl:

```dart
Future<ShareholderSearchPageDto> listShareholders({
  required bool received,
  String keyword = '',
  int page = 1,
  int pageSize = 20,
});
```

Update `FakeShareholderRepository` with stub returning paginated results from `TestData.shareholders` filtered by `PaymentStatus`.

- [ ] **Step 4: Run tests**

Run: `cd /Users/sypham/projects/becamex/share_verify && flutter test test/repositories/shareholder_repository_list_test.dart`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add lib/core/data/sources/shareholder_remote_source.dart lib/core/repositories/shareholder_repository.dart \
  test/repositories/shareholder_repository_list_test.dart test/support/fake_repositories.dart
git commit -m "feat: add shareholder list repository method"
```

---

### Task 10: Shareholders list screen + controller

**Files:**
- Create: `lib/core/controllers/shareholders_list_controller.dart`
- Create: `lib/core/screens/shareholders/shareholders_list_screen.dart`
- Create: `lib/core/screens/shareholders/components/shareholder_list_tile.dart`
- Create: `lib/core/bindings/shareholders_binding.dart`

- [ ] **Step 1: Create args class in screen file**

```dart
class ShareholdersListArgs {
  final bool received;
  const ShareholdersListArgs({required this.received});
}
```

- [ ] **Step 2: Implement controller** (mirror `RecipientsListController`)

```dart
class ShareholdersListController extends GetxController {
  ShareholdersListController({required this.received, ShareholderRepository? repository})
      : _repository = repository ?? Get.find<ShareholderRepository>();

  final bool received;
  final ShareholderRepository _repository;
  final items = <ShareholderSearchDto>[].obs;
  // ...same pagination pattern as RecipientsListController...

  Future<void> loadInitial() async {
    _page = 1;
    _hasMore = true;
    isLoading.value = true;
    errorMessage.value = null;
    try {
      final page = await _repository.listShareholders(
        received: received,
        keyword: searchQuery.value,
        page: _page,
        pageSize: _pageSize,
      );
      items.value = page.items;
      totalCount.value = page.totalCount;
      _hasMore = page.hasMore;
    } catch (error) {
      errorMessage.value = ApiClient.messageFrom(error);
      items.clear();
    } finally {
      isLoading.value = false;
    }
  }
}
```

- [ ] **Step 3: Implement `ShareholderListTile`**

Shows MCD, full name, total shares, receive time (if `receiveTime != null`).

- [ ] **Step 4: Implement screen**

- Route: `static const routeName = '/shareholders';`
- Title: `received ? 'Cổ đông đã check-in' : 'Cổ đông chưa check-in'`
- Search field, infinite scroll, pull-to-refresh, error/empty states (copy pattern from `RecipientsListScreen`)
- `onTap` → `Get.toNamed(ShareholderDetailScreen.routeName, arguments: item.mcd)`

- [ ] **Step 5: Binding**

```dart
class ShareholdersListBinding extends Bindings {
  @override
  void dependencies() {
    final args = Get.arguments is ShareholdersListArgs
        ? Get.arguments as ShareholdersListArgs
        : const ShareholdersListArgs(received: true);
    Get.lazyPut(() => ShareholdersListController(received: args.received));
  }
}
```

- [ ] **Step 6: Manual smoke test**

Run app, tap "Chưa nhận hỗ trợ" card (after routes registered in Task 14).

- [ ] **Step 7: Commit**

```bash
git add lib/core/controllers/shareholders_list_controller.dart \
  lib/core/screens/shareholders/shareholders_list_screen.dart \
  lib/core/screens/shareholders/components/shareholder_list_tile.dart \
  lib/core/bindings/shareholders_binding.dart
git commit -m "feat: add paginated shareholders list screen"
```

---

### Task 11: Shareholder detail screen

**Files:**
- Create: `lib/core/controllers/shareholder_detail_controller.dart`
- Create: `lib/core/screens/shareholders/shareholder_detail_screen.dart`
- Create: `lib/core/screens/shareholders/components/shareholder_detail_body.dart`
- Modify: `lib/core/bindings/shareholders_binding.dart`

- [ ] **Step 1: Implement controller**

```dart
class ShareholderDetailController extends GetxController {
  ShareholderDetailController({required this.mcd, ShareholderRepository? repository})
      : _repository = repository ?? Get.find<ShareholderRepository>();

  final String mcd;
  final ShareholderRepository _repository;
  final shareholder = Rxn<Shareholder>();
  final isLoading = false.obs;
  final errorMessage = RxnString();

  @override
  void onInit() {
    super.onInit();
    loadDetail();
  }

  Future<void> loadDetail() async {
    isLoading.value = true;
    errorMessage.value = null;
    try {
      shareholder.value = await _repository.findByMcd(mcd);
    } catch (error) {
      errorMessage.value = ApiClient.messageFrom(error);
    } finally {
      isLoading.value = false;
    }
  }
}
```

- [ ] **Step 2: Implement `ShareholderDetailBody`**

Reuse `SvResultInfoRow`, `EvidencePhotoPreview`:
- Always show shareholder info (MCD, name, shares, registration no, etc.)
- If `shareholder.travelSupport != null`: show recipient info + evidence + check-in time
- If not checked in: hide evidence block

- [ ] **Step 3: Implement screen** (mirror `RecipientDetailScreen` error/retry pattern)

Route: `static const routeName = '/shareholders/detail';`

- [ ] **Step 4: Commit**

```bash
git add lib/core/controllers/shareholder_detail_controller.dart \
  lib/core/screens/shareholders/shareholder_detail_screen.dart \
  lib/core/screens/shareholders/components/shareholder_detail_body.dart \
  lib/core/bindings/shareholders_binding.dart
git commit -m "feat: add shareholder detail screen"
```

---

### Task 12: Recipient repository + detail model for multi-check-in

**Files:**
- Modify: `lib/core/data/sources/recipient_remote_source.dart`
- Modify: `lib/core/repositories/recipient_repository.dart`
- Modify: `lib/core/data/dto/recipient_dtos.dart`
- Create: `lib/core/models/recipient_check_in.dart`
- Modify: `lib/core/models/recipient_detail.dart`
- Modify: `lib/core/data/mappers/recipient_mapper.dart`
- Modify: `test/support/fake_repositories.dart`

- [ ] **Step 1: Write failing mapper test** (`test/data/recipient_mapper_test.dart`)

```dart
test('RecipientMapper maps checkIns from new detail DTO', () {
  final dto = RecipientDetailDto.fromJson({
    'personId': 42,
    'personFullName': 'Nguyễn Văn A',
    'identityNo': '001234567890',
    'identityType': 'CCCD',
    'checkIns': [
      {
        'mcd': 'MCD001',
        'shareholderFullName': 'Nguyễn Văn A',
        'totalShares': 1000,
        'travelSupport': {
          'receiverName': 'Nguyễn Văn A',
          'receiveAmount': 500000,
          'receiveTime': '2026-06-20T08:30:00Z',
          'attendanceType': 'Direct',
        },
      },
    ],
  });

  final detail = RecipientMapper.fromDetailDto(dto);
  expect(detail.checkIns, hasLength(1));
  expect(detail.checkIns.first.mcd, 'MCD001');
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd /Users/sypham/projects/becamex/share_verify && flutter test test/data/recipient_mapper_test.dart`
Expected: FAIL

- [ ] **Step 3: Implement DTOs and models**

`recipient_dtos.dart` — replace `RecipientDetailDto`:

```dart
class RecipientCheckInDto {
  final String mcd;
  final String shareholderFullName;
  final num totalShares;
  final Map<String, dynamic> travelSupportJson;

  factory RecipientCheckInDto.fromJson(Map<String, dynamic> json) { /* ... */ }
}

class RecipientDetailDto {
  final int personId;
  final String personFullName;
  final String? identityNo;
  final String? identityType;
  final List<RecipientCheckInDto> checkIns;
}
```

`recipient_check_in.dart`:

```dart
class RecipientCheckIn {
  final String mcd;
  final String shareholderFullName;
  final num totalShares;
  final TravelSupportInfo travelSupport;
  const RecipientCheckIn({...});
}
```

`recipient_detail.dart`:

```dart
class RecipientDetail {
  final int personId;
  final String personFullName;
  final String? identityNo;
  final String? identityType;
  final List<RecipientCheckIn> checkIns;
}
```

`recipient_remote_source.dart` — extend `search`:

```dart
queryParameters: {
  'keyword': keyword,
  'page': page,
  'pageSize': pageSize,
  if (groupByPerson) 'groupBy': 'person',
  if (minLinkedMcd != null) 'minLinkedMcd': minLinkedMcd,
},
```

`recipient_repository.dart`:

```dart
Future<RecipientSearchPage> search({
  String keyword = '',
  int page = 1,
  int pageSize = 20,
  bool groupByPerson = false,
  int? minLinkedMcd,
});
```

- [ ] **Step 4: Run tests**

Run: `cd /Users/sypham/projects/becamex/share_verify && flutter test test/data/recipient_mapper_test.dart`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add lib/core/data/sources/recipient_remote_source.dart lib/core/repositories/recipient_repository.dart \
  lib/core/data/dto/recipient_dtos.dart lib/core/models/recipient_check_in.dart \
  lib/core/models/recipient_detail.dart lib/core/data/mappers/recipient_mapper.dart \
  test/data/recipient_mapper_test.dart test/support/fake_repositories.dart
git commit -m "feat: support multi-check-in recipient detail model"
```

---

### Task 13: Recipient detail body — multiple check-in blocks

**Files:**
- Modify: `lib/core/screens/recipients/components/recipient_detail_body.dart`
- Create: `test/widgets/recipient_detail_body_test.dart`

- [ ] **Step 1: Write failing widget test**

```dart
testWidgets('renders one card per check-in', (tester) async {
  final detail = RecipientDetail(
    personId: 1,
    personFullName: 'Nguyễn Văn A',
    identityNo: '001234567890',
    identityType: 'CCCD',
    checkIns: [
      RecipientCheckIn(
        mcd: 'MCD001',
        shareholderFullName: 'Nguyễn Văn A',
        totalShares: 1000,
        travelSupport: TravelSupportInfo(
          receiverName: 'Nguyễn Văn A',
          receiveAmount: 500000,
          receiveTime: DateTime(2026, 6, 20, 8, 30),
        ),
      ),
      RecipientCheckIn(
        mcd: 'MCD002',
        shareholderFullName: 'Nguyễn Văn B',
        totalShares: 2000,
        travelSupport: TravelSupportInfo(
          receiverName: 'Nguyễn Văn A',
          receiveAmount: 600000,
          receiveTime: DateTime(2026, 6, 21, 9, 0),
        ),
      ),
    ],
  );

  await tester.pumpWidget(
    MaterialApp(home: Scaffold(body: RecipientDetailBody(detail: detail))),
  );

  expect(find.text('MCD001'), findsOneWidget);
  expect(find.text('MCD002'), findsOneWidget);
  expect(find.text('Nguyễn Văn A'), findsWidgets);
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd /Users/sypham/projects/becamex/share_verify && flutter test test/widgets/recipient_detail_body_test.dart`
Expected: FAIL

- [ ] **Step 3: Rewrite `RecipientDetailBody`**

```dart
@override
Widget build(BuildContext context) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(detail.personFullName, /* headline */),
      if (detail.identityNo != null) SvResultInfoRow(...),
      const SizedBox(height: SvSpacing.md),
      for (final checkIn in detail.checkIns) ...[
        _CheckInBlock(checkIn: checkIn),
        const SizedBox(height: SvSpacing.md),
      ],
    ],
  );
}
```

Each `_CheckInBlock` shows: shareholder MCD + name + shares, recipient role cards (reuse `_PersonEvidenceCard`), evidence photo, check-in timestamp.

- [ ] **Step 4: Run tests**

Run: `cd /Users/sypham/projects/becamex/share_verify && flutter test test/widgets/recipient_detail_body_test.dart`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add lib/core/screens/recipients/components/recipient_detail_body.dart test/widgets/recipient_detail_body_test.dart
git commit -m "feat: show multiple check-in blocks in recipient detail"
```

---

### Task 14: Received support + warning screens and routes

**Files:**
- Create: `lib/core/screens/dashboard/received_support_screen.dart`
- Create: `lib/core/screens/dashboard/warning_recipients_screen.dart`
- Create: `lib/core/bindings/dashboard_drilldown_binding.dart`
- Modify: `lib/core/controllers/recipients_list_controller.dart`
- Modify: `lib/core/route.dart`

- [ ] **Step 1: Extend `RecipientsListController`**

```dart
class RecipientsListController extends GetxController {
  final bool groupByPerson;
  final int? minLinkedMcd;

  RecipientsListController({
    this.groupByPerson = false,
    this.minLinkedMcd,
    RecipientRepository? recipientRepository,
  }) : _recipientRepository = recipientRepository ?? Get.find<RecipientRepository>();

  // in loadInitial/loadMore:
  final page = await _recipientRepository.search(
    keyword: searchQuery.value,
    page: _page,
    pageSize: _pageSize,
    groupByPerson: groupByPerson,
    minLinkedMcd: minLinkedMcd,
  );
}
```

- [ ] **Step 2: Implement `ReceivedSupportScreen`**

```dart
class ReceivedSupportScreen extends StatelessWidget {
  static const routeName = '/dashboard/received';

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Đã nhận hỗ trợ'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Theo cổ đông'),
              Tab(text: 'Theo người nhận'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            ShareholdersListScreen.embedded(
              args: const ShareholdersListArgs(received: true),
            ),
            RecipientsListScreen.embedded(
              groupByPerson: true,
            ),
          ],
        ),
      ),
    );
  }
}
```

Add optional `embedded` constructors to list screens that omit `Scaffold` app bar when nested in tabs (use `Column` with search + list only).

- [ ] **Step 3: Implement `WarningRecipientsScreen`**

Route: `/dashboard/warnings`. Reuse `RecipientsListScreen` layout with title "Cảnh báo", controller `groupByPerson: true, minLinkedMcd: 2`. Badge "N MCD" already exists in `RecipientListTile` when `linkedMcdCount > 1`.

- [ ] **Step 4: Register routes in `route.dart`**

```dart
GetPage(
  name: ShareholdersListScreen.routeName,
  page: () => const ShareholdersListScreen(),
  binding: ShareholdersListBinding(),
),
GetPage(
  name: ShareholderDetailScreen.routeName,
  page: () => const ShareholderDetailScreen(),
  binding: ShareholderDetailBinding(),
),
GetPage(
  name: ReceivedSupportScreen.routeName,
  page: () => const ReceivedSupportScreen(),
  binding: ReceivedSupportBinding(),
),
GetPage(
  name: WarningRecipientsScreen.routeName,
  page: () => const WarningRecipientsScreen(),
  binding: WarningRecipientsBinding(),
),
```

- [ ] **Step 5: Run full Flutter test suite**

Run: `cd /Users/sypham/projects/becamex/share_verify && flutter test`
Expected: All PASS

- [ ] **Step 6: Commit**

```bash
git add lib/core/screens/dashboard/received_support_screen.dart \
  lib/core/screens/dashboard/warning_recipients_screen.dart \
  lib/core/bindings/dashboard_drilldown_binding.dart \
  lib/core/controllers/recipients_list_controller.dart lib/core/route.dart \
  lib/core/screens/shareholders/shareholders_list_screen.dart \
  lib/core/screens/recipients/recipients_list_screen.dart
git commit -m "feat: add received support and warning drill-down screens"
```

---

### Task 15: Cleanup deprecated dashboard code

**Files:**
- Delete: `lib/core/screens/dashboard/components/recent_activity_list.dart`
- Delete: `lib/core/screens/dashboard/components/progress_ring_section.dart`
- Delete: `lib/core/utils/dashboard_format.dart`
- Delete: `lib/core/models/activity_item.dart`
- Delete: `lib/core/data/mappers/activity_mapper.dart`
- Delete: `test/utils/dashboard_format_test.dart`
- Modify: `lib/core/data/sources/dashboard_remote_source.dart` (remove unused travel support import if any)
- Grep and remove any remaining references

- [ ] **Step 1: Delete files**

```bash
cd /Users/sypham/projects/becamex/share_verify
rm lib/core/screens/dashboard/components/recent_activity_list.dart \
   lib/core/screens/dashboard/components/progress_ring_section.dart \
   lib/core/utils/dashboard_format.dart \
   lib/core/models/activity_item.dart \
   lib/core/data/mappers/activity_mapper.dart \
   test/utils/dashboard_format_test.dart
```

- [ ] **Step 2: Fix compile errors from grep**

Run: `cd /Users/sypham/projects/becamex/share_verify && rg "activity_item|activity_mapper|dashboard_format|recent_activity|progress_ring" lib test`
Remove any stale imports.

- [ ] **Step 3: Run full test suite**

Run: `cd /Users/sypham/projects/becamex/share_verify && flutter test`
Expected: All PASS

- [ ] **Step 4: Commit**

```bash
git add -A
git commit -m "chore: remove deprecated dashboard activity and progress ring code"
```

---

## Self-Review

### Spec coverage

| Spec requirement | Task |
|------------------|------|
| 4 KPI cards, no progress ring/total/recent activity | Tasks 7, 8, 15 |
| Card tap navigation flows | Tasks 8, 10, 11, 14 |
| `warningCount` on dashboard summary | Tasks 2, 6 |
| `GET /api/shareholders/list` | Task 3, 9 |
| `GET /api/recipients?groupBy=person&minLinkedMcd` | Task 4, 12, 14 |
| `GET /api/recipients/{personId}` checkIns shape | Task 5, 12, 13 |
| ShareholdersListScreen pagination/search | Task 10 |
| ShareholderDetailScreen checked-in vs not | Task 11 |
| ReceivedSupportScreen 2 tabs | Task 14 |
| WarningRecipientsScreen with badge | Task 14 (reuses `RecipientListTile`) |
| RecipientDetailScreen multi-block | Task 13 |
| Backend tests | Tasks 1–5 |
| Flutter tests | Tasks 6–8, 13, 15 |
| Error handling (loading/error/empty/retry) | Tasks 10, 11, 14 (patterns from existing screens) |

### Placeholder scan

No TBD/TODO/similar-to placeholders in this plan.

### Type consistency

- Backend `RecipientDetailDto.CheckIns` ↔ Flutter `RecipientDetail.checkIns` ↔ `RecipientCheckInDto` / `RecipientCheckIn`
- `ShareholdersListArgs.received` used consistently in dashboard navigation and controller
- `groupByPerson` / `minLinkedMcd` passed from screen → controller → repository → remote source

---

## Execution Handoff

Plan complete and saved to `docs/superpowers/plans/2026-06-23-dashboard-redesign.md`. Two execution options:

**1. Subagent-Driven (recommended)** — dispatch a fresh subagent per task, review between tasks, fast iteration

**2. Inline Execution** — execute tasks in this session using executing-plans, batch execution with checkpoints

**Recommended order:** Complete Part 1 (Tasks 1–5) in ShareVerify first, then Part 2 (Tasks 6–15) in share_verify.

Which approach?
