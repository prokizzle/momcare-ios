# MomCare Native iOS — Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Build a native iOS app (SwiftUI + SwiftData + Firebase) that replaces the Flutter MomCare Tracker with full feature parity plus new features, designed to Apple HIG standards.

**Architecture:** Clean Architecture with vertical feature slices. @Observable ViewModels, SwiftData for persistence, Firebase Firestore for opt-in sync. Each feature is self-contained in Features/{Name}/ with Models, Views, and ViewModels subdirectories.

**Tech Stack:** SwiftUI (iOS 17+), SwiftData, Firebase iOS SDK 11+, Swift Testing, Swift 6 strict concurrency, XcodeGen

**Repo:** `feeling-mindful/momcare-ios` — regenerate Xcode project with `xcodegen generate`

**Flutter Reference:** `feeling-mindful/baby-mother-care` (archived, behavioral spec only)

---

## Task 1: Foundation — Design System & Core Infrastructure

### 1.1: Design Tokens

**Files:**
- Create: `MomCare/Core/DesignSystem/ColorTokens.swift`
- Create: `MomCare/Core/DesignSystem/Typography.swift`
- Create: `MomCare/Core/DesignSystem/Spacing.swift`
- Create: `MomCare/Core/DesignSystem/HapticManager.swift`

**ColorTokens.swift** — Semantic colors that adapt to light/dark. Dark mode is the PRIMARY design target. Warm accent palette, OLED-true blacks, reduced contrast for 3am use.

```swift
import SwiftUI

enum ColorTokens {
    // Primary — warm pink/coral, softer in dark mode
    static let accent = Color("AccentColor")

    // Semantic — adapt to context
    static let feedingColor = Color("FeedingColor")      // Warm blue
    static let selfCareColor = Color("SelfCareColor")    // Soft purple
    static let babyStatusColor = Color("BabyStatusColor")// Gentle green

    // Urgency — for "time since" indicators
    static let urgencyLow = Color.green        // < 2 hours
    static let urgencyMedium = Color.yellow    // 2-3 hours
    static let urgencyHigh = Color.orange      // > 3 hours

    // Surface — dark mode first
    static let cardBackground = Color(.secondarySystemBackground)
    static let groupedBackground = Color(.systemGroupedBackground)
}
```

**Typography.swift** — Must support Dynamic Type. Use system fonts with semantic sizing.

```swift
import SwiftUI

enum AppTypography {
    static let largeTimer = Font.system(size: 72, weight: .thin, design: .rounded)
    static let cardTitle = Font.headline
    static let cardSubtitle = Font.subheadline.weight(.medium)
    static let cardBody = Font.callout
    static let badge = Font.caption2.weight(.semibold)
    static let timestamp = Font.caption.monospacedDigit()
}
```

**Spacing.swift** — 4pt grid system.

```swift
enum Spacing {
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 12
    static let lg: CGFloat = 16
    static let xl: CGFloat = 24
    static let xxl: CGFloat = 32
    static let section: CGFloat = 40
}
```

**HapticManager.swift** — Centralized haptics. Every interaction should have tactile feedback.

```swift
import UIKit

@MainActor
enum HapticManager {
    private static let lightImpact = UIImpactFeedbackGenerator(style: .light)
    private static let mediumImpact = UIImpactFeedbackGenerator(style: .medium)
    private static let notification = UINotificationFeedbackGenerator()
    private static let selection = UISelectionFeedbackGenerator()

    static func tap() { lightImpact.impactOccurred() }
    static func toggle() { mediumImpact.impactOccurred() }
    static func success() { notification.notificationOccurred(.success) }
    static func error() { notification.notificationOccurred(.error) }
    static func select() { selection.selectionChanged() }
}
```

**Asset catalogs needed:**
- `MomCare/App/Assets.xcassets/FeedingColor.colorset/` — sRGB(0.35, 0.58, 0.87) light / sRGB(0.45, 0.68, 0.95) dark
- `MomCare/App/Assets.xcassets/SelfCareColor.colorset/` — sRGB(0.62, 0.45, 0.82) light / sRGB(0.72, 0.55, 0.92) dark
- `MomCare/App/Assets.xcassets/BabyStatusColor.colorset/` — sRGB(0.35, 0.75, 0.55) light / sRGB(0.45, 0.85, 0.65) dark

