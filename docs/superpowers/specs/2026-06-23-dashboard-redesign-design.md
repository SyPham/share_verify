# Dashboard Redesign — Design Spec

**Date:** 2026-06-23  
**Status:** Approved  
**Repos:** `share_verify` (Flutter), `ShareVerify` (.NET API)

## Summary

Redesign the mobile dashboard to show four tappable KPI cards with drill-down navigation. Remove the completion ring, total shareholders card, recent activity section, and KPI progress bars. Extend backend APIs to support filtered shareholder lists, person-grouped recipient lists, warning counts, and multi-check-in recipient details.

## Decisions Log

| Question | Decision |
|----------|----------|
| Card 1 vs Card 4 count | Same number (`receivedCount` = shareholders who checked in); differ only in navigation |
| "Chưa nhận hỗ trợ" tap | Opens list of shareholders not yet checked in |
| Recipient list grouping | Group by person (CCCD/CMND/Passport) — one row per person |
| KPI progress bars | Remove all progress bars from dashboard cards |
| Multi-check-in recipient detail | One block per shareholder: MCD info + evidence photo + check-in time |
| Approach | Extend existing APIs with query params (Approach 1) |

## Dashboard Layout

```
┌─────────────────────┬─────────────────────┐
│  Đã nhận hỗ trợ     │  Chưa nhận hỗ trợ   │
│  {receivedCount}    │  {notReceivedCount} │
├─────────────────────┼─────────────────────┤
│  ⚠ Cảnh báo         │  Cổ đông đã check-in│
│  {warningCount}     │  {receivedCount}    │
└─────────────────────┴─────────────────────┘
```

### Removed from dashboard

- `ProgressRingSection` (tiến độ chi trả)
- "Tổng số cổ đông" card
- "Hoạt động gần đây" section + link to recipients
- Linear progress bars on `SvKpiCard`

### Card behavior

| Card | Count | Tap navigation |
|------|-------|----------------|
| Đã nhận hỗ trợ | `receivedCount` | `ReceivedSupportScreen` (2 tabs) |
| Chưa nhận hỗ trợ | `notReceivedCount` | `ShareholdersListScreen(received: false)` |
| Cảnh báo | `warningCount` | `WarningRecipientsScreen` |
| Cổ đông đã check-in | `receivedCount` | `ShareholdersListScreen(received: true)` |

`warningCount` = number of unique persons (grouped by CCCD/CMND/Passport) who checked in for ≥2 shareholders.

## Navigation Flow

```
Dashboard
├── Đã nhận hỗ trợ → ReceivedSupportScreen
│   ├── Tab: Theo cổ đông → ShareholdersListScreen(received: true)
│   │   └── item → ShareholderDetailScreen
│   └── Tab: Theo người nhận → RecipientsListScreen(groupByPerson: true)
│       └── item → RecipientDetailScreen
├── Chưa nhận hỗ trợ → ShareholdersListScreen(received: false)
│   └── item → ShareholderDetailScreen (info only, no evidence)
├── Cảnh báo → WarningRecipientsScreen (minLinkedMcd: 2)
│   └── item → RecipientDetailScreen
└── Cổ đông đã check-in → ShareholdersListScreen(received: true)
    └── item → ShareholderDetailScreen
```

## Screen Specifications

### ShareholdersListScreen

- **Route:** `/shareholders` with args `{ received: bool }`
- **Title:** "Cổ đông đã check-in" or "Cổ đông chưa check-in"
- **List tile:** MCD, full name, total shares, receive time (if received)
- **Search:** MCD, name, registration number (optional keyword)
- **Pagination:** 20 per page, infinite scroll, pull-to-refresh

### ShareholderDetailScreen

- **Route:** `/shareholders/detail` with args `mcd`
- **API:** `GET /api/shareholders/{mcd}`
- **When checked in:** shareholder info + recipient info + evidence photo + check-in time
- **When not checked in:** shareholder info only (no evidence block)
- Reuse `SvResultInfoRow`, `EvidencePhotoPreview`

### ReceivedSupportScreen

- **Route:** `/dashboard/received`
- **Tab 1 "Theo cổ đông":** embeds or navigates to shareholder list (received=true)
- **Tab 2 "Theo người nhận":** recipient list with `groupBy=person`

### WarningRecipientsScreen

- **Route:** `/dashboard/warnings`
- Same layout as recipient list with `minLinkedMcd=2`
- List tile shows badge "N MCD" when linkedMcdCount > 1

### RecipientDetailScreen (extended)

- **Route:** `/recipients/detail` with args `personId`
- **Header:** person name, identity type, identity number
- **Body:** one block per check-in (sorted by receiveTime desc):
  - Shareholder MCD + full name + total shares
  - Recipient role info (direct/proxy)
  - Evidence photo
  - Check-in timestamp

## API Changes (ShareVerify backend)

### 1. Dashboard Summary — extended

```
GET /api/dashboard/summary
```

```json
{
  "receivedCount": 1234,
  "notReceivedCount": 567,
  "warningCount": 42,
  "totalShareholders": 1801,
  "completionRate": 68.52
}
```

- Add `warningCount`: count of `PersonId` values with ≥2 distinct `Mcd` in `TravelSupports`
- Keep `totalShareholders` and `completionRate` for backward compatibility; Flutter dashboard ignores them

### 2. Shareholder List — new endpoint

```
GET /api/shareholders/list?received={true|false}&keyword=&page=1&pageSize=20
```

