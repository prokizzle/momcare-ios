# Smart Widget + Live Activity Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Build a smart "Next Action" widget and generic Live Activity for any in-progress timer, with an End button via App Intent that works from the lock screen.

**Architecture:** SharedDataManager writes lightweight state to App Group UserDefaults. Widget reads it to render priority-based next actions. Live Activity uses ActivityKit for real-time timer display. EndActivityIntent uses AppIntents framework to stop timers from the lock screen. InProgressActivityAttributes is shared between main app and widget extension.

**Tech Stack:** WidgetKit, ActivityKit, AppIntents, SwiftUI, UserDefaults (App Group)

**Design Doc:** `docs/plans/2026-03-16-widgets-live-activities-design.md`

---

### Task 1: SharedDataManager

**Files:**
- Create: `MomCare/Platform/Shared/SharedDataManager.swift`
- Test: `MomCareTests/Platform/SharedDataManagerTests.swift`

**What to build:**

A `@MainActor` struct that reads/writes to `UserDefaults(suiteName: "group.com.feelingmindful.momcare")`. All keys use a `"mc_"` prefix to avoid collisions with SwiftData's use of the same container.

```swift
import Foundation
import WidgetKit

@MainActor
struct SharedDataManager {
    static let suiteName = "group.com.feelingmindful.momcare"

    private static var defaults: UserDefaults {
        UserDefaults(suiteName: suiteName) ?? .standard
    }

    // MARK: - Write

    static func updateBaby(name: String) {
        defaults.set(name, forKey: "mc_babyName")
    }

    static func updateFeeding(
        lastTime: Date?,
        lastType: String?,
        isInProgress: Bool,
        startTime: Date?,
        detail: String?,
        todayCount: Int
    ) {
        defaults.set(lastTime, forKey: "mc_lastFeedingTime")
        defaults.set(lastType, forKey: "mc_lastFeedingType")
        defaults.set(isInProgress, forKey: "mc_isFeedingInProgress")
        defaults.set(startTime, forKey: "mc_feedingStartTime")
        defaults.set(detail, forKey: "mc_feedingDetail")
        defaults.set(todayCount, forKey: "mc_todayFeedingCount")
        reloadWidgets()
    }

    static func updateNap(isInProgress: Bool, startTime: Date?) {
        defaults.set(isInProgress, forKey: "mc_isNapInProgress")
        defaults.set(startTime, forKey: "mc_napStartTime")
        reloadWidgets()
    }

    static func updateSelfCare(items: [SharedSelfCareItem]) {
        if let data = try? JSONEncoder().encode(items) {
            defaults.set(data, forKey: "mc_selfCareItems")
        }
        reloadWidgets()
    }

    static func updateVaccine(name: String?, ageMonths: Int?) {
        defaults.set(name, forKey: "mc_nextVaccineName")
        defaults.set(ageMonths, forKey: "mc_nextVaccineAgeMonths")
        reloadWidgets()
    }

    // MARK: - Read

    static var babyName: String { defaults.string(forKey: "mc_babyName") ?? "Baby" }
    static var lastFeedingTime: Date? { defaults.object(forKey: "mc_lastFeedingTime") as? Date }
    static var lastFeedingType: String? { defaults.string(forKey: "mc_lastFeedingType") }
    static var isFeedingInProgress: Bool { defaults.bool(forKey: "mc_isFeedingInProgress") }
    static var feedingStartTime: Date? { defaults.object(forKey: "mc_feedingStartTime") as? Date }
    static var feedingDetail: String? { defaults.string(forKey: "mc_feedingDetail") }
    static var todayFeedingCount: Int { defaults.integer(forKey: "mc_todayFeedingCount") }
    static var isNapInProgress: Bool { defaults.bool(forKey: "mc_isNapInProgress") }
    static var napStartTime: Date? { defaults.object(forKey: "mc_napStartTime") as? Date }
    static var nextVaccineName: String? { defaults.string(forKey: "mc_nextVaccineName") }
    static var nextVaccineAgeMonths: Int? {
        defaults.object(forKey: "mc_nextVaccineAgeMonths") as? Int
    }

    static var selfCareItems: [SharedSelfCareItem] {
        guard let data = defaults.data(forKey: "mc_selfCareItems") else { return [] }
        return (try? JSONDecoder().decode([SharedSelfCareItem].self, from: data)) ?? []
    }

    // MARK: - Helpers

    static func reloadWidgets() {
        WidgetCenter.shared.reloadAllTimelines()
    }
}

struct SharedSelfCareItem: Codable, Sendable {
    let name: String
    let icon: String
    let isDone: Bool
    let lastDoneDate: Date?
}
```

