# MomCare iOS — Claude Code Instructions

## Critical: Always Use Axiom Skills

**Before ANY iOS/Swift response, you MUST invoke the `axiom:ask` skill.**

This is non-negotiable. Even for "simple" questions. The axiom:ask skill routes to specialized iOS knowledge (SwiftUI, SwiftData, concurrency, build issues, etc.) and prevents common mistakes.

```
/axiom:ask <your question or task>
```

If you think there's even a 1% chance an Axiom skill applies, invoke it.

## Critical: Brainstorm Important Decisions

**Before making any significant architectural, design, or technical decision, invoke `superpowers:brainstorming`.**

This includes:
- Adding new dependencies or frameworks
- Changing data models or persistence strategy
- Choosing between implementation approaches
- Designing new feature UX flows
- Modifying the sync/auth architecture
- Any decision that would be hard to reverse

When in doubt, brainstorm first. Fast decisions lead to slow rewrites.

## No Emojis

Never use emojis in code, comments, commit messages, documentation, or UI strings. Keep all output clean and professional.

## Graphics & Icons

- **SF Symbols** for all standard UI icons (tabs, buttons, navigation, status indicators)
- **Nova MCP** for custom graphics, illustrations, and visual assets that SF Symbols cannot cover (onboarding art, empty states, marketing visuals, app icon variants)
- Never use emoji as a substitute for proper icons or graphics
- Never use third-party icon libraries — SF Symbols + Nova MCP covers everything

## Project Overview

- **App**: MomCare — premium baby & mother care tracker
- **Stack**: SwiftUI + @Observable + SwiftData + Firebase (iOS 17+)
- **Architecture**: Clean Architecture with vertical feature modules
- **Concurrency**: Swift 6 strict concurrency (async/await + actors)
- **Testing**: Swift Testing framework (`#expect`, `@Suite`, `@Test`)
- **Project Generation**: Tuist (`Project.swift` → .xcodeproj, managed via mise)
- **Design**: Dark mode PRIMARY, premium & warm, one-handed 3am use

## Project Structure

```
MomCare/
├── App/                    # App entry point, configuration
├── Core/                   # DI, extensions, design system
│   ├── DesignSystem/       # Theme, colors, typography, haptics
│   ├── Extensions/         # Swift/SwiftUI extensions
│   └── Services/           # HealthKit, PDF export, etc.
├── Domain/                 # Entities (structs), repository protocols
├── Data/                   # SwiftData models, Firebase, repo implementations
├── Features/               # Vertical feature slices
│   ├── Baby/               # Models, Views, ViewModels
│   ├── Feeding/            # Flagship feature — timer, patterns, Live Activity
│   ├── SelfCare/           # Mood, water, meals, daily essentials
│   ├── Dashboard/          # Mission Control
│   ├── Diapers/
│   ├── Sleep/
│   ├── Growth/
│   └── HealthEvents/
├── Shared/                 # Reusable UI components
└── Platform/               # Widgets, Live Activities, Siri, Watch
```

## Key Patterns

### Data Flow
```
View → ViewModel (@Observable) → Repository (protocol) → SwiftData / Firebase
                                                        ↕
                                               Domain Entities (structs)
```

### ViewModel Pattern
```swift
@Observable
final class FeedingViewModel {
    private let repository: FeedingRepositoryProtocol
    var feedings: [Feeding] = []
    var isLoading = false

    func loadFeedings(for babyId: UUID) async { ... }
}
```

### SwiftData Models
- `@Model` classes in `Data/Models/`
- Domain entities are plain structs in `Domain/Entities/`
- Repositories map between the two

### Firebase
- Firestore for opt-in sync and partner sharing
- Auth: Sign in with Apple + Google + anonymous
- Local-first: SwiftData is source of truth

## Build & Run

```bash
# Install/update external dependencies (run after changing Tuist/Package.swift)
tuist install

# Generate Xcode project (run after changing Project.swift or Tuist/Package.swift)
tuist generate

# Build
tuist build

# Test
tuist test

# Lint (run after every task / before every commit)
swiftlint --strict
```

Tuist is installed via mise (see `mise.toml`). Run `mise install` if `tuist` is not found.

## Linting

- **SwiftLint** with `--strict` is required after every task and before every commit
- All warnings are treated as errors in strict mode
- Fix all violations before committing -- no exceptions

## UI Libraries

- **ComponentsKit** — pre-built UI components (buttons, cards, modals, inputs, badges, etc.). Use as the primary component library before building custom components.
- **Lottie** — After Effects animations for onboarding, empty states, and celebrations. Use for rich animations that SF Symbols cannot cover.
- **Pow** — SwiftUI transitions and change effects (shake, shine, spray, haptic feedback). Use for micro-interactions and delightful feedback on user actions.
- **SkeletonUI** — loading placeholder skeletons. Use for all loading states instead of plain spinners.

### When to use what
- Loading states → SkeletonUI
- Buttons, cards, inputs, modals → ComponentsKit first, custom second
- Transitions, tap feedback, value changes → Pow
- Rich animations (onboarding, milestones) → Lottie
- Icons → SF Symbols (never third-party icon libs)
- Custom illustrations → Nova MCP

## Dependency Injection

Microapps-style DI using SwiftUI Environment + factory protocols (no third-party DI libraries):
- `DependencyContainer` protocol defines factory methods
- `AppDependencies` provides real implementations backed by SwiftData
- Injected via `@Environment(\.dependencies)` in views
- Tests use stub implementations conforming to repository protocols

## Conventions

- **No XCTest** — use Swift Testing (`import Testing`, `#expect`, `@Test`)
- **No Combine** — use `@Observable` and async/await
- **No third-party DI** — use SwiftUI `Environment` + factory protocols (microapps pattern)
- **SF Symbols** for all icons
- **Haptics** on every interactive element
- **44pt minimum** tap targets
- **Dark mode first** — design for OLED, then adapt light mode

## Linear Issues

All work is tracked in Linear under team **MomCare** (MOM-1 through MOM-17).
- iOS App project: issues MOM-1 to MOM-15, MOM-17
- Android App project: MOM-16

## Flutter Reference

The archived Flutter codebase at `baby-mother-care` serves as behavioral reference.
Key files for porting:
- `lib/domain/entities/` — entity definitions
- `lib/services/feeding_pattern_service.dart` — pattern analysis algorithm (port exactly)
- `lib/data/datasources/local/tables/` — database schema reference

## File Organization

- Source code in `MomCare/` (feature directories)
- Tests in `MomCareTests/` (mirror source structure)
- UI tests in `MomCareUITests/`
- Widget extension in `MomCareWidgetExtension/`
- Documentation in `docs/`
- Never save working files to the root directory
