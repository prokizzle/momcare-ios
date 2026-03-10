# MOM-4: Self-Care Tracking Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Build an event-driven self-care tracking system with a quick-tap action grid and intelligent contextual card feed that learns baby-state-relative patterns.

**Architecture:** Two-layer UI (action grid + card feed) backed by a SelfCareEngine that scores cards based on events, patterns, and context. SelfCarePatternService learns mom's rhythm relative to baby's feeding schedule. Content library ships as bundled JSON.

**Tech Stack:** SwiftUI, SwiftData, @Observable, Swift Testing, Swift 6 strict concurrency

**Design doc:** `docs/plans/2026-03-10-mom4-self-care-design.md`

---

## Task 1: Domain Entities

**Files:**
- Create: `MomCare/Domain/Entities/SelfCareLog.swift`
- Test: `MomCareTests/Domain/SelfCareLogTests.swift`

**Step 1: Write the failing test**

```swift
// MomCareTests/Domain/SelfCareLogTests.swift
import Testing
import Foundation
@testable import MomCare

@Suite("SelfCareLog Tests")
struct SelfCareLogTests {

    @Test("SelfCareActionType has all expected cases")
    func actionTypeCases() {
        let allCases = SelfCareActionType.allCases
        #expect(allCases.count == 9)
        #expect(allCases.contains(.shower))
        #expect(allCases.contains(.brushTeeth))
        #expect(allCases.contains(.changeClothes))
        #expect(allCases.contains(.shave))
        #expect(allCases.contains(.skincare))
        #expect(allCases.contains(.meditate))
        #expect(allCases.contains(.breathingExercise))
        #expect(allCases.contains(.water))
        #expect(allCases.contains(.meal))
    }

    @Test("SelfCareActionType provides label and systemImage")
    func actionTypeDisplay() {
        #expect(SelfCareActionType.shower.label == "Shower")
        #expect(!SelfCareActionType.shower.systemImage.isEmpty)
        #expect(SelfCareActionType.water.label == "Water")
        #expect(!SelfCareActionType.water.systemImage.isEmpty)
    }

    @Test("LogDetail water case round-trips through Codable")
    func logDetailWaterCodable() throws {
        let detail = LogDetail.water(glasses: 3)
        let data = try JSONEncoder().encode(detail)
        let decoded = try JSONDecoder().decode(LogDetail.self, from: data)
        if case .water(let glasses) = decoded {
            #expect(glasses == 3)
        } else {
            Issue.record("Expected water case")
        }
    }

    @Test("LogDetail meal case round-trips through Codable")
    func logDetailMealCodable() throws {
        let detail = LogDetail.meal(.breakfast)
        let data = try JSONEncoder().encode(detail)
        let decoded = try JSONDecoder().decode(LogDetail.self, from: data)
        if case .meal(let mealType) = decoded {
            #expect(mealType == .breakfast)
        } else {
            Issue.record("Expected meal case")
        }
    }

    @Test("LogDetail freeNote case round-trips through Codable")
    func logDetailFreeNoteCodable() throws {
        let detail = LogDetail.freeNote("Felt good")
        let data = try JSONEncoder().encode(detail)
        let decoded = try JSONDecoder().decode(LogDetail.self, from: data)
        if case .freeNote(let text) = decoded {
            #expect(text == "Felt good")
        } else {
            Issue.record("Expected freeNote case")
        }
    }

    @Test("SelfCareLog fixture creates valid default")
    func fixtureDefault() {
        let log = SelfCareLog.fixture()
        #expect(log.actionType == .water)
        #expect(log.detail == nil)
    }

    @Test("MealType has all four cases")
    func mealTypeCases() {
        let allCases = MealType.allCases
        #expect(allCases.count == 4)
        #expect(allCases.contains(.breakfast))
        #expect(allCases.contains(.lunch))
        #expect(allCases.contains(.dinner))
        #expect(allCases.contains(.snack))
    }
}
```

**Step 2: Run test to verify it fails**

Run: `xcodebuild test -scheme MomCare -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:MomCareTests/SelfCareLogTests 2>&1 | tail -5`
Expected: FAIL — types not defined

**Step 3: Write minimal implementation**

```swift
// MomCare/Domain/Entities/SelfCareLog.swift
import Foundation

enum SelfCareActionType: String, Codable, CaseIterable, Sendable {
    case shower, brushTeeth, changeClothes, shave
    case skincare
    case meditate, breathingExercise
    case water, meal
}

enum MealType: String, Codable, CaseIterable, Sendable {
    case breakfast, lunch, dinner, snack
}

enum LogDetail: Codable, Sendable, Equatable {
    case water(glasses: Int)
    case meal(MealType)
    case exercise(minutes: Int)
    case freeNote(String)
}

struct SelfCareLog: Identifiable, Codable, Sendable, Equatable {
    var id: UUID
    var actionType: SelfCareActionType
    var timestamp: Date
    var detail: LogDetail?
    var createdAt: Date
    var updatedAt: Date
}

extension SelfCareLog {
    static func fixture(
        id: UUID = UUID(),
        actionType: SelfCareActionType = .water,
        timestamp: Date = .now,
        detail: LogDetail? = nil,
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) -> SelfCareLog {
        SelfCareLog(
            id: id,
            actionType: actionType,
            timestamp: timestamp,
            detail: detail,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
}

extension SelfCareActionType {
    var label: String {
        switch self {
        case .shower: "Shower"
        case .brushTeeth: "Brush Teeth"
        case .changeClothes: "Change Clothes"
        case .shave: "Shave"
        case .skincare: "Skincare"
        case .meditate: "Meditate"
        case .breathingExercise: "Breathing"
        case .water: "Water"
        case .meal: "Meal"
        }
    }

    var systemImage: String {
        switch self {
        case .shower: "drop.triangle.fill"
        case .brushTeeth: "mouth.fill"
        case .changeClothes: "tshirt.fill"
        case .shave: "scissors"
        case .skincare: "face.smiling"
        case .meditate: "brain.head.profile"
        case .breathingExercise: "wind"
        case .water: "cup.and.saucer.fill"
        case .meal: "fork.knife"
        }
    }
}

extension MealType {
    var label: String {
        switch self {
        case .breakfast: "Breakfast"
        case .lunch: "Lunch"
        case .dinner: "Dinner"
        case .snack: "Snack"
        }
    }
}
```

**Step 4: Run test to verify it passes**

Run: `xcodebuild test -scheme MomCare -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:MomCareTests/SelfCareLogTests 2>&1 | tail -5`
Expected: PASS

**Step 5: Lint and commit**

```bash
swiftlint --strict
git add MomCare/Domain/Entities/SelfCareLog.swift MomCareTests/Domain/SelfCareLogTests.swift
git commit -m "feat(MOM-4): add SelfCareLog domain entities with action types"
```

---

## Task 2: Grid Configuration Entity

**Files:**
- Create: `MomCare/Domain/Entities/SelfCareGridItem.swift`
- Test: `MomCareTests/Domain/SelfCareGridItemTests.swift`

**Step 1: Write the failing test**

```swift
// MomCareTests/Domain/SelfCareGridItemTests.swift
import Testing
import Foundation
@testable import MomCare

@Suite("SelfCareGridItem Tests")
struct SelfCareGridItemTests {

    @Test("defaultGrid returns all 9 action types")
    func defaultGridCount() {
        let grid = SelfCareGridItem.defaultGrid()
        #expect(grid.count == 9)
    }

    @Test("defaultGrid items are in expected order")
    func defaultGridOrder() {
        let grid = SelfCareGridItem.defaultGrid()
        #expect(grid[0].actionType == .water)
        #expect(grid[1].actionType == .meal)
        #expect(grid[2].actionType == .brushTeeth)
    }

    @Test("defaultGrid items are all visible and not custom")
    func defaultGridDefaults() {
        let grid = SelfCareGridItem.defaultGrid()
        for item in grid {
            #expect(item.isVisible == true)
            #expect(item.isCustom == false)
            #expect(item.customName == nil)
            #expect(item.customIcon == nil)
        }
    }

    @Test("sortOrder is sequential starting from 0")
    func defaultGridSortOrder() {
        let grid = SelfCareGridItem.defaultGrid()
        for (index, item) in grid.enumerated() {
            #expect(item.sortOrder == index)
        }
    }

    @Test("fixture creates valid default")
    func fixtureDefault() {
        let item = SelfCareGridItem.fixture()
        #expect(item.isVisible == true)
        #expect(item.isCustom == false)
    }
}
```

**Step 2: Run test to verify it fails**

Run: `xcodebuild test -scheme MomCare -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:MomCareTests/SelfCareGridItemTests 2>&1 | tail -5`
Expected: FAIL

**Step 3: Write minimal implementation**

```swift
// MomCare/Domain/Entities/SelfCareGridItem.swift
import Foundation

struct SelfCareGridItem: Identifiable, Codable, Sendable, Equatable {
    var id: UUID
    var actionType: SelfCareActionType
    var isVisible: Bool
    var sortOrder: Int
    var isCustom: Bool
    var customName: String?
    var customIcon: String?

    var displayName: String {
        customName ?? actionType.label
    }

    var displayIcon: String {
        customIcon ?? actionType.systemImage
    }
}

extension SelfCareGridItem {
    static func defaultGrid() -> [SelfCareGridItem] {
        let defaultOrder: [SelfCareActionType] = [
            .water, .meal, .brushTeeth,
            .shower, .skincare, .changeClothes,
            .meditate, .breathingExercise, .shave
        ]
        return defaultOrder.enumerated().map { index, actionType in
            SelfCareGridItem(
                id: UUID(),
                actionType: actionType,
                isVisible: true,
                sortOrder: index,
                isCustom: false
            )
        }
    }

    static func fixture(
        id: UUID = UUID(),
        actionType: SelfCareActionType = .water,
        isVisible: Bool = true,
        sortOrder: Int = 0,
        isCustom: Bool = false,
        customName: String? = nil,
        customIcon: String? = nil
    ) -> SelfCareGridItem {
        SelfCareGridItem(
            id: id,
            actionType: actionType,
            isVisible: isVisible,
            sortOrder: sortOrder,
            isCustom: isCustom,
            customName: customName,
            customIcon: customIcon
        )
    }
}
```

**Step 4: Run test to verify it passes**

**Step 5: Lint and commit**

```bash
swiftlint --strict
git add MomCare/Domain/Entities/SelfCareGridItem.swift MomCareTests/Domain/SelfCareGridItemTests.swift
git commit -m "feat(MOM-4): add SelfCareGridItem entity with default grid"
```

---

## Task 3: Content Library Types and JSON

**Files:**
- Create: `MomCare/Domain/Entities/SelfCareContent.swift`
- Create: `MomCare/Core/Content/affirmations.json`
- Create: `MomCare/Core/Content/pep-talks.json`
- Create: `MomCare/Core/Content/check-in-prompts.json`
- Create: `MomCare/Core/Content/nudge-templates.json`
- Create: `MomCare/Core/Services/ContentLibrary.swift`
- Test: `MomCareTests/Core/ContentLibraryTests.swift`

**Step 1: Write the failing test**

