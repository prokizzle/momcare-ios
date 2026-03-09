# MOM-1: Project Foundation & Design System -- Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Build the foundational infrastructure (design system, DI, navigation, repository protocol, Firebase init) that all MomCare features depend on.

**Architecture:** Static enum design tokens with MC prefix, generic Repository protocol, SwiftUI Environment-based DI, @Observable navigation state with per-tab NavigationPath. Firebase configured at app launch.

**Tech Stack:** SwiftUI, SwiftData, Swift 6 (strict concurrency), Swift Testing, Firebase (Auth, Firestore, Analytics, Crashlytics), XcodeGen

---

### Task 1: Color Asset Catalogs

**Files:**
- Create: `MomCare/App/Assets.xcassets/FeedingColor.colorset/Contents.json`
- Create: `MomCare/App/Assets.xcassets/SelfCareColor.colorset/Contents.json`
- Create: `MomCare/App/Assets.xcassets/BabyStatusColor.colorset/Contents.json`

**Step 1: Create FeedingColor colorset**

Create `MomCare/App/Assets.xcassets/FeedingColor.colorset/Contents.json`:

```json
{
  "colors" : [
    {
      "color" : {
        "color-space" : "srgb",
        "components" : {
          "alpha" : "1.000",
          "blue" : "0.870",
          "green" : "0.580",
          "red" : "0.350"
        }
      },
      "idiom" : "universal"
    },
    {
      "appearances" : [
        {
          "appearance" : "luminosity",
          "value" : "dark"
        }
      ],
      "color" : {
        "color-space" : "srgb",
        "components" : {
          "alpha" : "1.000",
          "blue" : "0.950",
          "green" : "0.680",
          "red" : "0.450"
        }
      },
      "idiom" : "universal"
    }
  ],
  "info" : {
    "author" : "xcode",
    "version" : 1
  }
}
```

**Step 2: Create SelfCareColor colorset**

Create `MomCare/App/Assets.xcassets/SelfCareColor.colorset/Contents.json`:

```json
{
  "colors" : [
    {
      "color" : {
        "color-space" : "srgb",
        "components" : {
          "alpha" : "1.000",
          "blue" : "0.820",
          "green" : "0.450",
          "red" : "0.620"
        }
      },
      "idiom" : "universal"
    },
    {
      "appearances" : [
        {
          "appearance" : "luminosity",
          "value" : "dark"
        }
      ],
      "color" : {
        "color-space" : "srgb",
        "components" : {
          "alpha" : "1.000",
          "blue" : "0.920",
          "green" : "0.550",
          "red" : "0.720"
        }
      },
      "idiom" : "universal"
    }
  ],
  "info" : {
    "author" : "xcode",
    "version" : 1
  }
}
```

**Step 3: Create BabyStatusColor colorset**

Create `MomCare/App/Assets.xcassets/BabyStatusColor.colorset/Contents.json`:

```json
{
  "colors" : [
    {
      "color" : {
        "color-space" : "srgb",
        "components" : {
          "alpha" : "1.000",
          "blue" : "0.550",
          "green" : "0.750",
          "red" : "0.350"
        }
      },
      "idiom" : "universal"
    },
    {
      "appearances" : [
        {
          "appearance" : "luminosity",
          "value" : "dark"
        }
      ],
      "color" : {
        "color-space" : "srgb",
        "components" : {
          "alpha" : "1.000",
          "blue" : "0.650",
          "green" : "0.850",
          "red" : "0.450"
        }
      },
      "idiom" : "universal"
    }
  ],
  "info" : {
    "author" : "xcode",
    "version" : 1
  }
}
```

**Step 4: Commit**

```bash
git add MomCare/App/Assets.xcassets/FeedingColor.colorset \
       MomCare/App/Assets.xcassets/SelfCareColor.colorset \
       MomCare/App/Assets.xcassets/BabyStatusColor.colorset
git commit -m "feat(MOM-1): add FeedingColor, SelfCareColor, BabyStatusColor asset colorsets"
```

---

### Task 2: MCColor -- Color Tokens

**Files:**
- Create: `MomCare/Core/DesignSystem/ColorTokens.swift`
- Test: `MomCareTests/Core/DesignSystem/ColorTokensTests.swift`