### 1.2: Repository Protocol Pattern

**Files:**
- Create: `MomCare/Domain/Repositories/Repository.swift`

**Repository.swift** — Base protocol for all repositories. Async/await, not Combine.

```swift
import Foundation

protocol Repository<Entity>: Sendable {
    associatedtype Entity: Identifiable & Sendable

    func getAll() async throws -> [Entity]
    func getById(_ id: Entity.ID) async throws -> Entity?
    func create(_ entity: Entity) async throws -> Entity
    func update(_ entity: Entity) async throws -> Entity
    func delete(_ id: Entity.ID) async throws
}
```

### 1.3: DI via Environment

**Files:**
- Create: `MomCare/Core/DI/Dependencies.swift`

```swift
import SwiftUI

// Protocol for creating dependencies — mockable for tests
protocol DependencyContainer: Sendable {
    func makeBabyRepository() -> any BabyRepositoryProtocol
    func makeFeedingRepository() -> any FeedingRepositoryProtocol
    func makeSelfCareRepository() -> any SelfCareRepositoryProtocol
    // Add more as features are built
}

struct AppDependencies: DependencyContainer {
    let modelContainer: ModelContainer

    func makeBabyRepository() -> any BabyRepositoryProtocol {
        BabyRepository(modelContainer: modelContainer)
    }
    func makeFeedingRepository() -> any FeedingRepositoryProtocol {
        FeedingRepository(modelContainer: modelContainer)
    }
    func makeSelfCareRepository() -> any SelfCareRepositoryProtocol {
        SelfCareRepository(modelContainer: modelContainer)
    }
}

// Environment key
private struct DependencyContainerKey: EnvironmentKey {
    static let defaultValue: any DependencyContainer = PlaceholderDependencies()
}

extension EnvironmentValues {
    var dependencies: any DependencyContainer {
        get { self[DependencyContainerKey.self] }
        set { self[DependencyContainerKey.self] = newValue }
    }
}
```

### 1.4: Navigation Shell

**Files:**
- Modify: `MomCare/App/ContentView.swift`
- Create: `MomCare/App/AppNavigation.swift`

Set up `NavigationStack` per tab with `NavigationPath` for type-safe deep linking. Use `@Observable` for navigation state.

```swift
@Observable
final class AppNavigation {
    var selectedTab: AppTab = .dashboard
    var dashboardPath = NavigationPath()
    var feedingPath = NavigationPath()
    var selfCarePath = NavigationPath()
    var insightsPath = NavigationPath()

    enum AppTab: Int, CaseIterable {
        case dashboard, feeding, selfCare, insights
    }
}
```

---

## Task 2: Baby Management

### 2.1: Domain Entity

**Files:**
- Create: `MomCare/Domain/Entities/Baby.swift`
- Test: `MomCareTests/Domain/BabyTests.swift`

**Flutter reference:** `lib/domain/entities/baby.dart`

**Swift redesign decisions:**
- `gender` → `BiologicalSex` enum (male, female, other, preferNotToSay) instead of nullable String
- `feedingMethod` → `FeedingMethod` enum (breast, bottle, both) instead of String
- `birthWeight` → `Measurement<UnitMass>` instead of raw Int grams
- `birthLength` → `Measurement<UnitLength>` instead of raw Int cm
- All computed age properties (`ageInDays`, `ageString`) carry over

