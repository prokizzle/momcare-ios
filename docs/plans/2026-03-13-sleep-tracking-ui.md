# Sleep Tracking UI Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Build the sleep timer view, history view, and view model to complete MOM-7.

**Architecture:** SleepViewModel (@Observable) wraps SleepRepositoryProtocol and BabyActivityEngine. SleepTimerView mirrors FeedingTimerView (black screen, large timer, action button). SleepHistoryView follows FeedingHistoryView (grouped list with swipe delete). Navigation wired through BabyScreen nap card.

**Tech Stack:** SwiftUI, @Observable, SwiftData (via repository), Swift Testing, MCDesignSystem (MCColor.baby, MCTypography.largeTimer, MCSpacing, MCHaptic)

---

### Task 1: SleepViewModel

**Files:**
- Create: `MomCare/Features/Sleep/ViewModels/SleepViewModel.swift`
- Test: `MomCareTests/Features/Sleep/SleepViewModelTests.swift`

**Step 1: Create the directory structure**

Run: `mkdir -p MomCare/Features/Sleep/ViewModels MomCare/Features/Sleep/Views MomCareTests/Features/Sleep`

**Step 2: Write the test file**

```swift
import Testing
import Foundation
@testable import MomCare

@MainActor
@Suite("SleepViewModel")
struct SleepViewModelTests {
    let babyId = UUID()
    let stubRepo: StubSleepRepository

    init() {
        stubRepo = StubSleepRepository(sleeps: [
            .fixture(babyId: babyId, startTime: Date.now.addingTimeInterval(-7200), endTime: Date.now.addingTimeInterval(-3600), sleepType: .nap, quality: .good),
            .fixture(babyId: babyId, startTime: Date.now.addingTimeInterval(-86400), endTime: Date.now.addingTimeInterval(-82800), sleepType: .nighttime, quality: .fair),
        ])
    }

    @Test("loadSleeps populates sleeps and groupedSleeps")
    func loadSleeps() async {
        let vm = SleepViewModel(repository: stubRepo)
        await vm.loadSleeps(babyId: babyId)
        #expect(vm.sleeps.count == 2)
        #expect(!vm.groupedSleeps.isEmpty)
        #expect(!vm.isLoading)
    }

    @Test("deleteSleep removes entry")
    func deleteSleep() async {
        let vm = SleepViewModel(repository: stubRepo)
        await vm.loadSleeps(babyId: babyId)
        let idToDelete = vm.sleeps[0].id
        await vm.deleteSleep(id: idToDelete)
        #expect(vm.sleeps.count == 1)
    }

    @Test("endSleep updates in-progress sleep with quality and location")
    func endSleep() async {
        let inProgress = BabySleep.fixture(babyId: babyId, endTime: nil, sleepType: .nap)
        let repo = StubSleepRepository(sleeps: [], inProgress: inProgress)
        let vm = SleepViewModel(repository: repo)
        vm.selectedQuality = .good
        vm.selectedLocation = .crib
        await vm.endSleep(babyId: babyId)
        #expect(repo.updated.count == 1)
        #expect(repo.updated.first?.quality == .good)
        #expect(repo.updated.first?.location == .crib)
        #expect(repo.updated.first?.endTime != nil)
    }

    @Test("dailyTotal computes total duration for a day")
    func dailyTotal() async {
        let vm = SleepViewModel(repository: stubRepo)
        await vm.loadSleeps(babyId: babyId)
        let total = vm.dailyTotal(for: vm.groupedSleeps.first?.1 ?? [])
        #expect(total > 0)
    }
}
```

**Step 3: Run test to verify it fails**

Run: `xcodebuild test -scheme MomCare -workspace MomCare.xcworkspace -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:MomCareTests/SleepViewModelTests 2>&1 | tail -5`
Expected: Fails -- `SleepViewModel` not found

**Step 4: Write SleepViewModel**