**Step 1: Write the failing test**

Create `MomCareTests/Core/DesignSystem/ColorTokensTests.swift`:

```swift
import Testing
import SwiftUI
@testable import MomCare

@Suite("MCColor Tests")
struct MCColorTests {
    @Test("Semantic colors are accessible")
    func semanticColors() {
        let _ = MCColor.accent
        let _ = MCColor.feeding
        let _ = MCColor.selfCare
        let _ = MCColor.babyStatus
    }

    @Test("Urgency colors are accessible")
    func urgencyColors() {
        let _ = MCColor.Urgency.safe
        let _ = MCColor.Urgency.warning
        let _ = MCColor.Urgency.urgent
    }
}
```

**Step 2: Run test to verify it fails**

Run: `xcodebuild test -scheme MomCare -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing MomCareTests/MCColorTests 2>&1 | tail -20`
Expected: FAIL -- `MCColor` not found

**Step 3: Write implementation**

Create `MomCare/Core/DesignSystem/ColorTokens.swift`:

```swift
import SwiftUI

enum MCColor {
    static let accent = Color.accentColor
    static let feeding = Color("FeedingColor")
    static let selfCare = Color("SelfCareColor")
    static let babyStatus = Color("BabyStatusColor")

    enum Urgency {
        static let safe = Color.green
        static let warning = Color.yellow
        static let urgent = Color.orange
    }
}
```

**Step 4: Run test to verify it passes**

Run: `xcodebuild test -scheme MomCare -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing MomCareTests/MCColorTests 2>&1 | tail -20`
Expected: PASS

**Step 5: Commit**

```bash
git add MomCare/Core/DesignSystem/ColorTokens.swift \
       MomCareTests/Core/DesignSystem/ColorTokensTests.swift
git commit -m "feat(MOM-1): add MCColor semantic color tokens with tests"
```

---

### Task 3: MCTypography -- Font Tokens

**Files:**
- Create: `MomCare/Core/DesignSystem/Typography.swift`
- Test: `MomCareTests/Core/DesignSystem/TypographyTests.swift`

**Step 1: Write the failing test**

Create `MomCareTests/Core/DesignSystem/TypographyTests.swift`:

```swift
import Testing
import SwiftUI
@testable import MomCare

@Suite("MCTypography Tests")
struct MCTypographyTests {
    @Test("All font tokens are accessible")
    func fontTokens() {
        let _ = MCTypography.largeTimer
        let _ = MCTypography.cardTitle
        let _ = MCTypography.cardBody
        let _ = MCTypography.timestamp
    }
}
```

**Step 2: Run test to verify it fails**

Expected: FAIL -- `MCTypography` not found

**Step 3: Write implementation**

Create `MomCare/Core/DesignSystem/Typography.swift`:

```swift
import SwiftUI

enum MCTypography {
    static let largeTimer: Font = .system(size: 72, weight: .thin, design: .rounded)
    static let cardTitle: Font = .headline
    static let cardBody: Font = .callout
    static let timestamp: Font = .caption.monospacedDigit()
}
```

**Step 4: Run test to verify it passes**

Expected: PASS

**Step 5: Commit**

```bash
git add MomCare/Core/DesignSystem/Typography.swift \
       MomCareTests/Core/DesignSystem/TypographyTests.swift
git commit -m "feat(MOM-1): add MCTypography font tokens with tests"
```

---

### Task 4: MCSpacing -- Spacing Tokens

**Files:**
- Create: `MomCare/Core/DesignSystem/Spacing.swift`
- Test: `MomCareTests/Core/DesignSystem/SpacingTests.swift`

**Step 1: Write the failing test**

Create `MomCareTests/Core/DesignSystem/SpacingTests.swift`:

```swift
import Testing
@testable import MomCare

@Suite("MCSpacing Tests")
struct MCSpacingTests {
    @Test("Spacing values follow 4pt grid")
    func spacingValues() {
        #expect(MCSpacing.xs == 4)
        #expect(MCSpacing.sm == 8)
        #expect(MCSpacing.md == 12)
        #expect(MCSpacing.lg == 16)
        #expect(MCSpacing.xl == 24)
        #expect(MCSpacing.xxl == 32)
        #expect(MCSpacing.section == 40)
    }
}
```