```swift
import Foundation

struct Baby: Identifiable, Codable, Sendable {
    var id: UUID
    var name: String
    var dateOfBirth: Date
    var biologicalSex: BiologicalSex?
    var birthWeight: Double?         // grams
    var birthLength: Double?         // cm
    var birthHeadCircumference: Double? // cm
    var feedingMethod: FeedingMethod
    var photoData: Data?
    var isDeleted: Bool
    var createdAt: Date
    var updatedAt: Date

    enum BiologicalSex: String, Codable, CaseIterable, Sendable {
        case male, female, other, preferNotToSay
    }

    enum FeedingMethod: String, Codable, CaseIterable, Sendable {
        case breast, bottle, both
    }

    // Computed age properties — same logic as Flutter
    var ageInDays: Int { Calendar.current.dateComponents([.day], from: dateOfBirth, to: .now).day ?? 0 }
    var ageInWeeks: Int { ageInDays / 7 }
    var ageInMonths: Int { Calendar.current.dateComponents([.month], from: dateOfBirth, to: .now).month ?? 0 }

    var ageString: String {
        if ageInDays < 7 { return "\(ageInDays) \(ageInDays == 1 ? "day" : "days")" }
        if ageInWeeks < 8 { return "\(ageInWeeks) \(ageInWeeks == 1 ? "week" : "weeks")" }
        return "\(ageInMonths) \(ageInMonths == 1 ? "month" : "months")"
    }
}
```

### 2.2: SwiftData Model

**Files:**
- Create: `MomCare/Data/SwiftData/BabyModel.swift`

```swift
import SwiftData
import Foundation

@Model
final class BabyModel {
    @Attribute(.unique) var id: UUID
    var name: String
    var dateOfBirth: Date
    var biologicalSex: String?
    var birthWeight: Double?
    var birthLength: Double?
    var birthHeadCircumference: Double?
    var feedingMethod: String
    var photoData: Data?
    var isDeleted: Bool
    var createdAt: Date
    var updatedAt: Date

    // Relationships
    @Relationship(deleteRule: .cascade, inverse: \FeedingModel.baby)
    var feedings: [FeedingModel]

    @Relationship(deleteRule: .cascade, inverse: \DiaperModel.baby)
    var diapers: [DiaperModel]

    @Relationship(deleteRule: .cascade, inverse: \SleepModel.baby)
    var sleeps: [SleepModel]

    @Relationship(deleteRule: .cascade, inverse: \GrowthModel.baby)
    var growthRecords: [GrowthModel]

    @Relationship(deleteRule: .cascade, inverse: \HealthEventModel.baby)
    var healthEvents: [HealthEventModel]

    init(from entity: Baby) {
        self.id = entity.id
        self.name = entity.name
        self.dateOfBirth = entity.dateOfBirth
        self.biologicalSex = entity.biologicalSex?.rawValue
        self.birthWeight = entity.birthWeight
        self.birthLength = entity.birthLength
        self.birthHeadCircumference = entity.birthHeadCircumference
        self.feedingMethod = entity.feedingMethod.rawValue
        self.photoData = entity.photoData
        self.isDeleted = entity.isDeleted
        self.createdAt = entity.createdAt
        self.updatedAt = entity.updatedAt
        self.feedings = []
        self.diapers = []
        self.sleeps = []
        self.growthRecords = []
        self.healthEvents = []
    }

    func toEntity() -> Baby {
        Baby(
            id: id, name: name, dateOfBirth: dateOfBirth,
            biologicalSex: biologicalSex.flatMap { Baby.BiologicalSex(rawValue: $0) },
            birthWeight: birthWeight, birthLength: birthLength,
            birthHeadCircumference: birthHeadCircumference,
            feedingMethod: Baby.FeedingMethod(rawValue: feedingMethod) ?? .breast,
            photoData: photoData, isDeleted: isDeleted,
            createdAt: createdAt, updatedAt: updatedAt
        )
    }
}
```

### 2.3: Repository

**Files:**
- Create: `MomCare/Domain/Repositories/BabyRepositoryProtocol.swift`
- Create: `MomCare/Data/Repositories/BabyRepository.swift`
- Test: `MomCareTests/Data/BabyRepositoryTests.swift`

### 2.4: ViewModel

**Files:**
- Create: `MomCare/Features/Baby/ViewModels/BabyViewModel.swift`
- Test: `MomCareTests/Features/BabyViewModelTests.swift`