```swift
import Foundation

@Observable
@MainActor
final class SleepViewModel {
    private(set) var sleeps: [BabySleep] = [] {
        didSet { rebuildGrouped() }
    }
    private(set) var groupedSleeps: [(String, [BabySleep])] = []
    var selectedLocation: BabySleep.SleepLocation?
    var selectedQuality: BabySleep.SleepQuality?
    var showQualitySheet = false
    var isLoading = false

    private let repository: any SleepRepositoryProtocol

    private let dateFormatter: DateFormatter = {
        let fmt = DateFormatter()
        fmt.dateFormat = "EEE MMM d"
        return fmt
    }()

    init(repository: any SleepRepositoryProtocol) {
        self.repository = repository
    }

    func loadSleeps(babyId: UUID) async {
        isLoading = true
        defer { isLoading = false }
        do {
            sleeps = try await repository.getSleepsForBaby(babyId, limit: nil)
        } catch {
            // Non-fatal: list stays empty
        }
    }

    func endSleep(babyId: UUID) async {
        let end = Date.now
        do {
            if var existing = try await repository.getInProgressSleep(babyId: babyId) {
                existing.endTime = end
                existing.updatedAt = end
                existing.quality = selectedQuality
                existing.location = selectedLocation
                _ = try await repository.update(existing)
            }
        } catch {
            // Non-fatal
        }
        selectedQuality = nil
        selectedLocation = nil
        showQualitySheet = false
    }

    func deleteSleep(id: UUID) async {
        do {
            try await repository.delete(id)
            sleeps.removeAll { $0.id == id }
        } catch {
            // Non-fatal
        }
    }

    func dailyTotal(for sleeps: [BabySleep]) -> TimeInterval {
        sleeps.reduce(0) { $0 + $1.duration }
    }

    func formattedDuration(_ interval: TimeInterval) -> String {
        let total = Int(interval)
        let hours = total / 3600
        let minutes = (total % 3600) / 60
        if hours > 0 { return "\(hours)h \(minutes)m" }
        return "\(minutes)m"
    }

    private func rebuildGrouped() {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: sleeps) { sleep -> String in
            if calendar.isDateInToday(sleep.startTime) { return "Today" }
            if calendar.isDateInYesterday(sleep.startTime) { return "Yesterday" }
            return dateFormatter.string(from: sleep.startTime)
        }
        groupedSleeps = grouped.map { key, items in
            (key, items.sorted { $0.startTime > $1.startTime })
        }.sorted { lhs, rhs in
            (lhs.1.first?.startTime ?? .distantPast) > (rhs.1.first?.startTime ?? .distantPast)
        }
    }
}
```

**Step 5: Run tests to verify they pass**

Run: `xcodebuild test -scheme MomCare -workspace MomCare.xcworkspace -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:MomCareTests/SleepViewModelTests 2>&1 | tail -5`
Expected: All 4 tests PASS

**Step 6: Commit**

```bash
git add MomCare/Features/Sleep/ViewModels/SleepViewModel.swift MomCareTests/Features/Sleep/SleepViewModelTests.swift
git commit -m "feat(sleep): add SleepViewModel with tests"
```

---

### Task 2: SleepTimerView

**Files:**
- Create: `MomCare/Features/Sleep/Views/SleepTimerView.swift`

**Step 1: Write SleepTimerView**

Follow FeedingTimerView pattern exactly. Black background, large timer from engine, sleep type chip, location picker, end button with quality sheet.