```swift
// MomCareTests/Core/ContentLibraryTests.swift
import Testing
import Foundation
@testable import MomCare

@Suite("ContentLibrary Tests")
struct ContentLibraryTests {

    @Test("Loads affirmations from bundle")
    func loadsAffirmations() throws {
        let library = try ContentLibrary.loadFromBundle()
        #expect(library.affirmations.count >= 20)
    }

    @Test("Loads pep talks from bundle")
    func loadsPepTalks() throws {
        let library = try ContentLibrary.loadFromBundle()
        #expect(library.pepTalks.count >= 10)
    }

    @Test("Loads check-in prompts from bundle")
    func loadsCheckInPrompts() throws {
        let library = try ContentLibrary.loadFromBundle()
        #expect(library.checkInPrompts.count >= 5)
    }

    @Test("Loads nudge templates from bundle")
    func loadsNudgeTemplates() throws {
        let library = try ContentLibrary.loadFromBundle()
        #expect(library.nudgeTemplates.count >= 5)
    }

    @Test("All affirmations have non-empty text and at least one tag")
    func affirmationQuality() throws {
        let library = try ContentLibrary.loadFromBundle()
        for affirmation in library.affirmations {
            #expect(!affirmation.text.isEmpty)
            #expect(!affirmation.tags.isEmpty)
        }
    }

    @Test("Nudge template renders with substitutions")
    func nudgeTemplateRendering() {
        let template = NudgeTemplate(
            id: "test",
            template: "You usually {action} around now.",
            type: .patternDeviation
        )
        let result = template.render(substitutions: ["action": "shower"])
        #expect(result == "You usually shower around now.")
    }

    @Test("Nudge template with missing substitution leaves placeholder")
    func nudgeTemplateMissingSub() {
        let template = NudgeTemplate(
            id: "test",
            template: "It's been {hours} hours since your last water.",
            type: .timeGap
        )
        let result = template.render(substitutions: [:])
        #expect(result == "It's been {hours} hours since your last water.")
    }
}
```

**Step 2: Run test to verify it fails**

**Step 3: Write content types**

```swift
// MomCare/Domain/Entities/SelfCareContent.swift
import Foundation

struct Affirmation: Codable, Identifiable, Sendable {
    var id: String
    var text: String
    var tags: [Tag]

    enum Tag: String, Codable, Sendable {
        case morning, evening, tired, overwhelmed
        case newMom, milestone, general
    }
}

struct PepTalk: Codable, Identifiable, Sendable {
    var id: String
    var text: String
    var tags: [Affirmation.Tag]
}

struct CheckInPrompt: Codable, Identifiable, Sendable {
    var id: String
    var text: String
    var responseOptions: [String]
}

struct NudgeTemplate: Codable, Identifiable, Sendable {
    var id: String
    var template: String
    var type: NudgeType

    enum NudgeType: String, Codable, Sendable {
        case timeGap
        case patternDeviation
        case streak
        case hydration
        case selfCareWindow
    }

    func render(substitutions: [String: String]) -> String {
        var result = template
        for (key, value) in substitutions {
            result = result.replacingOccurrences(of: "{\(key)}", with: value)
        }
        return result
    }
}
```

**Step 4: Write ContentLibrary service**

```swift
// MomCare/Core/Services/ContentLibrary.swift
import Foundation

struct ContentLibrary: Sendable {
    let affirmations: [Affirmation]
    let pepTalks: [PepTalk]
    let checkInPrompts: [CheckInPrompt]
    let nudgeTemplates: [NudgeTemplate]

    static func loadFromBundle(bundle: Bundle = .main) throws -> ContentLibrary {
        ContentLibrary(
            affirmations: try loadJSON("affirmations", bundle: bundle),
            pepTalks: try loadJSON("pep-talks", bundle: bundle),
            checkInPrompts: try loadJSON("check-in-prompts", bundle: bundle),
            nudgeTemplates: try loadJSON("nudge-templates", bundle: bundle)
        )
    }

    private static func loadJSON<T: Decodable>(_ name: String, bundle: Bundle) throws -> [T] {
        guard let url = bundle.url(forResource: name, withExtension: "json", subdirectory: nil)
              ?? bundle.url(forResource: name, withExtension: "json") else {
            throw ContentLibraryError.fileNotFound(name)
        }
        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode([T].self, from: data)
    }
}

enum ContentLibraryError: Error, LocalizedError {
    case fileNotFound(String)

    var errorDescription: String? {
        switch self {
        case .fileNotFound(let name): "Content file not found: \(name).json"
        }
    }
}
```

**Step 5: Create JSON content files**

Create `MomCare/Core/Content/affirmations.json` with 30+ affirmations (expand to 80-100 later). Each entry follows the `Affirmation` schema. Example entries:

```json
[
  {"id": "aff-001", "text": "You are doing an incredible job, even on the hard days.", "tags": ["general"]},
  {"id": "aff-002", "text": "Taking care of yourself is taking care of your baby.", "tags": ["general", "tired"]},
  ...
]
```

Create `MomCare/Core/Content/pep-talks.json` with 15+ entries.
Create `MomCare/Core/Content/check-in-prompts.json` with 10+ entries.
Create `MomCare/Core/Content/nudge-templates.json` with 10+ entries.

> **Note for implementer:** Write genuine, warm, non-guilt content following the tone guidelines in the design doc. Never imperative. Always supportive. Short. The JSON files should be substantive -- this is user-facing content that defines the product personality.

**Step 6: Run tests to verify they pass**

**Step 7: Lint and commit**

```bash
swiftlint --strict
git add MomCare/Domain/Entities/SelfCareContent.swift MomCare/Core/Services/ContentLibrary.swift MomCare/Core/Content/ MomCareTests/Core/ContentLibraryTests.swift
git commit -m "feat(MOM-4): add content library with affirmations, pep talks, prompts"
```

---

## Task 4: ActionPattern and SelfCarePatternService

**Files:**
- Create: `MomCare/Domain/Entities/ActionPattern.swift`
- Create: `MomCare/Domain/Services/SelfCarePatternService.swift`
- Test: `MomCareTests/Domain/SelfCarePatternServiceTests.swift`

**Step 1: Write the failing test**

```swift
// MomCareTests/Domain/SelfCarePatternServiceTests.swift
import Testing
import Foundation
@testable import MomCare

@Suite("SelfCarePatternService Tests")
struct SelfCarePatternServiceTests {

    @Test("Returns empty patterns when no logs")
    func emptyLogs() {
        let patterns = SelfCarePatternService.analyzePatterns(
            logs: [],
            feedingEndTimes: []
        )
        #expect(patterns.isEmpty)
    }

    @Test("Computes averageTimesPerDay for water")
    func averageTimesPerDay() {
        let now = Date.now
        var logs: [SelfCareLog] = []
        // 3 water logs per day for 3 days
        for day in 0..<3 {
            for hour in [8, 12, 18] {
                let timestamp = Calendar.current.date(
                    byAdding: .day, value: -day,
                    to: Calendar.current.date(bySettingHour: hour, minute: 0, second: 0, of: now)!
                )!
                logs.append(SelfCareLog.fixture(actionType: .water, timestamp: timestamp))
            }
        }

        let patterns = SelfCarePatternService.analyzePatterns(logs: logs, feedingEndTimes: [])
        let waterPattern = patterns.first { $0.actionType == .water }
        #expect(waterPattern != nil)
        #expect(waterPattern!.averageTimesPerDay >= 2.5)
        #expect(waterPattern!.averageTimesPerDay <= 3.5)
    }

    @Test("Detects relativeToFeeding pattern")
    func relativeToFeeding() {
        let now = Date.now
        var logs: [SelfCareLog] = []
        var feedingEndTimes: [Date] = []

        // Pattern: she showers ~20 min after each feeding, 5 data points
        for i in 0..<5 {
            let feedingEnd = now.addingTimeInterval(Double(-i) * 10800) // every 3 hours
            feedingEndTimes.append(feedingEnd)
            let showerTime = feedingEnd.addingTimeInterval(1200) // 20 min later
            logs.append(SelfCareLog.fixture(actionType: .shower, timestamp: showerTime))
        }

        let patterns = SelfCarePatternService.analyzePatterns(
            logs: logs,
            feedingEndTimes: feedingEndTimes
        )
        let showerPattern = patterns.first { $0.actionType == .shower }
        #expect(showerPattern != nil)
        #expect(showerPattern!.relativeToFeeding != nil)
        let relativeMinutes = Int(showerPattern!.relativeToFeeding! / 60)
        #expect(relativeMinutes >= 15 && relativeMinutes <= 25)
    }

    @Test("Streak counts consecutive days")
    func streakDays() {
        let now = Date.now
        var logs: [SelfCareLog] = []
        // Skincare every day for 5 days
        for day in 0..<5 {
            let timestamp = Calendar.current.date(byAdding: .day, value: -day, to: now)!
            logs.append(SelfCareLog.fixture(actionType: .skincare, timestamp: timestamp))
        }

        let patterns = SelfCarePatternService.analyzePatterns(logs: logs, feedingEndTimes: [])
        let skincarePattern = patterns.first { $0.actionType == .skincare }
        #expect(skincarePattern != nil)
        #expect(skincarePattern!.streakDays == 5)
    }

    @Test("Confidence is low with few data points")
    func lowConfidence() {
        let logs = [SelfCareLog.fixture(actionType: .meditate)]
        let patterns = SelfCarePatternService.analyzePatterns(logs: logs, feedingEndTimes: [])
        let pattern = patterns.first { $0.actionType == .meditate }
        #expect(pattern != nil)
        #expect(pattern!.confidence <= 0.4)
    }

    @Test("Confidence is high with many consistent data points")
    func highConfidence() {
        let now = Date.now
        var logs: [SelfCareLog] = []
        // Water 6x per day for 14 days = 84 data points
        for day in 0..<14 {
            for hour in [7, 9, 11, 13, 16, 20] {
                let timestamp = Calendar.current.date(
                    byAdding: .day, value: -day,
                    to: Calendar.current.date(bySettingHour: hour, minute: 0, second: 0, of: now)!
                )!
                logs.append(SelfCareLog.fixture(actionType: .water, timestamp: timestamp))
            }
        }

        let patterns = SelfCarePatternService.analyzePatterns(logs: logs, feedingEndTimes: [])
        let waterPattern = patterns.first { $0.actionType == .water }
        #expect(waterPattern != nil)
        #expect(waterPattern!.confidence >= 0.8)
    }

    @Test("Compliance measures percentage of days with at least one log")
    func compliance() {
        let now = Date.now
        var logs: [SelfCareLog] = []
        // Skincare on 5 of the last 7 days
        for day in [0, 1, 2, 4, 6] {
            let timestamp = Calendar.current.date(byAdding: .day, value: -day, to: now)!
            logs.append(SelfCareLog.fixture(actionType: .skincare, timestamp: timestamp))
        }

        let patterns = SelfCarePatternService.analyzePatterns(logs: logs, feedingEndTimes: [])
        let skincarePattern = patterns.first { $0.actionType == .skincare }
        #expect(skincarePattern != nil)
        #expect(skincarePattern!.compliance >= 0.6)
        #expect(skincarePattern!.compliance <= 0.8)
    }
}
```

**Step 2: Run test to verify it fails**

**Step 3: Write ActionPattern entity**

```swift
// MomCare/Domain/Entities/ActionPattern.swift
import Foundation

struct ActionPattern: Sendable, Equatable {
    let actionType: SelfCareActionType
    let averageTimesPerDay: Double
    let typicalTimestamps: [DateInterval]
    let relativeToFeeding: TimeInterval?
    let streakDays: Int
    let compliance: Double
    let confidence: Double
}
```

**Step 4: Write SelfCarePatternService**

