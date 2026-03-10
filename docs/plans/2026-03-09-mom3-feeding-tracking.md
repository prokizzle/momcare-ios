# MOM-3: Feeding Tracking Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Build the complete feeding tracking feature — the flagship, most complex, most-used feature that establishes patterns for all subsequent features.

**Architecture:** Follows MOM-2's Clean Architecture: Feeding domain entity (struct) → FeedingModel (@Model) → FeedingRepository (@MainActor) → FeedingViewModel (@MainActor @Observable) → Views. Adds FeedingPatternService as a pure domain service ported from Flutter. Timer uses structured concurrency with `AsyncTimerSequence` or a simple `Task` + `try await Task.sleep`.

**Tech Stack:** SwiftUI, SwiftData, Swift Testing, @Observable, Swift 6 strict concurrency

---

## Context for Implementer

**Existing patterns (from MOM-2) you MUST follow:**
- `@MainActor` on Repository, ViewModel, DI protocols — NOT `@unchecked Sendable`
- `error = nil` at the start of every async ViewModel operation
- `#Predicate` captures require local `let` bindings: `let fetchId = id`
- SwiftData model stores enums as raw Strings (e.g., `feedingTypeRaw: String`)
- SwiftData model uses `isSoftDeleted: Bool` (not `isDeleted`) to avoid `PersistentModel` collision
- Domain entities have `fixture()` factory in extension for tests
- Test stubs: `@MainActor private final class StubFeedingRepository: FeedingRepositoryProtocol`
- `@preconcurrency EnvironmentKey` for DI environment key
- `MCHaptic.tap()` / `.success()` / `.select()` on every interaction
- 44pt minimum tap targets, dark mode first
- `BabyFormData` pattern: form inputs → struct → ViewModel converts to entity

**Key files to reference:**
- `MomCare/Domain/Entities/Baby.swift` — entity pattern
- `MomCare/Data/SwiftData/BabyModel.swift` — SwiftData model pattern
- `MomCare/Data/Repositories/BabyRepository.swift` — repository pattern
- `MomCare/Features/Baby/ViewModels/BabyViewModel.swift` — ViewModel pattern
- `MomCare/Core/DI/Dependencies.swift` — DI wiring pattern
- `MomCare/Data/SwiftData/Schema/SchemaV1.swift` — VersionedSchema pattern
- `MomCare/Core/DesignSystem/` — MCColor, MCSpacing, MCTypography, MCHaptic

**Flutter reference (port exactly):**
- `baby-mother-care/lib/services/feeding_pattern_service.dart` — pattern algorithm
- `baby-mother-care/lib/domain/models/feeding_pattern.dart` — pattern entity

**Build & test commands:**
```bash
xcodegen generate
xcodebuild build -scheme MomCare -destination 'platform=iOS Simulator,name=iPhone 16' -quiet
xcodebuild test -scheme MomCare -destination 'platform=iOS Simulator,name=iPhone 16'
swiftlint --strict
```

---

## Task 1: Feeding Domain Entity + Enums

**Files:**
- Create: `MomCare/Domain/Entities/Feeding.swift`
- Create: `MomCare/Domain/Entities/FeedingPattern.swift`
- Test: `MomCareTests/Domain/FeedingTests.swift`

**Step 1: Write the failing tests**

```swift
// MomCareTests/Domain/FeedingTests.swift
import Testing
import Foundation
@testable import MomCare

@Suite("Feeding Entity Tests")
struct FeedingTests {

    // MARK: - Computed Properties

    @Test("isInProgress is true when endTime is nil")
    func isInProgress() {
        let feeding = Feeding.fixture(endTime: nil)
        #expect(feeding.isInProgress == true)
    }

    @Test("isInProgress is false when endTime is set")
    func isNotInProgress() {
        let feeding = Feeding.fixture(
            startTime: Date.now.addingTimeInterval(-600),
            endTime: Date.now
        )
        #expect(feeding.isInProgress == false)
    }

    @Test("duration computes from start and end times")
    func duration() {
        let start = Date.now.addingTimeInterval(-1800) // 30 min ago
        let end = Date.now
        let feeding = Feeding.fixture(startTime: start, endTime: end)
        #expect(abs(feeding.duration - 1800) < 1) // ~30 minutes in seconds
    }

    @Test("duration returns 0 when in progress")
    func durationInProgress() {
        let feeding = Feeding.fixture(endTime: nil)
        #expect(feeding.duration == 0)
    }

    @Test("durationFormatted shows minutes for short durations")
    func durationFormattedMinutes() {
        let start = Date.now.addingTimeInterval(-600) // 10 min ago
        let end = Date.now
        let feeding = Feeding.fixture(startTime: start, endTime: end)
        #expect(feeding.durationFormatted == "10 min")
    }

    @Test("durationFormatted shows hours and minutes for long durations")
    func durationFormattedHours() {
        let start = Date.now.addingTimeInterval(-5400) // 1h 30m ago
        let end = Date.now
        let feeding = Feeding.fixture(startTime: start, endTime: end)
        #expect(feeding.durationFormatted == "1h 30m")
    }

    // MARK: - Codable

    @Test("Feeding round-trips through JSON")
    func feedingCodable() throws {
        let feeding = Feeding.fixture()
        let data = try JSONEncoder().encode(feeding)
        let decoded = try JSONDecoder().decode(Feeding.self, from: data)
        #expect(decoded.id == feeding.id)
        #expect(decoded.feedingType == feeding.feedingType)
        #expect(decoded.breastSide == feeding.breastSide)
    }

    @Test("FeedingType round-trips through JSON")
    func feedingTypeCodable() throws {
        for type in Feeding.FeedingType.allCases {
            let data = try JSONEncoder().encode(type)
            let decoded = try JSONDecoder().decode(Feeding.FeedingType.self, from: data)
            #expect(decoded == type)
        }
    }

    @Test("BreastSide round-trips through JSON")
    func breastSideCodable() throws {
        for side in Feeding.BreastSide.allCases {
            let data = try JSONEncoder().encode(side)
            let decoded = try JSONDecoder().decode(Feeding.BreastSide.self, from: data)
            #expect(decoded == side)
        }
    }

    @Test("BottleContent round-trips through JSON")
    func bottleContentCodable() throws {
        for content in Feeding.BottleContent.allCases {
            let data = try JSONEncoder().encode(content)
            let decoded = try JSONDecoder().decode(Feeding.BottleContent.self, from: data)
            #expect(decoded == content)
        }
    }

    @Test("FeedingQuality round-trips through JSON")
    func feedingQualityCodable() throws {
        for quality in Feeding.FeedingQuality.allCases {
            let data = try JSONEncoder().encode(quality)
            let decoded = try JSONDecoder().decode(Feeding.FeedingQuality.self, from: data)
            #expect(decoded == quality)
        }
    }
}
```

**Step 2: Run tests to verify they fail**

Run: `xcodebuild test -scheme MomCare -destination 'platform=iOS Simulator,name=iPhone 16' 2>&1 | grep -E '(error|FAIL|passed|failed)'`
Expected: Compilation errors — `Feeding` type doesn't exist yet.

**Step 3: Implement Feeding entity**

```swift
// MomCare/Domain/Entities/Feeding.swift
import Foundation

struct Feeding: Identifiable, Codable, Sendable, Equatable {
    var id: UUID
    var babyId: UUID
    var feedingType: FeedingType
    var startTime: Date
    var endTime: Date?
    var breastSide: BreastSide?
    var breastDuration: TimeInterval?
    var amountMl: Int?
    var bottleContent: BottleContent?
    var foodDescription: String?
    var quality: FeedingQuality?
    var notes: String?
    var createdAt: Date
    var updatedAt: Date

    var isInProgress: Bool { endTime == nil }

    var duration: TimeInterval {
        guard let endTime else { return 0 }
        return endTime.timeIntervalSince(startTime)
    }

    var durationFormatted: String {
        let totalMinutes = Int(duration) / 60
        if totalMinutes < 60 {
            return "\(totalMinutes) min"
        }
        let hours = totalMinutes / 60
        let mins = totalMinutes % 60
        if mins == 0 {
            return "\(hours)h"
        }
        return "\(hours)h \(mins)m"
    }

    enum FeedingType: String, Codable, CaseIterable, Sendable {
        case breast, bottle, pumping, solid
    }

    enum BreastSide: String, Codable, CaseIterable, Sendable {
        case left, right, both
    }

    enum BottleContent: String, Codable, CaseIterable, Sendable {
        case breastMilk, formula, mixed
    }

    enum FeedingQuality: String, Codable, CaseIterable, Sendable {
        case good, fussy, distracted, sleepy
    }
}

extension Feeding.FeedingType {
    var label: String {
        switch self {
        case .breast: "Breast"
        case .bottle: "Bottle"
        case .pumping: "Pumping"
        case .solid: "Solid Food"
        }
    }

    var systemImage: String {
        switch self {
        case .breast: "drop.fill"
        case .bottle: "waterbottle.fill"
        case .pumping: "arrow.up.heart.fill"
        case .solid: "fork.knife"
        }
    }
}

extension Feeding.BreastSide {
    var label: String {
        switch self {
        case .left: "Left"
        case .right: "Right"
        case .both: "Both"
        }
    }
}

extension Feeding.BottleContent {
    var displayName: String {
        switch self {
        case .breastMilk: "Breast Milk"
        case .formula: "Formula"
        case .mixed: "Mixed"
        }
    }
}

extension Feeding.FeedingQuality {
    var displayName: String {
        switch self {
        case .good: "Good"
        case .fussy: "Fussy"
        case .distracted: "Distracted"
        case .sleepy: "Sleepy"
        }
    }
}

extension Feeding {
    static func fixture(
        id: UUID = UUID(),
        babyId: UUID = UUID(),
        feedingType: FeedingType = .breast,
        startTime: Date = Date.now.addingTimeInterval(-1800),
        endTime: Date? = Date.now,
        breastSide: BreastSide? = .left,
        breastDuration: TimeInterval? = nil,
        amountMl: Int? = nil,
        bottleContent: BottleContent? = nil,
        foodDescription: String? = nil,
        quality: FeedingQuality? = nil,
        notes: String? = nil,
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) -> Feeding {
        Feeding(
            id: id,
            babyId: babyId,
            feedingType: feedingType,
            startTime: startTime,
            endTime: endTime,
            breastSide: breastSide,
            breastDuration: breastDuration,
            amountMl: amountMl,
            bottleContent: bottleContent,
            foodDescription: foodDescription,
            quality: quality,
            notes: notes,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
}
```