```swift
import SwiftUI

@Observable
final class BabyViewModel {
    private let repository: any BabyRepositoryProtocol

    var babies: [Baby] = []
    var selectedBaby: Baby?
    var isLoading = false
    var error: Error?

    init(repository: any BabyRepositoryProtocol) {
        self.repository = repository
    }

    func loadBabies() async {
        isLoading = true
        defer { isLoading = false }
        do {
            babies = try await repository.getAll().filter { !$0.isDeleted }
            if selectedBaby == nil { selectedBaby = babies.first }
        } catch { self.error = error }
    }

    func createBaby(_ baby: Baby) async { /* ... */ }
    func updateBaby(_ baby: Baby) async { /* ... */ }
    func deleteBaby(_ id: UUID) async { /* soft delete */ }
    func selectBaby(_ baby: Baby) { selectedBaby = baby }
}
```

### 2.5: Views

**Files:**
- Create: `MomCare/Features/Baby/Views/AddBabyView.swift` — Single-screen onboarding, progressive disclosure
- Create: `MomCare/Features/Baby/Views/BabyProfileView.swift` — Full-screen profile card
- Create: `MomCare/Features/Baby/Views/BabySelectorView.swift` — Tab-based switcher for nav bar
- Create: `MomCare/Shared/Components/BabyAvatarView.swift` — Reusable photo/initial circle

**HIG requirements:**
- Progressive disclosure on AddBabyView: only name + birthday required, everything else expandable
- BabySelectorView uses `.menu` picker style in toolbar
- All tappable areas ≥ 44pt
- SF Symbols: `person.crop.circle` for avatar, `plus.circle.fill` for add

---

## Task 3: Feeding Tracking (Flagship)

### 3.1: Domain Entity

**Files:**
- Create: `MomCare/Domain/Entities/Feeding.swift`
- Test: `MomCareTests/Domain/FeedingTests.swift`

**Flutter reference:** `lib/domain/entities/feeding.dart`

**Swift redesign:**
- `feedingType` → `FeedingType` enum with associated values
- `breastSide` → `BreastSide` enum
- `quality` → `FeedingQuality` enum
- `bottleType` → `BottleContent` enum
- Duration as `TimeInterval` not Int minutes

```swift
import Foundation

struct Feeding: Identifiable, Codable, Sendable {
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
        guard let end = endTime else { return Date.now.timeIntervalSince(startTime) }
        return end.timeIntervalSince(startTime)
    }

    var durationFormatted: String {
        let minutes = Int(duration) / 60
        if minutes < 60 { return "\(minutes) min" }
        return "\(minutes / 60)h \(minutes % 60)m"
    }

    enum FeedingType: String, Codable, CaseIterable, Sendable {
        case breast, bottle, pumping, solid

        var label: String {
            switch self {
            case .breast: "Breast"
            case .bottle: "Bottle"
            case .pumping: "Pumping"
            case .solid: "Solids"
            }
        }

        var systemImage: String {
            switch self {
            case .breast: "drop.fill"
            case .bottle: "cup.and.saucer.fill"
            case .pumping: "arrow.down.circle.fill"
            case .solid: "fork.knife"
            }
        }
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
```

### 3.2: SwiftData Model

**Files:**
- Create: `MomCare/Data/SwiftData/FeedingModel.swift`

Same pattern as BabyModel — `@Model` class with `init(from:)` and `toEntity()` conversion methods. Store enums as raw String values in SwiftData. Relationship: `var baby: BabyModel?`

### 3.3: Repository

**Files:**
- Create: `MomCare/Domain/Repositories/FeedingRepositoryProtocol.swift`
- Create: `MomCare/Data/Repositories/FeedingRepository.swift`
- Test: `MomCareTests/Data/FeedingRepositoryTests.swift`

**FeedingRepositoryProtocol** extends base Repository with feeding-specific methods:

```swift
protocol FeedingRepositoryProtocol: Repository where Entity == Feeding {
    func getFeedingsForBaby(_ babyId: UUID, limit: Int?) async throws -> [Feeding]
    func getFeedingsForDateRange(babyId: UUID, start: Date, end: Date) async throws -> [Feeding]
    func getInProgressFeeding(babyId: UUID) async throws -> Feeding?
}
```

### 3.4: Feeding Pattern Service

**Files:**
- Create: `MomCare/Domain/Services/FeedingPatternService.swift`
- Create: `MomCare/Domain/Entities/FeedingPattern.swift`
- Test: `MomCareTests/Domain/FeedingPatternServiceTests.swift`