```swift
import SwiftUI

@MainActor
struct SleepTimerView: View {
    let babyId: UUID
    @Environment(BabyActivityEngine.self) private var engine
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var sleepType: BabySleep.SleepType = .autoDetect()
    @State private var selectedLocation: BabySleep.SleepLocation?
    @State private var showLocationPicker = false
    @State private var showQualitySheet = false

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: MCSpacing.xxl) {
                sleepTypeChip
                timerDisplay
                locationRow
                Spacer()
                endButton
            }
            .padding(.horizontal, MCSpacing.xl)
            .padding(.top, MCSpacing.section)
        }
        .sheet(isPresented: $showQualitySheet) {
            qualitySheet
        }
    }

    private var sleepTypeChip: some View {
        Button {
            sleepType = sleepType == .nap ? .nighttime : .nap
            MCHaptic.toggle()
        } label: {
            HStack(spacing: MCSpacing.sm) {
                Image(systemName: sleepType.systemImage)
                    .font(.title2)
                Text(sleepType.label)
                    .font(MCTypography.cardTitle)
            }
            .foregroundStyle(.secondary)
            .padding(.horizontal, MCSpacing.lg)
            .padding(.vertical, MCSpacing.sm)
            .background {
                Capsule().fill(.ultraThinMaterial)
            }
        }
        .accessibilityLabel("Sleep type: \(sleepType.label). Tap to change.")
    }

    private var timerDisplay: some View {
        Text(engine.napElapsedFormatted)
            .font(MCTypography.largeTimer)
            .monospacedDigit()
            .foregroundStyle(.white)
            .contentTransition(.numericText())
            .animation(reduceMotion ? nil : .default, value: engine.napElapsedFormatted)
            .accessibilityLabel("Timer: \(engine.napElapsedFormatted)")
    }

    private var locationRow: some View {
        VStack(spacing: MCSpacing.sm) {
            Button {
                withAnimation { showLocationPicker.toggle() }
                MCHaptic.tap()
            } label: {
                HStack {
                    Image(systemName: "mappin.circle.fill")
                    Text(selectedLocation?.label ?? "Add Location")
                    Spacer()
                    Image(systemName: showLocationPicker ? "chevron.up" : "chevron.down")
                        .font(.caption)
                }
                .font(.callout)
                .foregroundStyle(.secondary)
                .padding(.horizontal, MCSpacing.lg)
                .padding(.vertical, MCSpacing.md)
                .background {
                    RoundedRectangle(cornerRadius: 12).fill(.ultraThinMaterial)
                }
            }

            if showLocationPicker {
                locationChips
            }
        }
    }

    private var locationChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: MCSpacing.sm) {
                ForEach(BabySleep.SleepLocation.allCases, id: \.self) { location in
                    Button {
                        selectedLocation = selectedLocation == location ? nil : location
                        MCHaptic.tap()
                    } label: {
                        Text(location.label)
                            .font(.caption)
                            .padding(.horizontal, MCSpacing.md)
                            .padding(.vertical, MCSpacing.sm)
                            .background {
                                Capsule().fill(
                                    selectedLocation == location
                                        ? MCColor.baby.opacity(0.3)
                                        : Color.white.opacity(0.1)
                                )
                            }
                            .overlay {
                                Capsule().stroke(
                                    selectedLocation == location ? MCColor.baby : .clear,
                                    lineWidth: 1
                                )
                            }
                    }
                    .foregroundStyle(.white)
                }
            }
            .padding(.horizontal, MCSpacing.lg)
        }
    }

    private var endButton: some View {
        Button {
            showQualitySheet = true
            MCHaptic.tap()
        } label: {
            Text("End Sleep")
                .font(.title3.weight(.semibold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(MCColor.baby)
                .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .padding(.bottom, MCSpacing.xxl)
    }

    private var qualitySheet: some View {
        VStack(spacing: MCSpacing.xl) {
            Text("How was this sleep?")
                .font(.title3.weight(.semibold))
                .padding(.top, MCSpacing.xl)

            HStack(spacing: MCSpacing.xl) {
                ForEach(BabySleep.SleepQuality.allCases, id: \.self) { quality in
                    Button {
                        Task {
                            await finishSleep(quality: quality)
                        }
                    } label: {
                        VStack(spacing: MCSpacing.sm) {
                            Image(systemName: quality.systemImage)
                                .font(.largeTitle)
                                .foregroundStyle(MCColor.baby)
                            Text(quality.label)
                                .font(.callout)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, MCSpacing.lg)
                        .background {
                            RoundedRectangle(cornerRadius: 16).fill(.ultraThinMaterial)
                        }
                    }
                    .foregroundStyle(.primary)
                }
            }
            .padding(.horizontal, MCSpacing.lg)

            Button("Skip") {
                Task { await finishSleep(quality: nil) }
            }
            .foregroundStyle(.secondary)
            .padding(.bottom, MCSpacing.xl)
        }
        .presentationDetents([.height(260)])
        .presentationDragIndicator(.visible)
    }

    private func finishSleep(quality: BabySleep.SleepQuality?) async {
        // Update the in-progress sleep with quality + location before ending
        if var existing = try? await updateSleepMetadata(quality: quality) {
            _ = existing // consumed by update
        }
        await engine.endNap(babyId: babyId)
        MCHaptic.success()
        showQualitySheet = false
        dismiss()
    }

    @discardableResult
    private func updateSleepMetadata(quality: BabySleep.SleepQuality?) async -> BabySleep? {
        // Access repository through a SleepViewModel passed via environment if needed,
        // or directly update via engine's repository. For now, the engine's endNap handles
        // the endTime. We need to set quality and location on the in-progress record.
        // This will be wired through SleepViewModel in the navigation task.
        return nil
    }
}
```

