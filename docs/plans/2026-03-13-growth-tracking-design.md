# Growth Tracking Design

> **Goal:** Chart-first growth tracking with WHO percentile curves, locale-aware unit display, and Swift Charts visualization.

## Decisions

- WHO only (0-24 months) -- CDC deferred until 2+ year age range is needed
- Locale-based units (metric/imperial) -- no manual toggle, follows device setting
- Growth card on BabyScreen -- same level as Nap/Feeding/Diaper
- Add GrowthRecordModel to SchemaV4 directly -- pre-launch, no migration needed
- Single ViewModel + pure chart service -- matches existing patterns

## Data Model

```swift
struct GrowthRecord: Identifiable, Codable, Sendable, Equatable {
    var id: UUID
    var babyId: UUID
    var date: Date
    var weightGrams: Double?
    var lengthCm: Double?
    var headCircumferenceCm: Double?
    var notes: String?
    var createdAt: Date
    var updatedAt: Date
    var isDeleted: Bool
}
```

Stored in metric internally. Display formatted via `Locale.current.measurementSystem`:
- `.metric`: kg, cm
- `.us` / `.uk`: lbs/oz, inches

## WHO Data

6 bundled JSON files in `MomCare/Core/Content/WHO/`:
- `weight_boys.json`, `weight_girls.json`
- `length_boys.json`, `length_girls.json`
- `head_boys.json`, `head_girls.json`

Each file: array of monthly data points (0-24 months) with percentiles 3, 15, 50, 85, 97.

```json
[
  { "month": 0, "p3": 2500, "p15": 2900, "p50": 3300, "p85": 3700, "p97": 4200 },
  { "month": 1, "p3": 3200, "p15": 3600, "p50": 4200, "p85": 4800, "p97": 5400 }
]
```

## Architecture

```
GrowthScreen -> GrowthViewModel -> GrowthRepository -> SwiftData
                    |
             GrowthChartService (pure struct, loads WHO JSON, calculates percentiles)
```

### GrowthChartService

Pure struct, no state. Methods:
- `loadStandard(measurement:sex:) -> [WHODataPoint]` -- loads from bundle
- `percentile(value:ageMonths:standard:) -> Double?` -- interpolates baby's percentile
- `chartData(records:standard:measurement:) -> GrowthChartData` -- returns chart-ready arrays

### GrowthRepositoryProtocol

```swift
protocol GrowthRepositoryProtocol: Repository where Entity == GrowthRecord {
    func getRecordsForBaby(_ babyId: UUID, limit: Int?) async throws -> [GrowthRecord]
    func getRecordsForDateRange(babyId: UUID, start: Date, end: Date) async throws -> [GrowthRecord]
}
```

### GrowthViewModel

`@Observable @MainActor` -- holds records, selected measurement type, chart data. Delegates to GrowthChartService for percentile calculations and chart data generation.

## Views

### GrowthScreen (chart-first)

- Segmented picker: Weight / Length / Head Circumference
- Swift Charts `Chart`:
  - `AreaMark` for percentile bands (3-97 light fill, 15-85 medium fill)
  - `LineMark` for 50th percentile (dashed)
  - `PointMark` + `LineMark` for baby's measurements (accent color)
- "Add Measurement" button opens sheet
- Measurement history list below chart (sorted by date descending)
- Empty state with illustration when no records

### AddMeasurementView (sheet)

- Date picker (default today, max today)
- Weight field (label shows kg or lbs based on locale)
- Length field (cm or in based on locale)
- Head circumference field (cm or in)
- Notes (optional text field)
- Save button -- at least one measurement required
- Input in display units, converted to metric for storage

## Navigation

- `BabyRoute.growth` case added to navigation enum
- Growth card in `BabyCardGrid` on `BabyScreen`
- `GrowthViewModel` created in `MomCareApp.swift`, passed to `BabyScreen`

## Files

```
Create: MomCare/Domain/Entities/GrowthRecord.swift
Create: MomCare/Domain/Repositories/GrowthRepositoryProtocol.swift
Create: MomCare/Domain/Services/GrowthChartService.swift
Create: MomCare/Data/SwiftData/GrowthRecordModel.swift
Create: MomCare/Data/Repositories/GrowthRepository.swift
Create: MomCare/Features/Growth/ViewModels/GrowthViewModel.swift
Create: MomCare/Features/Growth/Views/GrowthScreen.swift
Create: MomCare/Features/Growth/Views/AddMeasurementView.swift
Create: MomCare/Core/Content/WHO/*.json (6 files)
Modify: MomCare/Data/SwiftData/Schema/SchemaV4.swift (add GrowthRecordModel)
Modify: MomCare/Core/DI/Dependencies.swift (add makeGrowthRepository)
Modify: MomCare/Features/Baby/Views/BabyScreen.swift (add Growth card)
Modify: MomCare/App/MomCareApp.swift (create GrowthViewModel)
Create: MomCareTests/Features/Growth/GrowthChartServiceTests.swift
Create: MomCareTests/Features/Growth/GrowthViewModelTests.swift
Create: MomCareTests/Domain/GrowthRecordTests.swift
```

## Testing

- **GrowthChartServiceTests** -- WHO data loading, percentile calculation accuracy, interpolation edge cases, missing data handling
- **GrowthViewModelTests** -- CRUD, measurement type switching, chart data updates, empty state
- **GrowthRecordTests** -- entity creation, locale formatting, fixture helpers

## Accessibility

- Chart: `.accessibilityLabel` with current percentile description
- VoiceOver: chart summary ("Weight at 50th percentile, 5.2 kg at 2 months")
- Dynamic Type support on axis labels and form fields
- 44pt+ tap targets on all interactive elements