```swift
// MomCare/Domain/Services/SelfCarePatternService.swift
import Foundation

enum SelfCarePatternService {
    static let analysisDays = 14
    private static let minDataPointsForRelativePattern = 3
    private static let maxRelativeToFeedingMinutes = 120
    private static let relativeToFeedingVarianceThreshold = 0.5

    static func analyzePatterns(
        logs: [SelfCareLog],
        feedingEndTimes: [Date]
    ) -> [ActionPattern] {
        let calendar = Calendar.current
        let now = Date.now
        let analysisStart = calendar.date(byAdding: .day, value: -analysisDays, to: now)!
        let recentLogs = logs.filter { $0.timestamp >= analysisStart }

        let grouped = Dictionary(grouping: recentLogs) { $0.actionType }

        return grouped.compactMap { actionType, actionLogs in
            analyzeAction(
                actionType: actionType,
                logs: actionLogs,
                feedingEndTimes: feedingEndTimes,
                analysisDays: analysisDays,
                calendar: calendar,
                now: now
            )
        }
    }

    private static func analyzeAction(
        actionType: SelfCareActionType,
        logs: [SelfCareLog],
        feedingEndTimes: [Date],
        analysisDays: Int,
        calendar: Calendar,
        now: Date
    ) -> ActionPattern {
        let sortedLogs = logs.sorted { $0.timestamp > $1.timestamp }

        // Average times per day
        let daysWithData = Set(sortedLogs.map { calendar.startOfDay(for: $0.timestamp) }).count
        let activeDays = max(daysWithData, 1)
        let averageTimesPerDay = Double(sortedLogs.count) / Double(min(activeDays, analysisDays))

        // Streak
        let streakDays = calculateStreak(logs: sortedLogs, calendar: calendar, now: now)

        // Compliance (days with at least one log / total analysis days)
        let uniqueDays = Set(sortedLogs.map { calendar.startOfDay(for: $0.timestamp) })
        let totalDays = max(analysisDays, 1)
        let compliance = Double(uniqueDays.count) / Double(totalDays)

        // Relative to feeding
        let relativeToFeeding = detectRelativeToFeeding(
            logs: sortedLogs,
            feedingEndTimes: feedingEndTimes
        )

        // Time clusters (simplified: group by hour)
        let typicalTimestamps = detectTimeClusters(logs: sortedLogs, calendar: calendar)

        // Confidence
        let confidence = calculateConfidence(
            sampleSize: sortedLogs.count,
            daysOfData: uniqueDays.count,
            hasRelativePattern: relativeToFeeding != nil
        )

        return ActionPattern(
            actionType: actionType,
            averageTimesPerDay: averageTimesPerDay,
            typicalTimestamps: typicalTimestamps,
            relativeToFeeding: relativeToFeeding,
            streakDays: streakDays,
            compliance: compliance,
            confidence: confidence
        )
    }

    private static func calculateStreak(
        logs: [SelfCareLog],
        calendar: Calendar,
        now: Date
    ) -> Int {
        let uniqueDays = Set(logs.map { calendar.startOfDay(for: $0.timestamp) })
            .sorted(by: >)

        var streak = 0
        var checkDate = calendar.startOfDay(for: now)

        for _ in 0..<365 {
            if uniqueDays.contains(checkDate) {
                streak += 1
                guard let prevDay = calendar.date(byAdding: .day, value: -1, to: checkDate) else {
                    break
                }
                checkDate = prevDay
            } else {
                break
            }
        }
        return streak
    }

    private static func detectRelativeToFeeding(
        logs: [SelfCareLog],
        feedingEndTimes: [Date]
    ) -> TimeInterval? {
        guard logs.count >= minDataPointsForRelativePattern,
              !feedingEndTimes.isEmpty else { return nil }

        let sortedFeedingEnds = feedingEndTimes.sorted()

        var offsets: [TimeInterval] = []
        for log in logs {
            // Find the closest feeding end BEFORE this log
            if let closestFeedingEnd = sortedFeedingEnds.last(where: { $0 <= log.timestamp }) {
                let offset = log.timestamp.timeIntervalSince(closestFeedingEnd)
                let offsetMinutes = offset / 60
                if offsetMinutes > 0 && offsetMinutes <= Double(maxRelativeToFeedingMinutes) {
                    offsets.append(offset)
                }
            }
        }

        guard offsets.count >= minDataPointsForRelativePattern else { return nil }

        let avg = offsets.reduce(0, +) / Double(offsets.count)
        let variance = offsets.map { ($0 - avg) * ($0 - avg) }.reduce(0, +) / Double(offsets.count)
        let stdDev = variance.squareRoot()
        let cv = avg > 0 ? stdDev / avg : 1.0

        guard cv < relativeToFeedingVarianceThreshold else { return nil }

        return avg
    }

    private static func detectTimeClusters(
        logs: [SelfCareLog],
        calendar: Calendar
    ) -> [DateInterval] {
        let hourGroups = Dictionary(grouping: logs) { calendar.component(.hour, from: $0.timestamp) }

        return hourGroups
            .filter { $0.value.count >= 2 }
            .sorted { $0.key < $1.key }
            .compactMap { hour, _ -> DateInterval? in
                guard let start = calendar.date(bySettingHour: hour, minute: 0, second: 0, of: .now),
                      let end = calendar.date(bySettingHour: hour, minute: 59, second: 59, of: .now) else {
                    return nil
                }
                return DateInterval(start: start, end: end)
            }
    }

    private static func calculateConfidence(
        sampleSize: Int,
        daysOfData: Int,
        hasRelativePattern: Bool
    ) -> Double {
        let sizeScore: Double
        if sampleSize >= 30 { sizeScore = 0.9 }
        else if sampleSize >= 15 { sizeScore = 0.7 }
        else if sampleSize >= 5 { sizeScore = 0.5 }
        else { sizeScore = 0.3 }

        let daysScore: Double
        if daysOfData >= 10 { daysScore = 0.9 }
        else if daysOfData >= 5 { daysScore = 0.6 }
        else { daysScore = 0.3 }

        let relativeBonus: Double = hasRelativePattern ? 0.1 : 0.0

        return min(sizeScore * 0.5 + daysScore * 0.5 + relativeBonus, 1.0)
    }
}
```

**Step 5: Run tests to verify they pass**

**Step 6: Lint and commit**

```bash
swiftlint --strict
git add MomCare/Domain/Entities/ActionPattern.swift MomCare/Domain/Services/SelfCarePatternService.swift MomCareTests/Domain/SelfCarePatternServiceTests.swift
git commit -m "feat(MOM-4): add SelfCarePatternService with baby-state-relative learning"
```

---

## Task 5: SwiftData Models

**Files:**
- Create: `MomCare/Data/SwiftData/SelfCareLogModel.swift`
- Create: `MomCare/Data/SwiftData/SelfCareGridItemModel.swift`
- Create: `MomCare/Data/SwiftData/ContentHistoryModel.swift`
- Modify: `MomCare/Data/SwiftData/Schema/SchemaV1.swift` — add new models (or create SchemaV2 if migration is needed)
- Test: `MomCareTests/Data/SelfCareLogModelTests.swift`
- Test: `MomCareTests/Data/SelfCareGridItemModelTests.swift`

**Step 1: Write the failing test**

```swift
// MomCareTests/Data/SelfCareLogModelTests.swift
import Testing
import Foundation
import SwiftData
@testable import MomCare

@Suite("SelfCareLogModel Tests")
struct SelfCareLogModelTests {

    @Test("Converts from entity and back")
    @MainActor
    func roundTrip() {
        let entity = SelfCareLog.fixture(
            actionType: .water,
            detail: .water(glasses: 3)
        )
        let model = SelfCareLogModel(from: entity)
        let result = model.toEntity()
        #expect(result.id == entity.id)
        #expect(result.actionType == .water)
        if case .water(let glasses) = result.detail {
            #expect(glasses == 3)
        } else {
            Issue.record("Expected water detail")
        }
    }

    @Test("Converts meal detail correctly")
    @MainActor
    func mealRoundTrip() {
        let entity = SelfCareLog.fixture(
            actionType: .meal,
            detail: .meal(.lunch)
        )
        let model = SelfCareLogModel(from: entity)
        let result = model.toEntity()
        if case .meal(let mealType) = result.detail {
            #expect(mealType == .lunch)
        } else {
            Issue.record("Expected meal detail")
        }
    }

    @Test("Handles nil detail")
    @MainActor
    func nilDetail() {
        let entity = SelfCareLog.fixture(actionType: .shower, detail: nil)
        let model = SelfCareLogModel(from: entity)
        let result = model.toEntity()
        #expect(result.detail == nil)
    }

    @Test("update(from:) applies changes")
    @MainActor
    func updateFromEntity() {
        let entity = SelfCareLog.fixture(actionType: .water)
        let model = SelfCareLogModel(from: entity)

        var updated = entity
        updated.detail = .water(glasses: 5)
        model.update(from: updated)

        let result = model.toEntity()
        if case .water(let glasses) = result.detail {
            #expect(glasses == 5)
        } else {
            Issue.record("Expected water detail after update")
        }
    }
}
```

```swift
// MomCareTests/Data/SelfCareGridItemModelTests.swift
import Testing
import Foundation
import SwiftData
@testable import MomCare

@Suite("SelfCareGridItemModel Tests")
struct SelfCareGridItemModelTests {

    @Test("Converts from entity and back")
    @MainActor
    func roundTrip() {
        let entity = SelfCareGridItem.fixture(actionType: .shower, sortOrder: 3)
        let model = SelfCareGridItemModel(from: entity)
        let result = model.toEntity()
        #expect(result.actionType == .shower)
        #expect(result.sortOrder == 3)
        #expect(result.isVisible == true)
    }

    @Test("Handles custom items")
    @MainActor
    func customItem() {
        let entity = SelfCareGridItem.fixture(
            isCustom: true,
            customName: "Vitamins",
            customIcon: "pills.fill"
        )
        let model = SelfCareGridItemModel(from: entity)
        let result = model.toEntity()
        #expect(result.isCustom == true)
        #expect(result.customName == "Vitamins")
        #expect(result.customIcon == "pills.fill")
    }
}
```

**Step 2: Run test to verify it fails**

**Step 3: Write SwiftData models**

```swift
// MomCare/Data/SwiftData/SelfCareLogModel.swift
import Foundation
import SwiftData

@Model
final class SelfCareLogModel {
    @Attribute(.unique) var id: UUID
    var actionTypeRaw: String
    var timestamp: Date
    var detailJSON: Data?
    var isSoftDeleted: Bool
    var createdAt: Date
    var updatedAt: Date

    init(from entity: SelfCareLog) {
        self.id = entity.id
        self.actionTypeRaw = entity.actionType.rawValue
        self.timestamp = entity.timestamp
        self.detailJSON = Self.encodeDetail(entity.detail)
        self.isSoftDeleted = false
        self.createdAt = entity.createdAt
        self.updatedAt = entity.updatedAt
    }

    func toEntity() -> SelfCareLog {
        SelfCareLog(
            id: id,
            actionType: SelfCareActionType(rawValue: actionTypeRaw) ?? .water,
            timestamp: timestamp,
            detail: Self.decodeDetail(detailJSON),
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }

    func update(from entity: SelfCareLog) {
        self.actionTypeRaw = entity.actionType.rawValue
        self.timestamp = entity.timestamp
        self.detailJSON = Self.encodeDetail(entity.detail)
        self.updatedAt = Date.now
    }

    private static func encodeDetail(_ detail: LogDetail?) -> Data? {
        guard let detail else { return nil }
        return try? JSONEncoder().encode(detail)
    }

    private static func decodeDetail(_ data: Data?) -> LogDetail? {
        guard let data else { return nil }
        return try? JSONDecoder().decode(LogDetail.self, from: data)
    }
}
```

