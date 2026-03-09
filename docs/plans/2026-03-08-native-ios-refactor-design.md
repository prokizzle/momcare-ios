# Native iOS Refactor — Design Document

*Last updated: 2026-03-08*

## Decision Summary

| Aspect | Decision |
|--------|----------|
| **Approach** | Clean room rewrite, feature-by-feature vertical slices |
| **iOS stack** | SwiftUI + @Observable + SwiftData + Firebase (iOS 17+) |
| **Android stack** | Kotlin + Jetpack Compose + Room + Firebase |
| **Architecture** | Clean Architecture with vertical feature modules |
| **Sync** | Firebase Firestore, local-first, opt-in |
| **Android timing** | Starts mid-iOS development, ships shortly after |
| **Flutter** | Killed. Archived as behavioral reference. |
| **Design philosophy** | Premium & warm — luxury feel that genuinely cares |
| **Phase 1 scope** | Full feature parity + redesigned data models + unbuilt features |

## Motivation

- Full native experiences on both iOS and Android
- Deep platform integration (Widgets, Live Activities, Siri, HealthKit, Apple Watch)
- Competing against clunky incumbent baby tracking apps
- Apple HIG compliance at every step
- Maintenance simplicity — no Flutter overhead

## Architecture

### Project Structure

```
MomCare/
├── App/                    # App entry point, configuration
├── Core/                   # DI, extensions, design system
├── Domain/                 # Entities (structs), repository protocols, services
├── Data/                   # SwiftData models, Firebase, repository implementations
├── Features/               # Feature modules (vertical slices)
│   ├── Baby/               # Models, Views, ViewModels
│   ├── Feeding/
│   ├── SelfCare/
│   ├── Dashboard/
│   ├── Diapers/
│   ├── Sleep/
│   ├── Growth/
│   └── HealthEvents/
├── Shared/                 # Reusable UI components, design tokens
└── Platform/               # Widgets, Live Activities, Siri, Watch
```

### Tech Stack

| Concern | Choice | Rationale |
|---------|--------|-----------|
| UI | SwiftUI | Native, declarative, iOS 17+ |
| State | `@Observable` ViewModels | Simpler than Combine, replaces BLoC |
| Persistence | SwiftData | Native ORM, CloudKit-ready, replaces Drift |
| Sync | Firebase Firestore | Cross-platform, scales to zero, familiar |
| DI | Swift `Environment` + factory protocol | Native to SwiftUI, no third-party |
| Navigation | `NavigationStack` + `NavigationPath` | Type-safe, deep-link ready |
| Concurrency | Swift async/await + actors | Modern, safe, replaces streams |
| Testing | Swift Testing framework | Modern `#expect` syntax |

### Data Flow

```
View → ViewModel (@Observable) → Repository (protocol) → SwiftData / Firebase
                                                       ↕
                                              Domain Entities (structs)
```

### Data Model Redesign

- Replace monolithic `SelfCareEntry` with typed structs
- Swift enums with associated values instead of string-based types
- `@Relationship` for SwiftData instead of manual foreign keys
- `CodingKey` conformance for Firebase serialization
- New: Daily essentials as user-customizable checklist items

## Feature Design

### Build Order

1. Project foundation — Xcode project, SwiftData schema, Firebase setup, design system
2. Baby management — CRUD, multi-baby support
3. Feeding tracking — Full feature, establishes all patterns
4. Self-care — Follows feeding patterns
5. Mission Control dashboard — Ties it all together
6. Diapers — Quick-log with minimal friction
7. Sleep tracking — Start/stop timer with auto nap/night detection
8. Growth tracking — Chart-first with WHO/CDC curves
9. Health events — Timeline view with photo support
10. Platform features — Widgets, Live Activities, Siri, Apple Watch

### Baby Management

- Single-screen onboarding with progressive disclosure
- Tab-based baby switcher in navigation bar
- Full-screen profile card with inline editing

### Feeding Tracking (Flagship)

- One-tap start — large button, no modal, no form
- Live Activity on Lock Screen with elapsed time, breast side, stop button
- Dynamic Island compact view with timer + side indicator
- Full-screen timer designed for one-handed 3am use with haptics
- Segmented control for type (Breast, Bottle, Pumping, Solids)
- History grouped by day with swipe actions
- Inline pattern insights card (average interval, predicted next, confidence)

### Self-Care

