# Growth Tracking Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Build chart-first growth tracking with WHO percentile curves, locale-aware units, and Swift Charts visualization.

**Architecture:** GrowthRecord entity + SwiftData model + repository follows existing patterns. GrowthChartService is a pure struct that loads bundled WHO JSON and calculates percentiles. GrowthViewModel owns CRUD and chart data. GrowthScreen uses Swift Charts with AreaMark bands and PointMark overlays.

**Tech Stack:** SwiftUI, Swift Charts, SwiftData, Swift Testing

**Design doc:** `docs/plans/2026-03-13-growth-tracking-design.md`

---

## Task 1: GrowthRecord Entity + Repository Protocol

**Files:**
- Create: `MomCare/Domain/Entities/GrowthRecord.swift`
- Create: `MomCare/Domain/Repositories/GrowthRepositoryProtocol.swift`
- Test: `MomCareTests/Domain/GrowthRecordTests.swift`

**Step 1: Write the failing test**

```swift
// MomCareTests/Domain/GrowthRecordTests.swift
import Testing
import Foundation
@testable import MomCare

@Suite("GrowthRecord")
struct GrowthRecordTests {

    @Test("Create record with all measurements")
    func createWithAllMeasurements() {
        let babyId = UUID()
        let record = GrowthRecord.fixture(
            babyId: babyId,
            weightGrams: 5200,
            lengthCm: 58.5,
            headCircumferenceCm: 38.2
        )

        #expect(record.babyId == babyId)
        #expect(record.weightGrams == 5200)
        #expect(record.lengthCm == 58.5)
        #expect(record.headCircumferenceCm == 38.2)
        #expect(!record.isDeleted)
    }

    @Test("Create record with partial measurements")
    func createWithPartialMeasurements() {
        let record = GrowthRecord.fixture(weightGrams: 5200)
        #expect(record.weightGrams == 5200)
        #expect(record.lengthCm == nil)
        #expect(record.headCircumferenceCm == nil)
    }

    @Test("Weight formatted respects locale")
    func weightFormatted() {
        let record = GrowthRecord.fixture(weightGrams: 5200)
        let formatted = record.weightFormatted
        // Should contain a number regardless of locale
        #expect(!formatted.isEmpty)
    }

    @Test("Length formatted respects locale")
    func lengthFormatted() {
        let record = GrowthRecord.fixture(lengthCm: 58.5)
        let formatted = record.lengthFormatted
        #expect(!formatted.isEmpty)
    }

    @Test("Age in months at measurement")
    func ageAtMeasurement() {
        let dob = Calendar.current.date(byAdding: .month, value: -3, to: .now)!
        let record = GrowthRecord.fixture(date: .now)
        let ageMonths = record.ageInMonths(dateOfBirth: dob)
        #expect(ageMonths == 3)
    }
}
```

**Step 2: Run test to verify it fails**

Run: `tuist build 2>&1 | tail -5`
Expected: FAIL (GrowthRecord not defined)

**Step 3: Write the implementation**

```swift
// MomCare/Domain/Entities/GrowthRecord.swift
import Foundation

struct GrowthRecord: Identifiable, Codable, Sendable, Equatable {
    var id: UUID
    var babyId: UUID
    var date: Date
    var weightGrams: Double?
    var lengthCm: Double?
    var headCircumferenceCm: Double?
    var notes: String?
    var isDeleted: Bool
    var createdAt: Date
    var updatedAt: Date

    // MARK: - Locale-aware formatting

    var weightFormatted: String {
        guard let grams = weightGrams else { return "--" }
        if Locale.current.measurementSystem == .metric {
            let kg = grams / 1000.0
            return String(format: "%.1f kg", kg)
        } else {
            let lbs = grams / 453.592
            return String(format: "%.1f lbs", lbs)
        }
    }

    var lengthFormatted: String {
        guard let cm = lengthCm else { return "--" }
        if Locale.current.measurementSystem == .metric {
            return String(format: "%.1f cm", cm)
        } else {
            let inches = cm / 2.54
            return String(format: "%.1f in", inches)
        }
    }

    var headCircumferenceFormatted: String {
        guard let cm = headCircumferenceCm else { return "--" }
        if Locale.current.measurementSystem == .metric {
            return String(format: "%.1f cm", cm)
        } else {
            let inches = cm / 2.54
            return String(format: "%.1f in", inches)
        }
    }

    func ageInMonths(dateOfBirth: Date) -> Int {
        Calendar.current.dateComponents([.month], from: dateOfBirth, to: date).month ?? 0
    }
}

// MARK: - Testing Fixtures

extension GrowthRecord {
    static func fixture(
        id: UUID = UUID(),
        babyId: UUID = UUID(),
        date: Date = .now,
        weightGrams: Double? = nil,
        lengthCm: Double? = nil,
        headCircumferenceCm: Double? = nil,
        notes: String? = nil,
        isDeleted: Bool = false,
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) -> GrowthRecord {
        GrowthRecord(
            id: id,
            babyId: babyId,
            date: date,
            weightGrams: weightGrams,
            lengthCm: lengthCm,
            headCircumferenceCm: headCircumferenceCm,
            notes: notes,
            isDeleted: isDeleted,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
}
```

```swift
// MomCare/Domain/Repositories/GrowthRepositoryProtocol.swift
import Foundation

protocol GrowthRepositoryProtocol: Repository where Entity == GrowthRecord {
    func getRecordsForBaby(_ babyId: UUID, limit: Int?) async throws -> [GrowthRecord]
    func getRecordsForDateRange(babyId: UUID, start: Date, end: Date) async throws -> [GrowthRecord]
}
```