**Step 2: Run test to verify it fails**

Expected: FAIL -- `MCSpacing` not found

**Step 3: Write implementation**

Create `MomCare/Core/DesignSystem/Spacing.swift`:

```swift
import Foundation

enum MCSpacing {
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 12
    static let lg: CGFloat = 16
    static let xl: CGFloat = 24
    static let xxl: CGFloat = 32
    static let section: CGFloat = 40
}
```

**Step 4: Run test to verify it passes**

Expected: PASS

**Step 5: Commit**

```bash
git add MomCare/Core/DesignSystem/Spacing.swift \
       MomCareTests/Core/DesignSystem/SpacingTests.swift
git commit -m "feat(MOM-1): add MCSpacing 4pt grid tokens with tests"
```

---

### Task 5: MCHaptic -- Haptic Feedback Manager

**Files:**
- Create: `MomCare/Core/DesignSystem/HapticManager.swift`
- Test: `MomCareTests/Core/DesignSystem/HapticManagerTests.swift`

**Step 1: Write the failing test**

Create `MomCareTests/Core/DesignSystem/HapticManagerTests.swift`:

```swift
import Testing
@testable import MomCare

@Suite("MCHaptic Tests")
struct MCHapticTests {
    @Test("Haptic methods exist and are callable")
    @MainActor
    func hapticMethods() {
        MCHaptic.tap()
        MCHaptic.toggle()
        MCHaptic.success()
        MCHaptic.error()
        MCHaptic.select()
    }
}
```

**Step 2: Run test to verify it fails**

Expected: FAIL -- `MCHaptic` not found

**Step 3: Write implementation**

Create `MomCare/Core/DesignSystem/HapticManager.swift`:

```swift
import UIKit

@MainActor
enum MCHaptic {
    private static let lightImpact = UIImpactFeedbackGenerator(style: .light)
    private static let mediumImpact = UIImpactFeedbackGenerator(style: .medium)
    private static let notification = UINotificationFeedbackGenerator()
    private static let selection = UISelectionFeedbackGenerator()

    static func tap() {
        lightImpact.impactOccurred()
    }

    static func toggle() {
        mediumImpact.impactOccurred()
    }

    static func success() {
        notification.notificationOccurred(.success)
    }

    static func error() {
        notification.notificationOccurred(.error)
    }

    static func select() {
        selection.selectionChanged()
    }
}
```

**Step 4: Run test to verify it passes**

Expected: PASS

**Step 5: Commit**

```bash
git add MomCare/Core/DesignSystem/HapticManager.swift \
       MomCareTests/Core/DesignSystem/HapticManagerTests.swift
git commit -m "feat(MOM-1): add MCHaptic feedback manager with tests"
```

---

### Task 6: Repository Base Protocol

**Files:**
- Create: `MomCare/Domain/Repositories/Repository.swift`

**Step 1: Write implementation**

Create `MomCare/Domain/Repositories/Repository.swift`:

```swift
import Foundation

protocol Repository<Entity>: Sendable {
    associatedtype Entity: Identifiable & Sendable

    func getAll() async throws -> [Entity]
    func getById(_ id: Entity.ID) async throws -> Entity?
    func create(_ entity: Entity) async throws -> Entity
    func update(_ entity: Entity) async throws -> Entity
    func delete(_ id: Entity.ID) async throws
}
```

No test needed -- protocol has no implementation. Conformances are tested in feature issues (MOM-2+).

**Step 2: Commit**

```bash
git add MomCare/Domain/Repositories/Repository.swift
git commit -m "feat(MOM-1): add generic Repository base protocol"
```

---

### Task 7: Dependency Injection Container

**Files:**
- Create: `MomCare/Core/DI/Dependencies.swift`
- Test: `MomCareTests/Core/DI/DependenciesTests.swift`

**Step 1: Write the failing test**

Create `MomCareTests/Core/DI/DependenciesTests.swift`:

```swift
import Testing
import SwiftUI
@testable import MomCare

@Suite("Dependencies Tests")
struct DependenciesTests {
    @Test("AppDependencies conforms to DependencyContainer")
    func conformance() {
        let deps: any DependencyContainer = AppDependencies()
        #expect(deps is AppDependencies)
    }

    @Test("Environment key has default value")
    func environmentKey() {
        let defaultValue = DependenciesKey.defaultValue
        #expect(defaultValue is AppDependencies)
    }
}
```

**Step 2: Run test to verify it fails**

Expected: FAIL -- `DependencyContainer` not found

**Step 3: Write implementation**

Create `MomCare/Core/DI/Dependencies.swift`:

```swift
import SwiftUI

protocol DependencyContainer: Sendable {
    // Factory methods added here as features land.
    // Example (MOM-2): func makeBabyRepository() -> any BabyRepositoryProtocol
}

final class AppDependencies: DependencyContainer, @unchecked Sendable {
    // Concrete factory methods added per feature.
}

struct DependenciesKey: EnvironmentKey {
    static let defaultValue: any DependencyContainer = AppDependencies()
}

extension EnvironmentValues {
    var dependencies: any DependencyContainer {
        get { self[DependenciesKey.self] }
        set { self[DependenciesKey.self] = newValue }
    }
}
```

**Step 4: Run test to verify it passes**

Expected: PASS

**Step 5: Commit**

```bash
git add MomCare/Core/DI/Dependencies.swift \
       MomCareTests/Core/DI/DependenciesTests.swift
git commit -m "feat(MOM-1): add DependencyContainer protocol and Environment injection"
```

---

### Task 8: Navigation Shell

**Files:**
- Create: `MomCare/App/AppNavigation.swift`
- Modify: `MomCare/App/ContentView.swift`
- Test: `MomCareTests/App/AppNavigationTests.swift`

**Step 1: Write the failing test**

Create `MomCareTests/App/AppNavigationTests.swift`:

```swift
import Testing
@testable import MomCare

@Suite("AppNavigation Tests")
struct AppNavigationTests {
    @Test("Default tab is dashboard")
    func defaultTab() {
        let nav = AppNavigation()
        #expect(nav.selectedTab == .dashboard)
    }

    @Test("Each tab has its own navigation path")
    func tabPaths() {
        let nav = AppNavigation()
        #expect(nav.dashboardPath.isEmpty)
        #expect(nav.feedingPath.isEmpty)
        #expect(nav.selfCarePath.isEmpty)
        #expect(nav.insightsPath.isEmpty)
    }

    @Test("Tab enum has all four cases")
    func allTabs() {
        let tabs = AppTab.allCases
        #expect(tabs.count == 4)
        #expect(tabs.contains(.dashboard))
        #expect(tabs.contains(.feeding))
        #expect(tabs.contains(.selfCare))
        #expect(tabs.contains(.insights))
    }
}
```

**Step 2: Run test to verify it fails**

Expected: FAIL -- `AppNavigation` not found

**Step 3: Write AppNavigation**

Create `MomCare/App/AppNavigation.swift`:

```swift
import SwiftUI

enum AppTab: String, CaseIterable, Sendable {
    case dashboard
    case feeding
    case selfCare
    case insights
}

@Observable
final class AppNavigation {
    var selectedTab: AppTab = .dashboard
    var dashboardPath = NavigationPath()
    var feedingPath = NavigationPath()
    var selfCarePath = NavigationPath()
    var insightsPath = NavigationPath()

    func handleURL(_ url: URL) {
        // Deep link routing added per feature
    }
}
```

**Step 4: Run test to verify it passes**

Expected: PASS

**Step 5: Update ContentView to use NavigationStack per tab**

Replace `MomCare/App/ContentView.swift` with:

```swift
import SwiftUI

struct ContentView: View {
    @State private var navigation = AppNavigation()

    var body: some View {
        TabView(selection: $navigation.selectedTab) {
            Tab("Dashboard", systemImage: "heart.text.clipboard", value: .dashboard) {
                NavigationStack(path: $navigation.dashboardPath) {
                    Text("Mission Control")
                }
            }

            Tab("Feeding", systemImage: "drop.fill", value: .feeding) {
                NavigationStack(path: $navigation.feedingPath) {
                    Text("Feeding")
                }
            }

            Tab("Self-Care", systemImage: "sparkles", value: .selfCare) {
                NavigationStack(path: $navigation.selfCarePath) {
                    Text("Self-Care")
                }
            }

            Tab("Insights", systemImage: "chart.xyaxis.line", value: .insights) {
                NavigationStack(path: $navigation.insightsPath) {
                    Text("Insights")
                }
            }
        }
        .environment(navigation)
    }
}

#Preview {
    ContentView()
}
```

