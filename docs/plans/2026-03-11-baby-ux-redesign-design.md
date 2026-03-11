# Baby UX Redesign — Design Document

**Date**: 2026-03-11
**Status**: Approved
**Covers**: MOM-7 (Sleep), MOM-8+ (Baby tab, Now tab, Journal, Plan)

## Context

The current app has separate Feeding, Diapers, and Dashboard tabs. The timer-based
feeding UI requires navigating to a dedicated in-progress screen. Baby activity data
is siloed per feature with no unified history.

This redesign unifies all baby tracking into a cohesive, thumb-friendly experience
modeled on the Self-Care card grid pattern, makes way for a Plan tab with development
strategy selection, and evolves Dashboard into a live "Now" surface with ML-curated
smart actions.

---

## Tab Structure

```
Now | Baby | Self-Care | Journal | Plan
```

- **Now** — Live, present-moment home tab. Replaces Mission Control / Dashboard.
- **Baby** — Full baby action card grid. Central tracking surface.
- **Self-Care** — Unchanged. Retains prominent position (app differentiator).
- **Journal** — Timeline history, grouped by day, filterable. Dedicated history tab.
- **Plan** — Development strategy selector + guidance.

Tab selection persists via `@SceneStorage("selectedTab")`.

---

## Architecture

### BabyActivityEngine

A shared `@Observable` class injected via `.environment()` at the root level.
Single source of truth for all active baby activity state across tabs.

```
@Observable
final class BabyActivityEngine {
    var activeNap: ActiveNap?           // nil = no nap in progress
    var activeFeeding: ActiveFeeding?   // nil = no feeding in progress
    var pendingDiaperNote: DiaperEntry? // non-nil = awaiting optional notes

    var suggestedActions: [BabyAction]  // sync computed, scored by engine
    var suggestions: [SmartSuggestion]  // sync computed, mixed baby + self-care
}
```

Injected at app root:
```swift
RootView()
    .environment(babyActivityEngine)
    .environment(selfCareEngine)      // existing
```

Views read via:
```swift
@Environment(BabyActivityEngine.self) private var engine
```

### Activity State Machine

Each trackable activity follows:

```
idle → active → [needs-detail] → complete
```

- **idle**: Card shows primary action (Start Nap, Start Feeding, Log Diaper)
- **active**: Card transforms in-place — shows elapsed time + End action
- **needs-detail** (diaper only): Card briefly morphs to Wet/Dirty/Both selector (3s timeout)
- **complete**: Entry written to SwiftData, card returns to idle

State transitions are synchronous + `withAnimation`. SwiftData writes happen in
async `Task` (State-as-Bridge pattern, WWDC 2025).

---

## Now Tab

Replaces Mission Control Dashboard. Tab label: "Now".

### Layout (top to bottom)

**Baby Status Strip**
Compact horizontal summary of current baby state:
- Active nap: "Napping • 1h 12m" with pulsing indicator
- Active feeding: "Feeding • Left • 8m"
- Idle: "Fed 2h ago · Napped 3h ago · Diaper 1h ago"

Each stat is tappable: active states navigate to Baby tab with card highlighted;
historical stats navigate to Journal.

**Smart Actions (2–4 cards)**
ML/event-engine scored subset of baby and self-care actions. Same card visual as
Baby and Self-Care tabs (`.ultraThinMaterial`, 80pt, haptics). If a nap is active,
"End Nap • elapsed" appears here. Engine scores by: active strategy, time of day,
recency, Self-Care streaks.

**Smart Suggestions Feed**
Scrollable vertical feed of suggestion cards:
- Journal entries needing follow-up ("Short nap — 22 min. Add context?")
- Self-Care nudges ("No water logged today")
- Plan strategy tips relevant to current state
- Pattern observations ("Baby napping at 10am consistently")

All suggestion cards navigate to Journal, Baby, or Self-Care — no dead ends.

---

## Baby Tab

Full action card grid. Same pattern as Self-Care: 3-column `LazyVGrid`, 80pt cards,
`.ultraThinMaterial` background, spring scale animation on tap, haptics on every
interaction.

### Cards

**Nap Card**
- Idle: moon icon + "Nap"
- Tap: starts nap, card transforms in-place to "End Nap • 0:00" with elapsed counter
  and pulsing indicator
- Tap again: ends nap, writes BabySleep to SwiftData, returns to idle
- Sleep type auto-detected by hour (19:00–06:00 = nighttime, else nap)