- Two tiers: tracked categories + daily essentials
- **Tracked categories**: Mood (slider), Water (ring + tap), Meals (chips), Sleep, Exercise, Medication
- **Daily essentials** (new): Toggle checklist — teeth brushing, shower, skincare, vitamins, went outside, custom user-defined items
- Activity Rings-style daily completion indicator
- Date navigation for past/future days

### Mission Control Dashboard

- Baby status card with live "time since" counters, color-coded urgency
- Mom status card with completion ring, mood, water, last meal
- Smart contextual suggestions based on patterns and time gaps

### Diapers (New UI)

- Quick-log: type toggle (wet/dirty/both), optional stool details
- Target: 2-second interaction

### Sleep (New UI)

- Start/stop timer like feeding
- Auto-detect nap vs. nighttime based on time of day
- Quality logged on wake

### Growth (New UI)

- Chart-first: WHO/CDC growth curves with baby's measurements overlaid
- Simple measurement form
- PDF export for pediatrician visits

### Health Events (New UI)

- Timeline view
- Log vaccines, illnesses, milestones, doctor visits
- Photo support (rash documentation, etc.)

## HIG Principles

| Principle | Application |
|-----------|-------------|
| Clarity | Large tap targets, clear typography, SF Symbols |
| Deference | Content-first, no chrome competing with data |
| Depth | Meaningful sheets, popovers, navigation transitions |
| Direct manipulation | Swipe actions, drag to reorder, long-press menus |
| Feedback | Haptics on every interaction |
| Consistency | Standard navigation, platform tab bar, native pickers |

## Platform Integration

### WidgetKit

- **Feeding Timer** (Small): Countdown to next predicted feeding or active timer
- **Daily Summary** (Medium): Feeding count + self-care ring
- **Quick Actions** (Small): 2x2 grid — Start Feed, Log Diaper, Log Water, Log Mood
- **Growth Chart** (Large): Mini growth curve with latest measurement

### Live Activities & Dynamic Island

- Active feeding: timer, breast side, tap to expand
- Sleep tracking: elapsed nap time, quality log on end

### App Intents & Siri

- "Start a feeding" → launches timer
- "Log a diaper change" → quick confirmation
- "How long since the last feeding?" → spoken response
- "Log 2 glasses of water" → confirmed with haptic
- Spotlight search integration

### Apple Watch (Phase 2)

- Feeding timer complication
- Start/stop from wrist
- Quick diaper log, water increment
- Glanceable baby status

### HealthKit

- Write: baby growth measurements
- Read: mom's sleep and step data
- Bidirectional: self-care sleep ↔ Health app

### Notifications

- Smart feeding reminders based on pattern analysis
- Gentle self-care nudges respecting Focus modes
- Milestone celebrations

## Firebase Architecture

### Firestore Structure

```
users/{uid}/
├── profile                    # Preferences, subscription tier
├── babies/{babyId}/
│   ├── feedings/{id}
│   ├── diapers/{id}
│   ├── sleeps/{id}
│   ├── growth/{id}
│   └── healthEvents/{id}
├── selfCare/{date}/
│   ├── entries/{id}           # Tracked categories
│   └── essentials/{id}        # Daily toggles
└── sharing/{partnerId}        # Partner access grants
```

### Sync Strategy

- Local-first: SwiftData is source of truth, works fully offline
- Opt-in sync for multi-device and partner sharing
- Last-write-wins conflict resolution with timestamps
- Real-time Firestore snapshot listeners for partner sharing

### Authentication

- Sign in with Apple (required) + Google Sign-In
- Anonymous auth for try-before-signup
- Account linking for anonymous → registered

### Partner Sharing

- Invite via link/QR code
- Read/write access to baby data only (self-care private by default)
- Optional self-care sharing
- Real-time updates

## Android Strategy

- Starts mid-iOS development once architecture is proven
- Kotlin + Jetpack Compose + Room + same Firebase backend
- Material Design 3 — native Android feel, not an iOS port
- Feature parity with platform-native UI idioms

## Dark Mode

Primary design target — not an afterthought. Reduced contrast, warm accents, OLED-true blacks. Optimized for 3am feeds.

## Design Philosophy

Premium & warm. Luxury feel that genuinely cares. "Like a knowledgeable friend, not a textbook." One-tap everything. Designed for one-handed, sleep-deprived use. Every interaction has haptic feedback. The app should make clunky competitors feel ancient.
