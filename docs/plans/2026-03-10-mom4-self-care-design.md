# MOM-4: Self-Care Tracking with Daily Essentials — Design

## Overview

Maternal self-care tracking reimagined as a low-effort support system, not a checklist. Two layers: a quick-tap action grid for logging physical self-care, and an intelligent contextual card feed that surfaces support based on baby state, learned patterns, and curated content.

**Core philosophy:** Compliance over overwhelm. Passive support, not active burden. The app learns the mom's rhythm — driven by the baby's schedule, not the clock — and gently supports her without configuration or guilt.

## Key Departures from Linear Spec

- **Dropped mood tracker** — replaced with ambient check-in prompts in the card feed
- **Dropped completion ring** — rings say "you're behind." The self-care tab is for doing, not judging. Progress review belongs on the Dashboard (MOM-5).
- **Dropped typed entry system** (mood/water/meal/sleep/exercise/medication as separate rich trackers) — replaced with unified action grid where every tap is a simple log, with optional detail on long-press
- **Added event engine** — card feed is driven by baby state (feeding ended, time patterns) not static layout
- **Added pattern learning** — baby-state-relative patterns (e.g., "she showers ~20min after feeding") not clock-time heuristics
- **Added curated content library** — affirmations, pep talks, check-in prompts shipped as bundled JSON

## Data Model

### Action Types

```swift
enum SelfCareActionType: String, Codable, CaseIterable, Sendable {
    // Hygiene
    case shower, brushTeeth, changeClothes, shave
    // Skincare
    case skincare
    // Wellness
    case meditate, breathingExercise
    // Nutrition
    case water, meal
}
```

### Action Log

Every tap creates one. This is the raw data the pattern service learns from.

```swift
struct SelfCareLog: Identifiable, Codable, Sendable {
    var id: UUID
    var actionType: SelfCareActionType
    var timestamp: Date
    var detail: LogDetail?
}

enum LogDetail: Codable, Sendable {
    case water(glasses: Int)           // default 1
    case meal(MealType)                // breakfast/lunch/dinner/snack
    case exercise(minutes: Int)
    case freeNote(String)              // catch-all for any action
}
```

### Grid Configuration

Per-user, ML-adjustable. Separate from logs — grid is configuration, logs are data.

```swift
struct SelfCareGridItem: Identifiable, Codable, Sendable {
    var id: UUID
    var actionType: SelfCareActionType
    var isVisible: Bool
    var sortOrder: Int           // ML can reorder
    var isCustom: Bool
    var customName: String?
    var customIcon: String?      // SF Symbol
}
```

### SwiftData Models

- `SelfCareLogModel` — `@Model` class mapping to/from `SelfCareLog`
- `SelfCareGridItemModel` — `@Model` class for grid configuration persistence

## Event Engine

### Events

```swift
enum SelfCareEvent: Sendable {
    case feedingEnded(babyId: UUID, duration: TimeInterval)
    case feedingStarted(babyId: UUID)
    case selfCareLogged(SelfCareLog)
    case appOpened
    case timeTick                    // periodic re-evaluation (~15 min)
}
```

### Card Scoring

Each potential card gets a relevance score (0.0 - 1.0) based on weighted signals:

| Signal | Example | Weight |
|--------|---------|--------|
| Event trigger | Feeding just ended -> surface hydration, self-care window | High |
| Pattern match | She usually does X at this time-since-last-feed | High |
| Time gap | No water in 3 hours | Medium |
| Freshness | Haven't shown this affirmation recently | Medium |
| Day progress | Evening + no skincare logged | Low |
| Frequency | She does this daily, hasn't today | Medium |

### Architecture

```
FeedingViewModel --publishes--> SelfCareEngine --scores--> [SelfCareCard]
                                     ^                          |
                              SelfCarePatternService      Card Feed UI
                              (learns from SelfCareLogs)
```

- `SelfCareEngine` is `@Observable`. Card feed view observes it directly.
- `SelfCarePatternService` is a pure function service. Logs in, patterns out. Testable, no side effects.
- Events published via direct method call: `engine.handle(.feedingEnded(...))`.
- Engine never nags. Below-threshold cards don't show. Empty feed is valid: "Everything's good."

## Pattern Service

### ActionPattern

```swift
struct ActionPattern: Sendable {
    let actionType: SelfCareActionType
    let averageTimesPerDay: Double
    let typicalTimestamps: [DateInterval]   // time clusters
    let relativeToFeeding: TimeInterval?    // baby-state-relative
    let streakDays: Int
    let compliance: Double                  // 0-1
    let confidence: Double                  // 0-1
}
```

### Baby-State-Relative Learning

The key differentiator. Instead of "she showers at 2pm," the service learns "she showers ~20 minutes after a feeding ends." Mom's schedule is dictated by the baby, not the clock.

### How Patterns Feed the Engine

1. **Grid reordering** — High-compliance actions sort higher. Actions with `relativeToFeeding` get boosted when a feeding just ended.
2. **Card scoring** — Pattern match signal is strong.
3. **Nudge timing** — Gentle nudges fire when the pattern says she'd normally have done something but hasn't. Buffer window prevents premature nudges.

### Bootstrap Period (first 1-2 weeks)

- `confidence` is low, so pattern-based signals are down-weighted
- Engine falls back to common-sense heuristics: hydration every 2-3 hours, morning/evening skincare, post-feeding window
- Learned patterns gradually override heuristics as data accumulates
- No onboarding wizard — the app just gets smarter

### Analysis Triggers