```swift
// MomCare/Data/SwiftData/SelfCareGridItemModel.swift
import Foundation
import SwiftData

@Model
final class SelfCareGridItemModel {
    @Attribute(.unique) var id: UUID
    var actionTypeRaw: String
    var isVisible: Bool
    var sortOrder: Int
    var isCustom: Bool
    var customName: String?
    var customIcon: String?

    init(from entity: SelfCareGridItem) {
        self.id = entity.id
        self.actionTypeRaw = entity.actionType.rawValue
        self.isVisible = entity.isVisible
        self.sortOrder = entity.sortOrder
        self.isCustom = entity.isCustom
        self.customName = entity.customName
        self.customIcon = entity.customIcon
    }

    func toEntity() -> SelfCareGridItem {
        SelfCareGridItem(
            id: id,
            actionType: SelfCareActionType(rawValue: actionTypeRaw) ?? .water,
            isVisible: isVisible,
            sortOrder: sortOrder,
            isCustom: isCustom,
            customName: customName,
            customIcon: customIcon
        )
    }

    func update(from entity: SelfCareGridItem) {
        self.actionTypeRaw = entity.actionType.rawValue
        self.isVisible = entity.isVisible
        self.sortOrder = entity.sortOrder
        self.isCustom = entity.isCustom
        self.customName = entity.customName
        self.customIcon = entity.customIcon
    }
}
```

```swift
// MomCare/Data/SwiftData/ContentHistoryModel.swift
import Foundation
import SwiftData

@Model
final class ContentHistoryModel {
    @Attribute(.unique) var contentId: String
    var lastShownAt: Date

    init(contentId: String, lastShownAt: Date = .now) {
        self.contentId = contentId
        self.lastShownAt = lastShownAt
    }
}
```

**Step 4: Update SchemaV2 and migration plan**

Since we're adding new models, create `SchemaV2`:

```swift
// MomCare/Data/SwiftData/Schema/SchemaV2.swift
import Foundation
import SwiftData

enum SchemaV2: VersionedSchema {
    static var versionIdentifier: Schema.Version { .init(2, 0, 0) }

    static var models: [any PersistentModel.Type] {
        [
            BabyModel.self,
            FeedingModel.self,
            SelfCareLogModel.self,
            SelfCareGridItemModel.self,
            ContentHistoryModel.self
        ]
    }
}
```

Update `MomCareMigrationPlan.swift`:
```swift
enum MomCareMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] {
        [SchemaV1.self, SchemaV2.self]
    }

    static var stages: [MigrationStage] {
        [migrateV1toV2]
    }

    static let migrateV1toV2 = MigrationStage.lightweight(
        fromVersion: SchemaV1.self,
        toVersion: SchemaV2.self
    )
}
```

Update `MomCareApp.swift` to reference `SchemaV2` instead of `SchemaV1`.

Update `Dependencies.swift` to include new model types in the in-memory container.

**Step 5: Run tests to verify they pass**

**Step 6: Lint and commit**

```bash
swiftlint --strict
git add MomCare/Data/SwiftData/SelfCareLogModel.swift MomCare/Data/SwiftData/SelfCareGridItemModel.swift MomCare/Data/SwiftData/ContentHistoryModel.swift MomCare/Data/SwiftData/Schema/SchemaV2.swift MomCare/Data/SwiftData/Schema/MomCareMigrationPlan.swift MomCare/App/MomCareApp.swift MomCare/Core/DI/Dependencies.swift MomCareTests/Data/SelfCareLogModelTests.swift MomCareTests/Data/SelfCareGridItemModelTests.swift
git commit -m "feat(MOM-4): add SwiftData models for self-care logs, grid, content history"
```

---

## Task 6: Repository Protocol and Implementation

**Files:**
- Create: `MomCare/Domain/Repositories/SelfCareRepositoryProtocol.swift`
- Create: `MomCare/Data/Repositories/SelfCareRepository.swift`
- Modify: `MomCare/Core/DI/Dependencies.swift` — add `makeSelfCareRepository()`
- Test: `MomCareTests/Data/SelfCareRepositoryTests.swift`

**Step 1: Write the failing test**

```swift
// MomCareTests/Data/SelfCareRepositoryTests.swift
import Testing
import Foundation
import SwiftData
@testable import MomCare

@Suite("SelfCareRepository Tests")
struct SelfCareRepositoryTests {

    @MainActor
    private func makeSUT() throws -> SelfCareRepository {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(
            for: SelfCareLogModel.self, SelfCareGridItemModel.self, ContentHistoryModel.self,
            BabyModel.self, FeedingModel.self,
            configurations: config
        )
        let context = ModelContext(container)
        return SelfCareRepository(modelContext: context)
    }

    @Test("create inserts log and returns it")
    @MainActor
    func createLog() async throws {
        let repo = try makeSUT()
        let log = SelfCareLog.fixture(actionType: .water, detail: .water(glasses: 1))
        let created = try await repo.create(log)
        #expect(created.actionType == .water)
    }

    @Test("getLogsForDate returns only logs from that date")
    @MainActor
    func getLogsForDate() async throws {
        let repo = try makeSUT()
        let today = Date.now
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: today)!
        _ = try await repo.create(SelfCareLog.fixture(timestamp: today))
        _ = try await repo.create(SelfCareLog.fixture(timestamp: today))
        _ = try await repo.create(SelfCareLog.fixture(timestamp: yesterday))

        let logs = try await repo.getLogsForDate(today)
        #expect(logs.count == 2)
    }

    @Test("getLogsForDateRange returns logs in range")
    @MainActor
    func getLogsForDateRange() async throws {
        let repo = try makeSUT()
        let now = Date.now
        _ = try await repo.create(SelfCareLog.fixture(timestamp: now))
        _ = try await repo.create(SelfCareLog.fixture(
            timestamp: now.addingTimeInterval(-172800) // 2 days ago
        ))

        let logs = try await repo.getLogsForDateRange(
            start: now.addingTimeInterval(-86400),
            end: now.addingTimeInterval(3600)
        )
        #expect(logs.count == 1)
    }

    @Test("getLogsByActionType returns filtered logs")
    @MainActor
    func getLogsByActionType() async throws {
        let repo = try makeSUT()
        _ = try await repo.create(SelfCareLog.fixture(actionType: .water))
        _ = try await repo.create(SelfCareLog.fixture(actionType: .water))
        _ = try await repo.create(SelfCareLog.fixture(actionType: .shower))

        let waterLogs = try await repo.getLogsByActionType(.water, limit: nil)
        #expect(waterLogs.count == 2)
    }

    @Test("delete soft-deletes log")
    @MainActor
    func softDelete() async throws {
        let repo = try makeSUT()
        let log = try await repo.create(SelfCareLog.fixture())
        try await repo.delete(log.id)

        let all = try await repo.getAll()
        #expect(all.isEmpty)
    }

    @Test("getGridItems returns persisted grid configuration")
    @MainActor
    func getGridItems() async throws {
        let repo = try makeSUT()
        let items = SelfCareGridItem.defaultGrid()
        for item in items {
            try await repo.saveGridItem(item)
        }
        let retrieved = try await repo.getGridItems()
        #expect(retrieved.count == 9)
    }

    @Test("saveGridItem updates existing item")
    @MainActor
    func updateGridItem() async throws {
        let repo = try makeSUT()
        var item = SelfCareGridItem.fixture(sortOrder: 0)
        try await repo.saveGridItem(item)

        item.sortOrder = 5
        try await repo.saveGridItem(item)

        let retrieved = try await repo.getGridItems()
        #expect(retrieved.count == 1)
        #expect(retrieved.first?.sortOrder == 5)
    }

    @Test("recordContentShown persists and isContentRecentlyShown detects it")
    @MainActor
    func contentHistory() async throws {
        let repo = try makeSUT()
        try await repo.recordContentShown(contentId: "aff-001")

        let recent = try await repo.isContentRecentlyShown(
            contentId: "aff-001",
            within: 3600
        )
        #expect(recent == true)

        let notRecent = try await repo.isContentRecentlyShown(
            contentId: "aff-999",
            within: 3600
        )
        #expect(notRecent == false)
    }
}
```

**Step 2: Run test to verify it fails**

**Step 3: Write protocol**

```swift
// MomCare/Domain/Repositories/SelfCareRepositoryProtocol.swift
import Foundation

protocol SelfCareRepositoryProtocol: Repository where Entity == SelfCareLog {
    func getLogsForDate(_ date: Date) async throws -> [SelfCareLog]
    func getLogsForDateRange(start: Date, end: Date) async throws -> [SelfCareLog]
    func getLogsByActionType(_ type: SelfCareActionType, limit: Int?) async throws -> [SelfCareLog]

    func getGridItems() async throws -> [SelfCareGridItem]
    func saveGridItem(_ item: SelfCareGridItem) async throws
    func deleteGridItem(_ id: UUID) async throws

    func recordContentShown(contentId: String) async throws
    func isContentRecentlyShown(contentId: String, within seconds: TimeInterval) async throws -> Bool
}
```

**Step 4: Write repository implementation**