Note: The `updateSleepMetadata` function is a placeholder. In Task 4 (navigation wiring), we will pass a `SleepViewModel` to `SleepTimerView` and use it to set quality/location before calling `engine.endNap`.

**Step 2: Verify build**

Run: `xcodebuild build -scheme MomCare -workspace MomCare.xcworkspace -destination 'platform=iOS Simulator,name=iPhone 16' 2>&1 | grep -E "error:|BUILD SUCCEEDED|BUILD FAILED"`
Expected: BUILD SUCCEEDED

**Step 3: Commit**

```bash
git add MomCare/Features/Sleep/Views/SleepTimerView.swift
git commit -m "feat(sleep): add SleepTimerView with timer, type chip, location picker, quality sheet"
```

---

### Task 3: SleepHistoryView

**Files:**
- Create: `MomCare/Features/Sleep/Views/SleepHistoryView.swift`

**Step 1: Write SleepHistoryView**

Follow FeedingHistoryView pattern: grouped List, swipe delete, confirmation dialog.

```swift
import SwiftUI

@MainActor
struct SleepHistoryView: View {
    let viewModel: SleepViewModel
    let babyId: UUID
    @State private var sleepToDelete: BabySleep?

    var body: some View {
        Group {
            if viewModel.sleeps.isEmpty && !viewModel.isLoading {
                ContentUnavailableView(
                    "No Sleep Records",
                    systemImage: "moon.zzz",
                    description: Text("Sleep sessions will appear here.")
                )
            } else {
                sleepList
            }
        }
        .navigationTitle("Sleep History")
        .task { await viewModel.loadSleeps(babyId: babyId) }
        .confirmationDialog(
            "Delete Sleep Record?",
            isPresented: Binding(
                get: { sleepToDelete != nil },
                set: { if !$0 { sleepToDelete = nil } }
            )
        ) {
            Button("Delete", role: .destructive) {
                if let sleep = sleepToDelete {
                    Task { await viewModel.deleteSleep(id: sleep.id) }
                }
            }
        } message: {
            Text("This sleep record will be removed.")
        }
    }

    private var sleepList: some View {
        List {
            ForEach(viewModel.groupedSleeps, id: \.0) { section in
                Section {
                    ForEach(section.1) { sleep in
                        sleepRow(sleep)
                            .swipeActions(edge: .trailing) {
                                Button("Delete", role: .destructive) {
                                    sleepToDelete = sleep
                                }
                            }
                    }
                } header: {
                    sectionHeader(title: section.0, sleeps: section.1)
                }
            }
        }
        .listStyle(.insetGrouped)
    }

    private func sectionHeader(title: String, sleeps: [BabySleep]) -> some View {
        HStack {
            Text(title)
            Spacer()
            Text(viewModel.formattedDuration(viewModel.dailyTotal(for: sleeps)))
                .foregroundStyle(.secondary)
        }
    }

    private func sleepRow(_ sleep: BabySleep) -> some View {
        HStack(spacing: MCSpacing.md) {
            Image(systemName: sleep.sleepType.systemImage)
                .font(.title3)
                .foregroundStyle(MCColor.baby)
                .frame(width: 32, height: 32)

            VStack(alignment: .leading, spacing: MCSpacing.xs) {
                Text(sleep.sleepType.label)
                    .font(MCTypography.cardTitle)
                HStack(spacing: MCSpacing.xs) {
                    Text(viewModel.formattedDuration(sleep.duration))
                    if let location = sleep.location {
                        Text("--")
                            .foregroundStyle(.tertiary)
                        Text(location.label)
                    }
                }
                .font(MCTypography.cardBody)
                .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: MCSpacing.xs) {
                Text(sleep.startTime, style: .time)
                    .font(MCTypography.timestamp)
                if let quality = sleep.quality {
                    Image(systemName: quality.systemImage)
                        .font(.caption)
                        .foregroundStyle(MCColor.baby)
                }
            }
            .foregroundStyle(.secondary)
        }
        .padding(.vertical, MCSpacing.xs)
    }
}
```