| Param | Required | Description |
|-------|----------|-------------|
| `received` | yes | `true` = checked in, `false` = not checked in |
| `keyword` | no | Filter by MCD, name, registration number |
| `page`, `pageSize` | no | Pagination (default 1, 20; max pageSize 100) |

- Join `Shareholders` ↔ `TravelSupports` on `Mcd` (direct join, not via PersonShareholders)
- `received=true` → `WHERE TravelSupport exists for Mcd`
- `received=false` → `WHERE no TravelSupport for Mcd`
- Empty keyword → return all matching records (paginated)
- Response: reuse `PagedResultDto<ShareholderSearchDto>`

Existing `GET /api/shareholders/search` (keyword required) unchanged for autocomplete/picker.

### 3. Recipients Search — extended

```
GET /api/recipients?keyword=&groupBy=person&minLinkedMcd=2&page=1&pageSize=20
```

| Param | Description |
|-------|-------------|
| `groupBy=person` | One row per PersonId; `linkedMcdCount` = distinct Mcd count; `receiveTime` = latest |
| `minLinkedMcd` | Filter persons with ≥ N linked MCDs (use `2` for warnings) |
| `keyword` | Optional search filter |

Without `groupBy` → existing per-check-in behavior preserved.

### 4. Recipient Detail — extended

```
GET /api/recipients/{personId}
```

New response shape:

```json
{
  "personId": 42,
  "personFullName": "Nguyễn Văn A",
  "identityNo": "001234567890",
  "identityType": "CCCD",
  "checkIns": [
    {
      "mcd": "MCD001",
      "shareholderFullName": "Nguyễn Văn A",
      "totalShares": 1000,
      "travelSupport": {
        "receiverName": "Nguyễn Văn A",
        "receiverIdentityNo": "001234567890",
        "identityType": "CCCD",
        "attendanceType": "Direct",
        "receiveAmount": 500000,
        "receiveTime": "2026-06-20T08:30:00Z",
        "photoPath": "/uploads/...",
        "operatorName": "NV01"
      }
    }
  ]
}
```

- `checkIns` = all `TravelSupport` records for `personId`, ordered by `ReceiveTime` descending
- Replaces single `travelSupport` + `linkedShareholders` fields

### 5. Shareholder Detail — unchanged

```
GET /api/shareholders/{mcd}
```

Sufficient for checked-in shareholder detail. Not-checked-in shareholders return `allowanceReceived: false`, `travelSupport: null`.

## Flutter Changes (share_verify)

### Models

```dart
class DashboardStats {
  final int receivedCount;
  final int notReceivedCount;
  final int warningCount;
}

class RecipientDetail {
  final int personId;
  final String personFullName;
  final String? identityNo;
  final String? identityType;
  final List<RecipientCheckIn> checkIns;
}

class RecipientCheckIn {
  final String mcd;
  final String shareholderFullName;
  final num totalShares;
  final TravelSupportInfo travelSupport;
}
```

### New files

| File | Purpose |
|------|---------|
| `screens/dashboard/received_support_screen.dart` | 2-tab received support view |
| `screens/shareholders/shareholders_list_screen.dart` | Paginated shareholder list |
| `screens/shareholders/shareholder_detail_screen.dart` | Shareholder detail |
| `screens/dashboard/warning_recipients_screen.dart` | Warning recipient list |
| `screens/shareholders/components/shareholder_list_tile.dart` | List tile widget |
| `screens/shareholders/components/shareholder_detail_body.dart` | Detail body widget |
| Controllers + bindings for each new screen | GetX state management |

### Modified files

| File | Change |
|------|--------|
| `dashboard_screen.dart` | 4-card grid, remove old sections |
| `dashboard_controller.dart` | Add warningCount, remove recent activity |
| `dashboard_stats.dart`, DTOs, mapper | Add warningCount |
| `sv_kpi_card.dart` | Make progress optional (hidden by default) |
| `recipient_repository.dart` | Add groupByPerson, minLinkedMcd params |
| `shareholder_repository.dart` | Add listShareholders method |
| `recipient_detail_body.dart` | Multi-block check-in layout |
| `recipient_dtos.dart`, mappers, models | New RecipientDetail shape |
| `route.dart` | Register new routes |

### Removed / deprecated

- `recent_activity_list.dart`
- `progress_ring_section.dart` (if unused elsewhere)
- `ActivityItem` model, `getRecentActivity()` in dashboard repository
- `dashboard_format.dart` (if no remaining references)

## Error Handling

- All list screens: loading spinner, error message with retry, empty state message
- Pull-to-refresh retries failed loads
- Detail screens: "Thử lại" button on error (existing `RecipientDetailScreen` pattern)
- Missing evidence photo: `EvidencePhotoPreview` placeholder (existing behavior)

## Testing

### Backend (`ShareVerify.Tests`)

- `DashboardService`: warningCount with 0, 1, 2+ MCD per person
- `ShareholderRepository.ListAsync`: received=true/false, keyword filter, pagination
- `RecipientRepository.SearchAsync`: groupBy=person, minLinkedMcd=2
- `RecipientRepository.GetDetailAsync`: returns all check-ins ordered by time

### Flutter (`share_verify/test`)

- `dashboard_controller_test`: warningCount parsing, no recent activity fetch
- Widget: dashboard renders 4 cards, no progress ring
- `recipient_detail_body_test`: multiple check-in blocks
- Update `fake_repositories` for new API signatures

## Out of Scope

- Web admin dashboard changes
- Excel export changes
- Changes to verification/check-in flow
- Redesign of settings or other tabs