```swift
// MomCare/Data/Repositories/SelfCareRepository.swift
import Foundation
import SwiftData

@MainActor
final class SelfCareRepository: SelfCareRepositoryProtocol {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func getAll() async throws -> [SelfCareLog] {
        let descriptor = FetchDescriptor<SelfCareLogModel>(
            predicate: #Predicate<SelfCareLogModel> { $0.isSoftDeleted == false },
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )
        return try modelContext.fetch(descriptor).map { $0.toEntity() }
    }

    func getById(_ id: UUID) async throws -> SelfCareLog? {
        let fetchId = id
        let descriptor = FetchDescriptor<SelfCareLogModel>(
            predicate: #Predicate<SelfCareLogModel> { $0.id == fetchId && $0.isSoftDeleted == false }
        )
        return try modelContext.fetch(descriptor).first?.toEntity()
    }

    func create(_ entity: SelfCareLog) async throws -> SelfCareLog {
        let model = SelfCareLogModel(from: entity)
        modelContext.insert(model)
        try modelContext.save()
        return model.toEntity()
    }

    func update(_ entity: SelfCareLog) async throws -> SelfCareLog {
        let fetchId = entity.id
        let descriptor = FetchDescriptor<SelfCareLogModel>(
            predicate: #Predicate<SelfCareLogModel> { $0.id == fetchId }
        )
        guard let model = try modelContext.fetch(descriptor).first else {
            throw RepositoryError.notFound
        }
        model.update(from: entity)
        try modelContext.save()
        return model.toEntity()
    }

    func delete(_ id: UUID) async throws {
        let fetchId = id
        let descriptor = FetchDescriptor<SelfCareLogModel>(
            predicate: #Predicate<SelfCareLogModel> { $0.id == fetchId }
        )
        guard let model = try modelContext.fetch(descriptor).first else {
            throw RepositoryError.notFound
        }
        model.isSoftDeleted = true
        model.updatedAt = .now
        try modelContext.save()
    }

    func getLogsForDate(_ date: Date) async throws -> [SelfCareLog] {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        return try await getLogsForDateRange(start: startOfDay, end: endOfDay)
    }

    func getLogsForDateRange(start: Date, end: Date) async throws -> [SelfCareLog] {
        let fetchStart = start
        let fetchEnd = end
        let descriptor = FetchDescriptor<SelfCareLogModel>(
            predicate: #Predicate<SelfCareLogModel> {
                $0.isSoftDeleted == false &&
                $0.timestamp >= fetchStart &&
                $0.timestamp < fetchEnd
            },
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )
        return try modelContext.fetch(descriptor).map { $0.toEntity() }
    }

    func getLogsByActionType(_ type: SelfCareActionType, limit: Int?) async throws -> [SelfCareLog] {
        let typeRaw = type.rawValue
        var descriptor = FetchDescriptor<SelfCareLogModel>(
            predicate: #Predicate<SelfCareLogModel> {
                $0.isSoftDeleted == false && $0.actionTypeRaw == typeRaw
            },
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )
        if let limit {
            descriptor.fetchLimit = limit
        }
        return try modelContext.fetch(descriptor).map { $0.toEntity() }
    }

    // MARK: - Grid Items

    func getGridItems() async throws -> [SelfCareGridItem] {
        let descriptor = FetchDescriptor<SelfCareGridItemModel>(
            sortBy: [SortDescriptor(\.sortOrder)]
        )
        return try modelContext.fetch(descriptor).map { $0.toEntity() }
    }

    func saveGridItem(_ item: SelfCareGridItem) async throws {
        let fetchId = item.id
        let descriptor = FetchDescriptor<SelfCareGridItemModel>(
            predicate: #Predicate<SelfCareGridItemModel> { $0.id == fetchId }
        )
        if let existing = try modelContext.fetch(descriptor).first {
            existing.update(from: item)
        } else {
            modelContext.insert(SelfCareGridItemModel(from: item))
        }
        try modelContext.save()
    }

    func deleteGridItem(_ id: UUID) async throws {
        let fetchId = id
        let descriptor = FetchDescriptor<SelfCareGridItemModel>(
            predicate: #Predicate<SelfCareGridItemModel> { $0.id == fetchId }
        )
        guard let model = try modelContext.fetch(descriptor).first else {
            throw RepositoryError.notFound
        }
        modelContext.delete(model)
        try modelContext.save()
    }

    // MARK: - Content History

    func recordContentShown(contentId: String) async throws {
        let fetchId = contentId
        let descriptor = FetchDescriptor<ContentHistoryModel>(
            predicate: #Predicate<ContentHistoryModel> { $0.contentId == fetchId }
        )
        if let existing = try modelContext.fetch(descriptor).first {
            existing.lastShownAt = .now
        } else {
            modelContext.insert(ContentHistoryModel(contentId: contentId))
        }
        try modelContext.save()
    }

    func isContentRecentlyShown(contentId: String, within seconds: TimeInterval) async throws -> Bool {
        let fetchId = contentId
        let cutoff = Date.now.addingTimeInterval(-seconds)
        let descriptor = FetchDescriptor<ContentHistoryModel>(
            predicate: #Predicate<ContentHistoryModel> {
                $0.contentId == fetchId && $0.lastShownAt >= cutoff
            }
        )
        return try !modelContext.fetch(descriptor).isEmpty
    }
}
```

**Step 5: Update Dependencies.swift**

Add `makeSelfCareRepository()` to `DependencyContainer` protocol and `AppDependencies`. Update `DependenciesKey.defaultValue` to include the new model types.

**Step 6: Run tests to verify they pass**

**Step 7: Lint and commit**

```bash
swiftlint --strict
git add MomCare/Domain/Repositories/SelfCareRepositoryProtocol.swift MomCare/Data/Repositories/SelfCareRepository.swift MomCare/Core/DI/Dependencies.swift MomCareTests/Data/SelfCareRepositoryTests.swift
git commit -m "feat(MOM-4): add SelfCareRepository with log, grid, and content history persistence"
```

---

## Task 7: SelfCareEngine (Card Scoring)

**Files:**
- Create: `MomCare/Domain/Entities/SelfCareCard.swift`
- Create: `MomCare/Domain/Services/SelfCareEngine.swift`
- Test: `MomCareTests/Domain/SelfCareEngineTests.swift`

**Step 1: Write the failing test**

```swift
// MomCareTests/Domain/SelfCareEngineTests.swift
import Testing
import Foundation
@testable import MomCare

@Suite("SelfCareEngine Tests")
struct SelfCareEngineTests {

    private func makeEngine(
        logs: [SelfCareLog] = [],
        patterns: [ActionPattern] = [],
        library: ContentLibrary? = nil
    ) -> SelfCareEngine {
        SelfCareEngine(
            logs: logs,
            patterns: patterns,
            contentLibrary: library ?? ContentLibrary(
                affirmations: [
                    Affirmation(id: "aff-1", text: "You are doing great.", tags: [.general])
                ],
                pepTalks: [
                    PepTalk(id: "pep-1", text: "Every day you show up for your baby is a victory.", tags: [.general])
                ],
                checkInPrompts: [
                    CheckInPrompt(id: "ci-1", text: "How are you feeling?", responseOptions: ["Great", "OK", "Tired"])
                ],
                nudgeTemplates: [
                    NudgeTemplate(id: "nudge-1", template: "You usually {action} around now.", type: .patternDeviation)
                ]
            ),
            shownContentIds: [],
            currentDate: .now
        )
    }

    @Test("feedingEnded produces self-care window card")
    func feedingEndedCard() {
        let engine = makeEngine()
        let cards = engine.scoreCards(after: .feedingEnded(babyId: UUID(), duration: 1200))
        let windowCard = cards.first { $0.type == .selfCareWindow }
        #expect(windowCard != nil)
        #expect(windowCard!.score > 0.5)
    }

    @Test("Hydration nudge appears when no water logged in 2+ hours")
    func hydrationNudge() {
        let oldWaterLog = SelfCareLog.fixture(
            actionType: .water,
            timestamp: Date.now.addingTimeInterval(-7200 - 60)
        )
        let engine = makeEngine(logs: [oldWaterLog])
        let cards = engine.scoreCards(after: .timeTick)
        let hydrationCard = cards.first { $0.type == .hydrationNudge }
        #expect(hydrationCard != nil)
    }

    @Test("No hydration nudge when water logged recently")
    func noHydrationNudgeWhenRecent() {
        let recentWater = SelfCareLog.fixture(
            actionType: .water,
            timestamp: Date.now.addingTimeInterval(-1800)
        )
        let engine = makeEngine(logs: [recentWater])
        let cards = engine.scoreCards(after: .timeTick)
        let hydrationCard = cards.first { $0.type == .hydrationNudge }
        #expect(hydrationCard == nil)
    }

    @Test("Affirmation card appears periodically")
    func affirmationCard() {
        let engine = makeEngine()
        let cards = engine.scoreCards(after: .appOpened)
        let affirmationCard = cards.first { $0.type == .affirmation }
        #expect(affirmationCard != nil)
    }

    @Test("Streak card appears for 3+ day streaks")
    func streakCard() {
        let showerPattern = ActionPattern(
            actionType: .shower,
            averageTimesPerDay: 1.0,
            typicalTimestamps: [],
            relativeToFeeding: nil,
            streakDays: 4,
            compliance: 0.8,
            confidence: 0.7
        )
        let engine = makeEngine(patterns: [showerPattern])
        let cards = engine.scoreCards(after: .timeTick)
        let streakCard = cards.first { $0.type == .streak }
        #expect(streakCard != nil)
        #expect(streakCard!.message.contains("4"))
    }

    @Test("Empty card list when nothing scores above threshold")
    func emptyWhenBelowThreshold() {
        let recentWater = SelfCareLog.fixture(
            actionType: .water,
            timestamp: Date.now.addingTimeInterval(-300)
        )
        // All recent, no patterns, no streaks -- should produce mostly low scores
        let engine = makeEngine(
            logs: [recentWater],
            patterns: [],
            library: ContentLibrary(
                affirmations: [], pepTalks: [],
                checkInPrompts: [], nudgeTemplates: []
            )
        )
        let cards = engine.scoreCards(after: .timeTick)
        // With empty content library and recent activity, very few cards should score
        #expect(cards.count <= 1) // possibly just the empty-state card or nothing
    }

    @Test("Cards are sorted by score descending")
    func cardsSortedByScore() {
        let engine = makeEngine()
        let cards = engine.scoreCards(after: .feedingEnded(babyId: UUID(), duration: 1200))
        for i in 0..<(cards.count - 1) {
            #expect(cards[i].score >= cards[i + 1].score)
        }
    }

    @Test("Pattern-based nudge fires when relativeToFeeding matches")
    func patternNudge() {
        let showerPattern = ActionPattern(
            actionType: .shower,
            averageTimesPerDay: 1.0,
            typicalTimestamps: [],
            relativeToFeeding: 1200, // 20 minutes after feeding
            streakDays: 5,
            compliance: 0.8,
            confidence: 0.8
        )
        let engine = makeEngine(patterns: [showerPattern])
        let cards = engine.scoreCards(after: .feedingEnded(babyId: UUID(), duration: 900))
        let nudgeCard = cards.first { $0.type == .gentleNudge }
        #expect(nudgeCard != nil)
    }
}
```

**Step 2: Run test to verify it fails**

**Step 3: Write SelfCareCard entity**

```swift
// MomCare/Domain/Entities/SelfCareCard.swift
import Foundation

struct SelfCareCard: Identifiable, Sendable {
    var id: UUID
    var type: CardType
    var message: String
    var score: Double
    var relatedAction: SelfCareActionType?
    var timestamp: Date

    enum CardType: String, Sendable {
        case selfCareWindow
        case hydrationNudge
        case affirmation
        case pepTalk
        case checkIn
        case streak
        case gentleNudge
    }
}
```

**Step 4: Write SelfCareEngine**

The engine is a pure function service (like FeedingPatternService) -- takes state in, returns scored cards out. No side effects, fully testable.