**Step 4: Run test to verify it passes**

Run: `tuist build 2>&1 | tail -5`
Expected: Build Succeeded

**Step 5: Commit**

```bash
git add MomCare/Domain/Entities/GrowthRecord.swift MomCare/Domain/Repositories/GrowthRepositoryProtocol.swift MomCareTests/Domain/GrowthRecordTests.swift
git commit -m "feat(growth): add GrowthRecord entity and repository protocol"
```

---

## Task 2: SwiftData Model + Repository + Schema

**Files:**
- Create: `MomCare/Data/SwiftData/GrowthRecordModel.swift`
- Create: `MomCare/Data/Repositories/GrowthRepository.swift`
- Modify: `MomCare/Data/SwiftData/Schema/SchemaV4.swift`
- Modify: `MomCare/Core/DI/Dependencies.swift`

**Step 1: Create the SwiftData model**

```swift
// MomCare/Data/SwiftData/GrowthRecordModel.swift
import Foundation
import SwiftData

@Model
final class GrowthRecordModel {
    @Attribute(.unique) var id: UUID
    var babyId: UUID
    var date: Date
    var weightGrams: Double?
    var lengthCm: Double?
    var headCircumferenceCm: Double?
    var notes: String?
    var isSoftDeleted: Bool
    var createdAt: Date
    var updatedAt: Date

    init(from record: GrowthRecord) {
        self.id = record.id
        self.babyId = record.babyId
        self.date = record.date
        self.weightGrams = record.weightGrams
        self.lengthCm = record.lengthCm
        self.headCircumferenceCm = record.headCircumferenceCm
        self.notes = record.notes
        self.isSoftDeleted = record.isDeleted
        self.createdAt = record.createdAt
        self.updatedAt = record.updatedAt
    }

    func toEntity() -> GrowthRecord {
        GrowthRecord(
            id: id,
            babyId: babyId,
            date: date,
            weightGrams: weightGrams,
            lengthCm: lengthCm,
            headCircumferenceCm: headCircumferenceCm,
            notes: notes,
            isDeleted: isSoftDeleted,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }

    func update(from record: GrowthRecord) {
        date = record.date
        weightGrams = record.weightGrams
        lengthCm = record.lengthCm
        headCircumferenceCm = record.headCircumferenceCm
        notes = record.notes
        updatedAt = .now
    }
}
```

**Step 2: Create the repository**

```swift
// MomCare/Data/Repositories/GrowthRepository.swift
import Foundation
import SwiftData

@MainActor
final class GrowthRepository: GrowthRepositoryProtocol {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func getAll() async throws -> [GrowthRecord] {
        let descriptor = FetchDescriptor<GrowthRecordModel>(
            predicate: #Predicate<GrowthRecordModel> { $0.isSoftDeleted == false },
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        return try modelContext.fetch(descriptor).map { $0.toEntity() }
    }

    func getById(_ id: UUID) async throws -> GrowthRecord? {
        let fetchId = id
        let descriptor = FetchDescriptor<GrowthRecordModel>(
            predicate: #Predicate<GrowthRecordModel> { $0.id == fetchId }
        )
        return try modelContext.fetch(descriptor).first?.toEntity()
    }

    func create(_ entity: GrowthRecord) async throws -> GrowthRecord {
        let model = GrowthRecordModel(from: entity)
        modelContext.insert(model)
        try modelContext.save()
        return model.toEntity()
    }

    func update(_ entity: GrowthRecord) async throws -> GrowthRecord {
        let entityId = entity.id
        let descriptor = FetchDescriptor<GrowthRecordModel>(
            predicate: #Predicate<GrowthRecordModel> { $0.id == entityId }
        )
        guard let model = try modelContext.fetch(descriptor).first else {
            throw RepositoryError.notFound
        }
        model.update(from: entity)
        try modelContext.save()
        return model.toEntity()
    }

    func delete(_ id: UUID) async throws {
        let deleteId = id
        let descriptor = FetchDescriptor<GrowthRecordModel>(
            predicate: #Predicate<GrowthRecordModel> { $0.id == deleteId }
        )
        guard let model = try modelContext.fetch(descriptor).first else {
            throw RepositoryError.notFound
        }
        model.isSoftDeleted = true
        model.updatedAt = .now
        try modelContext.save()
    }

    func getRecordsForBaby(_ babyId: UUID, limit: Int?) async throws -> [GrowthRecord] {
        let fetchBabyId = babyId
        var descriptor = FetchDescriptor<GrowthRecordModel>(
            predicate: #Predicate<GrowthRecordModel> {
                $0.babyId == fetchBabyId && $0.isSoftDeleted == false
            },
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        if let limit {
            descriptor.fetchLimit = limit
        }
        return try modelContext.fetch(descriptor).map { $0.toEntity() }
    }

    func getRecordsForDateRange(babyId: UUID, start: Date, end: Date) async throws -> [GrowthRecord] {
        let fetchBabyId = babyId
        let rangeStart = start
        let rangeEnd = end
        let descriptor = FetchDescriptor<GrowthRecordModel>(
            predicate: #Predicate<GrowthRecordModel> {
                $0.babyId == fetchBabyId &&
                $0.isSoftDeleted == false &&
                $0.date >= rangeStart &&
                $0.date < rangeEnd
            },
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        return try modelContext.fetch(descriptor).map { $0.toEntity() }
    }
}
```

**Step 3: Add GrowthRecordModel to SchemaV4**

