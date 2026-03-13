# Baby UX Redesign Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Restructure the app into Now | Baby | Self-Care | Journal | Plan tabs with a shared BabyActivityEngine driving in-place card state transforms for nap, feeding, and diaper tracking.

**Architecture:** `BabyActivityEngine` is an `@Observable @MainActor` class injected via `.environment()` at app root. Cards on the Baby tab read engine state directly — SwiftUI's granular tracking re-renders only affected cards. State transitions (idle → active → complete) are synchronous with `withAnimation`; SwiftData writes happen in async `Task` (State-as-Bridge).

**Tech Stack:** SwiftUI + @Observable + SwiftData (SchemaV4) + Swift 6 strict concurrency + Swift Testing

---

## Pre-flight: Existing uncommitted files

Five files were created on this branch for the MOM-7 data layer and need to be committed before any new work:
- `MomCare/Domain/Entities/BabySleep.swift`
- `MomCare/Domain/Repositories/SleepRepositoryProtocol.swift`
- `MomCare/Data/SwiftData/BabySleepModel.swift`
- `MomCare/Data/SwiftData/Schema/SchemaV4.swift`
- `MomCare/Data/Repositories/SleepRepository.swift`

---

### Task 1: Commit existing MOM-7 data layer files

**Files:**
- Commit: all 5 files listed above

**Step 1: Verify files exist**

```bash
ls MomCare/Domain/Entities/BabySleep.swift \
   MomCare/Domain/Repositories/SleepRepositoryProtocol.swift \
   MomCare/Data/SwiftData/BabySleepModel.swift \
   MomCare/Data/SwiftData/Schema/SchemaV4.swift \
   MomCare/Data/Repositories/SleepRepository.swift
```
Expected: all 5 paths print (no error)

**Step 2: Commit**

```bash
git add MomCare/Domain/Entities/BabySleep.swift \
        MomCare/Domain/Repositories/SleepRepositoryProtocol.swift \
        MomCare/Data/SwiftData/BabySleepModel.swift \
        MomCare/Data/SwiftData/Schema/SchemaV4.swift \
        MomCare/Data/Repositories/SleepRepository.swift
git commit -m "feat(sleep): add BabySleep entity, model, repository, SchemaV4"
```

---

### Task 2: Wire SchemaV4 into migration plan and app

**Files:**
- Modify: `MomCare/Data/SwiftData/Schema/MomCareMigrationPlan.swift`
- Modify: `MomCare/App/MomCareApp.swift`

**Step 1: Update MomCareMigrationPlan**

Replace the entire file content:

```swift
import Foundation
import SwiftData

enum MomCareMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] {
        [SchemaV1.self, SchemaV2.self, SchemaV3.self, SchemaV4.self]
    }

    static var stages: [MigrationStage] {
        [migrateV1toV2, migrateV2toV3, migrateV3toV4]
    }

    static let migrateV1toV2 = MigrationStage.lightweight(
        fromVersion: SchemaV1.self,
        toVersion: SchemaV2.self
    )

    static let migrateV2toV3 = MigrationStage.lightweight(
        fromVersion: SchemaV2.self,
        toVersion: SchemaV3.self
    )

    static let migrateV3toV4 = MigrationStage.lightweight(
        fromVersion: SchemaV3.self,
        toVersion: SchemaV4.self
    )
}
```

**Step 2: Update MomCareApp — use SchemaV4**

In `MomCareApp.swift`, change the schema line from:
```swift
let schema = Schema(versionedSchema: SchemaV3.self)
```
to:
```swift
let schema = Schema(versionedSchema: SchemaV4.self)
```

**Step 3: Run SwiftLint**

```bash
swiftlint --strict
```
Expected: No violations.

**Step 4: Commit**

```bash
git add MomCare/Data/SwiftData/Schema/MomCareMigrationPlan.swift \
        MomCare/App/MomCareApp.swift
git commit -m "feat(schema): add SchemaV4 migration for BabySleepModel"
```

---

### Task 3: Add SleepRepository to Dependencies

**Files:**
- Modify: `MomCare/Core/DI/Dependencies.swift`

**Step 1: Add `makeSleepRepository()` to the protocol and AppDependencies**

Add to `DependencyContainer` protocol after `makeDiaperRepository`:
```swift
func makeSleepRepository() -> any SleepRepositoryProtocol
```

Add to `AppDependencies` after `makeDiaperRepository()`:
```swift
func makeSleepRepository() -> any SleepRepositoryProtocol {
    SleepRepository(modelContext: modelContext)
}
```

Update `DependenciesKey.defaultValue` — add `BabySleepModel.self` to the `ModelContainer` init:
```swift
let container = try! ModelContainer(
    for: BabyModel.self, FeedingModel.self,
    SelfCareLogModel.self, SelfCareGridItemModel.self, ContentHistoryModel.self,
    DiaperModel.self, BabySleepModel.self,
    configurations: config
)
```

**Step 2: Run SwiftLint**

```bash
swiftlint --strict
```

**Step 3: Commit**

```bash
git add MomCare/Core/DI/Dependencies.swift
git commit -m "feat(di): add makeSleepRepository to DependencyContainer"
```

---

### Task 4: Create BabyActivityEngine

**Files:**
- Create: `MomCare/Features/Baby/ViewModels/BabyActivityEngine.swift`

**Step 1: Create the directory**

```bash
mkdir -p MomCare/Features/Baby/ViewModels
```

**Step 2: Write BabyActivityEngine.swift**