**Tests:** Verify write/read round-trip for each data type. Use a custom suiteName for test isolation.

**Commit:** `feat(widgets): add SharedDataManager for app-to-widget data sharing`

---

### Task 2: InProgressActivityAttributes (shared between app + widget)

**Files:**
- Create: `MomCare/Platform/LiveActivities/InProgressActivityAttributes.swift`

**What to build:**

The ActivityAttributes struct must be accessible from both the main app (to start/update/end activities) and the widget extension (to render the Live Activity UI). Since the widget extension sources are separate (`MomCareWidgetExtension/**/*.swift`), we need to either:
- Put the file in the main app sources AND duplicate/import in widget extension
- Create a shared directory that both targets compile

RECOMMENDED: Put it in `MomCare/Platform/LiveActivities/` (main app sources). Then add the same file to the widget extension's sources in Project.swift by adding a second source glob, OR copy the file into the widget extension directory.

SIMPLEST APPROACH: Create the file in `MomCareWidgetExtension/` so it's compiled by the widget target, and import ActivityKit in the main app to use it (ActivityAttributes types are just Codable structs -- the main app can create them without the widget target).

Actually -- the CORRECT approach for Tuist: Create the file in a location that BOTH targets compile. Add `MomCare/Platform/LiveActivities/**/*.swift` to the widget extension's sources array in Project.swift.

```swift
import ActivityKit
import Foundation

struct InProgressActivityAttributes: ActivityAttributes {
    let babyName: String
    let activityType: String
    let activityIcon: String

    struct ContentState: Codable, Hashable {
        let startTime: Date
        let detail: String?
    }
}
```

**Modify Project.swift:** Add to widget extension sources:
```swift
sources: [
    "MomCareWidgetExtension/**/*.swift",
    "MomCare/Platform/LiveActivities/**/*.swift",
],
```

**Commit:** `feat(widgets): add InProgressActivityAttributes shared between app and widget`

---

### Task 3: Enable Live Activities in Info.plist

**Files:**
- Modify: `MomCare/App/Info.plist`
- Modify: `MomCareWidgetExtension/Info.plist`

**What to do:**

Add to main app Info.plist:
```xml
<key>NSSupportsLiveActivities</key>
<true/>
```

Add to widget extension Info.plist (needed for the Live Activity UI to render):
```xml
<key>NSSupportsLiveActivities</key>
<true/>
```

**Commit:** `feat(widgets): enable Live Activities in Info.plist`

---

### Task 4: Live Activity View

**Files:**
- Create: `MomCareWidgetExtension/InProgressActivityView.swift`

**What to build:**

The WidgetKit Live Activity UI for lock screen, Dynamic Island compact, and Dynamic Island expanded. This file lives in the widget extension.

```swift
import ActivityKit
import SwiftUI
import WidgetKit

struct InProgressActivityLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: InProgressActivityAttributes.self) { context in
            // Lock screen / banner view
            lockScreenView(context: context)
        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded regions
                DynamicIslandExpandedRegion(.leading) {
                    Image(systemName: context.attributes.activityIcon)
                        .font(.title2)
                        .foregroundStyle(.accentColor)
                }
                DynamicIslandExpandedRegion(.center) {
                    VStack(spacing: 2) {
                        Text(context.attributes.babyName)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Text(context.state.startTime, style: .timer)
                            .font(.title.monospacedDigit())
                            .fontDesign(.rounded)
                    }
                }
                DynamicIslandExpandedRegion(.trailing) {
                    if let detail = context.state.detail {
                        Text(detail)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Button(intent: EndActivityAppIntent(activityType: context.attributes.activityType)) {
                        Text("End \(context.attributes.activityType.capitalized)")
                            .font(.subheadline.weight(.semibold))
                            .frame(maxWidth: .infinity)
                    }
                    .tint(.accentColor)
                }
            } compactLeading: {
                Image(systemName: context.attributes.activityIcon)
                    .foregroundStyle(.accentColor)
            } compactTrailing: {
                Text(context.state.startTime, style: .timer)
                    .monospacedDigit()
                    .frame(width: 56)
            } minimal: {
                Image(systemName: context.attributes.activityIcon)
                    .foregroundStyle(.accentColor)
            }
        }
    }

    @ViewBuilder
    private func lockScreenView(context: ActivityViewContext<InProgressActivityAttributes>) -> some View {
        HStack(spacing: 16) {
            Image(systemName: context.attributes.activityIcon)
                .font(.title)
                .foregroundStyle(.accentColor)

            VStack(alignment: .leading, spacing: 2) {
                Text(context.attributes.babyName)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(context.state.startTime, style: .timer)
                    .font(.title.monospacedDigit())
                    .fontDesign(.rounded)
                    .foregroundStyle(.primary)
                if let detail = context.state.detail {
                    Text(detail)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            Button(intent: EndActivityAppIntent(activityType: context.attributes.activityType)) {
                Image(systemName: "stop.circle.fill")
                    .font(.title)
                    .foregroundStyle(.accentColor)
            }
            .buttonStyle(.plain)
        }
        .padding()
        .activityBackgroundTint(.black.opacity(0.6))
    }
}
```