**Feeding Card**
- Idle: bottle icon + "Feed"
- Tap: presents half-sheet (`.sheet`) with three large thumb buttons: Left / Right / Bottle
- Selection: sheet dismisses, card transforms in-place to "Feeding • Left • 0:00"
- Tap again: ends feeding, writes BabyFeeding to SwiftData, returns to idle

**Diaper Card**
- Idle: diaper icon + "Diaper"
- Tap: logs diaper with timestamp, card morphs to Wet / Dirty / Both selector
- Selection or 3-second timeout: logs type, returns to idle
- If noteworthy (unusual), a suggestion card appears on Now tab

**Growth Card** (placeholder)
- Locked state, labeled "Growth"
- Tapping shows "Coming soon" — future milestone

### No In-Progress Screens
Cards contain all state. No navigation on start/end.

---

## Journal Tab

Timeline of all baby and self-care events, grouped by day.

**Layout**
- Section headers: "Today", "Yesterday", "Mon Mar 9"
- Each entry row: icon + type + timestamp + duration/amount
- Tap entry: detail sheet for view and edit

**Filters**
Chip row at top: All / Naps / Feeding / Diapers / Self-Care

**Data**
SwiftData fetch with 90-day limit. No pagination needed initially.

**Entry point from Now tab**
Suggestion cards and status strip stats navigate here.

---

## Plan Tab

Gives moms a framework, not just a log.

### Strategy Selector
On first open: picker with 4–6 curated development strategies.
Content sourced via Firecrawl and stored locally (offline-capable).

Examples: Babywise, Ferber, Montessori, Wonder Weeks, Attachment Parenting,
Eat-Play-Sleep.

Each strategy card: name, one-line philosophy, 3 key principles, Select button.
One active strategy at a time. Can be changed anytime.

### Active Strategy View
- Strategy name + philosophy summary
- Today's guidance card (age + strategy relevant tip)
- Transparency note: "We're surfacing feeding reminders because Babywise
  prioritizes feeding schedules"

### Progress (Phase 2)
- Nap pattern chart (last 7 days)
- Feeding frequency heatmap
- Milestone tracker

---

## SwiftData Changes

### New Models
- `BabySleepModel` — already created on current branch (SchemaV4)
- Feeding model already exists (`FeedingModel`)
- Diaper model already exists (`DiaperModel`)

### No schema changes needed for this redesign
The redesign is a UI/navigation change. Existing models support it.

---

## Property Wrapper Summary

| Object | Wrapper | Rationale |
|---|---|---|
| `BabyActivityEngine` | `.environment()` + plain property in views | Cross-tab shared state, @Observable handles tracking |
| Active nap/feeding state | Properties on engine | Engine is the source of truth |
| Feeding selector sheet | `@State var showFeedingSelector` | Local to card view |
| Tab selection | `@SceneStorage("selectedTab")` | Restored after app kill |
| BabyActivityEngine creation | `@State` in app root | Root owns lifecycle |

---

## Files Affected

### New
- `MomCare/Features/Baby/` — new feature directory
  - `ViewModels/BabyActivityEngine.swift`
  - `Views/BabyScreen.swift`
  - `Views/BabyActionCardView.swift`
  - `Views/FeedingSelectorSheet.swift`
- `MomCare/Features/Now/` — replaces Dashboard
  - `Views/NowScreen.swift`
  - `Views/BabyStatusStrip.swift`
  - `Views/SmartSuggestionCard.swift`
- `MomCare/Features/Journal/`
  - `Views/JournalScreen.swift`
  - `Views/JournalEntryRow.swift`
  - `Views/JournalEntryDetailSheet.swift`
- `MomCare/Features/Plan/`
  - `Views/PlanScreen.swift`
  - `Views/StrategyCardView.swift`
  - `Models/DevelopmentStrategy.swift`

### Modified
- `MomCare/App/ContentView.swift` — new tab structure
- `MomCare/App/MomCareApp.swift` — inject BabyActivityEngine
- `MomCare/App/AppNavigation.swift` — new tab cases
- `MomCare/Core/DI/Dependencies.swift` — BabyActivityEngine factory

### Deprecated
- `MomCare/Features/Dashboard/` — replaced by Now
- Feeding timer in-progress screen — replaced by in-place card

---

## Design Constraints

- Dark mode primary, OLED-optimized
- 44pt minimum tap targets on all interactive elements
- Haptics on every card tap
- One-handed thumb use (bottom-weighted layout)
- No emojis in UI strings — SF Symbols only
- Swift 6 strict concurrency throughout