```swift
// MomCare/Domain/Services/SelfCareEngine.swift
import Foundation

struct SelfCareEngine: Sendable {
    let logs: [SelfCareLog]
    let patterns: [ActionPattern]
    let contentLibrary: ContentLibrary
    let shownContentIds: [String]
    let currentDate: Date

    private static let scoreThreshold = 0.2
    private static let hydrationGapSeconds: TimeInterval = 7200
    private static let minStreakForCard = 3

    func scoreCards(after event: SelfCareEvent) -> [SelfCareCard] {
        var candidates: [SelfCareCard] = []

        candidates.append(contentsOf: scoreSelfCareWindow(event: event))
        candidates.append(contentsOf: scoreHydrationNudge())
        candidates.append(contentsOf: scoreAffirmation(event: event))
        candidates.append(contentsOf: scorePepTalk())
        candidates.append(contentsOf: scoreCheckIn())
        candidates.append(contentsOf: scoreStreaks())
        candidates.append(contentsOf: scorePatternNudges(event: event))

        return candidates
            .filter { $0.score >= Self.scoreThreshold }
            .sorted { $0.score > $1.score }
    }

    // MARK: - Individual card scorers

    private func scoreSelfCareWindow(event: SelfCareEvent) -> [SelfCareCard] {
        guard case .feedingEnded = event else { return [] }
        return [SelfCareCard(
            id: UUID(),
            type: .selfCareWindow,
            message: "You have a moment. What do you need?",
            score: 0.9,
            relatedAction: nil,
            timestamp: currentDate
        )]
    }

    private func scoreHydrationNudge() -> [SelfCareCard] {
        let lastWater = logs
            .filter { $0.actionType == .water }
            .max { $0.timestamp < $1.timestamp }

        let gap: TimeInterval
        if let lastWater {
            gap = currentDate.timeIntervalSince(lastWater.timestamp)
        } else {
            gap = Self.hydrationGapSeconds + 1
        }

        guard gap >= Self.hydrationGapSeconds else { return [] }

        let hours = Int(gap / 3600)
        let score = min(0.3 + Double(hours) * 0.1, 0.8)

        return [SelfCareCard(
            id: UUID(),
            type: .hydrationNudge,
            message: "Staying hydrated helps you keep going.",
            score: score,
            relatedAction: .water,
            timestamp: currentDate
        )]
    }

    private func scoreAffirmation(event: SelfCareEvent) -> [SelfCareCard] {
        guard !contentLibrary.affirmations.isEmpty else { return [] }

        let available = contentLibrary.affirmations.filter { !shownContentIds.contains($0.id) }
        guard let affirmation = available.first ?? contentLibrary.affirmations.first else { return [] }

        let score: Double
        switch event {
        case .appOpened: score = 0.6
        case .feedingEnded: score = 0.4
        default: score = 0.3
        }

        return [SelfCareCard(
            id: UUID(),
            type: .affirmation,
            message: affirmation.text,
            score: score,
            relatedAction: nil,
            timestamp: currentDate
        )]
    }

    private func scorePepTalk() -> [SelfCareCard] {
        guard !contentLibrary.pepTalks.isEmpty else { return [] }
        let todayLogCount = logs.filter {
            Calendar.current.isDate($0.timestamp, inSameDayAs: currentDate)
        }.count

        guard todayLogCount <= 2 else { return [] }

        let available = contentLibrary.pepTalks.filter { !shownContentIds.contains($0.id) }
        guard let pepTalk = available.first ?? contentLibrary.pepTalks.first else { return [] }

        return [SelfCareCard(
            id: UUID(),
            type: .pepTalk,
            message: pepTalk.text,
            score: 0.35,
            relatedAction: nil,
            timestamp: currentDate
        )]
    }

    private func scoreCheckIn() -> [SelfCareCard] {
        guard !contentLibrary.checkInPrompts.isEmpty else { return [] }
        let available = contentLibrary.checkInPrompts.filter { !shownContentIds.contains($0.id) }
        guard let prompt = available.first ?? contentLibrary.checkInPrompts.first else { return [] }

        return [SelfCareCard(
            id: UUID(),
            type: .checkIn,
            message: prompt.text,
            score: 0.25,
            relatedAction: nil,
            timestamp: currentDate
        )]
    }

    private func scoreStreaks() -> [SelfCareCard] {
        patterns
            .filter { $0.streakDays >= Self.minStreakForCard }
            .map { pattern in
                SelfCareCard(
                    id: UUID(),
                    type: .streak,
                    message: "\(pattern.streakDays) days of \(pattern.actionType.label.lowercased()) -- look at you.",
                    score: 0.5 + min(Double(pattern.streakDays) * 0.05, 0.3),
                    relatedAction: pattern.actionType,
                    timestamp: currentDate
                )
            }
    }

    private func scorePatternNudges(event: SelfCareEvent) -> [SelfCareCard] {
        guard case .feedingEnded = event else { return [] }

        return patterns
            .filter { $0.relativeToFeeding != nil && $0.confidence >= 0.5 }
            .compactMap { pattern in
                let template = contentLibrary.nudgeTemplates.first { $0.type == .patternDeviation }
                let message = template?.render(substitutions: [
                    "action": pattern.actionType.label.lowercased()
                ]) ?? "You usually \(pattern.actionType.label.lowercased()) around now."

                return SelfCareCard(
                    id: UUID(),
                    type: .gentleNudge,
                    message: message,
                    score: 0.4 * pattern.confidence,
                    relatedAction: pattern.actionType,
                    timestamp: currentDate
                )
            }
    }
}
```

**Step 5: Write the SelfCareEvent enum (if not already created)**

Add to `SelfCareEngine.swift` or its own file:

```swift
enum SelfCareEvent: Sendable {
    case feedingEnded(babyId: UUID, duration: TimeInterval)
    case feedingStarted(babyId: UUID)
    case selfCareLogged(SelfCareLog)
    case appOpened
    case timeTick
}
```

**Step 6: Run tests to verify they pass**

**Step 7: Lint and commit**

```bash
swiftlint --strict
git add MomCare/Domain/Entities/SelfCareCard.swift MomCare/Domain/Services/SelfCareEngine.swift MomCareTests/Domain/SelfCareEngineTests.swift
git commit -m "feat(MOM-4): add SelfCareEngine with event-driven card scoring"
```

---

## Task 8: SelfCareViewModel

**Files:**
- Create: `MomCare/Features/SelfCare/ViewModels/SelfCareViewModel.swift`
- Test: `MomCareTests/Features/SelfCareViewModelTests.swift`

**Step 1: Write the failing test**

```swift
// MomCareTests/Features/SelfCareViewModelTests.swift
import Testing
import Foundation
@testable import MomCare

@Suite("SelfCareViewModel Tests")
struct SelfCareViewModelTests {

    @MainActor
    private func makeSUT(
        logs: [SelfCareLog] = [],
        gridItems: [SelfCareGridItem] = SelfCareGridItem.defaultGrid()
    ) -> SelfCareViewModel {
        let repo = StubSelfCareRepository(logs: logs, gridItems: gridItems)
        let library = ContentLibrary(
            affirmations: [Affirmation(id: "a1", text: "Test", tags: [.general])],
            pepTalks: [],
            checkInPrompts: [],
            nudgeTemplates: []
        )
        return SelfCareViewModel(repository: repo, contentLibrary: library)
    }

    @Test("loadDay populates logs and grid items")
    @MainActor
    func loadDay() async {
        let log = SelfCareLog.fixture(actionType: .water, timestamp: .now)
        let sut = makeSUT(logs: [log])
        await sut.loadDay(.now)
        #expect(sut.todayLogs.count == 1)
        #expect(sut.gridItems.count == 9)
    }

    @Test("logAction creates a new log and refreshes state")
    @MainActor
    func logAction() async {
        let sut = makeSUT()
        await sut.loadDay(.now)
        await sut.logAction(.water)
        #expect(sut.todayLogs.count == 1)
        #expect(sut.todayLogs.first?.actionType == .water)
    }

    @Test("logAction with detail attaches detail")
    @MainActor
    func logActionWithDetail() async {
        let sut = makeSUT()
        await sut.loadDay(.now)
        await sut.logAction(.water, detail: .water(glasses: 2))
        #expect(sut.todayLogs.first?.detail != nil)
        if case .water(let glasses) = sut.todayLogs.first?.detail {
            #expect(glasses == 2)
        }
    }

    @Test("waterCountToday counts water logs for today")
    @MainActor
    func waterCount() async {
        let sut = makeSUT(logs: [
            SelfCareLog.fixture(actionType: .water, timestamp: .now),
            SelfCareLog.fixture(actionType: .water, timestamp: .now),
            SelfCareLog.fixture(actionType: .shower, timestamp: .now)
        ])
        await sut.loadDay(.now)
        #expect(sut.waterCountToday == 2)
    }

    @Test("handleEvent updates cards")
    @MainActor
    func handleEvent() async {
        let sut = makeSUT()
        await sut.loadDay(.now)
        await sut.handleEvent(.appOpened)
        #expect(!sut.cards.isEmpty)
    }

    @Test("recentlyTappedActions tracks last tap time")
    @MainActor
    func recentlyTapped() async {
        let sut = makeSUT()
        await sut.loadDay(.now)
        await sut.logAction(.shower)
        #expect(sut.isRecentlyTapped(.shower))
    }
}

@MainActor
private final class StubSelfCareRepository: SelfCareRepositoryProtocol {
    private var logStore: [SelfCareLog]
    private var gridStore: [SelfCareGridItem]
    private var contentHistory: [String: Date] = [:]

    init(logs: [SelfCareLog] = [], gridItems: [SelfCareGridItem] = []) {
        self.logStore = logs
        self.gridStore = gridItems
    }

    func getAll() async throws -> [SelfCareLog] { logStore.filter { true } }
    func getById(_ id: UUID) async throws -> SelfCareLog? { logStore.first { $0.id == id } }
    func create(_ entity: SelfCareLog) async throws -> SelfCareLog {
        logStore.append(entity)
        return entity
    }
    func update(_ entity: SelfCareLog) async throws -> SelfCareLog {
        if let idx = logStore.firstIndex(where: { $0.id == entity.id }) {
            logStore[idx] = entity
        }
        return entity
    }
    func delete(_ id: UUID) async throws {
        logStore.removeAll { $0.id == id }
    }

    func getLogsForDate(_ date: Date) async throws -> [SelfCareLog] {
        logStore.filter { Calendar.current.isDate($0.timestamp, inSameDayAs: date) }
    }
    func getLogsForDateRange(start: Date, end: Date) async throws -> [SelfCareLog] {
        logStore.filter { $0.timestamp >= start && $0.timestamp < end }
    }
    func getLogsByActionType(_ type: SelfCareActionType, limit: Int?) async throws -> [SelfCareLog] {
        let filtered = logStore.filter { $0.actionType == type }
        if let limit { return Array(filtered.prefix(limit)) }
        return filtered
    }

    func getGridItems() async throws -> [SelfCareGridItem] { gridStore }
    func saveGridItem(_ item: SelfCareGridItem) async throws {
        if let idx = gridStore.firstIndex(where: { $0.id == item.id }) {
            gridStore[idx] = item
        } else {
            gridStore.append(item)
        }
    }
    func deleteGridItem(_ id: UUID) async throws {
        gridStore.removeAll { $0.id == id }
    }

    func recordContentShown(contentId: String) async throws {
        contentHistory[contentId] = .now
    }
    func isContentRecentlyShown(contentId: String, within seconds: TimeInterval) async throws -> Bool {
        guard let shown = contentHistory[contentId] else { return false }
        return Date.now.timeIntervalSince(shown) < seconds
    }
}
```

**Step 2: Run test to verify it fails**

**Step 3: Write SelfCareViewModel**