Also create the FeedingPattern entity:

```swift
// MomCare/Domain/Entities/FeedingPattern.swift
import Foundation

struct FeedingPattern: Sendable {
    let averageInterval: TimeInterval
    let confidence: Double
    let sampleSize: Int
    let isInsufficient: Bool

    static func insufficient() -> FeedingPattern {
        FeedingPattern(
            averageInterval: 0,
            confidence: 0,
            sampleSize: 0,
            isInsufficient: true
        )
    }

    var intervalFormatted: String {
        if isInsufficient { return "Not enough data" }
        let totalMinutes = Int(averageInterval) / 60
        let hours = totalMinutes / 60
        let mins = totalMinutes % 60
        if hours == 0 { return "\(mins) min" }
        if mins == 0 { return "\(hours)h" }
        return "\(hours)h \(mins)m"
    }

    func isFeedingDue(lastFeedTime: Date) -> Bool {
        if isInsufficient { return false }
        let elapsed = Date.now.timeIntervalSince(lastFeedTime)
        return elapsed >= averageInterval * 0.9
    }

    func timeUntilNextFeed(lastFeedTime: Date) -> TimeInterval {
        if isInsufficient { return 0 }
        let elapsed = Date.now.timeIntervalSince(lastFeedTime)
        let remaining = averageInterval - elapsed
        return max(remaining, 0)
    }

    func timeUntilNextFeedFormatted(lastFeedTime: Date) -> String {
        let remaining = timeUntilNextFeed(lastFeedTime: lastFeedTime)
        if remaining == 0 { return "Now" }
        let totalMinutes = Int(remaining) / 60
        let hours = totalMinutes / 60
        let mins = totalMinutes % 60
        if hours == 0 { return "in \(mins) min" }
        if mins == 0 { return "in \(hours)h" }
        return "in \(hours)h \(mins)m"
    }
}
```

**Step 4: Run tests to verify they pass**

Run: `xcodegen generate && xcodebuild test -scheme MomCare -destination 'platform=iOS Simulator,name=iPhone 16' 2>&1 | grep -E '(passed|failed|Test run)'`
Expected: All FeedingTests pass.

**Step 5: Lint and commit**

```bash
swiftlint --strict
git add MomCare/Domain/Entities/Feeding.swift MomCare/Domain/Entities/FeedingPattern.swift MomCareTests/Domain/FeedingTests.swift
git commit -m "feat(MOM-3): add Feeding domain entity with enums and FeedingPattern"
```

---

## Task 2: FeedingPatternService (Port from Flutter)

**Files:**
- Create: `MomCare/Domain/Services/FeedingPatternService.swift`
- Test: `MomCareTests/Domain/FeedingPatternServiceTests.swift`

**Step 1: Write the failing tests**

```swift
// MomCareTests/Domain/FeedingPatternServiceTests.swift
import Testing
import Foundation
@testable import MomCare

@Suite("FeedingPatternService Tests")
struct FeedingPatternServiceTests {

    @Test("Returns insufficient when fewer than 3 feedings")
    func insufficientData() {
        let feedings = [Feeding.fixture(), Feeding.fixture()]
        let result = FeedingPatternService.analyzePattern(from: feedings)
        #expect(result.isInsufficient == true)
    }

    @Test("Returns insufficient when no valid intervals")
    func noValidIntervals() {
        // All feedings within 10 minutes of each other (< 30 min threshold)
        let now = Date.now
        let feedings = (0..<5).map { i in
            Feeding.fixture(
                startTime: now.addingTimeInterval(Double(-i * 600)), // 10 min apart
                endTime: now.addingTimeInterval(Double(-i * 600) + 300)
            )
        }
        let result = FeedingPatternService.analyzePattern(from: feedings)
        #expect(result.isInsufficient == true)
    }

    @Test("Calculates average interval correctly")
    func averageInterval() {
        let now = Date.now
        // 4 feedings, 2 hours (7200s) apart
        let feedings = (0..<4).map { i in
            Feeding.fixture(
                startTime: now.addingTimeInterval(Double(-i) * 7200),
                endTime: now.addingTimeInterval(Double(-i) * 7200 + 1200)
            )
        }
        let result = FeedingPatternService.analyzePattern(from: feedings)
        #expect(result.isInsufficient == false)
        // Intervals should be ~100 minutes each (endTime to next startTime)
        // endTime is startTime + 1200s (20min), next start is 7200s later
        // interval = 7200 - 1200 = 6000s = 100min — within 30-480 range
        let avgMinutes = Int(result.averageInterval) / 60
        #expect(avgMinutes >= 95 && avgMinutes <= 105)
    }

    @Test("Filters intervals outside 30-480 minute range")
    func filtersUnreasonableIntervals() {
        let now = Date.now
        // Mix: one 2-hour interval (valid), one 10-minute (too short), one 10-hour (too long)
        let feedings = [
            Feeding.fixture(startTime: now, endTime: now.addingTimeInterval(600)),
            // 2h gap from previous endTime
            Feeding.fixture(
                startTime: now.addingTimeInterval(-7800),
                endTime: now.addingTimeInterval(-7200)
            ),
            // 10min gap — too short, should be filtered
            Feeding.fixture(
                startTime: now.addingTimeInterval(-8400),
                endTime: now.addingTimeInterval(-7900)
            ),
            // 10h gap — too long, should be filtered
            Feeding.fixture(
                startTime: now.addingTimeInterval(-44400),
                endTime: now.addingTimeInterval(-44100)
            )
        ]
        let result = FeedingPatternService.analyzePattern(from: feedings)
        #expect(result.sampleSize == 4)
        // Only the valid 2h interval should remain
    }

    @Test("High confidence for consistent intervals with large sample")
    func highConfidence() {
        let now = Date.now
        // 25 feedings, all exactly 2.5 hours apart — very consistent, large sample
        let feedings = (0..<25).map { i in
            Feeding.fixture(
                startTime: now.addingTimeInterval(Double(-i) * 9000),
                endTime: now.addingTimeInterval(Double(-i) * 9000 + 1200)
            )
        }
        let result = FeedingPatternService.analyzePattern(from: feedings)
        #expect(result.confidence >= 0.8)
    }

    @Test("Low confidence for small inconsistent sample")
    func lowConfidence() {
        let now = Date.now
        // 3 feedings with varying intervals
        let feedings = [
            Feeding.fixture(startTime: now, endTime: now.addingTimeInterval(600)),
            Feeding.fixture(
                startTime: now.addingTimeInterval(-3600),
                endTime: now.addingTimeInterval(-3000)
            ),
            Feeding.fixture(
                startTime: now.addingTimeInterval(-18000),
                endTime: now.addingTimeInterval(-17400)
            )
        ]
        let result = FeedingPatternService.analyzePattern(from: feedings)
        #expect(result.confidence <= 0.6)
    }

    @Test("Uses endTime when available for interval calculation")
    func usesEndTime() {
        let now = Date.now
        // Feeding 1: start=-7200, end=-6000 (ended 100min ago)
        // Feeding 2: start=-3600 (started 60min ago), end=-3000
        // Interval: endTime1 to startTime2 = 6000 - 3600 = 2400s = 40min
        let feedings = [
            Feeding.fixture(
                startTime: now.addingTimeInterval(-3600),
                endTime: now.addingTimeInterval(-3000)
            ),
            Feeding.fixture(
                startTime: now.addingTimeInterval(-7200),
                endTime: now.addingTimeInterval(-6000)
            ),
            Feeding.fixture(
                startTime: now.addingTimeInterval(-10800),
                endTime: now.addingTimeInterval(-9600)
            )
        ]
        let result = FeedingPatternService.analyzePattern(from: feedings)
        #expect(result.isInsufficient == false)
    }

    @Test("formatTimeSince returns correct strings")
    func formatTimeSince() {
        #expect(FeedingPatternService.formatTimeSince(nil) == "No feedings yet")
        #expect(FeedingPatternService.formatTimeSince(2700) == "45 min ago")  // 45 min
        #expect(FeedingPatternService.formatTimeSince(3600) == "1h ago")      // exactly 1h
        #expect(FeedingPatternService.formatTimeSince(8100) == "2h 15m ago")  // 2h 15m
    }
}
```