NOTE: The `EndActivityAppIntent` is defined in Task 5. The Live Activity view references it for the "End" button. If this causes a build order issue, stub it first.

**Commit:** `feat(widgets): add Live Activity view for lock screen and Dynamic Island`

---

### Task 5: EndActivityAppIntent

**Files:**
- Create: `MomCare/Platform/Intents/EndActivityAppIntent.swift`

**What to build:**

An AppIntent that can be triggered from the Live Activity's "End" button. It needs to:
1. Determine activity type (feeding or nap)
2. End the in-progress activity in the repository
3. Update SharedDataManager
4. End the Live Activity

IMPORTANT: App Intents run in the main app process. They CAN access SwiftData and repositories. But they need a way to get the ModelContext. Use a static shared instance or reconstruct from the App Group container.

```swift
import AppIntents
import ActivityKit
import SwiftData

struct EndActivityAppIntent: AppIntent {
    static let title: LocalizedStringResource = "End Activity"

    @Parameter(title: "Activity Type")
    var activityType: String

    init() {
        self.activityType = "feeding"
    }

    init(activityType: String) {
        self.activityType = activityType
    }

    func perform() async throws -> some IntentResult {
        // Create a ModelContext from the App Group container
        let schema = Schema(versionedSchema: SchemaV6.self)
        let config = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            groupContainer: .identifier("group.com.feelingmindful.momcare")
        )
        let container = try ModelContainer(for: schema, configurations: [config])
        let context = ModelContext(container)

        let now = Date.now

        if activityType == "feeding" {
            // Find in-progress feeding and end it
            let descriptor = FetchDescriptor<FeedingModel>(
                predicate: #Predicate<FeedingModel> {
                    $0.endTime == nil && $0.isSoftDeleted == false
                }
            )
            if let model = try context.fetch(descriptor).first {
                model.endTime = now
                model.updatedAt = now
                try context.save()
            }
            await SharedDataManager.updateFeeding(
                lastTime: now,
                lastType: nil,
                isInProgress: false,
                startTime: nil,
                detail: nil,
                todayCount: SharedDataManager.todayFeedingCount
            )
        } else if activityType == "nap" {
            let descriptor = FetchDescriptor<BabySleepModel>(
                predicate: #Predicate<BabySleepModel> {
                    $0.endTime == nil && $0.isSoftDeleted == false
                }
            )
            if let model = try context.fetch(descriptor).first {
                model.endTime = now
                model.updatedAt = now
                try context.save()
            }
            await SharedDataManager.updateNap(isInProgress: false, startTime: nil)
        }

        // End all running Live Activities
        for activity in Activity<InProgressActivityAttributes>.activities {
            await activity.end(
                ActivityContent(state: .init(startTime: now, detail: nil), staleDate: nil),
                dismissalPolicy: .immediate
            )
        }

        return .result()
    }
}
```

This file also needs to be compiled by the widget extension (for the Button(intent:) reference). Add `MomCare/Platform/Intents/**/*.swift` to the widget extension's sources in Project.swift.

**Update Project.swift widget sources:**
```swift
sources: [
    "MomCareWidgetExtension/**/*.swift",
    "MomCare/Platform/LiveActivities/**/*.swift",
    "MomCare/Platform/Intents/**/*.swift",
],
```

**Commit:** `feat(widgets): add EndActivityAppIntent for lock screen End button`

---

### Task 6: Hook Live Activities into BabyActivityEngine

**Files:**
- Modify: `MomCare/Features/Baby/ViewModels/BabyActivityEngine.swift`