```swift
// MomCare/Features/SelfCare/ViewModels/SelfCareViewModel.swift
import Foundation

@MainActor
@Observable
final class SelfCareViewModel {
    var todayLogs: [SelfCareLog] = []
    var gridItems: [SelfCareGridItem] = []
    var cards: [SelfCareCard] = []
    var patterns: [ActionPattern] = []
    var isLoading = false
    var error: Error?

    private let repository: any SelfCareRepositoryProtocol
    private let contentLibrary: ContentLibrary
    private var recentTaps: [SelfCareActionType: Date] = [:]
    private var shownContentIds: [String] = []
    private var allRecentLogs: [SelfCareLog] = []
    private var feedingEndTimes: [Date] = []

    init(repository: any SelfCareRepositoryProtocol, contentLibrary: ContentLibrary) {
        self.repository = repository
        self.contentLibrary = contentLibrary
    }

    var waterCountToday: Int {
        todayLogs.filter { $0.actionType == .water }.count
    }

    func isRecentlyTapped(_ actionType: SelfCareActionType) -> Bool {
        guard let lastTap = recentTaps[actionType] else { return false }
        return Date.now.timeIntervalSince(lastTap) < 7200 // 2 hours
    }

    func loadDay(_ date: Date) async {
        error = nil
        isLoading = true
        defer { isLoading = false }

        do {
            todayLogs = try await repository.getLogsForDate(date)

            let analysisStart = Calendar.current.date(
                byAdding: .day, value: -SelfCarePatternService.analysisDays, to: date
            )!
            allRecentLogs = try await repository.getLogsForDateRange(
                start: analysisStart,
                end: date.addingTimeInterval(86400)
            )

            let existingGrid = try await repository.getGridItems()
            if existingGrid.isEmpty {
                let defaults = SelfCareGridItem.defaultGrid()
                for item in defaults {
                    try await repository.saveGridItem(item)
                }
                gridItems = defaults
            } else {
                gridItems = existingGrid
            }

            patterns = SelfCarePatternService.analyzePatterns(
                logs: allRecentLogs,
                feedingEndTimes: feedingEndTimes
            )

            // Populate recent taps from today's logs
            for log in todayLogs {
                if let existing = recentTaps[log.actionType] {
                    if log.timestamp > existing {
                        recentTaps[log.actionType] = log.timestamp
                    }
                } else {
                    recentTaps[log.actionType] = log.timestamp
                }
            }
        } catch {
            self.error = error
        }
    }

    func logAction(_ actionType: SelfCareActionType, detail: LogDetail? = nil) async {
        let log = SelfCareLog(
            id: UUID(),
            actionType: actionType,
            timestamp: .now,
            detail: detail,
            createdAt: .now,
            updatedAt: .now
        )

        do {
            let created = try await repository.create(log)
            todayLogs.insert(created, at: 0)
            allRecentLogs.insert(created, at: 0)
            recentTaps[actionType] = .now

            patterns = SelfCarePatternService.analyzePatterns(
                logs: allRecentLogs,
                feedingEndTimes: feedingEndTimes
            )

            await handleEvent(.selfCareLogged(created))
        } catch {
            self.error = error
        }
    }

    func handleEvent(_ event: SelfCareEvent) async {
        if case .feedingEnded(_, _) = event {
            feedingEndTimes.append(.now)
        }

        let engine = SelfCareEngine(
            logs: allRecentLogs,
            patterns: patterns,
            contentLibrary: contentLibrary,
            shownContentIds: shownContentIds,
            currentDate: .now
        )

        cards = engine.scoreCards(after: event)

        // Track shown content
        for card in cards where card.type == .affirmation || card.type == .pepTalk || card.type == .checkIn {
            if !shownContentIds.contains(card.message) {
                shownContentIds.append(card.message)
            }
        }
    }

    func dismissCard(_ id: UUID) {
        cards.removeAll { $0.id == id }
    }
}
```

**Step 4: Run tests to verify they pass**

**Step 5: Lint and commit**

```bash
swiftlint --strict
git add MomCare/Features/SelfCare/ViewModels/SelfCareViewModel.swift MomCareTests/Features/SelfCareViewModelTests.swift
git commit -m "feat(MOM-4): add SelfCareViewModel with event handling and pattern integration"
```

---

## Task 9: Action Grid View

**Files:**
- Create: `MomCare/Features/SelfCare/Views/ActionGridView.swift`
- Create: `MomCare/Features/SelfCare/Views/ActionGridItemView.swift`

> **Note:** This is the UI layer. No separate test file -- UI is validated by building + running. ViewModel tests cover the logic.

**Step 1: Write ActionGridItemView**

```swift
// MomCare/Features/SelfCare/Views/ActionGridItemView.swift
import SwiftUI

struct ActionGridItemView: View {
    let item: SelfCareGridItem
    let isRecentlyTapped: Bool
    let waterCount: Int?
    let onTap: () -> Void
    let onLongPress: () -> Void

    @State private var isAnimating = false

    var body: some View {
        Button {
            MCHaptic.tap()
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                isAnimating = true
            }
            onTap()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                isAnimating = false
            }
        } label: {
            VStack(spacing: MCSpacing.xs) {
                ZStack(alignment: .topTrailing) {
                    Image(systemName: item.displayIcon)
                        .font(.title2)
                        .frame(width: 28, height: 28)

                    if let waterCount, item.actionType == .water, waterCount > 0 {
                        Text("x\(waterCount)")
                            .font(.caption2.bold())
                            .foregroundStyle(.secondary)
                            .offset(x: 8, y: -4)
                    }
                }

                Text(item.displayName)
                    .font(.caption2)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 80)
            .background {
                RoundedRectangle(cornerRadius: 16)
                    .fill(.ultraThinMaterial)
                    .overlay {
                        if isRecentlyTapped {
                            RoundedRectangle(cornerRadius: 16)
                                .fill(MCColor.selfCare.opacity(0.15))
                        }
                    }
            }
            .scaleEffect(isAnimating ? 0.92 : 1.0)
        }
        .buttonStyle(.plain)
        .simultaneousGesture(
            LongPressGesture(minimumDuration: 0.5)
                .onEnded { _ in
                    MCHaptic.toggle()
                    onLongPress()
                }
        )
        .accessibilityLabel(item.displayName)
        .accessibilityHint(isRecentlyTapped ? "Logged recently" : "Tap to log")
    }
}
```

**Step 2: Write ActionGridView**

```swift
// MomCare/Features/SelfCare/Views/ActionGridView.swift
import SwiftUI

struct ActionGridView: View {
    let gridItems: [SelfCareGridItem]
    let recentlyTapped: (SelfCareActionType) -> Bool
    let waterCount: Int
    let onTap: (SelfCareActionType) -> Void
    let onLongPress: (SelfCareActionType) -> Void

    private let columns = Array(repeating: GridItem(.flexible(), spacing: MCSpacing.sm), count: 3)

    var body: some View {
        LazyVGrid(columns: columns, spacing: MCSpacing.sm) {
            ForEach(gridItems.filter(\.isVisible).sorted { $0.sortOrder < $1.sortOrder }) { item in
                ActionGridItemView(
                    item: item,
                    isRecentlyTapped: recentlyTapped(item.actionType),
                    waterCount: item.actionType == .water ? waterCount : nil,
                    onTap: { onTap(item.actionType) },
                    onLongPress: { onLongPress(item.actionType) }
                )
            }
        }
        .padding(.horizontal, MCSpacing.lg)
    }
}
```

**Step 3: Build to verify compilation**

Run: `xcodebuild build -scheme MomCare -destination 'platform=iOS Simulator,name=iPhone 16' 2>&1 | tail -5`

**Step 4: Lint and commit**

```bash
swiftlint --strict
git add MomCare/Features/SelfCare/Views/ActionGridView.swift MomCare/Features/SelfCare/Views/ActionGridItemView.swift
git commit -m "feat(MOM-4): add action grid with warm glow, haptics, and water badge"
```

---

## Task 10: Card Feed View

**Files:**
- Create: `MomCare/Features/SelfCare/Views/SelfCareCardView.swift`
- Create: `MomCare/Features/SelfCare/Views/CardFeedView.swift`

**Step 1: Write SelfCareCardView**

```swift
// MomCare/Features/SelfCare/Views/SelfCareCardView.swift
import SwiftUI

struct SelfCareCardView: View {
    let card: SelfCareCard
    let onDismiss: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: MCSpacing.md) {
            Image(systemName: iconForCardType(card.type))
                .font(.title3)
                .foregroundStyle(colorForCardType(card.type))
                .frame(width: 24)

            VStack(alignment: .leading, spacing: MCSpacing.xs) {
                if card.type == .streak {
                    Text("Streak")
                        .font(.caption.bold())
                        .foregroundStyle(MCColor.selfCare)
                }
                Text(card.message)
                    .font(MCTypography.cardBody)
                    .foregroundStyle(.primary)
            }

            Spacer()
        }
        .padding(MCSpacing.lg)
        .background {
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
        }
        .accessibilityElement(children: .combine)
    }

    private func iconForCardType(_ type: SelfCareCard.CardType) -> String {
        switch type {
        case .selfCareWindow: "sparkles"
        case .hydrationNudge: "cup.and.saucer.fill"
        case .affirmation: "heart.fill"
        case .pepTalk: "sun.max.fill"
        case .checkIn: "face.smiling"
        case .streak: "flame.fill"
        case .gentleNudge: "leaf.fill"
        }
    }

    private func colorForCardType(_ type: SelfCareCard.CardType) -> Color {
        switch type {
        case .selfCareWindow: MCColor.selfCare
        case .hydrationNudge: .blue
        case .affirmation: .pink
        case .pepTalk: .orange
        case .checkIn: .purple
        case .streak: MCColor.selfCare
        case .gentleNudge: .green
        }
    }
}
```

**Step 2: Write CardFeedView**

```swift
// MomCare/Features/SelfCare/Views/CardFeedView.swift
import SwiftUI

struct CardFeedView: View {
    let cards: [SelfCareCard]
    let onDismiss: (UUID) -> Void

    var body: some View {
        if cards.isEmpty {
            emptyState
        } else {
            LazyVStack(spacing: MCSpacing.md) {
                ForEach(cards) { card in
                    SelfCareCardView(card: card, onDismiss: { onDismiss(card.id) })
                        .transition(.asymmetric(
                            insertion: .opacity.combined(with: .move(edge: .top)),
                            removal: .opacity.combined(with: .move(edge: .trailing))
                        ))
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) {
                                onDismiss(card.id)
                            } label: {
                                Label("Dismiss", systemImage: "xmark")
                            }
                        }
                }
            }
            .padding(.horizontal, MCSpacing.lg)
            .animation(.easeInOut(duration: 0.3), value: cards.map(\.id))
        }
    }

    private var emptyState: some View {
        Text("Everything's good. You know what you need.")
            .font(MCTypography.cardBody)
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.center)
            .padding(.vertical, MCSpacing.xxl)
            .padding(.horizontal, MCSpacing.lg)
    }
}
```

**Step 3: Build to verify compilation**

**Step 4: Lint and commit**

```bash
swiftlint --strict
git add MomCare/Features/SelfCare/Views/SelfCareCardView.swift MomCare/Features/SelfCare/Views/CardFeedView.swift
git commit -m "feat(MOM-4): add contextual card feed with dismiss and empty state"
```

---

## Task 11: SelfCareScreen (Main Tab) and Detail Sheet

**Files:**
- Create: `MomCare/Features/SelfCare/Views/SelfCareScreen.swift`
- Create: `MomCare/Features/SelfCare/Views/LogDetailSheet.swift`
- Modify: `MomCare/App/ContentView.swift` — wire in SelfCareScreen
- Modify: `MomCare/App/MomCareApp.swift` — create SelfCareViewModel

**Step 1: Write LogDetailSheet**

```swift
// MomCare/Features/SelfCare/Views/LogDetailSheet.swift
import SwiftUI

struct LogDetailSheet: View {
    let actionType: SelfCareActionType
    let onSave: (LogDetail) -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var glasses = 1
    @State private var selectedMealType: MealType = .breakfast
    @State private var exerciseMinutes = 30
    @State private var note = ""

    var body: some View {
        NavigationStack {
            Form {
                switch actionType {
                case .water:
                    Stepper("Glasses: \(glasses)", value: $glasses, in: 1...20)
                case .meal:
                    Picker("Meal", selection: $selectedMealType) {
                        ForEach(MealType.allCases, id: \.self) { type in
                            Text(type.label).tag(type)
                        }
                    }
                    .pickerStyle(.segmented)
                default:
                    Section("Notes") {
                        TextField("Optional note", text: $note, axis: .vertical)
                            .lineLimit(3...6)
                    }
                }
            }
            .navigationTitle(actionType.label)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        MCHaptic.success()
                        let detail: LogDetail
                        switch actionType {
                        case .water:
                            detail = .water(glasses: glasses)
                        case .meal:
                            detail = .meal(selectedMealType)
                        default:
                            detail = note.isEmpty ? .freeNote("") : .freeNote(note)
                        }
                        onSave(detail)
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }
}
```