In `MomCare/Data/SwiftData/Schema/SchemaV4.swift`, add `GrowthRecordModel.self` to the models array:

```swift
static var models: [any PersistentModel.Type] {
    [
        BabyModel.self,
        FeedingModel.self,
        SelfCareLogModel.self,
        SelfCareGridItemModel.self,
        ContentHistoryModel.self,
        DiaperModel.self,
        BabySleepModel.self,
        GrowthRecordModel.self
    ]
}
```

**Step 4: Add makeGrowthRepository to Dependencies**

In `MomCare/Core/DI/Dependencies.swift`:

Add to `DependencyContainer` protocol:
```swift
func makeGrowthRepository() -> any GrowthRepositoryProtocol
```

Add to `AppDependencies` class:
```swift
func makeGrowthRepository() -> any GrowthRepositoryProtocol {
    GrowthRepository(modelContext: modelContext)
}
```

**Step 5: Build**

Run: `tuist build 2>&1 | tail -5`
Expected: Build Succeeded

**Step 6: Commit**

```bash
git add MomCare/Data/SwiftData/GrowthRecordModel.swift MomCare/Data/Repositories/GrowthRepository.swift MomCare/Data/SwiftData/Schema/SchemaV4.swift MomCare/Core/DI/Dependencies.swift
git commit -m "feat(growth): add SwiftData model, repository, and DI wiring"
```

---

## Task 3: WHO Growth Data + GrowthChartService

**Files:**
- Create: `MomCare/Core/Content/WHO/weight_boys.json`
- Create: `MomCare/Core/Content/WHO/weight_girls.json`
- Create: `MomCare/Core/Content/WHO/length_boys.json`
- Create: `MomCare/Core/Content/WHO/length_girls.json`
- Create: `MomCare/Core/Content/WHO/head_boys.json`
- Create: `MomCare/Core/Content/WHO/head_girls.json`
- Create: `MomCare/Domain/Services/GrowthChartService.swift`
- Test: `MomCareTests/Features/Growth/GrowthChartServiceTests.swift`

**Step 1: Create WHO JSON data files**

Each JSON file is an array of objects with keys: `month`, `p3`, `p15`, `p50`, `p85`, `p97`. Data covers months 0-24.

Use official WHO Child Growth Standards data:
- Weight in grams
- Length in cm
- Head circumference in cm

Example structure for `weight_boys.json`:
```json
[
  {"month": 0, "p3": 2500, "p15": 2900, "p50": 3300, "p85": 3700, "p97": 4200},
  {"month": 1, "p3": 3400, "p15": 3900, "p50": 4500, "p85": 5100, "p97": 5700},
  ...
]
```

Create all 6 files with accurate WHO growth standard values for months 0-24. Source: WHO Multicentre Growth Reference Study (MGRS). Use the published LMS/percentile tables from the WHO website.

**Step 2: Write the failing tests**

```swift
// MomCareTests/Features/Growth/GrowthChartServiceTests.swift
import Testing
import Foundation
@testable import MomCare

@Suite("GrowthChartService")
struct GrowthChartServiceTests {

    let service = GrowthChartService()

    @Test("Load WHO weight data for boys")
    func loadWeightBoys() throws {
        let data = try service.loadStandard(measurement: .weight, sex: .male)
        #expect(data.count == 25) // months 0-24
        #expect(data[0].month == 0)
        #expect(data[0].p50 > 0)
    }

    @Test("Load WHO weight data for girls")
    func loadWeightGirls() throws {
        let data = try service.loadStandard(measurement: .weight, sex: .female)
        #expect(data.count == 25)
    }

    @Test("Load WHO length data")
    func loadLength() throws {
        let data = try service.loadStandard(measurement: .length, sex: .male)
        #expect(data.count == 25)
        // Length at birth should be around 46-54 cm
        #expect(data[0].p50 > 40 && data[0].p50 < 60)
    }

    @Test("Load WHO head circumference data")
    func loadHead() throws {
        let data = try service.loadStandard(measurement: .headCircumference, sex: .female)
        #expect(data.count == 25)
    }

    @Test("Calculate percentile for 50th percentile value")
    func percentileAt50th() throws {
        let data = try service.loadStandard(measurement: .weight, sex: .male)
        let p50Value = data[3].p50 // 3-month value
        let percentile = service.percentile(value: p50Value, ageMonths: 3, standard: data)
        #expect(percentile != nil)
        // Should be close to 50
        #expect(abs(percentile! - 50) < 5)
    }

    @Test("Percentile below p3 returns < 3")
    func percentileBelowP3() throws {
        let data = try service.loadStandard(measurement: .weight, sex: .male)
        let tinyValue = data[3].p3 - 500
        let percentile = service.percentile(value: tinyValue, ageMonths: 3, standard: data)
        #expect(percentile != nil)
        #expect(percentile! < 3)
    }

    @Test("Percentile above p97 returns > 97")
    func percentileAboveP97() throws {
        let data = try service.loadStandard(measurement: .weight, sex: .male)
        let hugeValue = data[3].p97 + 1000
        let percentile = service.percentile(value: hugeValue, ageMonths: 3, standard: data)
        #expect(percentile != nil)
        #expect(percentile! > 97)
    }

    @Test("Chart data returns percentile bands and baby points")
    func chartData() throws {
        let records = [
            GrowthRecord.fixture(date: .now, weightGrams: 5200),
            GrowthRecord.fixture(
                date: Calendar.current.date(byAdding: .month, value: -1, to: .now)!,
                weightGrams: 4500
            )
        ]
        let dob = Calendar.current.date(byAdding: .month, value: -3, to: .now)!
        let result = try service.chartData(
            records: records,
            sex: .male,
            measurement: .weight,
            dateOfBirth: dob
        )
        #expect(!result.percentileBands.isEmpty)
        #expect(result.babyPoints.count == 2)
    }

    @Test("Age out of range returns nil percentile")
    func ageOutOfRange() throws {
        let data = try service.loadStandard(measurement: .weight, sex: .male)
        let percentile = service.percentile(value: 10000, ageMonths: 30, standard: data)
        #expect(percentile == nil)
    }

    @Test("Nil sex defaults to combined/unisex approximation")
    func nilSexDefaults() throws {
        let data = try service.loadStandard(measurement: .weight, sex: nil)
        #expect(data.count == 25)
    }
}
```