```swift
import Foundation

// MARK: - Supporting Types

enum FeedMethod: String, Sendable {
    case left, right, bottle

    var label: String { rawValue.capitalized }

    var systemImage: String {
        switch self {
        case .left: "arrow.left.circle.fill"
        case .right: "arrow.right.circle.fill"
        case .bottle: "drop.fill"
        }
    }
}

// MARK: - BabyActivityEngine

@Observable
@MainActor
final class BabyActivityEngine {

    // MARK: - Active State

    private(set) var napStartTime: Date?
    private(set) var feedingStartTime: Date?
    private(set) var feedMethod: FeedMethod?
    private(set) var showDiaperOptions: Bool = false
    private(set) var napElapsed: TimeInterval = 0
    private(set) var feedingElapsed: TimeInterval = 0

    var isNapActive: Bool { napStartTime != nil }
    var isFeedingActive: Bool { feedingStartTime != nil }

    var napElapsedFormatted: String { formatElapsed(napElapsed) }
    var feedingElapsedFormatted: String { formatElapsed(feedingElapsed) }

    // MARK: - Dependencies

    private let sleepRepository: any SleepRepositoryProtocol
    private let feedingRepository: any FeedingRepositoryProtocol
    private let diaperRepository: any DiaperRepositoryProtocol

    var onFeedingEnded: (@MainActor (UUID, TimeInterval) -> Void)?

    private var napTimerTask: Task<Void, Never>?
    private var feedingTimerTask: Task<Void, Never>?

    // MARK: - Init

    init(
        sleepRepository: any SleepRepositoryProtocol,
        feedingRepository: any FeedingRepositoryProtocol,
        diaperRepository: any DiaperRepositoryProtocol
    ) {
        self.sleepRepository = sleepRepository
        self.feedingRepository = feedingRepository
        self.diaperRepository = diaperRepository
    }

    // MARK: - Load In-Progress (on app launch)

    func loadInProgress(babyId: UUID) async {
        if let sleep = try? await sleepRepository.getInProgressSleep(babyId: babyId) {
            napStartTime = sleep.startTime
            napElapsed = Date.now.timeIntervalSince(sleep.startTime)
            startNapTick()
        }
        if let feeding = try? await feedingRepository.getInProgressFeeding(babyId: babyId) {
            feedingStartTime = feeding.startTime
            feedingElapsed = Date.now.timeIntervalSince(feeding.startTime)
            feedMethod = feeding.feedingType == .bottle ? .bottle
                : feeding.breastSide == .right ? .right : .left
            startFeedingTick()
        }
    }

    // MARK: - Nap

    func startNap(babyId: UUID) async {
        guard !isNapActive else { return }
        let start = Date.now
        napStartTime = start
        napElapsed = 0
        startNapTick()
        let sleep = BabySleep(
            id: UUID(),
            babyId: babyId,
            startTime: start,
            endTime: nil,
            sleepType: BabySleep.SleepType.autoDetect(at: start),
            location: nil,
            quality: nil,
            notes: nil,
            createdAt: start,
            updatedAt: start
        )
        _ = try? await sleepRepository.create(sleep)
    }

    func endNap(babyId: UUID) async {
        guard let start = napStartTime else { return }
        stopNapTick()
        let end = Date.now
        if let existing = try? await sleepRepository.getInProgressSleep(babyId: babyId) {
            var updated = existing
            updated.endTime = end
            updated.updatedAt = end
            _ = try? await sleepRepository.update(updated)
        }
        napStartTime = nil
        napElapsed = 0
    }

    // MARK: - Feeding

    func startFeeding(babyId: UUID, method: FeedMethod) async {
        guard !isFeedingActive else { return }
        let start = Date.now
        feedingStartTime = start
        feedMethod = method
        feedingElapsed = 0
        startFeedingTick()
        let feedingType: Feeding.FeedingType = method == .bottle ? .bottle : .breast
        let side: Feeding.BreastSide? = method == .left ? .left : method == .right ? .right : nil
        let feeding = Feeding(
            id: UUID(),
            babyId: babyId,
            feedingType: feedingType,
            startTime: start,
            endTime: nil,
            breastSide: side,
            breastDuration: nil,
            amountMl: nil,
            bottleContent: nil,
            foodDescription: nil,
            quality: nil,
            notes: nil,
            createdAt: start,
            updatedAt: start
        )
        _ = try? await feedingRepository.create(feeding)
    }

    func endFeeding(babyId: UUID) async {
        guard let start = feedingStartTime else { return }
        stopFeedingTick()
        let end = Date.now
        let duration = end.timeIntervalSince(start)
        if let existing = try? await feedingRepository.getInProgressFeeding(babyId: babyId) {
            var updated = existing
            updated.endTime = end
            updated.updatedAt = end
            _ = try? await feedingRepository.update(updated)
        }
        onFeedingEnded?(babyId, duration)
        feedingStartTime = nil
        feedMethod = nil
        feedingElapsed = 0
    }

    // MARK: - Diaper

    func logDiaper(babyId: UUID) {
        showDiaperOptions = true
        Task { [weak self] in
            try? await Task.sleep(for: .seconds(3))
            guard let self else { return }
            if self.showDiaperOptions {
                self.showDiaperOptions = false
            }
        }
    }

    func selectDiaperType(_ type: Diaper.DiaperType, babyId: UUID) async {
        showDiaperOptions = false
        let now = Date.now
        let diaper = Diaper(
            id: UUID(),
            babyId: babyId,
            changedAt: now,
            diaperType: type,
            notes: nil,
            createdAt: now,
            updatedAt: now
        )
        _ = try? await diaperRepository.create(diaper)
    }

    // MARK: - Background / Foreground

    func pauseTimers() {
        stopNapTick()
        stopFeedingTick()
    }

    func resumeTimersIfNeeded() {
        if isNapActive { updateNapElapsed(); startNapTick() }
        if isFeedingActive { updateFeedingElapsed(); startFeedingTick() }
    }

    // MARK: - Timer Internals

    private func startNapTick() {
        stopNapTick()
        napTimerTask = Task { [weak self] in
            while !Task.isCancelled {
                do { try await Task.sleep(for: .seconds(1)) } catch { break }
                guard !Task.isCancelled, let self else { break }
                self.updateNapElapsed()
            }
        }
    }

    private func stopNapTick() {
        napTimerTask?.cancel()
        napTimerTask = nil
    }

    private func updateNapElapsed() {
        guard let start = napStartTime else { return }
        napElapsed = Date.now.timeIntervalSince(start)
    }

    private func startFeedingTick() {
        stopFeedingTick()
        feedingTimerTask = Task { [weak self] in
            while !Task.isCancelled {
                do { try await Task.sleep(for: .seconds(1)) } catch { break }
                guard !Task.isCancelled, let self else { break }
                self.updateFeedingElapsed()
            }
        }
    }

    private func stopFeedingTick() {
        feedingTimerTask?.cancel()
        feedingTimerTask = nil
    }

    private func updateFeedingElapsed() {
        guard let start = feedingStartTime else { return }
        feedingElapsed = Date.now.timeIntervalSince(start)
    }

    private func formatElapsed(_ interval: TimeInterval) -> String {
        let total = Int(interval)
        let h = total / 3600
        let m = (total % 3600) / 60
        let s = total % 60
        if h > 0 { return String(format: "%d:%02d:%02d", h, m, s) }
        return String(format: "%02d:%02d", m, s)
    }
}
```

**Step 3: Run SwiftLint**

```bash
swiftlint --strict
```

**Step 4: Commit**

```bash
git add MomCare/Features/Baby/ViewModels/BabyActivityEngine.swift
git commit -m "feat(baby): add BabyActivityEngine with nap/feeding/diaper state machine"
```

---

### Task 5: Tests for BabyActivityEngine

**Files:**
- Create: `MomCareTests/Features/Baby/BabyActivityEngineTests.swift`

**Step 1: Create test stubs**

Create `MomCareTests/Features/Baby/StubSleepRepository.swift`:

```swift
import Foundation
@testable import MomCare

final class StubSleepRepository: SleepRepositoryProtocol, @unchecked Sendable {
    var sleeps: [BabySleep]
    var inProgress: BabySleep?
    var created: [BabySleep] = []
    var updated: [BabySleep] = []

    init(sleeps: [BabySleep] = [], inProgress: BabySleep? = nil) {
        self.sleeps = sleeps
        self.inProgress = inProgress
    }

    func getAll() async throws -> [BabySleep] { sleeps }
    func getById(_ id: UUID) async throws -> BabySleep? { sleeps.first { $0.id == id } }
    func create(_ entity: BabySleep) async throws -> BabySleep { created.append(entity); return entity }
    func update(_ entity: BabySleep) async throws -> BabySleep { updated.append(entity); return entity }
    func delete(_ id: UUID) async throws { sleeps.removeAll { $0.id == id } }
    func getSleepsForBaby(_ babyId: UUID, limit: Int?) async throws -> [BabySleep] { sleeps }
    func getSleepsForDateRange(babyId: UUID, start: Date, end: Date) async throws -> [BabySleep] { sleeps }
    func getInProgressSleep(babyId: UUID) async throws -> BabySleep? { inProgress }
}
```