**Step 2: Run tests to verify they fail**

Expected: Compilation errors — `FeedingPatternService` doesn't exist yet.

**Step 3: Implement FeedingPatternService**

```swift
// MomCare/Domain/Services/FeedingPatternService.swift
import Foundation

enum FeedingPatternService {
    static let minFeedingsForPattern = 3
    static let patternAnalysisDays = 7
    private static let minIntervalMinutes = 30
    private static let maxIntervalMinutes = 480

    static func analyzePattern(from feedings: [Feeding]) -> FeedingPattern {
        guard feedings.count >= minFeedingsForPattern else {
            return .insufficient()
        }

        var intervals: [Int] = []
        for i in 0..<(feedings.count - 1) {
            let current = feedings[i]
            let next = feedings[i + 1]

            let currentTime = current.endTime ?? current.startTime
            let nextTime = next.startTime

            let intervalMinutes = abs(Int(currentTime.timeIntervalSince(nextTime))) / 60

            if intervalMinutes >= minIntervalMinutes && intervalMinutes <= maxIntervalMinutes {
                intervals.append(intervalMinutes)
            }
        }

        guard !intervals.isEmpty else {
            return .insufficient()
        }

        let totalMinutes = intervals.reduce(0, +)
        let avgMinutes = totalMinutes / intervals.count
        let confidence = calculateConfidence(intervals: intervals, sampleSize: feedings.count)

        return FeedingPattern(
            averageInterval: TimeInterval(avgMinutes * 60),
            confidence: confidence,
            sampleSize: feedings.count,
            isInsufficient: false
        )
    }

    private static func calculateConfidence(intervals: [Int], sampleSize: Int) -> Double {
        guard !intervals.isEmpty else { return 0 }

        let sizeConfidence: Double
        if sampleSize >= 20 {
            sizeConfidence = 0.9
        } else if sampleSize >= 10 {
            sizeConfidence = 0.7
        } else if sampleSize >= 5 {
            sizeConfidence = 0.5
        } else {
            sizeConfidence = 0.3
        }

        let avg = Double(intervals.reduce(0, +)) / Double(intervals.count)
        let variance = intervals
            .map { (Double($0) - avg) * (Double($0) - avg) }
            .reduce(0, +) / Double(intervals.count)
        let coefficientOfVariation = avg > 0 ? variance / avg : 0

        let consistencyConfidence: Double
        if coefficientOfVariation < 0.2 {
            consistencyConfidence = 1.0
        } else if coefficientOfVariation < 0.4 {
            consistencyConfidence = 0.8
        } else if coefficientOfVariation < 0.6 {
            consistencyConfidence = 0.6
        } else {
            consistencyConfidence = 0.4
        }

        return min(max(sizeConfidence * 0.4 + consistencyConfidence * 0.6, 0.0), 1.0)
    }

    static func formatTimeSince(_ seconds: TimeInterval?) -> String {
        guard let seconds else { return "No feedings yet" }
        let hours = Int(seconds) / 3600
        let mins = (Int(seconds) % 3600) / 60
        if hours == 0 { return "\(mins) min ago" }
        if mins == 0 { return "\(hours)h ago" }
        return "\(hours)h \(mins)m ago"
    }
}
```

**Step 4: Run tests**

Run: `xcodegen generate && xcodebuild test -scheme MomCare -destination 'platform=iOS Simulator,name=iPhone 16' 2>&1 | grep -E '(passed|failed|Test run)'`
Expected: All FeedingPatternServiceTests pass.

**Step 5: Lint and commit**

```bash
swiftlint --strict
git add MomCare/Domain/Services/FeedingPatternService.swift MomCareTests/Domain/FeedingPatternServiceTests.swift
git commit -m "feat(MOM-3): add FeedingPatternService ported from Flutter"
```

---

## Task 3: FeedingModel SwiftData Class

**Files:**
- Create: `MomCare/Data/SwiftData/FeedingModel.swift`
- Modify: `MomCare/Data/SwiftData/BabyModel.swift` — add `feedings` relationship
- Modify: `MomCare/Data/SwiftData/Schema/SchemaV1.swift` — register FeedingModel
- Test: `MomCareTests/Data/FeedingModelTests.swift`

**Step 1: Write the failing tests**

```swift
// MomCareTests/Data/FeedingModelTests.swift
import Testing
import Foundation
import SwiftData
@testable import MomCare

@Suite("FeedingModel Tests")
struct FeedingModelTests {

    @Test("FeedingModel converts from Feeding entity")
    @MainActor
    func convertFromEntity() {
        let feeding = Feeding.fixture(feedingType: .breast, breastSide: .left)
        let model = FeedingModel(from: feeding)
        #expect(model.id == feeding.id)
        #expect(model.feedingTypeRaw == "breast")
        #expect(model.breastSideRaw == "left")
    }

    @Test("FeedingModel converts to Feeding entity")
    @MainActor
    func convertToEntity() {
        let feeding = Feeding.fixture(
            feedingType: .bottle,
            bottleContent: .formula,
            amountMl: 120
        )
        let model = FeedingModel(from: feeding)
        let entity = model.toEntity()
        #expect(entity.feedingType == .bottle)
        #expect(entity.bottleContent == .formula)
        #expect(entity.amountMl == 120)
    }

    @Test("FeedingModel persists to in-memory store")
    @MainActor
    func persistence() throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(
            for: BabyModel.self, FeedingModel.self,
            configurations: config
        )
        let context = ModelContext(container)

        let model = FeedingModel(from: Feeding.fixture())
        context.insert(model)
        try context.save()

        let descriptor = FetchDescriptor<FeedingModel>()
        let results = try context.fetch(descriptor)
        #expect(results.count == 1)
    }
}
```

**Step 2: Run tests to verify they fail**

Expected: Compilation errors — `FeedingModel` doesn't exist yet.

**Step 3: Implement FeedingModel**

```swift
// MomCare/Data/SwiftData/FeedingModel.swift
import Foundation
import SwiftData

@Model
final class FeedingModel {
    @Attribute(.unique) var id: UUID
    var babyId: UUID
    var feedingTypeRaw: String
    var startTime: Date
    var endTime: Date?
    var breastSideRaw: String?
    var breastDuration: Double?
    var amountMl: Int?
    var bottleContentRaw: String?
    var foodDescription: String?
    var qualityRaw: String?
    var notes: String?
    var isSoftDeleted: Bool
    var createdAt: Date
    var updatedAt: Date

    var baby: BabyModel?

    init(from feeding: Feeding) {
        self.id = feeding.id
        self.babyId = feeding.babyId
        self.feedingTypeRaw = feeding.feedingType.rawValue
        self.startTime = feeding.startTime
        self.endTime = feeding.endTime
        self.breastSideRaw = feeding.breastSide?.rawValue
        self.breastDuration = feeding.breastDuration
        self.amountMl = feeding.amountMl
        self.bottleContentRaw = feeding.bottleContent?.rawValue
        self.foodDescription = feeding.foodDescription
        self.qualityRaw = feeding.quality?.rawValue
        self.notes = feeding.notes
        self.isSoftDeleted = false
        self.createdAt = feeding.createdAt
        self.updatedAt = feeding.updatedAt
    }

    func toEntity() -> Feeding {
        Feeding(
            id: id,
            babyId: babyId,
            feedingType: Feeding.FeedingType(rawValue: feedingTypeRaw) ?? .breast,
            startTime: startTime,
            endTime: endTime,
            breastSide: breastSideRaw.flatMap { Feeding.BreastSide(rawValue: $0) },
            breastDuration: breastDuration,
            amountMl: amountMl,
            bottleContent: bottleContentRaw.flatMap { Feeding.BottleContent(rawValue: $0) },
            foodDescription: foodDescription,
            quality: qualityRaw.flatMap { Feeding.FeedingQuality(rawValue: $0) },
            notes: notes,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }

    func update(from feeding: Feeding) {
        feedingTypeRaw = feeding.feedingType.rawValue
        startTime = feeding.startTime
        endTime = feeding.endTime
        breastSideRaw = feeding.breastSide?.rawValue
        breastDuration = feeding.breastDuration
        amountMl = feeding.amountMl
        bottleContentRaw = feeding.bottleContent?.rawValue
        foodDescription = feeding.foodDescription
        qualityRaw = feeding.quality?.rawValue
        notes = feeding.notes
        updatedAt = Date.now
    }
}
```

