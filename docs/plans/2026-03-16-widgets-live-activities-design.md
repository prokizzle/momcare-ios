# Smart Widget + Generic Live Activity Design

## Goal

Build a smart "Next Action" widget and a generic Live Activity for any in-progress timer (feeding, nap). The widget surfaces the single most relevant thing a parent needs to do right now. The Live Activity shows elapsed time on the lock screen and Dynamic Island for any active timer, with an "End" button that works without opening the app.

## SharedDataManager

Lightweight key-value snapshot in `UserDefaults(suiteName: "group.com.feelingmindful.momcare")`. The main app writes on every state change; the widget reads instantly.

### Keys

| Key | Type | Source |
|-----|------|--------|
| `babyName` | String | BabyViewModel |
| `lastFeedingTime` | Date? | FeedingViewModel/BabyActivityEngine |
| `lastFeedingType` | String? | FeedingViewModel/BabyActivityEngine |
| `isFeedingInProgress` | Bool | BabyActivityEngine |
| `feedingStartTime` | Date? | BabyActivityEngine |
| `feedingDetail` | String? | "Left breast", "Bottle", etc. |
| `isNapInProgress` | Bool | BabyActivityEngine |
| `napStartTime` | Date? | BabyActivityEngine |
| `todayFeedingCount` | Int | FeedingViewModel |
| `selfCareItems` | Data? | Encoded [{name, icon, isDone, lastDoneDate}] |
| `nextVaccineName` | String? | VaccineScheduleService |
| `nextVaccineAgeMonths` | Int? | VaccineScheduleService |

### Write Triggers

- `BabyActivityEngine.startFeeding/endFeeding/startNap/endNap`
- `FeedingViewModel.startFeeding/endFeeding/toggleBreastSide`
- `SelfCareViewModel` on item toggle
- App foreground (`scenePhase .active`)

After each write: `WidgetCenter.shared.reloadAllTimelines()`

## Next Action Widget

### Priority System

| # | Condition | Icon | Title | Detail |
|---|-----------|------|-------|--------|
| 1 | Feeding in progress | drop.fill | "Feeding" | Live timer |
| 2 | Nap in progress | moon.stars.fill | "Napping" | Live timer |
| 3 | >3 hrs since last feed | drop.fill | "Time to feed" | "Last fed 3h 20m ago" |
| 4 | Vaccine due | syringe.fill | Vaccine name | "Due at X months" |
| 5 | Self-care item (streak) | Item's icon | Item name | "Not done since yesterday" |
| 6 | All caught up | checkmark.circle | "All good" | "Last fed 45m ago" |

### Self-Care Streak Logic

Sort uncompleted self-care items by `lastDoneDate` ascending. The item the user has neglected longest surfaces first. Specific and actionable ("Drink water") rather than generic ("3 items remaining").

### Widget Sizes

**Small:** Next action only -- icon, title, detail. Nunito for title text, system widget background, accent-colored icon.

**Medium:** Next action prominently at top + up to 2 secondary items below in compact rows.

### Visual Style (Hybrid)

- System `.widgetBackground` for wallpaper blending
- Nunito font for primary text (brand signature)
- SF Pro for secondary/detail text
- Accent colors for activity icons (MCColor.feeding, MCColor.baby, etc.)
- MCRadius for internal corner details

### Timeline Strategy

- Active timer: Use `Text(date, style: .timer)` for live countdown (no timeline updates needed)
- No active timer: 15-minute refresh interval
- `WidgetCenter.shared.reloadAllTimelines()` called on every `SharedDataManager.update()`

## Generic Live Activity

### InProgressActivityAttributes

```swift
struct InProgressActivityAttributes: ActivityAttributes {
    let babyName: String
    let activityType: String      // "feeding" or "nap"
    let activityIcon: String      // SF Symbol name

    struct ContentState: Codable, Hashable {
        let startTime: Date
        let detail: String?       // "Left breast", "Bottle", nil for nap
    }
}
```

### Lock Screen (Expanded)

- Baby name + activity type at top
- Large timer: `Text(startTime, style: .timer)` in Nunito
- Detail text (breast side / bottle type) if present
- "End" button via EndActivityIntent -- stops timer without opening app

### Dynamic Island

**Compact:**
- Leading: activity icon (colored)
- Trailing: elapsed timer

**Expanded:**
- Same layout as lock screen

### Lifecycle

| Event | Action |
|-------|--------|
| `BabyActivityEngine.startFeeding()` | `Activity.request(attributes:content:)` |
| `FeedingViewModel.toggleBreastSide()` | `activity.update(content:)` |
| `BabyActivityEngine.endFeeding()` | `activity.end(dismissalPolicy: .default)` |
| `BabyActivityEngine.startNap()` | `Activity.request(attributes:content:)` |
| `BabyActivityEngine.endNap()` | `activity.end(dismissalPolicy: .default)` |

## EndActivityIntent (App Intent)

```swift
struct EndActivityIntent: AppIntent {
    static let title: LocalizedStringResource = "End Activity"

    @Parameter(title: "Activity Type")
    var activityType: String

    func perform() async throws -> some IntentResult {
        // Access BabyActivityEngine via DI
        // Call endFeeding() or endNap()
        // Update SharedDataManager
        // End Live Activity
        // Reload widget timelines
    }
}
```

Runs in the main app process (not widget extension), so it can access SwiftData and repositories normally.

## Files

```
MomCare/Platform/Shared/SharedDataManager.swift
MomCare/Platform/LiveActivities/InProgressActivityAttributes.swift
MomCare/Platform/LiveActivities/InProgressActivityView.swift
MomCare/Platform/Intents/EndActivityIntent.swift

MomCareWidgetExtension/NextActionWidget.swift
MomCareWidgetExtension/NextActionProvider.swift
MomCareWidgetExtension/NextActionEntryView.swift

Modified:
MomCare/App/Info.plist                    -- add NSSupportsLiveActivities
MomCare/Features/Baby/ViewModels/BabyActivityEngine.swift  -- add Live Activity hooks
MomCare/Features/Feeding/ViewModels/FeedingViewModel.swift -- add Live Activity update
MomCare/Features/SelfCare/ViewModels/SelfCareViewModel.swift -- write to SharedDataManager
MomCare/App/MomCareApp.swift              -- write baby name + initial state on launch
```

## Info.plist Changes

Add to `MomCare/App/Info.plist`:
```xml
<key>NSSupportsLiveActivities</key>
<true/>
```