**Flutter reference:** `lib/services/feeding_pattern_service.dart` — port the exact algorithm:
- Minimum 3 feedings required
- Look back 7 days
- Filter intervals < 30 min or > 480 min
- Confidence = 40% sample size weight + 60% consistency weight
- `FeedingPattern` struct with `averageInterval: TimeInterval`, `confidence: Double`, `sampleSize: Int`, `predictedNextFeeding: Date?`, `isDue: Bool`

### 3.5: ViewModel

**Files:**
- Create: `MomCare/Features/Feeding/ViewModels/FeedingViewModel.swift`
- Test: `MomCareTests/Features/FeedingViewModelTests.swift`

```swift
@Observable
final class FeedingViewModel {
    private let repository: any FeedingRepositoryProtocol
    private let patternService: FeedingPatternService

    var feedings: [Feeding] = []
    var inProgressFeeding: Feeding?
    var pattern: FeedingPattern?
    var selectedType: Feeding.FeedingType = .breast
    var selectedSide: Feeding.BreastSide = .left
    var isLoading = false
    var error: Error?

    // Timer state
    var isTimerRunning = false
    var elapsedTime: TimeInterval = 0

    func startFeeding(babyId: UUID, type: Feeding.FeedingType) async { /* ... */ }
    func endFeeding() async { /* ... */ }
    func toggleBreastSide() { /* L↔R with haptic */ }
    func loadFeedings(babyId: UUID) async { /* ... */ }
    func analyzePattern(babyId: UUID) async { /* ... */ }
    func deleteFeeding(_ id: UUID) async { /* ... */ }
}
```

### 3.6: Views

**Files:**
- Create: `MomCare/Features/Feeding/Views/FeedingScreen.swift` — Main tab content
- Create: `MomCare/Features/Feeding/Views/FeedingTimerView.swift` — Full-screen timer, one-handed use
- Create: `MomCare/Features/Feeding/Views/FeedingHistoryView.swift` — Grouped list with swipe actions
- Create: `MomCare/Features/Feeding/Views/FeedingListItem.swift` — Row component
- Create: `MomCare/Features/Feeding/Views/FeedingDetailView.swift` — View/edit single feeding
- Create: `MomCare/Features/Feeding/Views/FeedingPatternCard.swift` — Inline insights
- Create: `MomCare/Features/Feeding/Views/QuickFeedButton.swift` — Large FAB-style start button

**FeedingTimerView critical HIG requirements:**
- Large 72pt timer font (thin, rounded, monospaced digits)
- Breast side toggle: two large buttons (L / R) with haptic on toggle
- Pause/resume button
- End feeding button (confirmation dialog)
- Dark mode optimized: OLED black background, warm accent timer
- Minimum 44pt tap targets — actually make them 60pt+ for bleary-eyed 3am use

**FeedingScreen layout:**
- Quick feed button (prominent, top area)
- Active feeding banner (if in-progress, tappable → timer view)
- Pattern insights card (if enough data)
- Feeding history (scrollable list, grouped by day)

---

## Task 4: Self-Care Tracking

### 4.1: Domain Entities

**Files:**
- Create: `MomCare/Domain/Entities/SelfCare/MoodEntry.swift`
- Create: `MomCare/Domain/Entities/SelfCare/WaterEntry.swift`
- Create: `MomCare/Domain/Entities/SelfCare/MealEntry.swift`
- Create: `MomCare/Domain/Entities/SelfCare/SleepEntry.swift`
- Create: `MomCare/Domain/Entities/SelfCare/ExerciseEntry.swift`
- Create: `MomCare/Domain/Entities/SelfCare/MedicationEntry.swift`
- Create: `MomCare/Domain/Entities/SelfCare/DailyEssential.swift`
- Create: `MomCare/Domain/Entities/SelfCare/DailySummary.swift`
- Test: `MomCareTests/Domain/SelfCareTests.swift`

**Flutter reference:** `lib/domain/entities/self_care_entry.dart` — this is a monolithic type with nullable fields. We're splitting it:

**Key redesign:** Instead of one `SelfCareEntry` with 15 nullable fields, use a `SelfCareEntry` enum with associated values:

```swift
enum SelfCareEntry: Identifiable, Codable, Sendable {
    case mood(MoodEntry)
    case water(WaterEntry)
    case meal(MealEntry)
    case sleep(SleepEntry)
    case exercise(ExerciseEntry)
    case medication(MedicationEntry)

    var id: UUID { /* extract from inner type */ }
    var timestamp: Date { /* extract from inner type */ }
}
```

**DailyEssential** — new model for toggle checklist:

```swift
struct DailyEssential: Identifiable, Codable, Sendable {
    var id: UUID
    var name: String
    var icon: String          // SF Symbol name
    var isBuiltIn: Bool       // vs user-created
    var isCompleted: Bool
    var date: Date
    var completedAt: Date?
}
```

**Built-in essentials:** teethBrushing (morning), teethBrushing (night), shower, skincare, vitamins, wentOutside

**DailySummary** — computed aggregate:

```swift
struct DailySummary {
    let date: Date
    let moodScore: Int?
    let waterGlasses: Int
    let mealsLogged: Int
    let sleepMinutes: Int?
    let exerciseMinutes: Int
    let essentialsCompleted: Int
    let essentialsTotal: Int

    var completionPercentage: Double {
        // Weight: mood 20%, water 20% (goal: 8), meals 20% (goal: 3),
        // sleep 15%, exercise 10%, essentials 15%
    }
}
```

### 4.2: SwiftData Models

**Files:**
- Create: `MomCare/Data/SwiftData/SelfCareModels.swift`

One `@Model` per entry type. All link to date for efficient daily queries via `#Predicate`.

### 4.3: Repository + ViewModel

Same pattern as feeding. Repository protocol with date-based queries. ViewModel holds daily state.

### 4.4: Views

**Files:**
- Create: `MomCare/Features/SelfCare/Views/SelfCareScreen.swift` — Main tab
- Create: `MomCare/Features/SelfCare/Views/DailyEssentialsStrip.swift` — Toggle checklist
- Create: `MomCare/Features/SelfCare/Views/MoodTrackerCard.swift` — Slider with faces
- Create: `MomCare/Features/SelfCare/Views/WaterTrackerCard.swift` — Ring + tap
- Create: `MomCare/Features/SelfCare/Views/MealTrackerCard.swift` — Chip buttons
- Create: `MomCare/Features/SelfCare/Views/CompletionRingView.swift` — Activity Rings style
- Create: `MomCare/Features/SelfCare/Views/DateNavigator.swift` — Swipe between days
- Create: `MomCare/Shared/Components/ProgressRing.swift` — Reusable ring component

---

## Task 5: Mission Control Dashboard

### 5.1: ViewModel

**Files:**
- Create: `MomCare/Features/Dashboard/ViewModels/DashboardViewModel.swift`

Depends on: BabyViewModel, FeedingViewModel, SelfCareViewModel (reads their state)

```swift
@Observable
final class DashboardViewModel {
    // Injected
    private let feedingRepo: any FeedingRepositoryProtocol
    private let selfCareRepo: any SelfCareRepositoryProtocol
    private let patternService: FeedingPatternService

    // State
    var lastFeeding: Feeding?
    var lastDiaper: Diaper?
    var lastSleep: BabySleep?
    var timeSinceFeeding: TimeInterval = 0
    var feedingUrgency: Urgency = .low
    var todaySummary: DailySummary?
    var suggestions: [SmartSuggestion] = []

    enum Urgency { case low, medium, high }

    struct SmartSuggestion: Identifiable {
        let id: UUID
        let message: String
        let icon: String
        let action: SuggestionAction
    }
}
```

### 5.2: Views

**Files:**
- Create: `MomCare/Features/Dashboard/Views/DashboardScreen.swift`
- Create: `MomCare/Features/Dashboard/Views/BabyStatusCard.swift`
- Create: `MomCare/Features/Dashboard/Views/MomStatusCard.swift`
- Create: `MomCare/Features/Dashboard/Views/SmartSuggestionBanner.swift`

**BabyStatusCard** — Live "time since" counter using `Text(date, style: .relative)`. Color-coded urgency ring.