**What to do:**

Add `import ActivityKit` at the top.

Add a private helper to manage the Live Activity:

```swift
private func startLiveActivity(type: String, icon: String, detail: String?, startTime: Date) {
    guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }
    let attributes = InProgressActivityAttributes(
        babyName: SharedDataManager.babyName,
        activityType: type,
        activityIcon: icon
    )
    let state = InProgressActivityAttributes.ContentState(
        startTime: startTime,
        detail: detail
    )
    do {
        _ = try Activity.request(
            attributes: attributes,
            content: .init(state: state, staleDate: nil)
        )
    } catch {
        // Non-fatal: Live Activity is a nice-to-have
    }
}

private func endLiveActivity() {
    Task {
        for activity in Activity<InProgressActivityAttributes>.activities {
            await activity.end(dismissalPolicy: .default)
        }
    }
}

private func updateLiveActivityDetail(_ detail: String?) {
    Task {
        for activity in Activity<InProgressActivityAttributes>.activities {
            let state = InProgressActivityAttributes.ContentState(
                startTime: activity.content.state.startTime,
                detail: detail
            )
            await activity.update(ActivityContent(state: state, staleDate: nil))
        }
    }
}
```

Then hook into existing methods:

- `startNap()`: After `startNapTick()`, call `startLiveActivity(type: "nap", icon: "moon.stars.fill", detail: nil, startTime: start)` and `SharedDataManager.updateNap(isInProgress: true, startTime: start)`
- `endNap()`: After stopping tick, call `endLiveActivity()` and `SharedDataManager.updateNap(isInProgress: false, startTime: nil)`
- `startFeeding()`: After `startFeedingTick()`, call `startLiveActivity(type: "feeding", icon: feedMethod?.systemImage ?? "drop.fill", detail: feedMethod?.label, startTime: start)` and `SharedDataManager.updateFeeding(...)`
- `endFeeding()`: After stopping tick, call `endLiveActivity()` and `SharedDataManager.updateFeeding(...)`

**Commit:** `feat(widgets): hook Live Activities into BabyActivityEngine`

---

### Task 7: Hook SharedDataManager into FeedingViewModel

**Files:**
- Modify: `MomCare/Features/Feeding/ViewModels/FeedingViewModel.swift`

**What to do:**

After `toggleBreastSide()`, update the Live Activity detail:

```swift
func toggleBreastSide() {
    selectedSide = selectedSide == .left ? .right : .left
    if var feeding = inProgressFeeding, feeding.feedingType == .breast {
        feeding.breastSide = selectedSide
        inProgressFeeding = feeding
    }
    // Update Live Activity with new side
    for activity in Activity<InProgressActivityAttributes>.activities {
        Task {
            let state = InProgressActivityAttributes.ContentState(
                startTime: activity.content.state.startTime,
                detail: selectedSide.label
            )
            await activity.update(ActivityContent(state: state, staleDate: nil))
        }
    }
}
```

Add `import ActivityKit` at the top.

**Commit:** `feat(widgets): update Live Activity on breast side toggle`

---

### Task 8: Next Action Widget -- Replace Existing Widget

**Files:**
- Rewrite: `MomCareWidgetExtension/MomCareWidgets.swift`

**What to build:**

Replace the entire existing widget with the smart Next Action widget. Read from SharedDataManager (UserDefaults in App Group) to determine priority.

The widget extension cannot import the main app module, so it needs its own copy of `SharedDataManager`'s READ methods and `SharedSelfCareItem`. The simplest approach: add `MomCare/Platform/Shared/SharedDataManager.swift` to the widget extension sources in Project.swift.

**Update Project.swift widget sources (final):**
```swift
sources: [
    "MomCareWidgetExtension/**/*.swift",
    "MomCare/Platform/LiveActivities/**/*.swift",
    "MomCare/Platform/Intents/**/*.swift",
    "MomCare/Platform/Shared/**/*.swift",
],
```

**Widget implementation:**

```swift
// NextActionEntry
struct NextActionEntry: TimelineEntry {
    let date: Date
    let action: NextAction
    let secondaryActions: [NextAction]
}

enum NextAction {
    case feedingInProgress(startTime: Date, detail: String?)
    case napInProgress(startTime: Date)
    case timeTofeed(lastFeedTime: Date)
    case vaccineDue(name: String, ageMonths: Int)
    case selfCareItem(name: String, icon: String, lastDone: String)
    case allGood(lastFeedTime: Date?)

    var icon: String { ... }
    var title: String { ... }
    var tintColor: Color { ... }
}
```