**Step 6: Commit**

```bash
git add MomCare/App/AppNavigation.swift \
       MomCare/App/ContentView.swift \
       MomCareTests/App/AppNavigationTests.swift
git commit -m "feat(MOM-1): add AppNavigation shell with per-tab NavigationStack"
```

---

### Task 9: Firebase Initialization & App Entry Point

**Files:**
- Modify: `MomCare/App/MomCareApp.swift`

**Step 1: Update MomCareApp.swift**

Replace `MomCare/App/MomCareApp.swift` with:

```swift
import SwiftUI
import SwiftData
import FirebaseCore

@main
struct MomCareApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            // Models will be registered here as they're built
        ])
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            groupContainer: .identifier("group.com.feelingmindful.momcare")
        )

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    init() {
        FirebaseApp.configure()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.dependencies, AppDependencies())
        }
        .modelContainer(sharedModelContainer)
    }
}
```

**Step 2: Verify build succeeds**

Run: `xcodegen generate && xcodebuild build -scheme MomCare -destination 'platform=iOS Simulator,name=iPhone 16' 2>&1 | tail -5`
Expected: BUILD SUCCEEDED

**Step 3: Run all tests**

Run: `xcodebuild test -scheme MomCare -destination 'platform=iOS Simulator,name=iPhone 16' 2>&1 | tail -20`
Expected: All tests pass

**Step 4: Commit**

```bash
git add MomCare/App/MomCareApp.swift
git commit -m "feat(MOM-1): wire Firebase init, DI, and environment into app entry point"
```

---

### Task 10: Clean Up Placeholder Test

**Files:**
- Modify: `MomCareTests/MomCareTests.swift`

**Step 1: Remove placeholder test**

The placeholder `appLaunches` test is no longer needed -- we have real tests now. Replace `MomCareTests/MomCareTests.swift` with:

```swift
import Testing
@testable import MomCare

// Feature-specific test suites live in their own files.
// See: Core/DesignSystem/, Core/DI/, App/
```

**Step 2: Run full test suite**

Run: `xcodebuild test -scheme MomCare -destination 'platform=iOS Simulator,name=iPhone 16' 2>&1 | tail -20`
Expected: All tests pass (MCColorTests, MCTypographyTests, MCSpacingTests, MCHapticTests, DependenciesTests, AppNavigationTests)

**Step 3: Commit**

```bash
git add MomCareTests/MomCareTests.swift
git commit -m "chore(MOM-1): replace placeholder test with real test suites"
```

---

### Task 11: Update Linear Issue Status

**Step 1:** Mark MOM-1 as "Done" in Linear.

**Step 2:** Verify all files created:

```
MomCare/
  App/
    MomCareApp.swift              (modified -- Firebase init, DI wiring)
    ContentView.swift             (modified -- NavigationStack per tab)
    AppNavigation.swift           (new)
    GoogleService-Info.plist      (new, gitignored)
    Assets.xcassets/
      FeedingColor.colorset/      (new)
      SelfCareColor.colorset/     (new)
      BabyStatusColor.colorset/   (new)
  Core/
    DesignSystem/
      ColorTokens.swift           (new)
      Typography.swift            (new)
      Spacing.swift               (new)
      HapticManager.swift         (new)
    DI/
      Dependencies.swift          (new)
  Domain/
    Repositories/
      Repository.swift            (new)

MomCareTests/
  Core/
    DesignSystem/
      ColorTokensTests.swift      (new)
      TypographyTests.swift       (new)
      SpacingTests.swift          (new)
      HapticManagerTests.swift    (new)
    DI/
      DependenciesTests.swift     (new)
  App/
    AppNavigationTests.swift      (new)
  MomCareTests.swift              (modified -- placeholder removed)
```