**Step 2: Write tests**

Create `MomCareTests/Features/Baby/BabyActivityEngineTests.swift`:

```swift
import Testing
import Foundation
@testable import MomCare

@Suite("BabyActivityEngine Tests")
struct BabyActivityEngineTests {

    private let babyId = UUID()

    @MainActor
    private func makeSUT(inProgressSleep: BabySleep? = nil) -> BabyActivityEngine {
        BabyActivityEngine(
            sleepRepository: StubSleepRepository(inProgress: inProgressSleep),
            feedingRepository: StubFeedingRepository(),
            diaperRepository: StubDiaperRepository()
        )
    }

    @Test("Initial state: no active nap or feeding")
    @MainActor
    func initialState() {
        let sut = makeSUT()
        #expect(!sut.isNapActive)
        #expect(!sut.isFeedingActive)
        #expect(!sut.showDiaperOptions)
    }

    @Test("startNap sets isNapActive")
    @MainActor
    func startNap() async {
        let sut = makeSUT()
        await sut.startNap(babyId: babyId)
        #expect(sut.isNapActive)
        #expect(sut.napStartTime != nil)
    }

    @Test("endNap clears active nap")
    @MainActor
    func endNap() async {
        let sut = makeSUT()
        await sut.startNap(babyId: babyId)
        await sut.endNap(babyId: babyId)
        #expect(!sut.isNapActive)
        #expect(sut.napStartTime == nil)
    }

    @Test("startNap while active is idempotent")
    @MainActor
    func startNapIdempotent() async {
        let sut = makeSUT()
        await sut.startNap(babyId: babyId)
        let firstStart = sut.napStartTime
        await sut.startNap(babyId: babyId)
        #expect(sut.napStartTime == firstStart)
    }

    @Test("startFeeding sets isFeedingActive with correct method")
    @MainActor
    func startFeeding() async {
        let sut = makeSUT()
        await sut.startFeeding(babyId: babyId, method: .left)
        #expect(sut.isFeedingActive)
        #expect(sut.feedMethod == .left)
    }

    @Test("endFeeding clears active feeding and fires callback")
    @MainActor
    func endFeeding() async {
        let sut = makeSUT()
        var callbackFired = false
        sut.onFeedingEnded = { @MainActor _, _ in callbackFired = true }
        await sut.startFeeding(babyId: babyId, method: .bottle)
        await sut.endFeeding(babyId: babyId)
        #expect(!sut.isFeedingActive)
        #expect(callbackFired)
    }

    @Test("logDiaper shows options")
    @MainActor
    func logDiaper() {
        let sut = makeSUT()
        sut.logDiaper(babyId: babyId)
        #expect(sut.showDiaperOptions)
    }

    @Test("selectDiaperType hides options")
    @MainActor
    func selectDiaperType() async {
        let sut = makeSUT()
        sut.logDiaper(babyId: babyId)
        await sut.selectDiaperType(.wet, babyId: babyId)
        #expect(!sut.showDiaperOptions)
    }

    @Test("napElapsedFormatted shows mm:ss for short durations")
    @MainActor
    func napElapsedFormat() async {
        let sut = makeSUT()
        await sut.startNap(babyId: babyId)
        // Format is deterministic regardless of exact elapsed
        #expect(sut.napElapsedFormatted.contains(":"))
    }

    @Test("loadInProgress detects in-progress nap")
    @MainActor
    func loadInProgressNap() async {
        let past = Date.now.addingTimeInterval(-300)
        let sleep = BabySleep.fixture(babyId: babyId, startTime: past, endTime: nil)
        let sut = makeSUT(inProgressSleep: sleep)
        await sut.loadInProgress(babyId: babyId)
        #expect(sut.isNapActive)
        #expect(sut.napElapsed >= 300)
    }
}
```

**Step 3: Run tests**

```bash
xcodebuild test -scheme MomCare -destination 'platform=iOS Simulator,name=iPhone 16' \
  -only-testing:MomCareTests/BabyActivityEngineTests 2>&1 | tail -20
```
Expected: All tests pass.

**Step 4: Commit**

```bash
git add MomCareTests/Features/Baby/
git commit -m "test(baby): add BabyActivityEngine state machine tests"
```

---

### Task 6: Update AppNavigation to new tab structure

**Files:**
- Modify: `MomCare/App/AppNavigation.swift`

**Step 1: Replace AppNavigation entirely**

```swift
import SwiftUI

enum AppTab: String, CaseIterable, Sendable {
    case now
    case baby
    case selfCare
    case journal
    case plan
}

@MainActor
@Observable
final class AppNavigation {
    var selectedTab: AppTab = .now
    var nowPath = NavigationPath()
    var babyPath = NavigationPath()
    var selfCarePath = NavigationPath()
    var journalPath = NavigationPath()
    var planPath = NavigationPath()

    func handleURL(_ url: URL) {
        assertionFailure("Deep link received but routing not yet implemented: \(url)")
    }
}
```

**Step 2: Run SwiftLint**

```bash
swiftlint --strict
```

Expected: Errors about `dashboard`, `feeding`, etc. references in other files — these will be fixed in subsequent tasks. For now, just verify the file itself is clean.

**Step 3: Commit**

```bash
git add MomCare/App/AppNavigation.swift
git commit -m "feat(nav): update AppNavigation to Now|Baby|SelfCare|Journal|Plan tabs"
```

---

### Task 7: Update AppNavigationTests

**Files:**
- Modify: `MomCareTests/App/AppNavigationTests.swift`

**Step 1: Replace test file**

```swift
import Testing
@testable import MomCare

@Suite("AppNavigation Tests")
struct AppNavigationTests {
    @Test("Default tab is now")
    @MainActor
    func defaultTab() {
        let nav = AppNavigation()
        #expect(nav.selectedTab == .now)
    }

    @Test("Each tab has its own navigation path")
    @MainActor
    func tabPaths() {
        let nav = AppNavigation()
        #expect(nav.nowPath.isEmpty)
        #expect(nav.babyPath.isEmpty)
        #expect(nav.selfCarePath.isEmpty)
        #expect(nav.journalPath.isEmpty)
        #expect(nav.planPath.isEmpty)
    }

    @Test("Tab enum has five cases")
    func allTabs() {
        let tabs = AppTab.allCases
        #expect(tabs.count == 5)
        #expect(tabs.contains(.now))
        #expect(tabs.contains(.baby))
        #expect(tabs.contains(.selfCare))
        #expect(tabs.contains(.journal))
        #expect(tabs.contains(.plan))
    }
}
```

**Step 2: Commit**

```bash
git add MomCareTests/App/AppNavigationTests.swift
git commit -m "test(nav): update AppNavigationTests for new tab structure"
```

---

### Task 8: Add MCColor.baby color token

**Files:**
- Modify: `MomCare/Core/DesignSystem/ColorTokens.swift`
- Create: `MomCare/App/Assets.xcassets/BabyColor.colorset/Contents.json`

**Step 1: Add baby color token**

In `ColorTokens.swift`, add after `diaper`:
```swift
static let baby = Color("BabyColor")
```

**Step 2: Create color asset**

Create `MomCare/App/Assets.xcassets/BabyColor.colorset/Contents.json`:

```json
{
  "colors": [
    {
      "color": {
        "color-space": "srgb",
        "components": {
          "alpha": "1.000",
          "blue": "0.878",
          "green": "0.749",
          "red": "0.502"
        }
      },
      "idiom": "universal"
    },
    {
      "appearances": [
        {
          "appearance": "luminosity",
          "value": "dark"
        }
      ],
      "color": {
        "color-space": "srgb",
        "components": {
          "alpha": "1.000",
          "blue": "0.949",
          "green": "0.831",
          "red": "0.612"
        }
      },
      "idiom": "universal"
    }
  ],
  "info": {
    "author": "xcode",
    "version": 1
  }
}
```

(Light: warm lavender #80BFE0-ish, Dark: slightly lighter. Adjust hue if design changes — this is a placeholder.)

**Step 3: Commit**

```bash
git add MomCare/Core/DesignSystem/ColorTokens.swift \
        "MomCare/App/Assets.xcassets/BabyColor.colorset/"
git commit -m "feat(design): add MCColor.baby token and BabyColor asset"
```

---

### Task 9: Create Baby tab views

**Files:**
- Create: `MomCare/Features/Baby/Views/BabyScreen.swift`
- Create: `MomCare/Features/Baby/Views/BabyActionCard.swift`
- Create: `MomCare/Features/Baby/Views/FeedingSelectorSheet.swift`

**Step 1: Create FeedingSelectorSheet.swift**

```swift
import SwiftUI

@MainActor
struct FeedingSelectorSheet: View {
    let onSelect: (FeedMethod) -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: MCSpacing.xl) {
            Text("How are you feeding?")
                .font(.title3.bold())
                .padding(.top, MCSpacing.xl)

            VStack(spacing: MCSpacing.md) {
                feedButton(.left, label: "Left Breast")
                feedButton(.right, label: "Right Breast")
                feedButton(.bottle, label: "Bottle")
            }
            .padding(.horizontal, MCSpacing.lg)

            Spacer()
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }

    @ViewBuilder
    private func feedButton(_ method: FeedMethod, label: String) -> some View {
        Button {
            MCHaptic.tap()
            onSelect(method)
            dismiss()
        } label: {
            HStack {
                Image(systemName: method.systemImage)
                    .font(.title2)
                Text(label)
                    .font(.headline)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 64)
            .background {
                RoundedRectangle(cornerRadius: 16)
                    .fill(.ultraThinMaterial)
            }
        }
        .buttonStyle(.plain)
    }
}
```

**Step 2: Create BabyActionCard.swift**

This single view handles nap, feeding, and diaper states — all driven by engine state.

```swift
import SwiftUI

enum BabyCardType: String, CaseIterable {
    case nap, feeding, diaper

    var idleIcon: String {
        switch self {
        case .nap: "moon.stars.fill"
        case .feeding: "drop.fill"
        case .diaper: "circle.dotted"
        }
    }

    var idleLabel: String {
        switch self {
        case .nap: "Nap"
        case .feeding: "Feed"
        case .diaper: "Diaper"
        }
    }
}

@MainActor
struct BabyActionCard: View {
    let cardType: BabyCardType
    let babyId: UUID
    @Environment(BabyActivityEngine.self) private var engine
    @State private var isAnimating = false
    @State private var showFeedingSelector = false

    var body: some View {
        Button {
            handleTap()
        } label: {
            cardContent
                .frame(maxWidth: .infinity)
                .frame(height: 80)
                .background {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(.ultraThinMaterial)
                        .overlay { activeOverlay }
                }
                .scaleEffect(isAnimating ? 0.92 : 1.0)
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showFeedingSelector) {
            FeedingSelectorSheet { method in
                Task { await engine.startFeeding(babyId: babyId, method: method) }
            }
        }
        .accessibilityLabel(accessibilityLabel)
    }

    @ViewBuilder
    private var cardContent: some View {
        VStack(spacing: MCSpacing.xs) {
            switch cardType {
            case .nap:
                napContent
            case .feeding:
                feedingContent
            case .diaper:
                diaperContent
            }
        }
    }

    @ViewBuilder
    private var napContent: some View {
        if engine.isNapActive {
            Image(systemName: "moon.stars.fill")
                .font(.title2)
                .foregroundStyle(MCColor.baby)
            Text("End Nap")
                .font(.caption2.bold())
            Text(engine.napElapsedFormatted)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .monospacedDigit()
        } else {
            Image(systemName: "moon.stars.fill")
                .font(.title2)
            Text("Nap")
                .font(.caption2)
        }
    }

    @ViewBuilder
    private var feedingContent: some View {
        if engine.isFeedingActive {
            Image(systemName: engine.feedMethod?.systemImage ?? "drop.fill")
                .font(.title2)
                .foregroundStyle(MCColor.feeding)
            Text("End Feed")
                .font(.caption2.bold())
            Text(engine.feedingElapsedFormatted)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .monospacedDigit()
        } else {
            Image(systemName: "drop.fill")
                .font(.title2)
            Text("Feed")
                .font(.caption2)
        }
    }

    @ViewBuilder
    private var diaperContent: some View {
        if engine.showDiaperOptions {
            HStack(spacing: MCSpacing.xs) {
                diaperOptionButton(.wet, label: "Wet")
                diaperOptionButton(.dirty, label: "Dirty")
                diaperOptionButton(.both, label: "Both")
            }
            .padding(.horizontal, MCSpacing.xs)
        } else {
            Image(systemName: "circle.dotted")
                .font(.title2)
            Text("Diaper")
                .font(.caption2)
        }
    }

    @ViewBuilder
    private func diaperOptionButton(_ type: Diaper.DiaperType, label: String) -> some View {
        Button {
            MCHaptic.tap()
            Task { await engine.selectDiaperType(type, babyId: babyId) }
        } label: {
            Text(label)
                .font(.caption2.bold())
                .frame(maxWidth: .infinity)
                .frame(height: 40)
                .background {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(MCColor.diaper.opacity(0.2))
                }
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var activeOverlay: some View {
        switch cardType {
        case .nap where engine.isNapActive:
            RoundedRectangle(cornerRadius: 16).fill(MCColor.baby.opacity(0.12))
        case .feeding where engine.isFeedingActive:
            RoundedRectangle(cornerRadius: 16).fill(MCColor.feeding.opacity(0.12))
        default:
            EmptyView()
        }
    }

    private var accessibilityLabel: String {
        switch cardType {
        case .nap: engine.isNapActive ? "End nap, elapsed \(engine.napElapsedFormatted)" : "Start nap"
        case .feeding: engine.isFeedingActive ? "End feeding, elapsed \(engine.feedingElapsedFormatted)" : "Start feeding"
        case .diaper: "Log diaper change"
        }
    }

    private func handleTap() {
        MCHaptic.tap()
        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
            isAnimating = true
        }
        Task {
            try? await Task.sleep(for: .seconds(0.3))
            isAnimating = false
        }

        switch cardType {
        case .nap:
            if engine.isNapActive {
                Task { await engine.endNap(babyId: babyId) }
            } else {
                Task { await engine.startNap(babyId: babyId) }
            }
        case .feeding:
            if engine.isFeedingActive {
                Task { await engine.endFeeding(babyId: babyId) }
            } else {
                showFeedingSelector = true
            }
        case .diaper:
            engine.logDiaper(babyId: babyId)
        }
    }
}
```

**Step 3: Create BabyScreen.swift**

```swift
import SwiftUI

@MainActor
struct BabyScreen: View {
    let babyId: UUID?

    var body: some View {
        ScrollView {
            if let babyId {
                BabyCardGrid(babyId: babyId)
                    .padding(.horizontal, MCSpacing.lg)
                    .padding(.vertical, MCSpacing.lg)
            } else {
                Text("Select a baby to get started")
                    .foregroundStyle(.secondary)
                    .padding(.top, MCSpacing.xl)
            }
        }
        .navigationTitle("Baby")
    }
}

@MainActor
private struct BabyCardGrid: View {
    let babyId: UUID
    private let columns = [
        GridItem(.flexible(), spacing: MCSpacing.sm),
        GridItem(.flexible(), spacing: MCSpacing.sm),
        GridItem(.flexible(), spacing: MCSpacing.sm)
    ]

    var body: some View {
        LazyVGrid(columns: columns, spacing: MCSpacing.sm) {
            BabyActionCard(cardType: .nap, babyId: babyId)
            BabyActionCard(cardType: .feeding, babyId: babyId)
            BabyActionCard(cardType: .diaper, babyId: babyId)
        }
    }
}
```

**Step 4: Run SwiftLint**

```bash
swiftlint --strict
```

**Step 5: Commit**

```bash
git add MomCare/Features/Baby/Views/
git commit -m "feat(baby): add BabyScreen card grid with in-place state transforms"
```

---

### Task 10: Create Now tab (replaces Dashboard)

**Files:**
- Create: `MomCare/Features/Now/Views/NowScreen.swift`
- Create: `MomCare/Features/Now/Views/BabyStatusStrip.swift`

**Step 1: Create BabyStatusStrip.swift**

```swift
import SwiftUI

@MainActor
struct BabyStatusStrip: View {
    @Environment(BabyActivityEngine.self) private var engine
    let babyId: UUID?

    var body: some View {
        HStack(spacing: MCSpacing.md) {
            if engine.isNapActive {
                statusPill(
                    icon: "moon.stars.fill",
                    text: "Napping \u{2022} \(engine.napElapsedFormatted)",
                    color: MCColor.baby
                )
            }
            if engine.isFeedingActive {
                statusPill(
                    icon: engine.feedMethod?.systemImage ?? "drop.fill",
                    text: "Feeding \u{2022} \(engine.feedingElapsedFormatted)",
                    color: MCColor.feeding
                )
            }
            if !engine.isNapActive, !engine.isFeedingActive {
                Text("All quiet")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, MCSpacing.lg)
        .padding(.vertical, MCSpacing.md)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    @ViewBuilder
    private func statusPill(icon: String, text: String, color: Color) -> some View {
        HStack(spacing: MCSpacing.xs) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Image(systemName: icon)
                .foregroundStyle(color)
                .font(.caption)
            Text(text)
                .font(.subheadline.monospacedDigit())
                .foregroundStyle(color)
        }
    }
}
```

**Step 2: Create NowScreen.swift**

NowScreen is a streamlined replacement for DashboardScreen. It reuses the existing `DashboardViewModel` for smart suggestions while adding the new `BabyStatusStrip`.

```swift
import SwiftUI

@MainActor
struct NowScreen: View {
    var dashboardViewModel: DashboardViewModel?
    let babyId: UUID?

    @Environment(AppNavigation.self) private var navigation

    var body: some View {
        Group {
            if let viewModel = dashboardViewModel {
                loadedView(viewModel: viewModel)
            } else {
                ProgressView()
            }
        }
        .navigationTitle("Now")
    }

    @ViewBuilder
    private func loadedView(viewModel: DashboardViewModel) -> some View {
        ScrollView {
            VStack(spacing: MCSpacing.lg) {
                BabyStatusStrip(babyId: babyId)

                if !viewModel.visibleSuggestions.isEmpty {
                    suggestionsSection(viewModel: viewModel)
                }
            }
            .padding(.horizontal, MCSpacing.lg)
            .padding(.vertical, MCSpacing.lg)
        }
        .task {
            await viewModel.loadDashboard(babyId: babyId)
        }
    }

    @ViewBuilder
    private func suggestionsSection(viewModel: DashboardViewModel) -> some View {
        VStack(alignment: .leading, spacing: MCSpacing.sm) {
            Text("Suggestions")
                .font(.caption.bold())
                .foregroundStyle(.secondary)
                .padding(.horizontal, MCSpacing.xs)

            ForEach(viewModel.visibleSuggestions) { suggestion in
                SmartSuggestionBanner(
                    suggestion: suggestion,
                    onDismiss: { viewModel.dismissSuggestion(suggestion) },
                    onTap: suggestion.actionTab.map { tab in
                        { navigation.selectedTab = tab }
                    }
                )
            }
        }
    }
}
```

Note: `SmartSuggestionBanner` already exists in the Dashboard feature. `suggestion.actionTab` currently returns an old `AppTab`. In Task 11 we'll update those references.

**Step 3: Run SwiftLint**

```bash
swiftlint --strict
```

**Step 4: Commit**

```bash
git add MomCare/Features/Now/
git commit -m "feat(now): add NowScreen with BabyStatusStrip replacing Dashboard"
```

---

### Task 11: Create Journal tab

**Files:**
- Create: `MomCare/Features/Journal/ViewModels/JournalViewModel.swift`
- Create: `MomCare/Features/Journal/Views/JournalScreen.swift`
- Create: `MomCare/Features/Journal/Views/JournalEntryRow.swift`

**Step 1: Create JournalEntry domain type**

Create `MomCare/Features/Journal/Models/JournalEntry.swift`:

```swift
import Foundation

enum JournalEntryKind: String, CaseIterable {
    case nap, feeding, diaper

    var label: String {
        switch self {
        case .nap: "Nap"
        case .feeding: "Feeding"
        case .diaper: "Diaper"
        }
    }

    var systemImage: String {
        switch self {
        case .nap: "moon.stars.fill"
        case .feeding: "drop.fill"
        case .diaper: "circle.dotted"
        }
    }
}

struct JournalEntry: Identifiable {
    let id: UUID
    let kind: JournalEntryKind
    let timestamp: Date
    let detail: String   // e.g. "45 min", "Left 12 min", "Wet"
}
```

**Step 2: Create JournalViewModel.swift**

```swift
import Foundation

@Observable
@MainActor
final class JournalViewModel {
    private(set) var entries: [JournalEntry] = []
    private(set) var groupedEntries: [(String, [JournalEntry])] = []
    var selectedFilter: JournalEntryKind? = nil
    var isLoading = false

    private let sleepRepository: any SleepRepositoryProtocol
    private let feedingRepository: any FeedingRepositoryProtocol
    private let diaperRepository: any DiaperRepositoryProtocol

    init(
        sleepRepository: any SleepRepositoryProtocol,
        feedingRepository: any FeedingRepositoryProtocol,
        diaperRepository: any DiaperRepositoryProtocol
    ) {
        self.sleepRepository = sleepRepository
        self.feedingRepository = feedingRepository
        self.diaperRepository = diaperRepository
    }

    func load(babyId: UUID) async {
        isLoading = true
        defer { isLoading = false }
        var allEntries: [JournalEntry] = []

        if let sleeps = try? await sleepRepository.getSleepsForBaby(babyId, limit: 200) {
            allEntries += sleeps.compactMap { sleep in
                guard let end = sleep.endTime else { return nil }
                let mins = Int(end.timeIntervalSince(sleep.startTime) / 60)
                return JournalEntry(id: sleep.id, kind: .nap, timestamp: sleep.startTime,
                                    detail: "\(mins) min")
            }
        }

        if let feedings = try? await feedingRepository.getFeedingsForBaby(babyId, limit: 200) {
            allEntries += feedings.compactMap { feeding in
                guard let end = feeding.endTime else { return nil }
                let mins = Int(end.timeIntervalSince(feeding.startTime) / 60)
                let side = feeding.breastSide?.rawValue.capitalized ?? "Bottle"
                return JournalEntry(id: feeding.id, kind: .feeding, timestamp: feeding.startTime,
                                    detail: "\(side) \(mins) min")
            }
        }

        if let diapers = try? await diaperRepository.getDiapersForBaby(babyId, limit: 200) {
            allEntries += diapers.map { diaper in
                JournalEntry(id: diaper.id, kind: .diaper, timestamp: diaper.changedAt,
                             detail: diaper.diaperType.rawValue.capitalized)
            }
        }

        entries = allEntries.sorted { $0.timestamp > $1.timestamp }
        rebuildGrouped()
    }

    var filteredEntries: [JournalEntry] {
        guard let filter = selectedFilter else { return entries }
        return entries.filter { $0.kind == filter }
    }

    private func rebuildGrouped() {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: filteredEntries) { entry -> String in
            if calendar.isDateInToday(entry.timestamp) { return "Today" }
            if calendar.isDateInYesterday(entry.timestamp) { return "Yesterday" }
            let fmt = DateFormatter()
            fmt.dateFormat = "EEE MMM d"
            return fmt.string(from: entry.timestamp)
        }
        groupedEntries = grouped
            .sorted { lhs, rhs in
                let lDate = filteredEntries.first { groupKey($0) == lhs.key }?.timestamp ?? .distantPast
                let rDate = filteredEntries.first { groupKey($0) == rhs.key }?.timestamp ?? .distantPast
                return lDate > rDate
            }
            .map { ($0.key, $0.value.sorted { $0.timestamp > $1.timestamp }) }
    }

    private func groupKey(_ entry: JournalEntry) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(entry.timestamp) { return "Today" }
        if calendar.isDateInYesterday(entry.timestamp) { return "Yesterday" }
        let fmt = DateFormatter()
        fmt.dateFormat = "EEE MMM d"
        return fmt.string(from: entry.timestamp)
    }
}
```

Note: `DiaperRepository` needs a `getDiapersForBaby(_:limit:)` method. Check if it exists — if not, add it to `DiaperRepositoryProtocol` and `DiaperRepository` following the same pattern as `getFeedingsForBaby`.

**Step 3: Create JournalEntryRow.swift**

```swift
import SwiftUI

@MainActor
struct JournalEntryRow: View {
    let entry: JournalEntry

    var body: some View {
        HStack(spacing: MCSpacing.md) {
            Image(systemName: entry.kind.systemImage)
                .font(.title3)
                .foregroundStyle(color(for: entry.kind))
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 2) {
                Text(entry.kind.label)
                    .font(.subheadline.bold())
                Text(entry.detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text(entry.timestamp, style: .time)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, MCSpacing.xs)
    }

    private func color(for kind: JournalEntryKind) -> Color {
        switch kind {
        case .nap: MCColor.baby
        case .feeding: MCColor.feeding
        case .diaper: MCColor.diaper
        }
    }
}
```

**Step 4: Create JournalScreen.swift**

```swift
import SwiftUI

@MainActor
struct JournalScreen: View {
    var viewModel: JournalViewModel?
    let babyId: UUID?
    @State private var didLoad = false

    var body: some View {
        Group {
            if let viewModel {
                loadedView(viewModel: viewModel)
            } else {
                ProgressView()
            }
        }
        .navigationTitle("Journal")
    }

    @ViewBuilder
    private func loadedView(viewModel: JournalViewModel) -> some View {
        VStack(spacing: 0) {
            filterChips(viewModel: viewModel)
                .padding(.horizontal, MCSpacing.lg)
                .padding(.vertical, MCSpacing.sm)

            List {
                ForEach(viewModel.groupedEntries, id: \.0) { section, entries in
                    Section(section) {
                        ForEach(entries) { entry in
                            JournalEntryRow(entry: entry)
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
        }
        .task {
            guard !didLoad, let babyId else { return }
            didLoad = true
            await viewModel.load(babyId: babyId)
        }
        .onChange(of: viewModel.selectedFilter) { _, _ in
            Task { if let babyId { await viewModel.load(babyId: babyId) } }
        }
    }

    @ViewBuilder
    private func filterChips(viewModel: JournalViewModel) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: MCSpacing.sm) {
                filterChip(label: "All", kind: nil, viewModel: viewModel)
                filterChip(label: "Naps", kind: .nap, viewModel: viewModel)
                filterChip(label: "Feeding", kind: .feeding, viewModel: viewModel)
                filterChip(label: "Diapers", kind: .diaper, viewModel: viewModel)
            }
        }
    }

    @ViewBuilder
    private func filterChip(label: String, kind: JournalEntryKind?, viewModel: JournalViewModel) -> some View {
        let isSelected = viewModel.selectedFilter == kind
        Button {
            MCHaptic.tap()
            viewModel.selectedFilter = kind
        } label: {
            Text(label)
                .font(.caption.bold())
                .padding(.horizontal, MCSpacing.md)
                .padding(.vertical, MCSpacing.xs)
                .background {
                    Capsule()
                        .fill(isSelected ? MCColor.baby : Color.secondary.opacity(0.2))
                }
                .foregroundStyle(isSelected ? .white : .primary)
        }
        .buttonStyle(.plain)
    }
}
```

**Step 5: Commit**

```bash
git add MomCare/Features/Journal/
git commit -m "feat(journal): add JournalScreen with timeline grouped by day and filter chips"
```

---

### Task 12: Create Plan tab

**Files:**
- Create: `MomCare/Features/Plan/Models/DevelopmentStrategy.swift`
- Create: `MomCare/Features/Plan/Views/PlanScreen.swift`
- Create: `MomCare/Features/Plan/Views/StrategyCardView.swift`

**Step 1: Create DevelopmentStrategy.swift**

```swift
import Foundation

struct DevelopmentStrategy: Identifiable, Codable, Equatable {
    let id: String
    let name: String
    let philosophy: String
    let principles: [String]  // 3 bullets

    static let all: [DevelopmentStrategy] = [
        DevelopmentStrategy(
            id: "babywise",
            name: "Babywise",
            philosophy: "Parent-directed feeding on a flexible schedule to help babies sleep through the night.",
            principles: [
                "Feed on a 2.5–3hr schedule, not on demand",
                "Eat-Wake-Sleep cycle structures the day",
                "Consistent schedule builds predictability"
            ]
        ),
        DevelopmentStrategy(
            id: "ferber",
            name: "Ferber Method",
            philosophy: "Graduated extinction approach helping babies learn to self-soothe at sleep time.",
            principles: [
                "Put baby down drowsy but awake",
                "Check in at increasing intervals if crying",
                "Consistency over 3-7 nights establishes the habit"
            ]
        ),
        DevelopmentStrategy(
            id: "wonder-weeks",
            name: "Wonder Weeks",
            philosophy: "Baby development follows predictable mental leaps with fussy periods and breakthroughs.",
            principles: [
                "Ten developmental leaps in the first 20 months",
                "Fussy periods signal upcoming cognitive jumps",
                "Each leap brings new perceptual abilities"
            ]
        ),
        DevelopmentStrategy(
            id: "attachment",
            name: "Attachment Parenting",
            philosophy: "Building a strong parent-child bond through proximity, responsiveness, and connection.",
            principles: [
                "Respond promptly to baby's cries",
                "Babywearing and co-sleeping (safely) encouraged",
                "Breastfeeding on demand as long as mutually desired"
            ]
        ),
        DevelopmentStrategy(
            id: "montessori",
            name: "Montessori",
            philosophy: "Child-led learning in a prepared environment that respects the child's natural development.",
            principles: [
                "Floor bed and low furniture promote independence",
                "Simple, natural toys support open-ended play",
                "Observe before intervening — trust the child's process"
            ]
        )
    ]
}
```

**Step 2: Create StrategyCardView.swift**

```swift
import SwiftUI

@MainActor
struct StrategyCardView: View {
    let strategy: DevelopmentStrategy
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: MCSpacing.md) {
            HStack {
                VStack(alignment: .leading, spacing: MCSpacing.xs) {
                    Text(strategy.name)
                        .font(.headline)
                    Text(strategy.philosophy)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(3)
                }
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(MCColor.baby)
                        .font(.title2)
                }
            }

            VStack(alignment: .leading, spacing: MCSpacing.xs) {
                ForEach(strategy.principles, id: \.self) { principle in
                    HStack(alignment: .top, spacing: MCSpacing.xs) {
                        Text("\u{2022}")
                            .foregroundStyle(MCColor.baby)
                        Text(principle)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            if !isSelected {
                Button {
                    MCHaptic.tap()
                    onSelect()
                } label: {
                    Text("Select")
                        .font(.caption.bold())
                        .frame(maxWidth: .infinity)
                        .frame(height: 36)
                        .background {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(MCColor.baby.opacity(0.2))
                        }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(MCSpacing.md)
        .background {
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .overlay {
                    if isSelected {
                        RoundedRectangle(cornerRadius: 16)
                            .strokeBorder(MCColor.baby, lineWidth: 1.5)
                    }
                }
        }
    }
}
```

**Step 3: Create PlanScreen.swift**

```swift
import SwiftUI

@MainActor
struct PlanScreen: View {
    @AppStorage("selectedStrategyId") private var selectedStrategyId: String = ""

    var selectedStrategy: DevelopmentStrategy? {
        DevelopmentStrategy.all.first { $0.id == selectedStrategyId }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: MCSpacing.lg) {
                if let selected = selectedStrategy {
                    activeStrategyHeader(selected)
                }

                VStack(alignment: .leading, spacing: MCSpacing.md) {
                    Text(selectedStrategy == nil ? "Choose a strategy" : "All Strategies")
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, MCSpacing.xs)

                    ForEach(DevelopmentStrategy.all) { strategy in
                        StrategyCardView(
                            strategy: strategy,
                            isSelected: strategy.id == selectedStrategyId
                        ) {
                            selectedStrategyId = strategy.id
                        }
                    }
                }
            }
            .padding(.horizontal, MCSpacing.lg)
            .padding(.vertical, MCSpacing.lg)
        }
        .navigationTitle("Plan")
    }

    @ViewBuilder
    private func activeStrategyHeader(_ strategy: DevelopmentStrategy) -> some View {
        VStack(alignment: .leading, spacing: MCSpacing.sm) {
            Text("Active Strategy")
                .font(.caption.bold())
                .foregroundStyle(.secondary)

            HStack {
                VStack(alignment: .leading, spacing: MCSpacing.xs) {
                    Text(strategy.name)
                        .font(.headline)
                    Text("Suggestions on Now are influenced by this strategy")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "lightbulb.fill")
                    .foregroundStyle(MCColor.baby)
            }
            .padding(MCSpacing.md)
            .background {
                RoundedRectangle(cornerRadius: 12)
                    .fill(MCColor.baby.opacity(0.1))
            }
        }
    }
}
```

**Step 4: Commit**

```bash
git add MomCare/Features/Plan/
git commit -m "feat(plan): add PlanScreen with development strategy selector"
```

---

### Task 13: Wire everything into MomCareApp and ContentView

**Files:**
- Modify: `MomCare/App/MomCareApp.swift`
- Modify: `MomCare/App/ContentView.swift`

**Step 1: Update MomCareApp.swift**

Add `@State private var babyActivityEngine: BabyActivityEngine?` alongside the other ViewModels.

In the `.task` block, after creating `diaperViewModel`, add:
```swift
let engine = BabyActivityEngine(
    sleepRepository: deps.makeSleepRepository(),
    feedingRepository: deps.makeFeedingRepository(),
    diaperRepository: deps.makeDiaperRepository()
)
if let scVM = selfCareViewModel {
    engine.onFeedingEnded = { @MainActor [weak scVM] babyId, duration in
        Task { await scVM?.handleEvent(.feedingEnded(babyId: babyId, duration: duration)) }
    }
}
if let babyId = babyViewModel?.selectedBaby?.id {
    await engine.loadInProgress(babyId: babyId)
}
babyActivityEngine = engine
```

Remove the old `feedingViewModel?.onFeedingEnded` wiring (now handled by engine).

In `.onChange(of: scenePhase)`:
```swift
case .active:
    feedingViewModel?.resumeTimerIfNeeded()
    babyActivityEngine?.resumeTimersIfNeeded()
case .background:
    feedingViewModel?.pauseTimer()
    babyActivityEngine?.pauseTimers()
```

Pass `babyActivityEngine` to `ContentView`:
```swift
ContentView(
    babyViewModel: babyViewModel,
    feedingViewModel: feedingViewModel,
    selfCareViewModel: selfCareViewModel,
    dashboardViewModel: dashboardViewModel,
    diaperViewModel: diaperViewModel,
    babyActivityEngine: babyActivityEngine,
    journalViewModel: journalViewModel   // add this too
)
```

Also create `journalViewModel`:
```swift
let journalViewModel = JournalViewModel(
    sleepRepository: deps.makeSleepRepository(),
    feedingRepository: deps.makeFeedingRepository(),
    diaperRepository: deps.makeDiaperRepository()
)
```

**Step 2: Update ContentView.swift**

Replace the entire file:

```swift
import SwiftUI

@MainActor
struct ContentView: View {
    @State private var navigation = AppNavigation()
    @SceneStorage("selectedTab") private var selectedTabRaw: String = AppTab.now.rawValue

    var babyViewModel: BabyViewModel?
    var feedingViewModel: FeedingViewModel?
    var selfCareViewModel: SelfCareViewModel?
    var dashboardViewModel: DashboardViewModel?
    var diaperViewModel: DiaperViewModel?
    var babyActivityEngine: BabyActivityEngine?
    var journalViewModel: JournalViewModel?

    @State private var showAddBaby = false

    var body: some View {
        Group {
            if let babyViewModel {
                if let engine = babyActivityEngine {
                    mainTabView(babyViewModel: babyViewModel)
                        .environment(engine)
                } else {
                    ProgressView()
                }
            } else {
                ProgressView()
            }
        }
        .onChange(of: babyViewModel?.babies.isEmpty) { _, isEmpty in
            if isEmpty == true { showAddBaby = true }
        }
        .sheet(isPresented: $showAddBaby) {
            if let babyViewModel { AddBabyView(viewModel: babyViewModel) }
        }
        .environment(navigation)
    }

    @ViewBuilder
    // swiftlint:disable:next function_body_length
    private func mainTabView(babyViewModel: BabyViewModel) -> some View {
        TabView(selection: $navigation.selectedTab) {
            NavigationStack(path: $navigation.nowPath) {
                NowScreen(dashboardViewModel: dashboardViewModel, babyId: babyViewModel.selectedBaby?.id)
                    .toolbar {
                        ToolbarItem(placement: .topBarLeading) {
                            BabySelectorView(viewModel: babyViewModel)
                        }
                    }
            }
            .tabItem { Label("Now", systemImage: "sparkle") }
            .tag(AppTab.now)

            NavigationStack(path: $navigation.babyPath) {
                BabyScreen(babyId: babyViewModel.selectedBaby?.id)
                    .toolbar {
                        ToolbarItem(placement: .topBarLeading) {
                            BabySelectorView(viewModel: babyViewModel)
                        }
                    }
            }
            .tabItem { Label("Baby", systemImage: "figure.and.child.holdinghands") }
            .tag(AppTab.baby)

            NavigationStack(path: $navigation.selfCarePath) {
                SelfCareScreen(viewModel: selfCareViewModel)
                    .toolbar {
                        ToolbarItem(placement: .topBarLeading) {
                            BabySelectorView(viewModel: babyViewModel)
                        }
                    }
            }
            .tabItem { Label("Self-Care", systemImage: "sparkles") }
            .tag(AppTab.selfCare)

            NavigationStack(path: $navigation.journalPath) {
                JournalScreen(viewModel: journalViewModel, babyId: babyViewModel.selectedBaby?.id)
                    .toolbar {
                        ToolbarItem(placement: .topBarLeading) {
                            BabySelectorView(viewModel: babyViewModel)
                        }
                    }
            }
            .tabItem { Label("Journal", systemImage: "book.pages") }
            .tag(AppTab.journal)

            NavigationStack(path: $navigation.planPath) {
                PlanScreen()
            }
            .tabItem { Label("Plan", systemImage: "map.fill") }
            .tag(AppTab.plan)
        }
    }
}

#Preview {
    ContentView()
}
```

**Step 3: Fix DashboardViewModel `actionTab` references**

`SmartSuggestion.actionTab` returns an `AppTab`. Search for references to old tab cases (`.dashboard`, `.feeding`, `.diapers`, `.insights`) and update to new cases (`.now`, `.baby`, `.journal`):

```bash
grep -rn "\.dashboard\|\.feeding\|\.diapers\|\.insights" MomCare/ --include="*.swift"
```

Update any found references to map to the nearest new tab.

**Step 4: Build**

```bash
xcodebuild build -scheme MomCare -destination 'platform=iOS Simulator,name=iPhone 16' 2>&1 | grep -E "error:|Build succeeded"
```
Expected: `Build succeeded`

**Step 5: Run SwiftLint**

```bash
swiftlint --strict
```

**Step 6: Commit**

```bash
git add MomCare/App/ContentView.swift MomCare/App/MomCareApp.swift
git commit -m "feat(app): wire BabyActivityEngine and new tab structure into root"
```

---

### Task 14: Update DependenciesTests for SchemaV4

**Files:**
- Modify: `MomCareTests/Core/DI/DependenciesTests.swift`

**Step 1: Add BabySleepModel to all ModelContainer constructions in the test file**

Search for every `ModelContainer(for:` call in DependenciesTests.swift and add `BabySleepModel.self` to the list:

```swift
let modelContainer = try ModelContainer(
    for: BabyModel.self, FeedingModel.self,
    SelfCareLogModel.self, SelfCareGridItemModel.self, ContentHistoryModel.self,
    DiaperModel.self, BabySleepModel.self,
    configurations: config
)
```

**Step 2: Add `makeSleepRepository` to `TestDependencies` and `MockSleepRepository`**

Wherever `TestDependencies` (or equivalent stub) is defined in the tests, add:
```swift
func makeSleepRepository() -> any SleepRepositoryProtocol {
    StubSleepRepository()
}
```

Add a test for it:
```swift
@Test("DependencyContainer requires makeSleepRepository")
@MainActor
func sleepRepositoryFactory() throws {
    let container = TestDependencies()
    let repo = container.makeSleepRepository()
    #expect(repo is StubSleepRepository)
}

@Test("AppDependencies creates real SleepRepository")
@MainActor
func appDependenciesCreatesSleepRepo() throws {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let modelContainer = try ModelContainer(
        for: BabyModel.self, FeedingModel.self,
        SelfCareLogModel.self, SelfCareGridItemModel.self, ContentHistoryModel.self,
        DiaperModel.self, BabySleepModel.self,
        configurations: config
    )
    let deps = AppDependencies(modelContext: modelContainer.mainContext)
    let repo = deps.makeSleepRepository()
    #expect(repo is SleepRepository)
}
```

**Step 3: Run all tests**

```bash
xcodebuild test -scheme MomCare -destination 'platform=iOS Simulator,name=iPhone 16' 2>&1 | tail -30
```
Expected: All tests pass.

**Step 4: Commit**

```bash
git add MomCareTests/
git commit -m "test(di): update DependenciesTests for SchemaV4 and SleepRepository"
```

---

### Task 15: Final lint, build, and full test run

**Step 1: SwiftLint**

```bash
swiftlint --strict
```
Expected: No violations.

**Step 2: Full build**

```bash
xcodebuild build -scheme MomCare -destination 'platform=iOS Simulator,name=iPhone 16' 2>&1 | grep -E "error:|Build succeeded"
```
Expected: `Build succeeded`

**Step 3: Full test suite**

```bash
xcodebuild test -scheme MomCare -destination 'platform=iOS Simulator,name=iPhone 16' 2>&1 | tail -30
```
Expected: All tests pass, no failures.

**Step 4: Final commit if any fixup needed**

```bash
git add -A
git commit -m "fix: resolve any final lint or build issues"
```

**Step 5: Push branch**

```bash
git push -u origin nick/mom-7-native-ios-sleep-tracking
```

---

## Notes for Implementation

**DiaperRepository missing `getDiapersForBaby`:** If this method doesn't exist, add it to `DiaperRepositoryProtocol` and `DiaperRepository` following the same pattern as `getFeedingsForBaby` in `FeedingRepository`. It needs `babyId` and `limit` params with an `isSoftDeleted == false` predicate.

**`suggestion.actionTab` old tab references:** `DashboardViewModel` returns `AppTab` values in suggestions. After the tab rename, any `.feeding` → `.baby`, `.dashboard` → `.now`, `.insights` → `.journal`. If `AppTab` cases are embedded in suggestion data, search and update them.

**FeedingViewModel stays:** The old Feeding tab is removed from the UI, but `FeedingViewModel` is kept in `MomCareApp` because it's still wired for pattern analysis. It will be cleaned up in a future issue.

**project.yml:** After adding new Swift files, run `xcodegen generate` to update the `.xcodeproj` if files don't appear in Xcode. The project uses XcodeGen.