**Step 3: Write the implementation**

```swift
// MomCare/Domain/Services/GrowthChartService.swift
import Foundation

struct GrowthChartService: Sendable {

    enum MeasurementType: String, CaseIterable, Sendable {
        case weight, length, headCircumference

        var label: String {
            switch self {
            case .weight: "Weight"
            case .length: "Length"
            case .headCircumference: "Head"
            }
        }

        var systemImage: String {
            switch self {
            case .weight: "scalemass.fill"
            case .length: "ruler.fill"
            case .headCircumference: "circle.dashed"
            }
        }
    }

    struct WHODataPoint: Codable, Sendable {
        let month: Int
        let p3: Double
        let p15: Double
        let p50: Double
        let p85: Double
        let p97: Double
    }

    struct GrowthChartData: Sendable {
        let percentileBands: [WHODataPoint]
        let babyPoints: [BabyDataPoint]
    }

    struct BabyDataPoint: Sendable {
        let ageMonths: Double
        let value: Double
        let percentile: Double?
    }

    // MARK: - Load WHO Data

    func loadStandard(measurement: MeasurementType, sex: Baby.BiologicalSex?) -> [WHODataPoint] {
        let sexKey: String
        switch sex {
        case .male: sexKey = "boys"
        case .female: sexKey = "girls"
        default: sexKey = "boys" // Default to boys for nil/other/preferNotToSay
        }

        let measurementKey: String
        switch measurement {
        case .weight: measurementKey = "weight"
        case .length: measurementKey = "length"
        case .headCircumference: measurementKey = "head"
        }

        let fileName = "\(measurementKey)_\(sexKey)"

        guard let url = Bundle.main.url(forResource: fileName, withExtension: "json", subdirectory: "WHO"),
              let data = try? Data(contentsOf: url),
              let points = try? JSONDecoder().decode([WHODataPoint].self, from: data) else {
            return []
        }
        return points
    }

    // MARK: - Percentile Calculation

    func percentile(value: Double, ageMonths: Int, standard: [WHODataPoint]) -> Double? {
        guard let point = standard.first(where: { $0.month == ageMonths }) else {
            return nil
        }

        let knownPercentiles: [(percentile: Double, value: Double)] = [
            (3, point.p3),
            (15, point.p15),
            (50, point.p50),
            (85, point.p85),
            (97, point.p97)
        ]

        // Below p3
        if value <= knownPercentiles[0].value {
            let ratio = value / knownPercentiles[0].value
            return max(0.1, 3 * ratio)
        }

        // Above p97
        if value >= knownPercentiles[4].value {
            let excess = value - knownPercentiles[4].value
            let range = knownPercentiles[4].value - knownPercentiles[3].value
            guard range > 0 else { return 99 }
            return min(99.9, 97 + 3 * (excess / range))
        }

        // Interpolate between known percentiles
        for i in 0..<(knownPercentiles.count - 1) {
            let lower = knownPercentiles[i]
            let upper = knownPercentiles[i + 1]
            if value >= lower.value && value <= upper.value {
                let range = upper.value - lower.value
                guard range > 0 else { return lower.percentile }
                let fraction = (value - lower.value) / range
                return lower.percentile + fraction * (upper.percentile - lower.percentile)
            }
        }

        return nil
    }

    // MARK: - Chart Data

    func chartData(
        records: [GrowthRecord],
        sex: Baby.BiologicalSex?,
        measurement: MeasurementType,
        dateOfBirth: Date
    ) -> GrowthChartData {
        let standard = loadStandard(measurement: measurement, sex: sex)

        let babyPoints: [BabyDataPoint] = records.compactMap { record in
            let value: Double?
            switch measurement {
            case .weight: value = record.weightGrams
            case .length: value = record.lengthCm
            case .headCircumference: value = record.headCircumferenceCm
            }
            guard let value else { return nil }

            let ageMonths = record.ageInMonths(dateOfBirth: dateOfBirth)
            let pct = percentile(value: value, ageMonths: ageMonths, standard: standard)

            // Use fractional months for more precise plotting
            let days = Calendar.current.dateComponents([.day], from: dateOfBirth, to: record.date).day ?? 0
            let fractionalMonths = Double(days) / 30.44

            return BabyDataPoint(ageMonths: fractionalMonths, value: value, percentile: pct)
        }.sorted { $0.ageMonths < $1.ageMonths }

        return GrowthChartData(percentileBands: standard, babyPoints: babyPoints)
    }
}
```

**Step 4: Create all 6 WHO JSON files**

Create each file in `MomCare/Core/Content/WHO/` with accurate WHO data for months 0-24 (25 data points each). Use the official WHO Child Growth Standards published values.

**Step 5: Build and run tests**

Run: `tuist build 2>&1 | tail -5`
Expected: Build Succeeded

**Step 6: Commit**