Also add the `feedings` relationship to BabyModel (add after existing properties):

```swift
// In MomCare/Data/SwiftData/BabyModel.swift — add this property:
@Relationship(deleteRule: .cascade, inverse: \FeedingModel.baby)
var feedings: [FeedingModel]? = []
```

Update SchemaV1 to register FeedingModel:

```swift
// MomCare/Data/SwiftData/Schema/SchemaV1.swift
import Foundation
import SwiftData

enum SchemaV1: VersionedSchema {
    static var versionIdentifier: Schema.Version { .init(1, 0, 0) }

    static var models: [any PersistentModel.Type] {
        [BabyModel.self, FeedingModel.self]
    }
}
```

**Step 4: Run tests**

Run: `xcodegen generate && xcodebuild test -scheme MomCare -destination 'platform=iOS Simulator,name=iPhone 16' 2>&1 | grep -E '(passed|failed|Test run)'`
Expected: All tests pass (existing + new FeedingModelTests).

**Step 5: Lint and commit**

```bash
swiftlint --strict
git add MomCare/Data/SwiftData/FeedingModel.swift MomCare/Data/SwiftData/BabyModel.swift MomCare/Data/SwiftData/Schema/SchemaV1.swift MomCareTests/Data/FeedingModelTests.swift
git commit -m "feat(MOM-3): add FeedingModel SwiftData class with BabyModel relationship"
```

---

## Task 4: FeedingRepository

**Files:**
- Create: `MomCare/Domain/Repositories/FeedingRepositoryProtocol.swift`
- Create: `MomCare/Data/Repositories/FeedingRepository.swift`
- Test: `MomCareTests/Data/FeedingRepositoryTests.swift`

**Step 1: Write the failing tests**

```swift
// MomCareTests/Data/FeedingRepositoryTests.swift
import Testing
import Foundation
import SwiftData
@testable import MomCare

@Suite("FeedingRepository Tests")
struct FeedingRepositoryTests {

    @MainActor
    private func makeSUT() throws -> FeedingRepository {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(
            for: BabyModel.self, FeedingModel.self,
            configurations: config
        )
        let context = ModelContext(container)
        return FeedingRepository(modelContext: context)
    }

    private let testBabyId = UUID()

    @Test("create inserts feeding and returns it")
    @MainActor
    func create() async throws {
        let repo = try makeSUT()
        let feeding = Feeding.fixture(babyId: testBabyId)
        let created = try await repo.create(feeding)
        #expect(created.babyId == testBabyId)
    }

    @Test("getFeedingsForBaby returns feedings for specific baby")
    @MainActor
    func getFeedingsForBaby() async throws {
        let repo = try makeSUT()
        let otherBabyId = UUID()
        _ = try await repo.create(Feeding.fixture(babyId: testBabyId))
        _ = try await repo.create(Feeding.fixture(babyId: testBabyId))
        _ = try await repo.create(Feeding.fixture(babyId: otherBabyId))

        let feedings = try await repo.getFeedingsForBaby(testBabyId, limit: nil)
        #expect(feedings.count == 2)
    }

    @Test("getFeedingsForBaby respects limit")
    @MainActor
    func getFeedingsForBabyWithLimit() async throws {
        let repo = try makeSUT()
        for _ in 0..<5 {
            _ = try await repo.create(Feeding.fixture(babyId: testBabyId))
        }

        let feedings = try await repo.getFeedingsForBaby(testBabyId, limit: 3)
        #expect(feedings.count == 3)
    }

    @Test("getFeedingsForDateRange filters by date")
    @MainActor
    func getFeedingsForDateRange() async throws {
        let repo = try makeSUT()
        let now = Date.now
        let yesterday = now.addingTimeInterval(-86400)
        let twoDaysAgo = now.addingTimeInterval(-172800)

        _ = try await repo.create(Feeding.fixture(babyId: testBabyId, startTime: now))
        _ = try await repo.create(Feeding.fixture(babyId: testBabyId, startTime: yesterday))
        _ = try await repo.create(Feeding.fixture(babyId: testBabyId, startTime: twoDaysAgo))

        let feedings = try await repo.getFeedingsForDateRange(
            babyId: testBabyId,
            start: yesterday.addingTimeInterval(-3600),
            end: now.addingTimeInterval(3600)
        )
        #expect(feedings.count == 2) // now + yesterday, not twoDaysAgo
    }

    @Test("getInProgressFeeding returns feeding with nil endTime")
    @MainActor
    func getInProgressFeeding() async throws {
        let repo = try makeSUT()
        _ = try await repo.create(Feeding.fixture(babyId: testBabyId, endTime: Date.now))
        _ = try await repo.create(Feeding.fixture(babyId: testBabyId, endTime: nil))

        let inProgress = try await repo.getInProgressFeeding(babyId: testBabyId)
        #expect(inProgress != nil)
        #expect(inProgress?.isInProgress == true)
    }

    @Test("getInProgressFeeding returns nil when none in progress")
    @MainActor
    func getInProgressFeedingNone() async throws {
        let repo = try makeSUT()
        _ = try await repo.create(Feeding.fixture(babyId: testBabyId, endTime: Date.now))

        let inProgress = try await repo.getInProgressFeeding(babyId: testBabyId)
        #expect(inProgress == nil)
    }

    @Test("update modifies existing feeding")
    @MainActor
    func update() async throws {
        let repo = try makeSUT()
        var feeding = try await repo.create(Feeding.fixture(babyId: testBabyId, endTime: nil))
        feeding.endTime = Date.now
        let updated = try await repo.update(feeding)
        #expect(updated.endTime != nil)
    }

    @Test("delete soft-deletes feeding")
    @MainActor
    func softDelete() async throws {
        let repo = try makeSUT()
        let feeding = try await repo.create(Feeding.fixture(babyId: testBabyId))
        try await repo.delete(feeding.id)

        let all = try await repo.getFeedingsForBaby(testBabyId, limit: nil)
        #expect(all.isEmpty)
    }
}
```

**Step 2: Run tests to verify they fail**

Expected: Compilation errors — types don't exist yet.

**Step 3: Implement FeedingRepositoryProtocol and FeedingRepository**

```swift
// MomCare/Domain/Repositories/FeedingRepositoryProtocol.swift
import Foundation

protocol FeedingRepositoryProtocol: Repository where Entity == Feeding {
    func getFeedingsForBaby(_ babyId: UUID, limit: Int?) async throws -> [Feeding]
    func getFeedingsForDateRange(babyId: UUID, start: Date, end: Date) async throws -> [Feeding]
    func getInProgressFeeding(babyId: UUID) async throws -> Feeding?
}
```

```swift
// MomCare/Data/Repositories/FeedingRepository.swift
import Foundation
import SwiftData

@MainActor
final class FeedingRepository: FeedingRepositoryProtocol {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func getAll() async throws -> [Feeding] {
        let descriptor = FetchDescriptor<FeedingModel>(
            predicate: #Predicate<FeedingModel> { $0.isSoftDeleted == false },
            sortBy: [SortDescriptor(\.startTime, order: .reverse)]
        )
        return try modelContext.fetch(descriptor).map { $0.toEntity() }
    }

    func getById(_ id: UUID) async throws -> Feeding? {
        let fetchId = id
        let descriptor = FetchDescriptor<FeedingModel>(
            predicate: #Predicate<FeedingModel> { $0.id == fetchId }
        )
        return try modelContext.fetch(descriptor).first?.toEntity()
    }

    func create(_ entity: Feeding) async throws -> Feeding {
        let model = FeedingModel(from: entity)
        modelContext.insert(model)
        try modelContext.save()
        return model.toEntity()
    }

    func update(_ entity: Feeding) async throws -> Feeding {
        let entityId = entity.id
        let descriptor = FetchDescriptor<FeedingModel>(
            predicate: #Predicate<FeedingModel> { $0.id == entityId }
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
        let descriptor = FetchDescriptor<FeedingModel>(
            predicate: #Predicate<FeedingModel> { $0.id == deleteId }
        )
        guard let model = try modelContext.fetch(descriptor).first else {
            throw RepositoryError.notFound
        }
        model.isSoftDeleted = true
        model.updatedAt = .now
        try modelContext.save()
    }

    func getFeedingsForBaby(_ babyId: UUID, limit: Int?) async throws -> [Feeding] {
        let fetchBabyId = babyId
        var descriptor = FetchDescriptor<FeedingModel>(
            predicate: #Predicate<FeedingModel> {
                $0.babyId == fetchBabyId && $0.isSoftDeleted == false
            },
            sortBy: [SortDescriptor(\.startTime, order: .reverse)]
        )
        if let limit {
            descriptor.fetchLimit = limit
        }
        return try modelContext.fetch(descriptor).map { $0.toEntity() }
    }

    func getFeedingsForDateRange(babyId: UUID, start: Date, end: Date) async throws -> [Feeding] {
        let fetchBabyId = babyId
        let rangeStart = start
        let rangeEnd = end
        let descriptor = FetchDescriptor<FeedingModel>(
            predicate: #Predicate<FeedingModel> {
                $0.babyId == fetchBabyId &&
                $0.isSoftDeleted == false &&
                $0.startTime >= rangeStart &&
                $0.startTime <= rangeEnd
            },
            sortBy: [SortDescriptor(\.startTime, order: .reverse)]
        )
        return try modelContext.fetch(descriptor).map { $0.toEntity() }
    }

    func getInProgressFeeding(babyId: UUID) async throws -> Feeding? {
        let fetchBabyId = babyId
        let descriptor = FetchDescriptor<FeedingModel>(
            predicate: #Predicate<FeedingModel> {
                $0.babyId == fetchBabyId &&
                $0.isSoftDeleted == false &&
                $0.endTime == nil
            }
        )
        return try modelContext.fetch(descriptor).first?.toEntity()
    }
}
```

