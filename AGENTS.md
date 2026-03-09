# MomCare iOS — Agent Instructions

## Project Context

MomCare is a premium baby & mother care tracking app being rewritten from Flutter to native iOS. This is a clean-room rewrite, not a port — we're redesigning data models and UX while preserving behavioral parity.

## Agent Roles

### Coder Agent
- Implement features as vertical slices (Domain → Data → ViewModel → View)
- Follow @Observable pattern for all ViewModels
- Use SwiftData @Model for persistence, plain structs for domain entities
- Every feature needs: entity, model, repository protocol, repository impl, viewmodel, view
- Write Swift Testing tests alongside implementation

### Reviewer Agent
- Verify Swift 6 strict concurrency compliance
- Check all interactive elements have haptic feedback
- Verify 44pt minimum tap targets
- Ensure dark mode looks correct (OLED blacks, warm accents)
- Validate @Observable usage (not ObservableObject)
- Check SwiftData relationships and #Predicate usage

### Tester Agent
- Use Swift Testing framework exclusively (`import Testing`)
- Structure: `@Suite("Feature Tests")` → `@Test("specific behavior")`
- Use `#expect` for assertions, `#require` for unwrapping
- Mock repositories with protocol conformance
- Test ViewModels in isolation from SwiftData
- Test pattern analysis algorithms with known data sets

### Architect Agent
- Maintain Clean Architecture boundaries (Domain has no dependencies)
- Ensure feature modules are independent vertical slices
- Repository protocols in Domain, implementations in Data
- SwiftUI Environment for dependency injection
- NavigationStack + NavigationPath for type-safe navigation

### Researcher Agent
- Reference Flutter codebase (`baby-mother-care`) for behavioral specs
- Key Flutter files:
  - `lib/domain/entities/` — entity field mappings
  - `lib/services/feeding_pattern_service.dart` — pattern algorithm (port exactly)
  - `lib/data/datasources/local/tables/` — database schema
  - `lib/presentation/blocs/` — business logic
- Check Apple documentation for latest SwiftUI/SwiftData APIs

## Build Order (Linear Issues)

1. **MOM-1**: Foundation (SwiftData, Firebase, design system, DI)
2. **MOM-2**: Baby Management (CRUD, multi-baby, profile)
3. **MOM-3**: Feeding Tracking (timer, types, history, patterns)
4. **MOM-4**: Self-Care (mood, water, meals, daily essentials)
5. **MOM-5**: Mission Control Dashboard
6. **MOM-6**: Diapers (quick-log, 2-second interaction)
7. **MOM-7**: Sleep Tracking (timer, auto nap/night detection)
8. **MOM-8**: Growth Tracking (charts, WHO/CDC curves)
9. **MOM-9**: Health Events (timeline, photos)
10. **MOM-10**: Notifications & App Intents / Siri
11. **MOM-11**: WidgetKit & Live Activities
12. **MOM-12**: Firebase Sync & Partner Sharing
13. **MOM-13**: HealthKit Integration
14. **MOM-14**: Design System Polish
15. **MOM-15**: PDF Export

## Key Decisions

| Decision | Choice | Rationale |
|----------|--------|-----------|
| State management | @Observable | Simpler than Combine, replaces BLoC |
| Persistence | SwiftData | Native ORM, CloudKit-ready |
| Sync | Firebase Firestore | Cross-platform, scales to zero |
| DI | SwiftUI Environment | Native, no third-party |
| Navigation | NavigationStack | Type-safe, deep-link ready |
| Testing | Swift Testing | Modern #expect syntax |
| Concurrency | async/await + actors | Swift 6, replaces streams |

## File Organization

```
MomCare/
├── App/              # Entry point
├── Core/             # DI, design system, services
├── Domain/           # Entities (structs), repository protocols
├── Data/             # @Model classes, Firebase, repo impls
├── Features/         # Vertical slices (Baby, Feeding, SelfCare, etc.)
├── Shared/           # Reusable components
└── Platform/         # Widgets, Live Activities, Siri
```

## Conventions

- Entity structs conform to `Identifiable`, `Codable`, `Hashable`
- @Model classes have `init(from entity:)` and `toEntity()` methods
- Repository protocols are in Domain, implementations in Data
- ViewModels are `@Observable final class` — never `ObservableObject`
- All dates stored as UTC, displayed in local timezone
- UUIDs for all entity IDs
- Firestore document IDs match local UUIDs