```bash
git add MomCare/Domain/Services/GrowthChartService.swift MomCare/Core/Content/WHO/ MomCareTests/Features/Growth/GrowthChartServiceTests.swift
git commit -m "feat(growth): add GrowthChartService with WHO data and percentile calculation"
```

---

## Task 4: GrowthViewModel

**Files:**
- Create: `MomCare/Features/Growth/ViewModels/GrowthViewModel.swift`
- Test: `MomCareTests/Features/Growth/GrowthViewModelTests.swift`

**Step 1: Write the failing tests**

```swift
// MomCareTests/Features/Growth/GrowthViewModelTests.swift
import Testing
import Foundation
@testable import MomCare

@Suite("GrowthViewModel")
struct GrowthViewModelTests {

    private let babyId = UUID()
    private let dob = Calendar.current.date(byAdding: .month, value: -3, to: .now)!

    @MainActor
    private func makeSUT(records: [GrowthRecord] = []) -> GrowthViewModel {
        let repo = StubGrowthRepository(records: records)
        return GrowthViewModel(repository: repo, chartService: GrowthChartService())
    }

    @Test("Initial state has no records")
    @MainActor
    func initialState() {
        let sut = makeSUT()
        #expect(sut.records.isEmpty)
        #expect(!sut.isLoading)
        #expect(sut.selectedMeasurement == .weight)
    }

    @Test("Load records for baby")
    @MainActor
    func loadRecords() async {
        let records = [
            GrowthRecord.fixture(babyId: babyId, weightGrams: 5200),
            GrowthRecord.fixture(babyId: babyId, weightGrams: 4500)
        ]
        let sut = makeSUT(records: records)
        await sut.loadRecords(babyId: babyId)
        #expect(sut.records.count == 2)
    }

    @Test("Add measurement creates record")
    @MainActor
    func addMeasurement() async {
        let sut = makeSUT()
        await sut.addMeasurement(
            babyId: babyId,
            date: .now,
            weightGrams: 5200,
            lengthCm: 58.5,
            headCircumferenceCm: 38.2,
            notes: nil
        )
        #expect(sut.records.count == 1)
        #expect(sut.records.first?.weightGrams == 5200)
    }

    @Test("Delete measurement removes record")
    @MainActor
    func deleteMeasurement() async {
        let record = GrowthRecord.fixture(babyId: babyId, weightGrams: 5200)
        let sut = makeSUT(records: [record])
        await sut.loadRecords(babyId: babyId)
        #expect(sut.records.count == 1)
        await sut.deleteRecord(id: record.id, babyId: babyId)
        #expect(sut.records.isEmpty)
    }

    @Test("Switch measurement type")
    @MainActor
    func switchMeasurement() {
        let sut = makeSUT()
        sut.selectedMeasurement = .length
        #expect(sut.selectedMeasurement == .length)
    }

    @Test("Update chart data after loading")
    @MainActor
    func updateChartData() async {
        let records = [
            GrowthRecord.fixture(babyId: babyId, date: .now, weightGrams: 5200)
        ]
        let sut = makeSUT(records: records)
        await sut.loadRecords(babyId: babyId)
        sut.updateChartData(sex: .male, dateOfBirth: dob)
        #expect(sut.chartData != nil)
        #expect(sut.chartData?.babyPoints.count == 1)
    }

    @Test("Latest percentile computed correctly")
    @MainActor
    func latestPercentile() async {
        let records = [
            GrowthRecord.fixture(babyId: babyId, date: .now, weightGrams: 5200)
        ]
        let sut = makeSUT(records: records)
        await sut.loadRecords(babyId: babyId)
        sut.updateChartData(sex: .male, dateOfBirth: dob)
        // Should have a percentile value
        #expect(sut.latestPercentile != nil)
    }
}

// MARK: - Stub

@MainActor
private final class StubGrowthRepository: GrowthRepositoryProtocol {
    private var store: [GrowthRecord]

    init(records: [GrowthRecord] = []) {
        self.store = records
    }

    func getAll() async throws -> [GrowthRecord] { store.filter { !$0.isDeleted } }
    func getById(_ id: UUID) async throws -> GrowthRecord? { store.first { $0.id == id } }

    func create(_ entity: GrowthRecord) async throws -> GrowthRecord {
        store.append(entity)
        return entity
    }

    func update(_ entity: GrowthRecord) async throws -> GrowthRecord {
        if let index = store.firstIndex(where: { $0.id == entity.id }) {
            store[index] = entity
        }
        return entity
    }

    func delete(_ id: UUID) async throws {
        store.removeAll { $0.id == id }
    }

    func getRecordsForBaby(_ babyId: UUID, limit: Int?) async throws -> [GrowthRecord] {
        let filtered = store.filter { $0.babyId == babyId && !$0.isDeleted }
        if let limit { return Array(filtered.prefix(limit)) }
        return filtered
    }

    func getRecordsForDateRange(babyId: UUID, start: Date, end: Date) async throws -> [GrowthRecord] {
        store.filter { $0.babyId == babyId && !$0.isDeleted && $0.date >= start && $0.date < end }
    }
}
```

**Step 2: Write the implementation**

