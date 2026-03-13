# Sleep Tracking UI Design

## Overview

Build the UI layer for MOM-7 sleep tracking. The data layer (entity, model, repository, schema migration, DI, activity engine) is complete. This design covers the timer view, history view, view model, and navigation wiring.

## Architecture

Follows the Feeding feature pattern: `SleepViewModel` (`@Observable`) drives `SleepTimerView` and `SleepHistoryView`. `BabyActivityEngine` handles nap start/stop and timer ticks. `SleepViewModel` delegates to the engine and adds quality/location selection on sleep end.

## SleepTimerView

Mirrors FeedingTimerView:

- Black full-screen background (3am use, OLED-friendly)
- Large timer display using MCTypography.largeTimer (72pt, thin, rounded), monospacedDigit(), contentTransition(.numericText())
- Sleep type chip at top -- auto-detected via SleepType.autoDetect(), tappable to override with MCHaptic.toggle()
- Location picker -- collapsible row with SleepLocation cases as horizontal chips, optional
- "End Sleep" button -- 56pt height, rounded corners (16pt), triggers quality sheet
- Quality sheet -- 3 tappable options (good/fair/poor) using SleepQuality.systemImage, dismisses and saves on tap with MCHaptic.success()

## SleepHistoryView

Follows FeedingHistoryView / DiaperHistoryView patterns:

- Daily summary header showing total sleep duration per day
- List sections grouped by day
- Each entry: sleep type icon, start/end times, duration, quality stars
- Swipe to delete with confirmation dialog
- Empty state via ContentUnavailableView
- .listStyle(.insetGrouped)

## SleepViewModel

```swift
@Observable @MainActor
final class SleepViewModel {
    private(set) var sleeps: [BabySleep] = []
    private(set) var groupedSleeps: [(String, [BabySleep])] = []
    var selectedLocation: SleepLocation?
    var selectedQuality: SleepQuality?
    var showQualitySheet: Bool = false

    func loadSleeps(babyId: UUID) async
    func endSleep(babyId: UUID) async   // sets quality + location, delegates to engine
    func deleteSleep(id: UUID) async
}
```

## Navigation

- BabyScreen nap card tap starts nap via engine (already works)
- Tapping active nap card pushes SleepTimerView onto babyPath NavigationStack
- SleepHistoryView accessible from Baby tab
- Navigation uses existing AppNavigation.babyPath

## Files

```
MomCare/Features/Sleep/ViewModels/SleepViewModel.swift
MomCare/Features/Sleep/Views/SleepTimerView.swift
MomCare/Features/Sleep/Views/SleepHistoryView.swift
```

## Design System Usage

- Colors: MCColor.baby for sleep-related accents
- Typography: MCTypography.largeTimer for timer, .cardTitle/.cardBody for history
- Spacing: MCSpacing constants (xs/sm/md/lg/xl)
- Haptics: MCHaptic.tap() on interactions, .toggle() on type switch, .success() on end sleep
- Loading: SkeletonUI for loading states
- Transitions: Pow for value change effects on timer