**Step 2: Write SelfCareScreen**

```swift
// MomCare/Features/SelfCare/Views/SelfCareScreen.swift
import SwiftUI

struct SelfCareScreen: View {
    var viewModel: SelfCareViewModel?

    @State private var showDetailSheet = false
    @State private var detailActionType: SelfCareActionType?

    var body: some View {
        Group {
            if let viewModel {
                loadedView(viewModel: viewModel)
            } else {
                ProgressView()
            }
        }
        .navigationTitle("Self-Care")
    }

    @ViewBuilder
    private func loadedView(viewModel: SelfCareViewModel) -> some View {
        ScrollView {
            VStack(spacing: MCSpacing.xl) {
                ActionGridView(
                    gridItems: viewModel.gridItems,
                    recentlyTapped: { viewModel.isRecentlyTapped($0) },
                    waterCount: viewModel.waterCountToday,
                    onTap: { actionType in
                        Task { await viewModel.logAction(actionType) }
                    },
                    onLongPress: { actionType in
                        detailActionType = actionType
                        showDetailSheet = true
                    }
                )

                CardFeedView(
                    cards: viewModel.cards,
                    onDismiss: { viewModel.dismissCard($0) }
                )
            }
            .padding(.vertical, MCSpacing.lg)
        }
        .task {
            await viewModel.loadDay(.now)
            await viewModel.handleEvent(.appOpened)
        }
        .sheet(isPresented: $showDetailSheet) {
            if let actionType = detailActionType {
                LogDetailSheet(actionType: actionType) { detail in
                    Task { await viewModel.logAction(actionType, detail: detail) }
                }
            }
        }
    }
}
```

**Step 3: Wire into ContentView and MomCareApp**

In `MomCareApp.swift`, add `@State private var selfCareViewModel: SelfCareViewModel?` and create it in the `.task` block alongside the other view models.

In `ContentView.swift`, accept `selfCareViewModel` as a parameter and replace the `Text("Self-Care")` placeholder with `SelfCareScreen(viewModel: selfCareViewModel)`.

**Step 4: Build and run to verify the tab works**

**Step 5: Lint and commit**

```bash
swiftlint --strict
git add MomCare/Features/SelfCare/Views/SelfCareScreen.swift MomCare/Features/SelfCare/Views/LogDetailSheet.swift MomCare/App/ContentView.swift MomCare/App/MomCareApp.swift
git commit -m "feat(MOM-4): add SelfCareScreen with action grid and card feed"
```

---

## Task 12: Feeding Integration

**Files:**
- Modify: `MomCare/Features/Feeding/ViewModels/FeedingViewModel.swift` — publish event when feeding ends
- Test: `MomCareTests/Integration/FeedingToSelfCareTests.swift`

**Step 1: Write the failing integration test**

```swift
// MomCareTests/Integration/FeedingToSelfCareTests.swift
import Testing
import Foundation
@testable import MomCare

@Suite("Feeding to Self-Care Integration Tests")
struct FeedingToSelfCareTests {

    @Test("SelfCareEngine produces window card from feeding end event")
    func feedingEndProducesWindowCard() {
        let engine = SelfCareEngine(
            logs: [],
            patterns: [],
            contentLibrary: ContentLibrary(
                affirmations: [Affirmation(id: "a1", text: "Test", tags: [.general])],
                pepTalks: [],
                checkInPrompts: [],
                nudgeTemplates: []
            ),
            shownContentIds: [],
            currentDate: .now
        )
        let cards = engine.scoreCards(after: .feedingEnded(babyId: UUID(), duration: 1200))
        let windowCard = cards.first { $0.type == .selfCareWindow }
        #expect(windowCard != nil)
    }

    @Test("Pattern service detects relative-to-feeding with mixed feeding data")
    func patternWithFeedingData() {
        let now = Date.now
        var logs: [SelfCareLog] = []
        var feedingEndTimes: [Date] = []

        // Simulate 7 feedings with shower ~15 min after each
        for i in 0..<7 {
            let feedEnd = now.addingTimeInterval(Double(-i) * 10800)
            feedingEndTimes.append(feedEnd)
            logs.append(SelfCareLog.fixture(
                actionType: .shower,
                timestamp: feedEnd.addingTimeInterval(900) // 15 min
            ))
        }

        let patterns = SelfCarePatternService.analyzePatterns(
            logs: logs,
            feedingEndTimes: feedingEndTimes
        )
        let showerPattern = patterns.first { $0.actionType == .shower }
        #expect(showerPattern?.relativeToFeeding != nil)
    }
}
```

**Step 2: Run test to verify it fails (or passes if engine is already correct)**

**Step 3: Add event publishing to FeedingViewModel**

Add a callback closure to `FeedingViewModel` that fires when a feeding ends:

```swift
// In FeedingViewModel, add:
var onFeedingEnded: ((UUID, TimeInterval) -> Void)?

// In endFeeding(), after successful completion:
if let duration = updated.duration {
    onFeedingEnded?(updated.babyId, duration)
}
```

Wire in `MomCareApp.swift` or `ContentView.swift`:

```swift
feedingViewModel?.onFeedingEnded = { babyId, duration in
    Task {
        await selfCareViewModel?.handleEvent(.feedingEnded(babyId: babyId, duration: duration))
    }
}
```

**Step 4: Run tests to verify they pass**

**Step 5: Lint and commit**

```bash
swiftlint --strict
git add MomCare/Features/Feeding/ViewModels/FeedingViewModel.swift MomCare/App/MomCareApp.swift MomCareTests/Integration/FeedingToSelfCareTests.swift
git commit -m "feat(MOM-4): integrate feeding events with self-care engine"
```

---

## Task 13: Content Rotation Tests

**Files:**
- Test: `MomCareTests/Domain/ContentRotationTests.swift`

**Step 1: Write tests**

```swift
// MomCareTests/Domain/ContentRotationTests.swift
import Testing
import Foundation
@testable import MomCare

@Suite("Content Rotation Tests")
struct ContentRotationTests {

    private func makeLibrary() -> ContentLibrary {
        ContentLibrary(
            affirmations: (1...5).map {
                Affirmation(id: "aff-\($0)", text: "Affirmation \($0)", tags: [.general])
            },
            pepTalks: (1...3).map {
                PepTalk(id: "pep-\($0)", text: "Pep talk \($0)", tags: [.general])
            },
            checkInPrompts: (1...3).map {
                CheckInPrompt(id: "ci-\($0)", text: "Check in \($0)", responseOptions: ["Good", "OK"])
            },
            nudgeTemplates: [
                NudgeTemplate(id: "n-1", template: "You usually {action} around now.", type: .patternDeviation)
            ]
        )
    }

    @Test("Engine avoids recently shown affirmations")
    func avoidsRecentAffirmations() {
        let library = makeLibrary()
        let shownIds = ["aff-1", "aff-2", "aff-3"]

        let engine = SelfCareEngine(
            logs: [],
            patterns: [],
            contentLibrary: library,
            shownContentIds: shownIds,
            currentDate: .now
        )

        let cards = engine.scoreCards(after: .appOpened)
        let affCard = cards.first { $0.type == .affirmation }
        #expect(affCard != nil)
        // Should not show aff-1 through aff-3 text
        #expect(affCard?.message != "Affirmation 1")
        #expect(affCard?.message != "Affirmation 2")
        #expect(affCard?.message != "Affirmation 3")
    }

    @Test("Engine falls back to first affirmation when all shown")
    func fallsBackWhenAllShown() {
        let library = makeLibrary()
        let shownIds = (1...5).map { "aff-\($0)" }

        let engine = SelfCareEngine(
            logs: [],
            patterns: [],
            contentLibrary: library,
            shownContentIds: shownIds,
            currentDate: .now
        )

        let cards = engine.scoreCards(after: .appOpened)
        let affCard = cards.first { $0.type == .affirmation }
        #expect(affCard != nil) // Should still show something
    }

    @Test("Streak card message includes day count")
    func streakCardContent() {
        let library = makeLibrary()
        let pattern = ActionPattern(
            actionType: .skincare,
            averageTimesPerDay: 1.0,
            typicalTimestamps: [],
            relativeToFeeding: nil,
            streakDays: 7,
            compliance: 0.9,
            confidence: 0.8
        )

        let engine = SelfCareEngine(
            logs: [],
            patterns: [pattern],
            contentLibrary: library,
            shownContentIds: [],
            currentDate: .now
        )

        let cards = engine.scoreCards(after: .timeTick)
        let streakCard = cards.first { $0.type == .streak }
        #expect(streakCard != nil)
        #expect(streakCard!.message.contains("7"))
        #expect(streakCard!.message.contains("skincare"))
    }
}
```

**Step 2: Run tests — they should pass with existing engine code**

**Step 3: Lint and commit**

```bash
swiftlint --strict
git add MomCareTests/Domain/ContentRotationTests.swift
git commit -m "test(MOM-4): add content rotation and streak display tests"
```

---

## Task 14: Final Integration — Build, Test, Lint

**Step 1: Run full test suite**

```bash
xcodebuild test -scheme MomCare -destination 'platform=iOS Simulator,name=iPhone 16' 2>&1 | grep -E '(Test Suite|Tests|FAIL|PASS|error:)'
```

**Step 2: Run SwiftLint strict**

```bash
swiftlint --strict
```

**Step 3: Fix any issues discovered**

**Step 4: Final commit**

```bash
git add -A
git commit -m "feat(MOM-4): self-care tracking complete — grid, engine, patterns, content"
```

---

## Summary

| Task | Component | Key Files |
|------|-----------|-----------|
| 1 | Domain entities | `SelfCareLog.swift` |
| 2 | Grid configuration | `SelfCareGridItem.swift` |
| 3 | Content library + JSON | `SelfCareContent.swift`, `ContentLibrary.swift`, `*.json` |
| 4 | Pattern service | `ActionPattern.swift`, `SelfCarePatternService.swift` |
| 5 | SwiftData models | `SelfCareLogModel.swift`, `SelfCareGridItemModel.swift`, `ContentHistoryModel.swift`, `SchemaV2.swift` |
| 6 | Repository | `SelfCareRepositoryProtocol.swift`, `SelfCareRepository.swift` |
| 7 | Engine (card scoring) | `SelfCareCard.swift`, `SelfCareEngine.swift` |
| 8 | ViewModel | `SelfCareViewModel.swift` |
| 9 | Action grid UI | `ActionGridView.swift`, `ActionGridItemView.swift` |
| 10 | Card feed UI | `SelfCareCardView.swift`, `CardFeedView.swift` |
| 11 | Main screen + wiring | `SelfCareScreen.swift`, `LogDetailSheet.swift`, `ContentView.swift`, `MomCareApp.swift` |
| 12 | Feeding integration | `FeedingViewModel.swift` modification |
| 13 | Content rotation tests | `ContentRotationTests.swift` |
| 14 | Final integration | Full build + test + lint |