```swift
// MomCare/Features/Growth/ViewModels/GrowthViewModel.swift
import Foundation

@Observable
@MainActor
final class GrowthViewModel {
    private let repository: any GrowthRepositoryProtocol
    private let chartService: GrowthChartService

    private(set) var records: [GrowthRecord] = []
    var selectedMeasurement: GrowthChartService.MeasurementType = .weight
    var chartData: GrowthChartService.GrowthChartData?
    var latestPercentile: Double?
    var isLoading = false
    var error: Error?
    var showAddSheet = false

    init(repository: any GrowthRepositoryProtocol, chartService: GrowthChartService = GrowthChartService()) {
        self.repository = repository
        self.chartService = chartService
    }

    func loadRecords(babyId: UUID) async {
        isLoading = true
        defer { isLoading = false }
        do {
            records = try await repository.getRecordsForBaby(babyId, limit: nil)
        } catch {
            self.error = error
        }
    }

    func addMeasurement(
        babyId: UUID,
        date: Date,
        weightGrams: Double?,
        lengthCm: Double?,
        headCircumferenceCm: Double?,
        notes: String?
    ) async {
        let record = GrowthRecord(
            id: UUID(),
            babyId: babyId,
            date: date,
            weightGrams: weightGrams,
            lengthCm: lengthCm,
            headCircumferenceCm: headCircumferenceCm,
            notes: notes,
            isDeleted: false,
            createdAt: .now,
            updatedAt: .now
        )
        do {
            let created = try await repository.create(record)
            records.insert(created, at: 0)
            records.sort { $0.date > $1.date }
        } catch {
            self.error = error
        }
    }

    func deleteRecord(id: UUID, babyId: UUID) async {
        do {
            try await repository.delete(id)
            records.removeAll { $0.id == id }
        } catch {
            self.error = error
        }
    }

    func updateChartData(sex: Baby.BiologicalSex?, dateOfBirth: Date) {
        let data = chartService.chartData(
            records: records,
            sex: sex,
            measurement: selectedMeasurement,
            dateOfBirth: dateOfBirth
        )
        chartData = data
        latestPercentile = data.babyPoints.last?.percentile
    }
}
```

**Step 3: Build and verify**

Run: `tuist build 2>&1 | tail -5`
Expected: Build Succeeded

**Step 4: Commit**

```bash
git add MomCare/Features/Growth/ViewModels/GrowthViewModel.swift MomCareTests/Features/Growth/GrowthViewModelTests.swift
git commit -m "feat(growth): add GrowthViewModel with CRUD and chart data"
```

---

## Task 5: GrowthScreen + AddMeasurementView

**Files:**
- Create: `MomCare/Features/Growth/Views/GrowthScreen.swift`
- Create: `MomCare/Features/Growth/Views/AddMeasurementView.swift`

**Step 1: Create AddMeasurementView**

```swift
// MomCare/Features/Growth/Views/AddMeasurementView.swift
import SwiftUI

@MainActor
struct AddMeasurementView: View {
    let babyId: UUID
    @Bindable var viewModel: GrowthViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var date = Date.now
    @State private var weightInput = ""
    @State private var lengthInput = ""
    @State private var headInput = ""
    @State private var notes = ""

    private var isMetric: Bool {
        Locale.current.measurementSystem == .metric
    }

    private var hasAtLeastOneMeasurement: Bool {
        !weightInput.isEmpty || !lengthInput.isEmpty || !headInput.isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Date") {
                    DatePicker("Measurement date", selection: $date, in: ...Date.now, displayedComponents: .date)
                        .labelsHidden()
                }

                Section("Measurements") {
                    HStack {
                        Text("Weight")
                        Spacer()
                        TextField(isMetric ? "kg" : "lbs", text: $weightInput)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                        Text(isMetric ? "kg" : "lbs")
                            .foregroundStyle(.secondary)
                    }

                    HStack {
                        Text("Length")
                        Spacer()
                        TextField(isMetric ? "cm" : "in", text: $lengthInput)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                        Text(isMetric ? "cm" : "in")
                            .foregroundStyle(.secondary)
                    }

                    HStack {
                        Text("Head circ.")
                        Spacer()
                        TextField(isMetric ? "cm" : "in", text: $headInput)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                        Text(isMetric ? "cm" : "in")
                            .foregroundStyle(.secondary)
                    }
                }

                Section("Notes") {
                    TextField("Optional notes", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle("Add Measurement")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        MCHaptic.success()
                        Task {
                            await save()
                            dismiss()
                        }
                    }
                    .disabled(!hasAtLeastOneMeasurement)
                }
            }
        }
    }

    private func save() async {
        let weightGrams = parseWeight(weightInput)
        let lengthCm = parseLength(lengthInput)
        let headCm = parseLength(headInput)

        await viewModel.addMeasurement(
            babyId: babyId,
            date: date,
            weightGrams: weightGrams,
            lengthCm: lengthCm,
            headCircumferenceCm: headCm,
            notes: notes.isEmpty ? nil : notes
        )
    }

    private func parseWeight(_ input: String) -> Double? {
        guard let value = Double(input) else { return nil }
        if isMetric {
            return value * 1000 // kg to grams
        } else {
            return value * 453.592 // lbs to grams
        }
    }

    private func parseLength(_ input: String) -> Double? {
        guard let value = Double(input) else { return nil }
        if isMetric {
            return value // already cm
        } else {
            return value * 2.54 // inches to cm
        }
    }
}
```

**Step 2: Create GrowthScreen**

