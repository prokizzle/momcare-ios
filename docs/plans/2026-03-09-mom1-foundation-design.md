# MOM-1: Project Foundation & Design System -- Design

*Approved: 2026-03-09*

## Decisions

- **Design tokens**: Static enums with `MC` prefix namespace (not structs/themes)
- **Repository pattern**: Generic base `Repository<Entity>` protocol + feature-specific sub-protocols
- **DI**: Protocol + SwiftUI `EnvironmentKey` (no third-party)
- **Navigation**: `@Observable AppNavigation` with one `NavigationPath` per tab
- **Firebase**: Set up now with `GoogleService-Info.plist` in place (gitignored)

## 1. Design System (`MomCare/Core/DesignSystem/`)

### MCColor (ColorTokens.swift)
Semantic colors via asset catalog colorsets (auto light/dark switching):
- `accent` -- warm coral/pink (already exists in AccentColor asset)
- `feeding` -- warm blue: sRGB(0.35, 0.58, 0.87) / dark: sRGB(0.45, 0.68, 0.95)
- `selfCare` -- soft purple: sRGB(0.62, 0.45, 0.82) / dark: sRGB(0.72, 0.55, 0.92)
- `babyStatus` -- gentle green: sRGB(0.35, 0.75, 0.55) / dark: sRGB(0.45, 0.85, 0.65)
- `Urgency` nested enum: safe (green), warning (yellow), urgent (orange)

3 new colorsets in asset catalog: `FeedingColor`, `SelfCareColor`, `BabyStatusColor`.

### MCTypography (Typography.swift)
Semantic `Font` static properties, all Dynamic Type compliant:
- `largeTimer` -- system size 72, thin weight, rounded design
- `cardTitle` -- .headline
- `cardBody` -- .callout
- `timestamp` -- .caption.monospacedDigit()

### MCSpacing (Spacing.swift)
4pt grid system:
- xs=4, sm=8, md=12, lg=16, xl=24, xxl=32, section=40

### MCHaptic (HapticManager.swift)
`@MainActor` enum with static methods:
- `tap()` -- light impact
- `toggle()` -- medium impact
- `success()` / `error()` -- notification feedback
- `select()` -- selection changed

## 2. Repository Pattern (`MomCare/Domain/Repositories/`)

Generic base protocol:
```swift
protocol Repository<Entity>: Sendable {
    associatedtype Entity: Identifiable & Sendable
    func getAll() async throws -> [Entity]
    func getById(_ id: Entity.ID) async throws -> Entity?
    func create(_ entity: Entity) async throws -> Entity
    func update(_ entity: Entity) async throws -> Entity
    func delete(_ id: Entity.ID) async throws
}
```

Only the base protocol in MOM-1. Feature-specific protocols come in MOM-2+.

## 3. Dependency Injection (`MomCare/Core/DI/`)

- `DependencyContainer` protocol with factory methods for repositories/services
- `AppDependencies` concrete class
- Custom `EnvironmentKey` for `@Environment(\.dependencies)` access
- Container starts mostly empty; factories added per feature

## 4. Navigation Shell (`MomCare/App/`)

`@Observable AppNavigation`:
- `selectedTab: AppTab` enum (dashboard, feeding, selfCare, insights)
- One `NavigationPath` per tab (preserves back stacks)
- `func handleURL(_ url: URL)` stub for deep links
- `ContentView` updated with `NavigationStack` per tab

## 5. Firebase Init

- `FirebaseApp.configure()` in `MomCareApp.init()`
- Analytics + Crashlytics initialization
- `GoogleService-Info.plist` in place (gitignored)

## 6. App Entry Point

- Wire `AppDependencies` and `AppNavigation` into environment
- SwiftData `ModelContainer` keeps empty schema (models added per feature)

## Firebase Project

- Project ID: `momcare-ios`
- Bundle ID: `com.feelingmindful.momcare`
- Services: Firestore (nam5), Auth (Anonymous + Google Sign-In)