Timeline provider reads from SharedDataManager and applies the priority logic. Small widget shows top action. Medium widget shows top + 2 secondary.

Visual style: system `.widgetBackground`, Nunito font for primary text (register font in widget extension -- add font resource to widget target in Project.swift), accent colors for icons.

**Update Project.swift widget resources:**
```swift
resources: [
    "MomCareWidgetExtension/Assets.xcassets",
    "MomCare/App/Resources/Fonts/**",
],
```

The widget also needs the font registered in its own Info.plist:
```xml
<key>UIAppFonts</key>
<array>
    <string>Nunito-VariableFont_wght.ttf</string>
</array>
```

**Register Live Activity in WidgetBundle:**
```swift
@main
struct MomCareWidgets: WidgetBundle {
    var body: some Widget {
        NextActionWidget()
        InProgressActivityLiveActivity()
    }
}
```

**Commit:** `feat(widgets): replace placeholder with smart Next Action widget`

---

### Task 9: Hook SharedDataManager into SelfCare + App Launch

**Files:**
- Modify: `MomCare/Features/SelfCare/ViewModels/SelfCareViewModel.swift`
- Modify: `MomCare/App/MomCareApp.swift`

**What to do in SelfCareViewModel:**

After `logAction()` completes, write self-care state:

```swift
// After logging action, update shared data
let items = gridItems.map { item in
    SharedSelfCareItem(
        name: item.actionType.label,
        icon: item.actionType.systemImage,
        isDone: isRecentlyTapped(item.actionType),
        lastDoneDate: todayLogs.first(where: { $0.actionType == item.actionType })?.timestamp
    )
}
SharedDataManager.updateSelfCare(items: items)
```

**What to do in MomCareApp:**

After VMs are created and baby is loaded, write initial state:

```swift
// After babyViewModel loaded
if let baby = babyVM.selectedBaby {
    SharedDataManager.updateBaby(name: baby.name)
}
```

**Commit:** `feat(widgets): sync self-care and baby state to SharedDataManager`

---

### Task 10: Build, Test, Verify

**Steps:**

1. `tuist generate` -- regenerate with updated Project.swift sources/resources
2. `tuist build` -- verify both main app and widget extension compile
3. `tuist test` -- all tests pass
4. `swiftlint --strict` on all new/modified files

**Known challenges:**
- Widget extension may have issues importing main app types. If so, the shared source files (SharedDataManager, InProgressActivityAttributes, EndActivityAppIntent) need careful placement.
- ActivityKit import may need `import ActivityKit` guarded with `#if canImport(ActivityKit)` in files shared with tests.
- The EndActivityAppIntent needs SwiftData models -- ensure the widget sources include the model files OR restructure to avoid that dependency.

**If widget extension can't see SwiftData models:** Move the EndActivityAppIntent to only the main app target (not shared with widget), and use a URL-based deep link for the End button instead of an AppIntent. The deep link approach: `Button { } label: { }.widgetURL(URL(string: "momcare://end-feeding")!)` and handle in MomCareApp's `.onOpenURL`.

**Commit:** `chore(widgets): final build verification and lint`

---

## Summary

| Task | What | Commit |
|------|------|--------|
| 1 | SharedDataManager + tests | feat: shared data |
| 2 | InProgressActivityAttributes | feat: activity attributes |
| 3 | Enable Live Activities in plists | feat: plist config |
| 4 | Live Activity view (lock screen + DI) | feat: activity view |
| 5 | EndActivityAppIntent | feat: end intent |
| 6 | Hook into BabyActivityEngine | feat: engine hooks |
| 7 | Hook into FeedingViewModel | feat: feeding hooks |
| 8 | Next Action widget (replace placeholder) | feat: smart widget |
| 9 | Hook into SelfCare + app launch | feat: self-care sync |
| 10 | Build, test, verify | chore: verification |

## Risk: Widget Extension Compilation

The biggest risk is getting the widget extension to compile with shared types. The Tuist multi-source approach (adding main app paths to widget extension sources) should work but may hit issues with:
- SwiftData model imports in EndActivityAppIntent
- Firebase or other dependencies leaking into widget compilation
- `@MainActor` constraints in shared types

If Task 5's AppIntent approach doesn't compile in the widget extension, fall back to URL-based deep links for the End button. This is a simpler approach that avoids cross-target compilation issues entirely.