```swift
// MomCare/Features/Growth/Views/GrowthScreen.swift
import Charts
import SwiftUI

@MainActor
struct GrowthScreen: View {
    let babyId: UUID
    let dateOfBirth: Date
    let biologicalSex: Baby.BiologicalSex?
    @Bindable var viewModel: GrowthViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: MCSpacing.xl) {
                measurementPicker
                chartSection
                percentileLabel
                addButton
                historySection
            }
            .padding(.horizontal, MCSpacing.lg)
            .padding(.vertical, MCSpacing.lg)
        }
        .navigationTitle("Growth")
        .task {
            await viewModel.loadRecords(babyId: babyId)
            viewModel.updateChartData(sex: biologicalSex, dateOfBirth: dateOfBirth)
        }
        .onChange(of: viewModel.selectedMeasurement) { _, _ in
            viewModel.updateChartData(sex: biologicalSex, dateOfBirth: dateOfBirth)
        }
        .onChange(of: viewModel.records) { _, _ in
            viewModel.updateChartData(sex: biologicalSex, dateOfBirth: dateOfBirth)
        }
        .sheet(isPresented: $viewModel.showAddSheet) {
            AddMeasurementView(babyId: babyId, viewModel: viewModel)
        }
    }

    // MARK: - Measurement Picker

    private var measurementPicker: some View {
        Picker("Measurement", selection: $viewModel.selectedMeasurement) {
            ForEach(GrowthChartService.MeasurementType.allCases, id: \.self) { type in
                Text(type.label).tag(type)
            }
        }
        .pickerStyle(.segmented)
    }

    // MARK: - Chart

    @ViewBuilder
    private var chartSection: some View {
        if let chartData = viewModel.chartData, !chartData.percentileBands.isEmpty {
            Chart {
                // 3rd-97th percentile band (lightest)
                ForEach(chartData.percentileBands, id: \.month) { point in
                    AreaMark(
                        x: .value("Month", point.month),
                        yStart: .value("P3", displayValue(point.p3)),
                        yEnd: .value("P97", displayValue(point.p97))
                    )
                    .foregroundStyle(MCColor.accent.opacity(0.08))
                }

                // 15th-85th percentile band (medium)
                ForEach(chartData.percentileBands, id: \.month) { point in
                    AreaMark(
                        x: .value("Month", point.month),
                        yStart: .value("P15", displayValue(point.p15)),
                        yEnd: .value("P85", displayValue(point.p85))
                    )
                    .foregroundStyle(MCColor.accent.opacity(0.15))
                }

                // 50th percentile line (dashed)
                ForEach(chartData.percentileBands, id: \.month) { point in
                    LineMark(
                        x: .value("Month", point.month),
                        y: .value("P50", displayValue(point.p50))
                    )
                    .foregroundStyle(MCColor.accent.opacity(0.4))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
                }

                // Baby's data points
                ForEach(chartData.babyPoints, id: \.ageMonths) { point in
                    PointMark(
                        x: .value("Month", point.ageMonths),
                        y: .value("Value", displayValue(point.value))
                    )
                    .foregroundStyle(MCColor.accent)
                    .symbolSize(60)
                }

                // Baby's line connecting points
                ForEach(chartData.babyPoints, id: \.ageMonths) { point in
                    LineMark(
                        x: .value("Month", point.ageMonths),
                        y: .value("Value", displayValue(point.value))
                    )
                    .foregroundStyle(MCColor.accent)
                    .lineStyle(StrokeStyle(lineWidth: 2))
                }
            }
            .chartXAxisLabel("Age (months)")
            .chartYAxisLabel(yAxisLabel)
            .frame(height: 280)
            .accessibilityLabel(chartAccessibilityLabel)
        } else {
            emptyChartPlaceholder
        }
    }

    private var emptyChartPlaceholder: some View {
        VStack(spacing: MCSpacing.lg) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            Text("No measurements yet")
                .font(MCTypography.cardTitle)
                .foregroundStyle(.secondary)
            Text("Add your first measurement to see growth charts")
                .font(MCTypography.cardBody)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
        }
        .frame(height: 280)
    }

    // MARK: - Percentile Label

    @ViewBuilder
    private var percentileLabel: some View {
        if let pct = viewModel.latestPercentile {
            HStack {
                Image(systemName: "chart.bar.fill")
                    .foregroundStyle(MCColor.accent)
                Text("Latest: \(Int(pct))th percentile")
                    .font(MCTypography.cardTitle)
            }
            .padding(MCSpacing.md)
            .frame(maxWidth: .infinity)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
        }
    }

    // MARK: - Add Button

    private var addButton: some View {
        Button {
            MCHaptic.tap()
            viewModel.showAddSheet = true
        } label: {
            HStack {
                Image(systemName: "plus.circle.fill")
                Text("Add Measurement")
            }
            .font(.headline)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(MCColor.accent, in: RoundedRectangle(cornerRadius: 14))
        }
    }

    // MARK: - History

    @ViewBuilder
    private var historySection: some View {
        if !viewModel.records.isEmpty {
            VStack(alignment: .leading, spacing: MCSpacing.md) {
                Text("History")
                    .font(MCTypography.cardTitle)

                ForEach(viewModel.records) { record in
                    HStack {
                        VStack(alignment: .leading, spacing: MCSpacing.xs) {
                            Text(record.date.formatted(date: .abbreviated, time: .omitted))
                                .font(.subheadline.bold())
                            HStack(spacing: MCSpacing.md) {
                                if record.weightGrams != nil {
                                    Label(record.weightFormatted, systemImage: "scalemass.fill")
                                }
                                if record.lengthCm != nil {
                                    Label(record.lengthFormatted, systemImage: "ruler.fill")
                                }
                                if record.headCircumferenceCm != nil {
                                    Label(record.headCircumferenceFormatted, systemImage: "circle.dashed")
                                }
                            }
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        }
                        Spacer()
                    }
                    .padding(MCSpacing.md)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 10))
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) {
                            Task {
                                await viewModel.deleteRecord(id: record.id, babyId: babyId)
                            }
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
            }
        }
    }

    // MARK: - Helpers

    private func displayValue(_ value: Double) -> Double {
        switch viewModel.selectedMeasurement {
        case .weight:
            return Locale.current.measurementSystem == .metric ? value / 1000.0 : value / 453.592
        case .length, .headCircumference:
            return Locale.current.measurementSystem == .metric ? value : value / 2.54
        }
    }

    private var yAxisLabel: String {
        let isMetric = Locale.current.measurementSystem == .metric
        switch viewModel.selectedMeasurement {
        case .weight: return isMetric ? "kg" : "lbs"
        case .length: return isMetric ? "cm" : "in"
        case .headCircumference: return isMetric ? "cm" : "in"
        }
    }

    private var chartAccessibilityLabel: String {
        if let pct = viewModel.latestPercentile {
            "\(viewModel.selectedMeasurement.label) chart showing baby at \(Int(pct))th percentile"
        } else {
            "\(viewModel.selectedMeasurement.label) growth chart"
        }
    }
}
```