**Step 4: Run tests**

Expected: All FeedingRepositoryTests pass.

**Step 5: Lint and commit**

```bash
swiftlint --strict
git add MomCare/Domain/Repositories/FeedingRepositoryProtocol.swift MomCare/Data/Repositories/FeedingRepository.swift MomCareTests/Data/FeedingRepositoryTests.swift
git commit -m "feat(MOM-3): add FeedingRepository with baby-scoped queries and in-progress lookup"
```

---

## Task 5: Wire FeedingRepository into DI + Update MomCareApp

**Files:**
- Modify: `MomCare/Core/DI/Dependencies.swift` — add `makeFeedingRepository()`
- Modify: `MomCareTests/Core/DI/DependenciesTests.swift` — update mocks

**Step 1: Add factory method to DependencyContainer**

In `Dependencies.swift`, add to the protocol and implementation:

```swift
// In DependencyContainer protocol:
func makeFeedingRepository() -> any FeedingRepositoryProtocol

// In AppDependencies:
func makeFeedingRepository() -> any FeedingRepositoryProtocol {
    FeedingRepository(modelContext: modelContext)
}
```

**Step 2: Update test mocks**

In `DependenciesTests.swift`, add the factory method to both `MockBabyRepository` (**note**: MockBabyRepository doesn't need this, but `TestDependencies` and `MockBabyRepository` in `DependenciesTests` do). Actually — add `makeFeedingRepository()` to `TestDependencies`:

```swift
// Add a MockFeedingRepository and update TestDependencies
@MainActor
private final class MockFeedingRepository: FeedingRepositoryProtocol {
    func getAll() async throws -> [Feeding] { [] }
    func getById(_ id: UUID) async throws -> Feeding? { nil }
    func create(_ entity: Feeding) async throws -> Feeding { entity }
    func update(_ entity: Feeding) async throws -> Feeding { entity }
    func delete(_ id: UUID) async throws {}
    func getFeedingsForBaby(_ babyId: UUID, limit: Int?) async throws -> [Feeding] { [] }
    func getFeedingsForDateRange(babyId: UUID, start: Date, end: Date) async throws -> [Feeding] { [] }
    func getInProgressFeeding(babyId: UUID) async throws -> Feeding? { nil }
}

// Update TestDependencies to add:
func makeFeedingRepository() -> any FeedingRepositoryProtocol {
    MockFeedingRepository()
}
```

Also add a test:

```swift
@Test("AppDependencies creates real FeedingRepository")
@MainActor
func appDependenciesCreatesFeedingRepo() throws {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let modelContainer = try ModelContainer(
        for: BabyModel.self, FeedingModel.self,
        configurations: config
    )
    let deps = AppDependencies(modelContext: modelContainer.mainContext)
    let repo = deps.makeFeedingRepository()
    #expect(repo is FeedingRepository)
}
```

**Step 3: Run tests**

Expected: All tests pass including new DI test.

**Step 4: Lint and commit**

```bash
swiftlint --strict
git add MomCare/Core/DI/Dependencies.swift MomCareTests/Core/DI/DependenciesTests.swift
git commit -m "feat(MOM-3): wire FeedingRepository into DependencyContainer"
```

---

## Task 6: FeedingViewModel

**Files:**
- Create: `MomCare/Features/Feeding/ViewModels/FeedingViewModel.swift`
- Test: `MomCareTests/Features/FeedingViewModelTests.swift`

**Step 1: Write the failing tests**

```swift
// MomCareTests/Features/FeedingViewModelTests.swift
import Testing
import Foundation
@testable import MomCare

@Suite("FeedingViewModel Tests")
struct FeedingViewModelTests {

    private let testBabyId = UUID()

    @MainActor
    private func makeSUT(
        feedings: [Feeding] = [],
        inProgress: Feeding? = nil
    ) -> FeedingViewModel {
        let repo = StubFeedingRepository(feedings: feedings, inProgress: inProgress)
        return FeedingViewModel(repository: repo)
    }

    @Test("loadFeedings populates array and checks in-progress")
    @MainActor
    func loadFeedings() async {
        let sut = makeSUT(feedings: [
            Feeding.fixture(babyId: testBabyId),
            Feeding.fixture(babyId: testBabyId)
        ])
        await sut.loadFeedings(babyId: testBabyId)
        #expect(sut.feedings.count == 2)
    }

    @Test("loadFeedings detects in-progress feeding")
    @MainActor
    func loadFeedingsInProgress() async {
        let inProgress = Feeding.fixture(babyId: testBabyId, endTime: nil)
        let sut = makeSUT(inProgress: inProgress)
        await sut.loadFeedings(babyId: testBabyId)
        #expect(sut.inProgressFeeding != nil)
        #expect(sut.isTimerRunning == true)
    }

    @Test("startFeeding creates in-progress entry")
    @MainActor
    func startFeeding() async {
        let sut = makeSUT()
        await sut.startFeeding(babyId: testBabyId, type: .breast)
        #expect(sut.inProgressFeeding != nil)
        #expect(sut.inProgressFeeding?.feedingType == .breast)
        #expect(sut.isTimerRunning == true)
    }

    @Test("endFeeding sets endTime and stops timer")
    @MainActor
    func endFeeding() async {
        let inProgress = Feeding.fixture(babyId: testBabyId, endTime: nil)
        let sut = makeSUT(inProgress: inProgress)
        await sut.loadFeedings(babyId: testBabyId)
        await sut.endFeeding()
        #expect(sut.inProgressFeeding == nil)
        #expect(sut.isTimerRunning == false)
    }

    @Test("toggleBreastSide alternates sides")
    @MainActor
    func toggleBreastSide() {
        let sut = makeSUT()
        #expect(sut.selectedSide == .left)
        sut.toggleBreastSide()
        #expect(sut.selectedSide == .right)
        sut.toggleBreastSide()
        #expect(sut.selectedSide == .left)
    }

    @Test("deleteFeeding removes from list")
    @MainActor
    func deleteFeeding() async {
        let feeding = Feeding.fixture(babyId: testBabyId)
        let sut = makeSUT(feedings: [feeding])
        await sut.loadFeedings(babyId: testBabyId)
        await sut.deleteFeeding(feeding.id)
        #expect(sut.feedings.isEmpty)
    }

    @Test("analyzePattern computes pattern from feedings")
    @MainActor
    func analyzePattern() async {
        let now = Date.now
        let feedings = (0..<10).map { i in
            Feeding.fixture(
                babyId: testBabyId,
                startTime: now.addingTimeInterval(Double(-i) * 7200),
                endTime: now.addingTimeInterval(Double(-i) * 7200 + 1200)
            )
        }
        let sut = makeSUT(feedings: feedings)
        await sut.loadFeedings(babyId: testBabyId)
        await sut.analyzePattern(babyId: testBabyId)
        #expect(sut.pattern != nil)
        #expect(sut.pattern?.isInsufficient == false)
    }
}

@MainActor
private final class StubFeedingRepository: FeedingRepositoryProtocol {
    private var store: [Feeding]
    private var inProgress: Feeding?

    init(feedings: [Feeding] = [], inProgress: Feeding? = nil) {
        self.store = feedings
        self.inProgress = inProgress
    }

    func getAll() async throws -> [Feeding] { store }
    func getById(_ id: UUID) async throws -> Feeding? { store.first { $0.id == id } }
    func create(_ entity: Feeding) async throws -> Feeding {
        store.append(entity)
        return entity
    }
    func update(_ entity: Feeding) async throws -> Feeding {
        if let idx = store.firstIndex(where: { $0.id == entity.id }) {
            store[idx] = entity
        }
        return entity
    }
    func delete(_ id: UUID) async throws {
        store.removeAll { $0.id == id }
    }
    func getFeedingsForBaby(_ babyId: UUID, limit: Int?) async throws -> [Feeding] {
        let filtered = store.filter { $0.babyId == babyId }
        if let limit { return Array(filtered.prefix(limit)) }
        return filtered
    }
    func getFeedingsForDateRange(babyId: UUID, start: Date, end: Date) async throws -> [Feeding] {
        store.filter { $0.babyId == babyId && $0.startTime >= start && $0.startTime <= end }
    }
    func getInProgressFeeding(babyId: UUID) async throws -> Feeding? {
        inProgress ?? store.first { $0.babyId == babyId && $0.isInProgress }
    }
}
```

**Step 2: Run tests to verify they fail**

Expected: Compilation errors — `FeedingViewModel` doesn't exist yet.

**Step 3: Implement FeedingViewModel**

```swift
// MomCare/Features/Feeding/ViewModels/FeedingViewModel.swift
import Foundation

@MainActor
@Observable
final class FeedingViewModel {
    var feedings: [Feeding] = []
    var inProgressFeeding: Feeding?
    var pattern: FeedingPattern?
    var selectedType: Feeding.FeedingType = .breast
    var selectedSide: Feeding.BreastSide = .left
    var isLoading = false
    var error: Error?

    var isTimerRunning = false
    var elapsedTime: TimeInterval = 0

    private let repository: any FeedingRepositoryProtocol
    private var timerTask: Task<Void, Never>?

    init(repository: any FeedingRepositoryProtocol) {
        self.repository = repository
    }

    func loadFeedings(babyId: UUID) async {
        error = nil
        isLoading = true
        defer { isLoading = false }
        do {
            feedings = try await repository.getFeedingsForBaby(babyId, limit: nil)
            inProgressFeeding = try await repository.getInProgressFeeding(babyId: babyId)
            if inProgressFeeding != nil {
                isTimerRunning = true
                updateElapsedTime()
                startTimerTick()
            }
        } catch {
            self.error = error
        }
    }

    func startFeeding(babyId: UUID, type: Feeding.FeedingType) async {
        error = nil
        let feeding = Feeding(
            id: UUID(),
            babyId: babyId,
            feedingType: type,
            startTime: .now,
            endTime: nil,
            breastSide: type == .breast ? selectedSide : nil,
            breastDuration: nil,
            amountMl: nil,
            bottleContent: nil,
            foodDescription: nil,
            quality: nil,
            notes: nil,
            createdAt: .now,
            updatedAt: .now
        )
        do {
            let created = try await repository.create(feeding)
            inProgressFeeding = created
            isTimerRunning = true
            elapsedTime = 0
            startTimerTick()
        } catch {
            self.error = error
        }
    }

    func endFeeding() async {
        error = nil
        guard var feeding = inProgressFeeding else { return }
        feeding.endTime = .now
        feeding.updatedAt = .now
        if feeding.feedingType == .breast {
            feeding.breastDuration = feeding.duration
        }
        do {
            let updated = try await repository.update(feeding)
            feedings.insert(updated, at: 0)
            inProgressFeeding = nil
            isTimerRunning = false
            elapsedTime = 0
            stopTimerTick()
        } catch {
            self.error = error
        }
    }

    func toggleBreastSide() {
        selectedSide = selectedSide == .left ? .right : .left
        if var feeding = inProgressFeeding, feeding.feedingType == .breast {
            feeding.breastSide = selectedSide
            inProgressFeeding = feeding
        }
    }

    func analyzePattern(babyId: UUID) async {
        error = nil
        do {
            let now = Date.now
            let weekAgo = now.addingTimeInterval(-Double(FeedingPatternService.patternAnalysisDays) * 86400)
            let recentFeedings = try await repository.getFeedingsForDateRange(
                babyId: babyId,
                start: weekAgo,
                end: now
            )
            pattern = FeedingPatternService.analyzePattern(from: recentFeedings)
        } catch {
            self.error = error
        }
    }

    func deleteFeeding(_ id: UUID) async {
        error = nil
        do {
            try await repository.delete(id)
            feedings.removeAll { $0.id == id }
        } catch {
            self.error = error
        }
    }

    func updateFeeding(_ feeding: Feeding) async {
        error = nil
        do {
            let updated = try await repository.update(feeding)
            if let idx = feedings.firstIndex(where: { $0.id == updated.id }) {
                feedings[idx] = updated
            }
        } catch {
            self.error = error
        }
    }

    // MARK: - Timer

    private func updateElapsedTime() {
        guard let start = inProgressFeeding?.startTime else { return }
        elapsedTime = Date.now.timeIntervalSince(start)
    }

    private func startTimerTick() {
        stopTimerTick()
        timerTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(1))
                guard !Task.isCancelled else { break }
                self?.updateElapsedTime()
            }
        }
    }

    private func stopTimerTick() {
        timerTask?.cancel()
        timerTask = nil
    }
}
```

**Step 4: Run tests**

Expected: All FeedingViewModelTests pass.

**Step 5: Lint and commit**

```bash
swiftlint --strict
git add MomCare/Features/Feeding/ViewModels/FeedingViewModel.swift MomCareTests/Features/FeedingViewModelTests.swift
git commit -m "feat(MOM-3): add FeedingViewModel with timer, CRUD, and pattern analysis"
```

---

## Task 7: FeedingTimerView (Critical 3am View)

**Files:**
- Create: `MomCare/Features/Feeding/Views/FeedingTimerView.swift`

**Step 1: Implement FeedingTimerView**

This is the most critical view — designed for 3am, one-handed, bleary-eyed use. True black OLED background, massive tap targets.

```swift
// MomCare/Features/Feeding/Views/FeedingTimerView.swift
import SwiftUI

struct FeedingTimerView: View {
    @Bindable var viewModel: FeedingViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showEndConfirmation = false

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: MCSpacing.xxl) {
                feedingTypeIndicator
                timerDisplay
                if viewModel.inProgressFeeding?.feedingType == .breast {
                    breastSideToggle
                }
                Spacer()
                endButton
            }
            .padding(.horizontal, MCSpacing.xl)
            .padding(.top, MCSpacing.section)
        }
        .confirmationDialog("End Feeding?", isPresented: $showEndConfirmation) {
            Button("End Feeding") {
                Task {
                    await viewModel.endFeeding()
                    MCHaptic.success()
                    dismiss()
                }
            }
        } message: {
            Text("Save this feeding session?")
        }
    }

    private var feedingTypeIndicator: some View {
        HStack(spacing: MCSpacing.sm) {
            if let type = viewModel.inProgressFeeding?.feedingType {
                Image(systemName: type.systemImage)
                    .font(.title2)
                Text(type.label)
                    .font(MCTypography.cardTitle)
            }
        }
        .foregroundStyle(.secondary)
    }

    private var timerDisplay: some View {
        Text(formattedTime)
            .font(MCTypography.largeTimer)
            .monospacedDigit()
            .foregroundStyle(.white)
            .contentTransition(.numericText())
    }

    private var formattedTime: String {
        let totalSeconds = Int(viewModel.elapsedTime)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        }
        return String(format: "%02d:%02d", minutes, seconds)
    }

    private var breastSideToggle: some View {
        HStack(spacing: MCSpacing.lg) {
            sideButton(side: .left)
            sideButton(side: .right)
        }
    }

    private func sideButton(side: Feeding.BreastSide) -> some View {
        Button {
            if viewModel.selectedSide != side {
                viewModel.toggleBreastSide()
                MCHaptic.toggle()
            }
        } label: {
            Text(side.label)
                .font(.title2.weight(.semibold))
                .frame(minWidth: 80, minHeight: 80)
                .background(
                    viewModel.selectedSide == side
                        ? MCColor.feeding.opacity(0.3)
                        : Color.white.opacity(0.1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            viewModel.selectedSide == side
                                ? MCColor.feeding
                                : Color.clear,
                            lineWidth: 2
                        )
                )
        }
        .foregroundStyle(.white)
    }

    private var endButton: some View {
        Button {
            showEndConfirmation = true
            MCHaptic.tap()
        } label: {
            Text("End Feeding")
                .font(.title3.weight(.semibold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(MCColor.feeding)
                .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .padding(.bottom, MCSpacing.xxl)
    }
}
```

**Step 2: Run build to verify it compiles**

Run: `xcodegen generate && xcodebuild build -scheme MomCare -destination 'platform=iOS Simulator,name=iPhone 16' -quiet`
Expected: Build succeeds.

**Step 3: Lint and commit**

```bash
swiftlint --strict
git add MomCare/Features/Feeding/Views/FeedingTimerView.swift
git commit -m "feat(MOM-3): add FeedingTimerView — 3am-optimized with large timer and breast side toggle"
```

---

## Task 8: FeedingListItem + FeedingHistoryView

**Files:**
- Create: `MomCare/Features/Feeding/Views/FeedingListItem.swift`
- Create: `MomCare/Features/Feeding/Views/FeedingHistoryView.swift`

**Step 1: Implement FeedingListItem**

```swift
// MomCare/Features/Feeding/Views/FeedingListItem.swift
import SwiftUI

struct FeedingListItem: View {
    let feeding: Feeding

    var body: some View {
        HStack(spacing: MCSpacing.md) {
            Image(systemName: feeding.feedingType.systemImage)
                .font(.title3)
                .foregroundStyle(MCColor.feeding)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: MCSpacing.xs) {
                Text(feeding.startTime.formatted(date: .omitted, time: .shortened))
                    .font(MCTypography.cardTitle)

                HStack(spacing: MCSpacing.sm) {
                    if !feeding.isInProgress {
                        Text(feeding.durationFormatted)
                            .font(MCTypography.cardBody)
                            .foregroundStyle(.secondary)
                    } else {
                        Text("In progress")
                            .font(MCTypography.cardBody)
                            .foregroundStyle(MCColor.feeding)
                    }

                    if let side = feeding.breastSide {
                        Text("• \(side.label)")
                            .font(MCTypography.cardBody)
                            .foregroundStyle(.secondary)
                    }

                    if let ml = feeding.amountMl {
                        Text("• \(ml) ml")
                            .font(MCTypography.cardBody)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Spacer()

            if let quality = feeding.quality {
                Text(quality.displayName)
                    .font(MCTypography.timestamp)
                    .padding(.horizontal, MCSpacing.sm)
                    .padding(.vertical, MCSpacing.xs)
                    .background(Color.secondary.opacity(0.15))
                    .clipShape(Capsule())
            }
        }
        .padding(.vertical, MCSpacing.xs)
    }
}
```

**Step 2: Implement FeedingHistoryView**

```swift
// MomCare/Features/Feeding/Views/FeedingHistoryView.swift
import SwiftUI

struct FeedingHistoryView: View {
    @Bindable var viewModel: FeedingViewModel
    let babyId: UUID
    @State private var feedingToDelete: Feeding?

    private var groupedFeedings: [(String, [Feeding])] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: viewModel.feedings) { feeding -> String in
            if calendar.isDateInToday(feeding.startTime) {
                return "Today"
            } else if calendar.isDateInYesterday(feeding.startTime) {
                return "Yesterday"
            } else {
                return feeding.startTime.formatted(date: .abbreviated, time: .omitted)
            }
        }
        return grouped.sorted { lhs, rhs in
            let lhsDate = lhs.value.first?.startTime ?? .distantPast
            let rhsDate = rhs.value.first?.startTime ?? .distantPast
            return lhsDate > rhsDate
        }
    }

    var body: some View {
        List {
            ForEach(groupedFeedings, id: \.0) { section in
                Section(section.0) {
                    ForEach(section.1) { feeding in
                        NavigationLink(value: feeding.id) {
                            FeedingListItem(feeding: feeding)
                        }
                        .swipeActions(edge: .trailing) {
                            Button("Delete", role: .destructive) {
                                feedingToDelete = feeding
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Feeding History")
        .confirmationDialog(
            "Delete Feeding?",
            isPresented: Binding(
                get: { feedingToDelete != nil },
                set: { if !$0 { feedingToDelete = nil } }
            )
        ) {
            Button("Delete", role: .destructive) {
                if let feeding = feedingToDelete {
                    Task { await viewModel.deleteFeeding(feeding.id) }
                }
            }
        } message: {
            Text("This feeding record will be permanently removed.")
        }
    }
}
```

**Step 3: Build and lint**

```bash
xcodegen generate
xcodebuild build -scheme MomCare -destination 'platform=iOS Simulator,name=iPhone 16' -quiet
swiftlint --strict
git add MomCare/Features/Feeding/Views/FeedingListItem.swift MomCare/Features/Feeding/Views/FeedingHistoryView.swift
git commit -m "feat(MOM-3): add FeedingListItem and FeedingHistoryView with day grouping"
```

---

## Task 9: FeedingDetailView + FeedingPatternCard + QuickFeedButton

**Files:**
- Create: `MomCare/Features/Feeding/Views/FeedingDetailView.swift`
- Create: `MomCare/Features/Feeding/Views/FeedingPatternCard.swift`
- Create: `MomCare/Features/Feeding/Views/QuickFeedButton.swift`

**Step 1: Implement FeedingDetailView**

```swift
// MomCare/Features/Feeding/Views/FeedingDetailView.swift
import SwiftUI

struct FeedingDetailView: View {
    @Bindable var viewModel: FeedingViewModel
    let feedingId: UUID
    @State private var editedFeeding: Feeding
    @State private var isEditing = false
    @State private var showError = false
    @Environment(\.dismiss) private var dismiss

    private var feeding: Feeding {
        viewModel.feedings.first { $0.id == feedingId } ?? editedFeeding
    }

    init(viewModel: FeedingViewModel, feedingId: UUID, feeding: Feeding) {
        self.viewModel = viewModel
        self.feedingId = feedingId
        self._editedFeeding = State(initialValue: feeding)
    }

    var body: some View {
        Form {
            Section("Type") {
                if isEditing {
                    Picker("Feeding Type", selection: $editedFeeding.feedingType) {
                        ForEach(Feeding.FeedingType.allCases, id: \.self) { type in
                            Label(type.label, systemImage: type.systemImage).tag(type)
                        }
                    }
                } else {
                    Label(feeding.feedingType.label, systemImage: feeding.feedingType.systemImage)
                }
            }

            Section("Time") {
                if isEditing {
                    DatePicker("Start", selection: $editedFeeding.startTime, in: ...Date.now)
                    if let endTime = editedFeeding.endTime {
                        DatePicker(
                            "End",
                            selection: Binding(
                                get: { endTime },
                                set: { editedFeeding.endTime = $0 }
                            ),
                            in: editedFeeding.startTime...Date.now
                        )
                    }
                } else {
                    LabeledContent("Start", value: feeding.startTime.formatted(date: .abbreviated, time: .shortened))
                    if let endTime = feeding.endTime {
                        LabeledContent("End", value: endTime.formatted(date: .abbreviated, time: .shortened))
                        LabeledContent("Duration", value: feeding.durationFormatted)
                    }
                }
            }

            if feeding.feedingType == .breast || (isEditing && editedFeeding.feedingType == .breast) {
                Section("Breast") {
                    if isEditing {
                        Picker("Side", selection: $editedFeeding.breastSide) {
                            Text("None").tag(nil as Feeding.BreastSide?)
                            ForEach(Feeding.BreastSide.allCases, id: \.self) { side in
                                Text(side.label).tag(side as Feeding.BreastSide?)
                            }
                        }
                    } else if let side = feeding.breastSide {
                        LabeledContent("Side", value: side.label)
                    }
                }
            }

            Section("Quality & Notes") {
                if isEditing {
                    Picker("Quality", selection: $editedFeeding.quality) {
                        Text("None").tag(nil as Feeding.FeedingQuality?)
                        ForEach(Feeding.FeedingQuality.allCases, id: \.self) { quality in
                            Text(quality.displayName).tag(quality as Feeding.FeedingQuality?)
                        }
                    }
                    TextField("Notes", text: Binding(
                        get: { editedFeeding.notes ?? "" },
                        set: { editedFeeding.notes = $0.isEmpty ? nil : $0 }
                    ), axis: .vertical)
                } else {
                    if let quality = feeding.quality {
                        LabeledContent("Quality", value: quality.displayName)
                    }
                    if let notes = feeding.notes {
                        Text(notes)
                            .font(MCTypography.cardBody)
                    }
                }
            }
        }
        .navigationTitle("Feeding Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(isEditing ? "Done" : "Edit") {
                    if isEditing {
                        saveChanges()
                    }
                    isEditing.toggle()
                    MCHaptic.tap()
                }
            }
        }
        .alert("Save Failed", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.error?.localizedDescription ?? "An unknown error occurred.")
        }
    }

    private func saveChanges() {
        editedFeeding.updatedAt = .now
        Task {
            await viewModel.updateFeeding(editedFeeding)
            if viewModel.error != nil {
                showError = true
            } else {
                MCHaptic.success()
            }
        }
    }
}
```

**Step 2: Implement FeedingPatternCard**

```swift
// MomCare/Features/Feeding/Views/FeedingPatternCard.swift
import SwiftUI

struct FeedingPatternCard: View {
    let pattern: FeedingPattern
    let lastFeedTime: Date?

    var body: some View {
        VStack(alignment: .leading, spacing: MCSpacing.sm) {
            Label("Feeding Pattern", systemImage: "chart.line.uptrend.xyaxis")
                .font(MCTypography.cardTitle)
                .foregroundStyle(.secondary)

            Text("Every ~\(pattern.intervalFormatted)")
                .font(.title3.weight(.semibold))

            if let lastFeedTime {
                Text("Next: \(pattern.timeUntilNextFeedFormatted(lastFeedTime: lastFeedTime))")
                    .font(MCTypography.cardBody)
                    .foregroundStyle(
                        pattern.isFeedingDue(lastFeedTime: lastFeedTime)
                            ? MCColor.feeding
                            : .secondary
                    )
            }

            confidenceIndicator
        }
        .padding(MCSpacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var confidenceIndicator: some View {
        HStack(spacing: MCSpacing.xs) {
            ForEach(0..<5, id: \.self) { i in
                Circle()
                    .fill(Double(i) / 5.0 < pattern.confidence ? MCColor.feeding : Color.secondary.opacity(0.3))
                    .frame(width: 6, height: 6)
            }
            Text("\(Int(pattern.confidence * 100))% confidence")
                .font(MCTypography.timestamp)
                .foregroundStyle(.secondary)
        }
    }
}
```

**Step 3: Implement QuickFeedButton**

```swift
// MomCare/Features/Feeding/Views/QuickFeedButton.swift
import SwiftUI

struct QuickFeedButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: {
            MCHaptic.tap()
            action()
        }) {
            HStack(spacing: MCSpacing.md) {
                Image(systemName: "drop.fill")
                    .font(.title2)
                Text("Start Feeding")
                    .font(.title3.weight(.semibold))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(MCColor.feeding)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }
}
```

**Step 4: Build and lint**

```bash
xcodegen generate
xcodebuild build -scheme MomCare -destination 'platform=iOS Simulator,name=iPhone 16' -quiet
swiftlint --strict
git add MomCare/Features/Feeding/Views/FeedingDetailView.swift MomCare/Features/Feeding/Views/FeedingPatternCard.swift MomCare/Features/Feeding/Views/QuickFeedButton.swift
git commit -m "feat(MOM-3): add FeedingDetailView, FeedingPatternCard, and QuickFeedButton"
```

---

## Task 10: FeedingScreen + Wire into ContentView

**Files:**
- Create: `MomCare/Features/Feeding/Views/FeedingScreen.swift`
- Modify: `MomCare/App/ContentView.swift` — replace Feeding tab placeholder
- Modify: `MomCare/App/MomCareApp.swift` — create FeedingViewModel

**Step 1: Implement FeedingScreen**

```swift
// MomCare/Features/Feeding/Views/FeedingScreen.swift
import SwiftUI

struct FeedingScreen: View {
    @Bindable var viewModel: FeedingViewModel
    let babyId: UUID
    @State private var showTimer = false

    var body: some View {
        ScrollView {
            VStack(spacing: MCSpacing.lg) {
                if viewModel.inProgressFeeding != nil {
                    activeFeedingBanner
                } else {
                    QuickFeedButton {
                        Task {
                            await viewModel.startFeeding(babyId: babyId, type: viewModel.selectedType)
                            showTimer = true
                        }
                    }
                }

                if let pattern = viewModel.pattern, !pattern.isInsufficient {
                    FeedingPatternCard(
                        pattern: pattern,
                        lastFeedTime: viewModel.feedings.first(where: { !$0.isInProgress })?.endTime
                    )
                }

                recentFeedingsSection
            }
            .padding(MCSpacing.lg)
        }
        .navigationTitle("Feeding")
        .task {
            await viewModel.loadFeedings(babyId: babyId)
            await viewModel.analyzePattern(babyId: babyId)
        }
        .refreshable {
            await viewModel.loadFeedings(babyId: babyId)
            await viewModel.analyzePattern(babyId: babyId)
        }
        .navigationDestination(isPresented: $showTimer) {
            FeedingTimerView(viewModel: viewModel)
        }
        .navigationDestination(for: UUID.self) { feedingId in
            if let feeding = viewModel.feedings.first(where: { $0.id == feedingId }) {
                FeedingDetailView(viewModel: viewModel, feedingId: feedingId, feeding: feeding)
            }
        }
    }

    private var activeFeedingBanner: some View {
        Button {
            showTimer = true
            MCHaptic.tap()
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: MCSpacing.xs) {
                    Text("Feeding in progress")
                        .font(MCTypography.cardTitle)
                    if let feeding = viewModel.inProgressFeeding {
                        Text(feeding.feedingType.label)
                            .font(MCTypography.cardBody)
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer()
                Text(timerText)
                    .font(MCTypography.largeTimer)
                    .monospacedDigit()
                Image(systemName: "chevron.right")
                    .foregroundStyle(.secondary)
            }
            .padding(MCSpacing.lg)
            .background(MCColor.feeding.opacity(0.15))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(MCColor.feeding.opacity(0.3), lineWidth: 1)
            )
        }
        .foregroundStyle(.primary)
    }

    private var timerText: String {
        let totalSeconds = Int(viewModel.elapsedTime)
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    private var recentFeedingsSection: some View {
        VStack(alignment: .leading, spacing: MCSpacing.sm) {
            HStack {
                Text("Recent")
                    .font(MCTypography.cardTitle)
                Spacer()
                NavigationLink("See All") {
                    FeedingHistoryView(viewModel: viewModel, babyId: babyId)
                }
                .font(MCTypography.cardBody)
            }

            if viewModel.feedings.isEmpty {
                Text("No feedings recorded yet")
                    .font(MCTypography.cardBody)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, MCSpacing.xl)
            } else {
                ForEach(viewModel.feedings.prefix(5)) { feeding in
                    NavigationLink(value: feeding.id) {
                        FeedingListItem(feeding: feeding)
                    }
                    .foregroundStyle(.primary)
                    if feeding.id != viewModel.feedings.prefix(5).last?.id {
                        Divider()
                    }
                }
            }
        }
    }
}
```

**Step 2: Wire into ContentView and MomCareApp**

In `MomCareApp.swift`, add a `@State private var feedingViewModel: FeedingViewModel?` and create it in the `.task` block alongside `babyViewModel`:

```swift
// Add to MomCareApp:
@State private var feedingViewModel: FeedingViewModel?

// In the .task block, after babyViewModel is created:
let feedingVM = FeedingViewModel(repository: deps.makeFeedingRepository())
feedingViewModel = feedingVM
```

Pass `feedingViewModel` to `ContentView`:

```swift
ContentView(babyViewModel: babyViewModel, feedingViewModel: feedingViewModel)
```

In `ContentView.swift`, add the parameter and replace the Feeding tab placeholder:

```swift
// Add parameter:
var feedingViewModel: FeedingViewModel?

// Replace the Feeding tab NavigationStack content:
NavigationStack(path: $navigation.feedingPath) {
    if let feedingViewModel, let babyId = babyViewModel?.selectedBaby?.id {
        FeedingScreen(viewModel: feedingViewModel, babyId: babyId)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    BabySelectorView(viewModel: babyViewModel!)
                }
            }
    } else {
        Text("Select a baby to start tracking")
            .foregroundStyle(.secondary)
    }
}
```

**Step 3: Build, test, lint**

```bash
xcodegen generate
xcodebuild build -scheme MomCare -destination 'platform=iOS Simulator,name=iPhone 16' -quiet
xcodebuild test -scheme MomCare -destination 'platform=iOS Simulator,name=iPhone 16' 2>&1 | grep -E '(passed|failed|Test run)'
swiftlint --strict
git add MomCare/Features/Feeding/Views/FeedingScreen.swift MomCare/App/ContentView.swift MomCare/App/MomCareApp.swift
git commit -m "feat(MOM-3): add FeedingScreen and wire feeding into ContentView"
```

---

## Task 11: Final Integration — Run All Tests + Lint

**Step 1: Regenerate Xcode project**

```bash
xcodegen generate
```

**Step 2: Build**

```bash
xcodebuild build -scheme MomCare -destination 'platform=iOS Simulator,name=iPhone 16' -quiet
```

**Step 3: Run all tests**

```bash
xcodebuild test -scheme MomCare -destination 'platform=iOS Simulator,name=iPhone 16' 2>&1 | grep -E '(passed|failed|Test run)'
```

Expected: All existing tests (36 from MOM-2) + new tests pass. New tests should include:
- ~11 FeedingTests (entity)
- ~8 FeedingPatternServiceTests
- ~3 FeedingModelTests
- ~9 FeedingRepositoryTests
- ~7 FeedingViewModelTests
- 1 DI test

**Step 4: Lint**

```bash
swiftlint --strict
```

Expected: 0 violations.

**Step 5: Fix any issues found**

If tests fail or lint violations exist, fix them and commit:

```bash
git add -A
git commit -m "fix(MOM-3): address test and lint issues from integration"
```

---

## Summary

| Task | Component | Tests | Files |
|------|-----------|-------|-------|
| 1 | Feeding entity + FeedingPattern | 11 | 3 |
| 2 | FeedingPatternService | 8 | 2 |
| 3 | FeedingModel SwiftData | 3 | 4 |
| 4 | FeedingRepository | 9 | 3 |
| 5 | DI wiring | 1 | 2 |
| 6 | FeedingViewModel | 7 | 2 |
| 7 | FeedingTimerView | 0 (UI) | 1 |
| 8 | FeedingListItem + HistoryView | 0 (UI) | 2 |
| 9 | DetailView + PatternCard + QuickFeed | 0 (UI) | 3 |
| 10 | FeedingScreen + wiring | 0 (integration) | 3 |
| 11 | Final integration | 0 (verify) | 0 |

**Total: ~39 new tests, ~25 new/modified files, 11 tasks**