**Step 2: Verify build**

Run: `xcodebuild build -scheme MomCare -workspace MomCare.xcworkspace -destination 'platform=iOS Simulator,name=iPhone 16' 2>&1 | grep -E "error:|BUILD SUCCEEDED|BUILD FAILED"`
Expected: BUILD SUCCEEDED

**Step 3: Commit**

```bash
git add MomCare/Features/Sleep/Views/SleepHistoryView.swift
git commit -m "feat(sleep): add SleepHistoryView with grouped list and daily totals"
```

---

### Task 4: Navigation Wiring

**Files:**
- Modify: `MomCare/Features/Baby/Views/BabyActionCard.swift` (nap card taps push SleepTimerView when active)
- Modify: `MomCare/Features/Baby/Views/BabyScreen.swift` (add sleep history navigation)
- Modify: `MomCare/Features/Sleep/Views/SleepTimerView.swift` (wire SleepViewModel for quality/location persistence)
- Modify: `MomCare/App/MomCareApp.swift` (create SleepViewModel)
- Modify: `MomCare/App/ContentView.swift` (pass SleepViewModel)

**Step 1: Update BabyActionCard -- nap card pushes SleepTimerView when active**

In `BabyActionCard.swift`, change the nap tap handler so tapping an *active* nap navigates to SleepTimerView instead of immediately ending it:

```swift
// In handleTap(), replace the .nap case:
case .nap:
    if engine.isNapActive {
        // Navigate to timer view instead of ending immediately
        showSleepTimer = true
    } else {
        Task { await engine.startNap(babyId: babyId) }
    }
```

Add `@State private var showSleepTimer = false` and a `.navigationDestination(isPresented: $showSleepTimer)` that pushes `SleepTimerView(babyId: babyId)`.

**Step 2: Update BabyScreen -- add Sleep History link**

Add a `NavigationLink` to `SleepHistoryView` below the card grid.

**Step 3: Wire SleepViewModel into SleepTimerView**

Add `let sleepViewModel: SleepViewModel` parameter to `SleepTimerView`. In `finishSleep`, call:
```swift
sleepViewModel.selectedQuality = quality
sleepViewModel.selectedLocation = selectedLocation
await sleepViewModel.endSleep(babyId: babyId)
await engine.endNap(babyId: babyId)
```

**Step 4: Create SleepViewModel in MomCareApp and pass through ContentView**

Follow the same pattern as `journalViewModel`: create in `.task`, pass as property.

**Step 5: Verify build**

Run: `xcodebuild build -scheme MomCare -workspace MomCare.xcworkspace -destination 'platform=iOS Simulator,name=iPhone 16' 2>&1 | grep -E "error:|BUILD SUCCEEDED|BUILD FAILED"`
Expected: BUILD SUCCEEDED

**Step 6: Run all tests**

Run: `xcodebuild test -scheme MomCare -workspace MomCare.xcworkspace -destination 'platform=iOS Simulator,name=iPhone 16' 2>&1 | tail -5`
Expected: All tests PASS

**Step 7: Commit**

```bash
git add MomCare/Features/Baby/Views/BabyActionCard.swift MomCare/Features/Baby/Views/BabyScreen.swift MomCare/Features/Sleep/Views/SleepTimerView.swift MomCare/App/MomCareApp.swift MomCare/App/ContentView.swift
git commit -m "feat(sleep): wire sleep timer and history into Baby tab navigation"
```

---

### Task 5: Final Verification

**Step 1: Run full test suite**

Run: `xcodebuild test -scheme MomCare -workspace MomCare.xcworkspace -destination 'platform=iOS Simulator,name=iPhone 16' 2>&1 | tail -10`
Expected: All tests PASS

**Step 2: Run SwiftLint**

Run: `swiftlint --strict 2>&1 | tail -5`
Expected: No violations

**Step 3: Fix any lint issues and commit**

```bash
git add -A && git commit -m "fix(sleep): resolve lint violations"
```

**Step 4: Push**

```bash
git push
```