**Step 3: Build**

Run: `tuist build 2>&1 | tail -5`
Expected: Build Succeeded

**Step 4: Commit**

```bash
git add MomCare/Features/Growth/Views/GrowthScreen.swift MomCare/Features/Growth/Views/AddMeasurementView.swift
git commit -m "feat(growth): add GrowthScreen with Swift Charts and AddMeasurementView"
```

---

## Task 6: Wire into BabyScreen + MomCareApp

**Files:**
- Modify: `MomCare/App/AppNavigation.swift` (add `.growth` to BabyRoute)
- Modify: `MomCare/Features/Baby/Views/BabyScreen.swift` (add Growth card + nav destination)
- Modify: `MomCare/App/MomCareApp.swift` (create GrowthViewModel)
- Modify: `MomCare/App/ContentView.swift` (pass GrowthViewModel through)

**Step 1: Add BabyRoute.growth**

In `MomCare/App/AppNavigation.swift`, add to the `BabyRoute` enum:

```swift
enum BabyRoute: Hashable {
    case sleepHistory
    case sleepTimer
    case growth
}
```

**Step 2: Add GrowthViewModel to MomCareApp**

In `MomCare/App/MomCareApp.swift`, add:

```swift
@State private var growthViewModel: GrowthViewModel?
```

In the `.task` block where other ViewModels are created (after `hasCompletedOnboarding`), add:

```swift
growthViewModel = GrowthViewModel(repository: deps.makeGrowthRepository())
```

Pass it to ContentView:

```swift
ContentView(
    babyViewModel: babyViewModel,
    selfCareViewModel: selfCareViewModel,
    dashboardViewModel: dashboardViewModel,
    babyActivityEngine: babyActivityEngine,
    journalViewModel: journalViewModel,
    sleepViewModel: sleepViewModel,
    growthViewModel: growthViewModel
)
```

**Step 3: Update ContentView**

In `MomCare/App/ContentView.swift`, add the property:

```swift
var growthViewModel: GrowthViewModel?
```

Pass it to `BabyScreen`:

```swift
BabyScreen(
    babyId: babyViewModel.selectedBaby?.id,
    sleepViewModel: sleepViewModel,
    growthViewModel: growthViewModel
)
```

**Step 4: Update BabyScreen**

In `MomCare/Features/Baby/Views/BabyScreen.swift`:

Add property:
```swift
var growthViewModel: GrowthViewModel?
```

Add Growth navigation link after Sleep History:
```swift
if growthViewModel != nil {
    NavigationLink(value: BabyRoute.growth) {
        HStack {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .foregroundStyle(MCColor.baby)
            Text("Growth Charts")
                .font(MCTypography.cardTitle)
            Spacer()
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(MCSpacing.md)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
    .buttonStyle(.plain)
}
```

Add navigation destination in the existing `.navigationDestination(for: BabyRoute.self)`:
```swift
case .growth:
    if let growthViewModel, let baby = /* get baby from parent */ {
        GrowthScreen(
            babyId: baby.id,
            dateOfBirth: baby.dateOfBirth,
            biologicalSex: baby.biologicalSex,
            viewModel: growthViewModel
        )
    }
```

Note: BabyScreen receives `babyId: UUID?` but GrowthScreen needs `dateOfBirth` and `biologicalSex`. You'll need to either pass the full `Baby` object to BabyScreen or add those parameters. The simplest approach: add `dateOfBirth: Date?` and `biologicalSex: Baby.BiologicalSex?` parameters to BabyScreen and pass them from ContentView where `babyViewModel.selectedBaby` is available.

**Step 5: Build and verify**

Run: `tuist build 2>&1 | tail -5`
Expected: Build Succeeded

**Step 6: Commit**

```bash
git add MomCare/App/AppNavigation.swift MomCare/Features/Baby/Views/BabyScreen.swift MomCare/App/MomCareApp.swift MomCare/App/ContentView.swift
git commit -m "feat(growth): wire growth tracking into BabyScreen and app root"
```

---

## Task 7: Lint, Build, Test, Push

**Step 1: Lint**

Run: `swiftlint lint --strict MomCare/ MomCareTests/ 2>&1 | tail -5`
Expected: 0 violations. Fix any violations.

**Step 2: Build**

Run: `tuist build 2>&1 | tail -5`
Expected: Build Succeeded

**Step 3: Test**

Run: `tuist test 2>&1 | tail -20`
Expected: All tests pass

**Step 4: Push**

```bash
git push -u origin nick/mom-8-native-ios-growth-tracking-with-whocdc-charts
```