**SmartSuggestion logic:**
- If no water logged in 4+ hours: "You haven't logged water in a while"
- If feeding pattern predicts next feed soon: "Baby may be hungry in ~X minutes"
- If self-care completion > 80%: "Great job — you're taking care of yourself today!"
- If no meals logged by 1pm: "Don't forget to eat — you need energy too"

---

## Task 6: Diaper Tracking

### 6.1: Domain Entity

**Files:**
- Create: `MomCare/Domain/Entities/Diaper.swift`

```swift
struct Diaper: Identifiable, Codable, Sendable {
    var id: UUID
    var babyId: UUID
    var timestamp: Date
    var type: DiaperType
    var stoolConsistency: StoolConsistency?
    var stoolColor: StoolColor?
    var hasRash: Bool
    var notes: String?
    var createdAt: Date

    enum DiaperType: String, Codable, CaseIterable, Sendable { case wet, dirty, both }
    enum StoolConsistency: String, Codable, CaseIterable, Sendable { case loose, normal, hard }
    enum StoolColor: String, Codable, CaseIterable, Sendable { case yellow, green, brown, black, red }
}
```

### 6.2-6.4: SwiftData, Repository, ViewModel, Views

Follow established patterns. Key view: `QuickDiaperLogView` — sheet with three big toggle buttons (wet/dirty/both), optional expandable details section. Target: 2-second interaction.

---

## Task 7: Sleep Tracking

### 7.1: Domain Entity

**Files:**
- Create: `MomCare/Domain/Entities/BabySleep.swift`

```swift
struct BabySleep: Identifiable, Codable, Sendable {
    var id: UUID
    var babyId: UUID
    var startTime: Date
    var endTime: Date?
    var sleepType: SleepType
    var location: SleepLocation?
    var quality: SleepQuality?
    var notes: String?
    var createdAt: Date

    var isInProgress: Bool { endTime == nil }
    var duration: TimeInterval { /* same pattern as Feeding */ }

    enum SleepType: String, Codable, Sendable { case nap, nighttime }
    enum SleepLocation: String, Codable, CaseIterable, Sendable { case crib, bassinet, coSleep, stroller, carSeat, other }
    enum SleepQuality: String, Codable, CaseIterable, Sendable { case good, fair, poor }

    // Auto-detect: if start time is between 7pm-6am → nighttime, else nap
    static func autoDetectType(at date: Date) -> SleepType {
        let hour = Calendar.current.component(.hour, from: date)
        return (hour >= 19 || hour < 6) ? .nighttime : .nap
    }
}
```

---

## Task 8: Growth Tracking

### 8.1: Domain Entity

```swift
struct GrowthRecord: Identifiable, Codable, Sendable {
    var id: UUID
    var babyId: UUID
    var date: Date
    var weightGrams: Double?
    var lengthCm: Double?
    var headCircumferenceCm: Double?
    var notes: String?
    var createdAt: Date

    // Computed for display (respects user's locale units)
    var weightFormatted: String { /* kg or lbs based on locale */ }
    var lengthFormatted: String { /* cm or inches based on locale */ }
}
```

### 8.2: WHO/CDC Growth Data

**Files:**
- Create: `MomCare/Domain/Services/GrowthChartService.swift`
- Create: `MomCare/Domain/Entities/GrowthPercentile.swift`
- Bundle: `MomCare/Resources/who_growth_data.json`

Bundle WHO growth standard data (weight-for-age, length-for-age, head-circumference-for-age). Calculate percentiles. Use **Swift Charts** for visualization.

---

## Task 9: Health Events

### 9.1: Domain Entity

```swift
struct HealthEvent: Identifiable, Codable, Sendable {
    var id: UUID
    var babyId: UUID
    var date: Date
    var endDate: Date?
    var eventType: EventType
    var title: String
    var notes: String?
    var photoData: [Data]
    var createdAt: Date

    enum EventType: String, Codable, CaseIterable, Sendable {
        case vaccine, illness, milestone, doctorVisit, allergy
    }
}
```

Use PhotosUI `PhotosPicker` for image selection. Timeline view with `LazyVStack` grouped by month.

---

## Task 10: Widgets + Live Activities

### 10.1: App Group Data Sharing

**Files:**
- Create: `MomCare/Platform/Shared/SharedDataManager.swift`