- On app open
- After each new log entry
- Batch computation over the last 14 days of logs

## UI Layer

### Self-Care Tab Layout

#### 1. Action Grid (top, always visible)

- 3-column grid of rounded square buttons
- Each button: SF Symbol icon + short label underneath
- **Default state**: Warm neutral (dark surface, soft label)
- **Recently tapped**: Subtle warm glow that fades over ~2 hours
- **Tap**: Micro-animation (gentle scale bounce) + haptic + logs `SelfCareLog`
- **Long-press**: Compact detail sheet (water quantity, meal type, free note). No full-screen transitions.
- **Water badge**: Small count showing today's total (e.g., "x4")
- Grid order adapts over time via `SelfCarePatternService`
- "Edit" button (small, top-right) for hide/reorder/add custom actions — optional, never required

#### 2. Contextual Card Feed (below grid, scrollable)

Vertically scrolling cards, sorted by engine relevance score. Cards appear/disappear with gentle animations.

| Card Type | Trigger Example | Content |
|-----------|----------------|---------|
| Hydration nudge | 2+ hours since last water tap | "Staying hydrated? Quick tap above." |
| Self-care window | Feeding just ended | "You have a moment. What do you need?" |
| Affirmation | Periodic, rotated from library | Warm, short affirmation text |
| Pep talk | Low activity day, evening | Longer encouraging message |
| Check-in | Mid-day, pattern-based | "How are you feeling?" + emoji-tap response |
| Streak/pattern | 3+ days consistent action | "3 days of morning skincare -- that's a rhythm." |
| Gentle nudge | Pattern deviation | "You usually hydrate around now." |

- **Empty state**: "Everything's good. You know what you need."
- Cards are dismissible with swipe
- No completion ring, no progress percentage, no guilt

## Content Library

### File Structure

```
MomCare/Core/Content/
  affirmations.json       // ~80-100 entries
  pep-talks.json          // ~30 entries
  check-in-prompts.json   // ~20 entries
  nudge-templates.json    // ~15 templates with placeholders
```

### Affirmation Structure

```swift
struct Affirmation: Codable, Identifiable, Sendable {
    var id: String
    var text: String
    var tags: [Tag]

    enum Tag: String, Codable, Sendable {
        case morning, evening, tired, overwhelmed
        case newMom, milestone, general
    }
}
```

### Nudge Templates

Templates use placeholders the engine fills:

```
"You usually {action} around now. Need a moment?"
"It's been {hours} hours since your last water. Quick sip?"
"3 days of {action} in a row -- that's becoming a habit."
```

### Rotation Rules

- No repeat affirmation within 48 hours
- Pep talks max once per day, scored higher on low-activity days
- Check-in prompts max twice per day
- Streak celebrations show immediately when earned
- Shown content IDs tracked in SwiftData

### Ambient Placement Beyond Self-Care Tab

- **Push notifications** — Timed to pattern-based windows (if enabled)
- **Dashboard cards (MOM-5)** — Rotating affirmation or self-care summary
- **Feeding timer screen** — Subtle affirmation at bottom while timing a feed

### Tone Guidelines

- Never imperative ("Drink water!")
- Always supportive ("Staying hydrated helps you keep going.")
- Never guilt ("You missed your skincare")
- Celebrate consistency, not completion ("Three days in a row -- look at you.")
- Short. One sentence, two max.

## Testing Strategy

### Domain Layer

| Test Suite | Coverage |
|------------|----------|
| `SelfCarePatternServiceTests` | Pattern computation from known log sets. Relative-to-feeding detection. Confidence scaling. Bootstrap heuristic fallback. |
| `SelfCareEngineTests` | Card scoring given events + patterns. Feeding-ended triggers self-care window. Empty feed when below threshold. Nudge timing buffer. |
| `ContentRotationTests` | No repeat affirmations within 48 hours. Pep talk max once/day. Streak triggers. |
| `NudgeTemplateTests` | Placeholder substitution. Edge-case inputs. |

### Data Layer

| Test Suite | Coverage |
|------------|----------|
| `SelfCareLogModelTests` | SwiftData mapping. LogDetail variants round-trip Codable. |
| `SelfCareGridItemModelTests` | Grid config persistence. Custom items survive restart. |
| `SelfCareRepositoryTests` | CRUD for logs. Query by date/action type. Soft delete. |

### ViewModel Layer

| Test Suite | Coverage |
|------------|----------|
| `SelfCareViewModelTests` | Tap logs entry. Long-press detail. Grid reorder after pattern update. Date-scoped retrieval. |

### Integration

| Test Suite | Coverage |
|------------|----------|
| `FeedingToSelfCareTests` | Feeding completion triggers engine event. Card feed updates. Pattern service detects relative-to-feeding timing. |

### Not in v1

- UI snapshot tests
- Push notification delivery
- Foundation Models content generation

## Firestore Schema

```
users/{uid}/selfCare/logs/{logId}
{ actionType: "water", timestamp: Timestamp, detail: { glasses: 1 } }

users/{uid}/selfCare/gridConfig/{itemId}
{ actionType: "shower", isVisible: true, sortOrder: 0, isCustom: false }

users/{uid}/selfCare/contentHistory/{contentId}
{ lastShownAt: Timestamp }
```

## Future Enhancements

- Foundation Models for personalized affirmation generation
- Sleep tracking integration (MOM-6) as additional event source
- Diaper change events as additional triggers
- Cross-device ML pattern sync
- HealthKit integration for automatic exercise/sleep detection