Use App Group (`group.com.feelingmindful.momcare`) with `UserDefaults(suiteName:)` for lightweight widget data. Write last feeding time, self-care summary on each update.

### 10.2: Live Activity

**Files:**
- Create: `MomCare/Platform/LiveActivities/FeedingActivity.swift`
- Create: `MomCare/Platform/LiveActivities/FeedingActivityAttributes.swift`

```swift
import ActivityKit

struct FeedingActivityAttributes: ActivityAttributes {
    let babyName: String
    let feedingType: String

    struct ContentState: Codable, Hashable {
        let startTime: Date
        let breastSide: String?
        let isPaused: Bool
    }
}
```

### 10.3: Widget Updates

**Files:**
- Modify: `MomCareWidgetExtension/MomCareWidgets.swift`

Add: DailySummaryWidget (medium), QuickActionsWidget (small), GrowthChartWidget (large)

---

## Task 11: App Intents & Siri

**Files:**
- Create: `MomCare/Platform/AppIntents/StartFeedingIntent.swift`
- Create: `MomCare/Platform/AppIntents/LogDiaperIntent.swift`
- Create: `MomCare/Platform/AppIntents/LogWaterIntent.swift`
- Create: `MomCare/Platform/AppIntents/FeedingStatusIntent.swift`
- Create: `MomCare/Platform/AppIntents/MomCareShortcuts.swift`

```swift
import AppIntents

struct StartFeedingIntent: AppIntent {
    static let title: LocalizedStringResource = "Start a Feeding"
    static let description = IntentDescription("Start tracking a feeding session")

    @Parameter(title: "Feeding Type")
    var feedingType: FeedingTypeEntity?

    func perform() async throws -> some IntentResult & ProvidesDialog {
        // Start feeding, return confirmation
        return .result(dialog: "Started tracking a \(feedingType?.name ?? "breast") feeding")
    }
}
```

---

## Task 12: Firebase Auth + Sync

### 12.1: Auth Service

**Files:**
- Create: `MomCare/Data/Firebase/AuthService.swift`

Sign in with Apple, Google Sign-In, anonymous auth, account linking. Use `@Observable` for auth state.

### 12.2: Firestore Sync Service

**Files:**
- Create: `MomCare/Data/Firebase/FirestoreSyncService.swift`
- Create: `MomCare/Data/Firebase/FirestoreMapper.swift`

Local-first sync: SwiftData writes happen immediately. If sync is enabled, changes are pushed to Firestore in background. Snapshot listeners pull partner changes in real-time. Last-write-wins with `updatedAt` timestamps.

### 12.3: Partner Sharing

**Files:**
- Create: `MomCare/Features/Settings/Views/PartnerSharingView.swift`
- Create: `MomCare/Data/Firebase/SharingService.swift`

Invite via Universal Link or QR code. Firestore security rules enforce access control.

---

## Task 13: HealthKit

**Files:**
- Create: `MomCare/Platform/HealthKit/HealthKitService.swift`

Request permissions at point of use. Write baby weight/height. Read mom's sleep and step count. Graceful degradation if denied.

---

## Task 14: Design System Polish

Final pass: audit every screen for Dynamic Type, VoiceOver labels, Reduce Motion, 44pt minimum tap targets, consistent haptic patterns, dark mode contrast.

---

## Build Order Summary

```
1. Foundation (Task 1)           → MOM-1, MOM-14
2. Baby Management (Task 2)      → MOM-2
3. Feeding Tracking (Task 3)     → MOM-3
4. Self-Care (Task 4)            → MOM-4
5. Dashboard (Task 5)            → MOM-5
6. Diapers (Task 6)              → MOM-6
7. Sleep (Task 7)                → MOM-7
8. Growth (Task 8)               → MOM-8
9. Health Events (Task 9)        → MOM-9
10. Widgets + Live Activities    → MOM-10
11. Siri + App Intents           → MOM-11
12. Firebase Sync                → MOM-12
13. HealthKit                    → MOM-13
14. PDF Export                   → MOM-15
15. Design Polish                → MOM-14 (final pass)
```

Each task follows TDD: write failing test → implement → verify → commit.
