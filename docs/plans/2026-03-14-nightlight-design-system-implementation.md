# Nightlight Design System Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Replace the generic design system with the "Nightlight" premium design language -- custom typography (Nunito), formalized tokens (opacity, radii, animation, elevation), Pow motion vocabulary, Nova Canvas illustrations, and Lottie celebration system.

**Architecture:** Design tokens are pure Swift enums/structs in `MomCare/Core/DesignSystem/`. Pow wrappers are SwiftUI view modifiers in the same directory. Lottie wrapper is a shared component. Illustrations are PNG assets in the asset catalog. Tokens are applied screen-by-screen after the foundation is built.

**Tech Stack:** SwiftUI, Nunito Variable Font (Google Fonts, OFL), Pow, Lottie, Nova Canvas MCP, SF Pro, New York (system)

**Design Doc:** `docs/plans/2026-03-14-nightlight-design-system-design.md`

---

## Task 1: Add Nunito Variable Font

**Files:**
- Create: `MomCare/App/Resources/Fonts/Nunito-VariableFont_wght.ttf`
- Modify: `MomCare/App/Info.plist`
- Modify: `Project.swift` (add font resources)

**Step 1: Download Nunito Variable Font**

```bash
# Download from Google Fonts
curl -L "https://fonts.google.com/download?family=Nunito" -o /tmp/nunito.zip
unzip /tmp/nunito.zip -d /tmp/nunito
ls /tmp/nunito/static/  # Find the variable font file
```

If the zip structure differs, look for `Nunito-VariableFont_wght.ttf` or `Nunito[wght].ttf` in the extracted directory.

**Step 2: Add font file to project**

```bash
mkdir -p MomCare/App/Resources/Fonts
cp /tmp/nunito/Nunito-VariableFont_wght.ttf MomCare/App/Resources/Fonts/
```

**Step 3: Register font in Info.plist**

Add to `MomCare/App/Info.plist` inside the top-level `<dict>`:

```xml
<key>UIAppFonts</key>
<array>
    <string>Nunito-VariableFont_wght.ttf</string>
</array>
```

**Step 4: Ensure Tuist includes font resources**

Check `Project.swift` -- the MomCare target should already glob resources. If fonts aren't in a globbed path, add:

```swift
resources: [
    "MomCare/App/Resources/**",
    // ... existing resource globs
]
```

**Step 5: Regenerate project and build**

```bash
tuist generate
tuist build
```

Expected: Build succeeds. Font is bundled.

**Step 6: Verify font loads at runtime**

Add a temporary print in `MomCareApp.init()`:

```swift
#if DEBUG
for family in UIFont.familyNames.sorted() where family.contains("Nunito") {
    print("Font family: \(family)")
    for name in UIFont.fontNames(forFamilyName: family) {
        print("  -> \(name)")
    }
}
#endif
```

Run in simulator. Expected output should list Nunito font names. Remove the debug print after verifying.

**Step 7: Commit**

```bash
git add MomCare/App/Resources/Fonts/ MomCare/App/Info.plist Project.swift
git commit -m "chore: add Nunito variable font to project"
```

---

## Task 2: Typography Tokens

**Files:**
- Modify: `MomCare/Core/DesignSystem/Typography.swift`
- Test: `MomCareTests/Core/DesignSystem/TypographyTests.swift`

**Step 1: Write the failing test**

Create `MomCareTests/Core/DesignSystem/TypographyTests.swift`:

```swift
import Testing
@testable import MomCare

@Suite("MCTypography tokens")
struct TypographyTests {

    @Test("Display tier fonts are non-nil")
    func displayTier() {
        // Verify custom font loads — if Nunito isn't bundled, .custom returns system font
        // We test that the tokens exist and produce valid Font values
        let _ = MCTypography.display
        let _ = MCTypography.timer
        let _ = MCTypography.title1
        let _ = MCTypography.title2
        let _ = MCTypography.title3
        let _ = MCTypography.stat
        let _ = MCTypography.button
        let _ = MCTypography.badge
    }

    @Test("Body tier fonts use system text styles")
    func bodyTier() {
        let _ = MCTypography.body
        let _ = MCTypography.callout
        let _ = MCTypography.subheadline
        let _ = MCTypography.footnote
        let _ = MCTypography.caption
        let _ = MCTypography.caption2
        let _ = MCTypography.timestamp
    }

    @Test("Emotional tier fonts use serif design")
    func emotionalTier() {
        let _ = MCTypography.affirmation
        let _ = MCTypography.milestone
    }

    @Test("Headline token exists for emphasized body")
    func headlineToken() {
        let _ = MCTypography.headline
    }
}
```

**Step 2: Run test to verify it fails**

```bash
tuist test
```

Expected: FAIL -- most tokens don't exist yet.

**Step 3: Implement typography tokens**

Replace `MomCare/Core/DesignSystem/Typography.swift` entirely:

```swift
import SwiftUI

enum MCTypography {

    // MARK: - Display Tier (Nunito — brand identity)

    static let display: Font = .custom("Nunito-ExtraLight", size: 48, relativeTo: .largeTitle)
    static let timer: Font = .custom("Nunito-Thin", size: 72, relativeTo: .largeTitle)
    static let title1: Font = .custom("Nunito-SemiBold", size: 28, relativeTo: .title)
    static let title2: Font = .custom("Nunito-SemiBold", size: 22, relativeTo: .title2)
    static let title3: Font = .custom("Nunito-Medium", size: 20, relativeTo: .title3)
    static let headline: Font = .custom("Nunito-SemiBold", size: 17, relativeTo: .headline)
    static let stat: Font = .custom("Nunito-Bold", size: 20, relativeTo: .title3).monospacedDigit()
    static let button: Font = .custom("Nunito-SemiBold", size: 17, relativeTo: .headline)
    static let badge: Font = .custom("Nunito-Bold", size: 11, relativeTo: .caption2)

    // MARK: - Body Tier (SF Pro — readability)

    static let body: Font = .body
    static let callout: Font = .callout
    static let subheadline: Font = .subheadline
    static let footnote: Font = .footnote
    static let caption: Font = .caption
    static let caption2: Font = .caption2
    static let timestamp: Font = .caption.monospacedDigit()

    // MARK: - Emotional Tier (New York — warmth)

    static let affirmation: Font = .system(.title3, design: .serif).italic()
    static let milestone: Font = .system(.title2, design: .serif, weight: .medium)

    // MARK: - Legacy Aliases (backward compatibility during migration)

    static let largeTimer: Font = timer
    static let cardTitle: Font = title3
    static let cardBody: Font = callout
}
```

Note: The legacy aliases (`largeTimer`, `cardTitle`, `cardBody`) ensure existing screens don't break. They'll be removed after migration.

**Step 4: Run tests to verify they pass**

```bash
tuist test
```

Expected: All typography tests PASS.

**Step 5: Lint**

```bash
swiftlint --strict MomCare/Core/DesignSystem/Typography.swift
```

**Step 6: Commit**

```bash
git add MomCare/Core/DesignSystem/Typography.swift MomCareTests/Core/DesignSystem/TypographyTests.swift
git commit -m "feat(design): add Nightlight typography tokens with Nunito display tier"
```

---

## Task 3: Opacity, Radius, and Elevation Tokens

**Files:**
- Create: `MomCare/Core/DesignSystem/OpacityTokens.swift`
- Create: `MomCare/Core/DesignSystem/RadiusTokens.swift`
- Create: `MomCare/Core/DesignSystem/ElevationTokens.swift`
- Modify: `MomCare/Core/DesignSystem/ColorTokens.swift`
- Test: `MomCareTests/Core/DesignSystem/DesignTokenTests.swift`

**Step 1: Write the failing test**

Create `MomCareTests/Core/DesignSystem/DesignTokenTests.swift`:

```swift
import SwiftUI
import Testing
@testable import MomCare

@Suite("Design tokens")
struct DesignTokenTests {

    @Test("Opacity tokens are in valid range")
    func opacityRange() {
        let values: [Double] = [
            MCOpacity.ghost, MCOpacity.whisper, MCOpacity.soft,
            MCOpacity.medium, MCOpacity.strong, MCOpacity.heavy
        ]
        for value in values {
            #expect(value > 0 && value < 1)
        }
    }

    @Test("Opacity tokens are ordered ascending")
    func opacityOrdering() {
        #expect(MCOpacity.ghost < MCOpacity.whisper)
        #expect(MCOpacity.whisper < MCOpacity.soft)
        #expect(MCOpacity.soft < MCOpacity.medium)
        #expect(MCOpacity.medium < MCOpacity.strong)
        #expect(MCOpacity.strong < MCOpacity.heavy)
    }

    @Test("Radius tokens are positive")
    func radiusPositive() {
        #expect(MCRadius.sm > 0)
        #expect(MCRadius.md > MCRadius.sm)
        #expect(MCRadius.lg > MCRadius.md)
        #expect(MCRadius.xl > MCRadius.lg)
    }

    @Test("Elevation levels are ordered by brightness")
    func elevationOrdering() {
        #expect(MCElevation.surfaceOpacity > 0)
        #expect(MCElevation.elevatedOpacity > MCElevation.surfaceOpacity)
        #expect(MCElevation.overlayOpacity > MCElevation.elevatedOpacity)
    }

    @Test("Canvas color is near-black")
    @MainActor
    func canvasColor() {
        let _ = MCColor.canvas
    }
}
```

**Step 2: Run test to verify it fails**

```bash
tuist test
```

Expected: FAIL -- MCOpacity, MCRadius, MCElevation don't exist.

**Step 3: Create OpacityTokens.swift**

```swift
import Foundation

enum MCOpacity {
    static let ghost: Double = 0.04
    static let whisper: Double = 0.08
    static let soft: Double = 0.12
    static let medium: Double = 0.20
    static let strong: Double = 0.40
    static let heavy: Double = 0.60
}
```

**Step 4: Create RadiusTokens.swift**

```swift
import Foundation

enum MCRadius {
    /// Chips, badges, inline elements
    static let sm: CGFloat = 8
    /// Data cards, list rows
    static let md: CGFloat = 12
    /// Action cards, buttons
    static let lg: CGFloat = 16
    /// Sheets, modals
    static let xl: CGFloat = 24
    /// Pills, capsules, avatars
    static let full: CGFloat = .infinity
}
```

**Step 5: Create ElevationTokens.swift**

```swift
import SwiftUI

enum MCElevation {
    /// Level 1 — Surface: data cards, history rows
    static let surfaceOpacity: Double = MCOpacity.whisper

    /// Level 2 — Elevated: action cards, active states
    static let elevatedOpacity: Double = MCOpacity.soft

    /// Level 3 — Overlay: sheets, modals, alerts
    static let overlayOpacity: Double = MCOpacity.medium

    /// Surface background color
    static var surface: Color {
        Color.white.opacity(surfaceOpacity)
    }

    /// Elevated background color
    static var elevated: Color {
        Color.white.opacity(elevatedOpacity)
    }

    /// Overlay background color
    static var overlay: Color {
        Color.white.opacity(overlayOpacity)
    }
}
```

**Step 6: Add canvas color and gradients to ColorTokens.swift**

Add to `MCColor` enum in `ColorTokens.swift`:

```swift
    /// Nightlight canvas — warm near-black, not pure #000000
    static let canvas = Color(red: 0.04, green: 0.03, blue: 0.04)
```

Add a new enum at the bottom of the file:

```swift
enum MCGradient {
    /// Screen-level warm radial gradient
    static func canvas() -> RadialGradient {
        RadialGradient(
            colors: [MCColor.canvas, .black],
            center: .center,
            startRadius: 0,
            endRadius: UIScreen.main.bounds.height * 0.8
        )
    }

    /// Nightlight glow halo around active elements
    static func glow(color: Color, radius: CGFloat = 40) -> RadialGradient {
        RadialGradient(
            colors: [color.opacity(0.15), color.opacity(0)],
            center: .center,
            startRadius: 0,
            endRadius: radius
        )
    }
}
```

**Step 7: Run tests**

```bash
tuist generate
tuist test
```

Expected: All design token tests PASS.

**Step 8: Lint**

```bash
swiftlint --strict MomCare/Core/DesignSystem/
```

**Step 9: Commit**

```bash
git add MomCare/Core/DesignSystem/ MomCareTests/Core/DesignSystem/
git commit -m "feat(design): add opacity, radius, elevation, canvas, and gradient tokens"
```

---

## Task 4: Animation Curve Tokens

**Files:**
- Create: `MomCare/Core/DesignSystem/AnimationTokens.swift`
- Test: `MomCareTests/Core/DesignSystem/DesignTokenTests.swift` (extend)

**Step 1: Write the failing test**

Add to `DesignTokenTests.swift`:

```swift
    @Test("Animation tokens exist")
    func animationTokens() {
        let _ = MCAnimation.quick
        let _ = MCAnimation.standard
        let _ = MCAnimation.gentle
        let _ = MCAnimation.slow
    }
```

**Step 2: Run test to verify it fails**

```bash
tuist test
```

**Step 3: Create AnimationTokens.swift**

```swift
import SwiftUI

enum MCAnimation {
    /// Micro-interactions: button press, toggle, selection (0.25s)
    static let quick: Animation = .spring(response: 0.25, dampingFraction: 0.8)

    /// Card transitions, sheet presentations (0.35s)
    static let standard: Animation = .spring(response: 0.35, dampingFraction: 0.75)

    /// Glow effects, background changes, empty state reveals (0.5s)
    static let gentle: Animation = .spring(response: 0.5, dampingFraction: 0.8)

    /// Onboarding reveals, celebration moments (0.7s)
    static let slow: Animation = .spring(response: 0.7, dampingFraction: 0.85)
}
```

**Step 4: Run tests**

```bash
tuist test
```

Expected: PASS.

**Step 5: Commit**

```bash
git add MomCare/Core/DesignSystem/AnimationTokens.swift MomCareTests/Core/DesignSystem/DesignTokenTests.swift
git commit -m "feat(design): add spring animation curve tokens"
```

---

## Task 5: Pow Transition and Effect Wrappers

**Files:**
- Create: `MomCare/Core/DesignSystem/MotionTokens.swift`

**Step 1: Create MotionTokens.swift**

```swift
import Pow
import SwiftUI

// MARK: - Transition Tokens

enum MCTransition {
    /// Cards entering the screen
    static var cardAppear: AnyTransition { .movingParts.pop }

    /// Cards leaving the screen
    static var cardDismiss: AnyTransition { .movingParts.vanish }

    /// New list items
    static var listInsert: AnyTransition { .movingParts.move(edge: .bottom) }

    /// Deleted list items
    static var listRemove: AnyTransition { .movingParts.poof }

    /// Sheet/modal appearance
    static var sheetPresent: AnyTransition { .movingParts.blur }

    /// Charts, hero content reveal
    static var heroReveal: AnyTransition { .movingParts.iris }

    /// Expanding/collapsing sections
    static var sectionExpand: AnyTransition { .movingParts.blinds }
}

// MARK: - View Modifiers

extension View {
    /// Apply a design-system transition with automatic reduceMotion handling
    func mcTransition(_ transition: AnyTransition) -> some View {
        self.transition(transition)
    }

    /// Glow effect — the Nightlight signature
    func mcGlow<V: Equatable>(color: Color, trigger: V) -> some View {
        self.changeEffect(.glow(color: color), value: trigger)
    }

    /// Celebration spray effect
    func mcCelebrate<V: Equatable>(trigger: V) -> some View {
        self.changeEffect(
            .spray(origin: UnitPoint(x: 0.5, y: 0.5)) {
                Image(systemName: "sparkle")
                    .foregroundStyle(.white)
            },
            value: trigger
        )
    }

    /// Shine sweep on CTAs
    func mcShine<V: Equatable>(trigger: V) -> some View {
        self.changeEffect(.shine, value: trigger)
    }

    /// Error shake
    func mcShake<V: Equatable>(trigger: V) -> some View {
        self.changeEffect(.shake, value: trigger)
    }

    /// Success rise
    func mcRise<V: Equatable>(trigger: V) -> some View {
        self.changeEffect(.rise, value: trigger)
    }

    /// Attention jump
    func mcJump<V: Equatable>(trigger: V) -> some View {
        self.changeEffect(.jump, value: trigger)
    }
}
```

**Step 2: Build to verify compilation**

```bash
tuist generate
tuist build
```

Expected: Build succeeds. Pow effects compile correctly.

**Step 3: Lint**

```bash
swiftlint --strict MomCare/Core/DesignSystem/MotionTokens.swift
```

**Step 4: Commit**

```bash
git add MomCare/Core/DesignSystem/MotionTokens.swift
git commit -m "feat(design): add Pow transition and effect wrappers"
```

---

## Task 6: MCLottieView Wrapper

**Files:**
- Create: `MomCare/Shared/Components/MCLottieView.swift`

**Step 1: Create MCLottieView.swift**

```swift
import Lottie
import SwiftUI

enum MCCelebration: String {
    case confetti = "celebration-confetti"
    case sparkle = "celebration-sparkle"
    case warmglow = "celebration-warmglow"
    case breathe = "loading-breathe"

    var accessibilityLabel: String {
        switch self {
        case .confetti: "Celebration: milestone achieved"
        case .sparkle: "Celebration: task completed"
        case .warmglow: "Session complete"
        case .breathe: "Loading"
        }
    }
}

enum MCLottieSize {
    case compact    // 80pt — loading, inline
    case standard   // 160pt — celebrations
    case fullscreen // fills container

    var dimension: CGFloat? {
        switch self {
        case .compact: 80
        case .standard: 160
        case .fullscreen: nil
        }
    }
}

struct MCLottieView: View {
    let animation: MCCelebration
    var size: MCLottieSize = .standard
    var loopMode: LottieLoopMode = .playOnce
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        if reduceMotion {
            staticFallback
        } else {
            lottieContent
        }
    }

    @ViewBuilder
    private var lottieContent: some View {
        let view = LottieView(animation: .named(animation.rawValue))
            .loopMode(loopMode)
            .accessibilityLabel(animation.accessibilityLabel)

        if let dimension = size.dimension {
            view.frame(width: dimension, height: dimension)
        } else {
            view
        }
    }

    private var staticFallback: some View {
        Image(systemName: fallbackIcon)
            .font(.title)
            .foregroundStyle(MCColor.accent)
            .accessibilityLabel(animation.accessibilityLabel)
    }

    private var fallbackIcon: String {
        switch animation {
        case .confetti, .sparkle: "checkmark.circle.fill"
        case .warmglow: "sun.max.fill"
        case .breathe: "ellipsis"
        }
    }
}
```

**Step 2: Build to verify compilation**

```bash
tuist generate
tuist build
```

Expected: Build succeeds. Lottie integration compiles.

**Step 3: Commit**

```bash
git add MomCare/Shared/Components/MCLottieView.swift
git commit -m "feat(design): add MCLottieView wrapper with reduceMotion fallback"
```

---

## Task 7: CelebrationOverlay Component

**Files:**
- Create: `MomCare/Shared/Components/CelebrationOverlay.swift`

**Step 1: Create CelebrationOverlay.swift**

```swift
import SwiftUI

struct CelebrationOverlay: View {
    let celebration: MCCelebration
    let message: String?
    @Binding var isPresented: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        if isPresented {
            ZStack {
                Color.black.opacity(MCOpacity.ghost)
                    .ignoresSafeArea()
                    .onTapGesture { dismiss() }

                VStack(spacing: MCSpacing.xl) {
                    MCLottieView(
                        animation: celebration,
                        size: celebration == .breathe ? .compact : .standard,
                        loopMode: .playOnce
                    )

                    if let message {
                        Text(message)
                            .font(MCTypography.milestone)
                            .foregroundStyle(.white)
                            .multilineTextAlignment(.center)
                            .transition(.opacity)
                    }
                }
            }
            .transition(.opacity)
            .onAppear {
                MCHaptic.success()
                scheduleDismissal()
            }
        }
    }

    private func scheduleDismissal() {
        let duration: Double = switch celebration {
        case .confetti: 2.5
        case .sparkle: 1.5
        case .warmglow: 2.0
        case .breathe: 0 // breathe loops, doesn't auto-dismiss
        }

        guard duration > 0 else { return }

        Task {
            try? await Task.sleep(for: .seconds(duration))
            await MainActor.run { dismiss() }
        }
    }

    private func dismiss() {
        withAnimation(MCAnimation.standard) {
            isPresented = false
        }
    }
}
```

**Step 2: Build**

```bash
tuist build
```

**Step 3: Commit**

```bash
git add MomCare/Shared/Components/CelebrationOverlay.swift
git commit -m "feat(design): add CelebrationOverlay with auto-dismiss and haptic pairing"
```

---

## Task 8: Generate Nova Canvas Illustrations

**Files:**
- Create: Assets in `MomCare/App/Assets.xcassets/Illustrations/`

**Step 1: Generate empty state illustrations**

Use Nova Canvas MCP to generate each illustration. Run all 6 in sequence:

For each illustration, use the prompt template from the design doc with the specific subject. Generate with color palette `[#DE94C7]`.

Save outputs to `MomCare/App/Assets.xcassets/Illustrations/` as image sets with @2x and @3x variants.

Asset naming:
- `mc-illustration-empty-feeding`
- `mc-illustration-empty-sleep`
- `mc-illustration-empty-growth`
- `mc-illustration-empty-diapers`
- `mc-illustration-empty-journal`
- `mc-illustration-empty-selfcare`

**Step 2: Generate onboarding hero illustrations**

Same process for:
- `mc-illustration-onboarding-welcome`
- `mc-illustration-onboarding-features`
- `mc-illustration-onboarding-privacy`

**Step 3: Generate status indicator illustrations**

Same process for:
- `mc-illustration-status-sleeping`
- `mc-illustration-status-feeding`

**Step 4: Add to asset catalog**

Create image sets in Xcode asset catalog for each illustration. Set rendering mode to "Template" for monochromatic tinting, or "Original" if the generated colors are final.

**Step 5: Build to verify assets load**

```bash
tuist generate
tuist build
```

**Step 6: Commit**

```bash
git add MomCare/App/Assets.xcassets/Illustrations/
git commit -m "feat(design): add Nova Canvas illustrations for empty states and onboarding"
```

---

## Task 9: MCIllustration Component

**Files:**
- Create: `MomCare/Shared/Components/MCIllustrationView.swift`

**Step 1: Create MCIllustrationView.swift**

```swift
import SwiftUI

enum MCIllustration: String {
    // Empty states
    case emptyFeeding = "mc-illustration-empty-feeding"
    case emptySleep = "mc-illustration-empty-sleep"
    case emptyGrowth = "mc-illustration-empty-growth"
    case emptyDiapers = "mc-illustration-empty-diapers"
    case emptyJournal = "mc-illustration-empty-journal"
    case emptySelfCare = "mc-illustration-empty-selfcare"

    // Onboarding
    case onboardingWelcome = "mc-illustration-onboarding-welcome"
    case onboardingFeatures = "mc-illustration-onboarding-features"
    case onboardingPrivacy = "mc-illustration-onboarding-privacy"

    // Status
    case statusSleeping = "mc-illustration-status-sleeping"
    case statusFeeding = "mc-illustration-status-feeding"
}

struct MCIllustrationView: View {
    let illustration: MCIllustration
    var size: CGFloat = 120
    var tint: Color = MCColor.accent
    @State private var appeared = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Image(illustration.rawValue)
            .resizable()
            .scaledToFit()
            .frame(width: size, height: size)
            .foregroundStyle(tint)
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 8)
            .onAppear {
                if reduceMotion {
                    appeared = true
                } else {
                    withAnimation(MCAnimation.gentle.delay(0.1)) {
                        appeared = true
                    }
                }
            }
    }
}
```

**Step 2: Build**

```bash
tuist build
```

**Step 3: Commit**

```bash
git add MomCare/Shared/Components/MCIllustrationView.swift
git commit -m "feat(design): add MCIllustrationView with entrance animation"
```

---

## Task 10: EmptyStateView Shared Component

**Files:**
- Create: `MomCare/Shared/Components/EmptyStateView.swift`

**Step 1: Create EmptyStateView.swift**

This combines the illustration, typography, and entrance choreography into one reusable component:

```swift
import SwiftUI

struct EmptyStateView: View {
    let illustration: MCIllustration
    let title: String
    let message: String
    var actionTitle: String?
    var action: (() -> Void)?

    @State private var step = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(spacing: MCSpacing.xl) {
            MCIllustrationView(illustration: illustration, size: 120)

            Text(title)
                .font(MCTypography.title3)
                .foregroundStyle(.white)
                .opacity(step >= 1 ? 1 : 0)

            Text(message)
                .font(MCTypography.callout)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .opacity(step >= 2 ? 1 : 0)

            if let actionTitle, let action {
                Button {
                    MCHaptic.tap()
                    action()
                } label: {
                    Text(actionTitle)
                        .font(MCTypography.button)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(MCColor.accent, in: RoundedRectangle(cornerRadius: MCRadius.lg))
                }
                .opacity(step >= 3 ? 1 : 0)
                .mcShine(trigger: step)
            }
        }
        .padding(.horizontal, MCSpacing.xl)
        .task {
            guard !reduceMotion else {
                step = 3
                return
            }
            for i in 1...3 {
                try? await Task.sleep(for: .seconds(0.15))
                withAnimation(MCAnimation.standard) {
                    step = i
                }
            }
        }
    }
}
```

**Step 2: Build and lint**

```bash
tuist build
swiftlint --strict MomCare/Shared/Components/EmptyStateView.swift
```

**Step 3: Commit**

```bash
git add MomCare/Shared/Components/EmptyStateView.swift
git commit -m "feat(design): add EmptyStateView with choreographed entrance"
```

---

## Task 11: NightlightBackground View Modifier

**Files:**
- Create: `MomCare/Core/DesignSystem/NightlightBackground.swift`

**Step 1: Create NightlightBackground.swift**

```swift
import SwiftUI

struct NightlightBackground: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background {
                MCGradient.canvas()
                    .ignoresSafeArea()
            }
    }
}

extension View {
    /// Apply the Nightlight warm canvas background
    func nightlightBackground() -> some View {
        modifier(NightlightBackground())
    }
}
```

**Step 2: Build**

```bash
tuist build
```

**Step 3: Commit**

```bash
git add MomCare/Core/DesignSystem/NightlightBackground.swift
git commit -m "feat(design): add nightlightBackground view modifier"
```

---

## Task 12: Apply Tokens to Dashboard (First Screen Migration)

**Files:**
- Modify: `MomCare/Features/Now/Views/NowScreen.swift`
- Modify: `MomCare/Features/Dashboard/Views/BabyStatusCard.swift`
- Modify: `MomCare/Features/Dashboard/Views/MomStatusCard.swift`

This is the first screen to receive the Nightlight treatment. It validates the token system works end-to-end.

**Step 1: Read current files**

Read all three files to understand current layout.

**Step 2: Apply changes**

For each file:
- Replace `Color.black.ignoresSafeArea()` with `.nightlightBackground()`
- Replace hardcoded `cornerRadius(16)` with `MCRadius.lg`
- Replace hardcoded `cornerRadius(12)` with `MCRadius.md`
- Replace `.ultraThinMaterial` on data cards with `MCElevation.surface`
- Replace `.headline` font with `MCTypography.title3` (Nunito) for card titles
- Replace `.callout` / `.body` fonts with `MCTypography.callout` / `MCTypography.body`
- Replace hardcoded opacity values with `MCOpacity` tokens
- Add `MCTransition.cardAppear` transitions on card views
- Add Pow `.mcGlow` on active status indicators

**Step 3: Build and run in simulator**

```bash
tuist build
```

Verify visually in simulator: warm background, Nunito titles, elevation differences between cards.

**Step 4: Lint**

```bash
swiftlint --strict MomCare/Features/Now/ MomCare/Features/Dashboard/
```

**Step 5: Commit**

```bash
git add MomCare/Features/Now/ MomCare/Features/Dashboard/
git commit -m "feat(design): apply Nightlight tokens to dashboard screen"
```

---

## Task 13: Apply Tokens to Baby Screen + Action Cards

**Files:**
- Modify: `MomCare/Features/Baby/Views/BabyScreen.swift`
- Modify: `MomCare/Features/Baby/Views/BabyActionCard.swift`

**Step 1: Read current files**

**Step 2: Apply changes**

- BabyScreen: `.nightlightBackground()`, Nunito titles, `MCRadius` tokens
- BabyActionCard: Replace `cornerRadius(16)` with `MCRadius.lg`, replace `.ultraThinMaterial` with `MCElevation.elevated` for action cards, add Pow `.mcGlow(color: MCColor.baby, trigger: engine.isNapActive)` on active nap card, add `MCTransition.cardAppear` on card appearance

**Step 3: Build, verify, lint**

**Step 4: Commit**

```bash
git commit -m "feat(design): apply Nightlight tokens to baby screen and action cards"
```

---

## Task 14: Apply Tokens to Feeding Timer

**Files:**
- Modify: `MomCare/Features/Feeding/Views/FeedingTimerView.swift`

**Step 1: Read current file**

**Step 2: Apply changes**

- Replace `Color.black.ignoresSafeArea()` with `.nightlightBackground()`
- Timer text: Already uses `MCTypography.largeTimer` alias which now resolves to Nunito Thin 72pt
- Add Pow `.mcGlow(color: MCColor.feeding, trigger: isTimerRunning)` on the timer display
- Replace hardcoded radii and opacity values with tokens
- On end feeding: trigger `CelebrationOverlay` with `.warmglow`

**Step 3: Build, verify, lint**

**Step 4: Commit**

```bash
git commit -m "feat(design): apply Nightlight tokens to feeding timer with glow"
```

---

## Task 15: Apply Tokens to Sleep Timer

**Files:**
- Modify: `MomCare/Features/Sleep/Views/SleepTimerView.swift`

Same pattern as Task 14:
- `.nightlightBackground()`
- Nunito timer typography (via alias)
- Pow `.mcGlow(color: MCColor.baby, ...)` on timer
- Token replacements for radii, opacity
- CelebrationOverlay on sleep end

**Commit:**

```bash
git commit -m "feat(design): apply Nightlight tokens to sleep timer"
```

---

## Task 16: Apply Tokens to Remaining Screens

**Files:**
- Modify: `MomCare/Features/Growth/Views/GrowthScreen.swift`
- Modify: `MomCare/Features/Growth/Views/AddMeasurementView.swift`
- Modify: `MomCare/Features/Diapers/Views/DiapersScreen.swift`
- Modify: `MomCare/Features/SelfCare/Views/SelfCareScreen.swift`
- Modify: `MomCare/Features/Journal/Views/JournalScreen.swift`
- Modify: `MomCare/App/ContentView.swift`

For each screen:
- `.nightlightBackground()` or warm canvas
- Replace typography with `MCTypography` tokens
- Replace hardcoded radii/opacity with tokens
- Add Pow transitions for list insertions/removals
- Add empty state with `EmptyStateView` where applicable
- Replace chart appearance with `MCTransition.heroReveal`

**Commit per feature group** (2-3 files per commit):

```bash
git commit -m "feat(design): apply Nightlight tokens to growth screens"
git commit -m "feat(design): apply Nightlight tokens to journal and self-care"
git commit -m "feat(design): apply Nightlight tokens to content view and tab bar"
```

---

## Task 17: Source and Add Lottie Animation Files

**Files:**
- Create: `MomCare/App/Resources/Animations/celebration-confetti.json`
- Create: `MomCare/App/Resources/Animations/celebration-sparkle.json`
- Create: `MomCare/App/Resources/Animations/celebration-warmglow.json`
- Create: `MomCare/App/Resources/Animations/loading-breathe.json`

**Step 1: Source animations from LottieFiles.com**

Search for:
- "confetti warm minimal" — download, customize colors to #DE94C7
- "sparkle radial" — download, customize
- "glow pulse warm" — download, customize
- "dots breathing loading" — download, customize

**Step 2: Customize colors**

Open each JSON file. Find color values (typically `"c"` objects with RGB arrays). Replace with MCColor.accent equivalents:
- Primary: `[0.87, 0.58, 0.78]` (accent)
- Secondary: `[1, 1, 1, 0.4]` (white at 40%)

**Step 3: Verify file sizes**

```bash
ls -la MomCare/App/Resources/Animations/
```

Each file should be under 50KB.

**Step 4: Build**

```bash
tuist generate
tuist build
```

**Step 5: Commit**

```bash
git add MomCare/App/Resources/Animations/
git commit -m "feat(design): add Lottie celebration and loading animations"
```

---

## Task 18: Wire Celebrations into Feature Screens

**Files:**
- Modify: `MomCare/Features/Feeding/ViewModels/FeedingViewModel.swift`
- Modify: `MomCare/Features/Sleep/Views/SleepTimerView.swift`
- Modify: `MomCare/Features/SelfCare/Views/SelfCareScreen.swift`
- Modify: `MomCare/Features/Growth/Views/GrowthScreen.swift`

For each screen that has a celebration trigger:
- Add `@State private var showCelebration = false`
- Add `CelebrationOverlay` in a ZStack
- Trigger on the appropriate event (end feeding, daily complete, etc.)
- Track first-time events in `@AppStorage("milestone_first_feeding")` etc.

**Commit:**

```bash
git commit -m "feat(design): wire celebration overlays into feature screens"
```

---

## Task 19: Update Onboarding with Illustrations

**Files:**
- Modify: `MomCare/Features/Onboarding/Views/WelcomePageView.swift`
- Modify: `MomCare/Features/Onboarding/Views/TourPageView.swift`
- Modify: `MomCare/Features/Onboarding/Views/PermissionStepView.swift`

Replace Lottie placeholder comments (SF Symbol + RoundedRectangle) with:
- `MCIllustrationView` using onboarding illustrations
- Pow `.heroReveal` transitions between pages
- Nunito typography for all headings
- `.nightlightBackground()`

**Commit:**

```bash
git commit -m "feat(design): replace onboarding placeholders with Nova Canvas illustrations"
```

---

## Task 20: Final Verification and Cleanup

**Files:**
- Modify: `MomCare/Core/DesignSystem/Typography.swift` (remove legacy aliases if all references migrated)

**Step 1: Search for remaining hardcoded values**

```bash
# Find remaining hardcoded corner radii
grep -rn "cornerRadius(" MomCare/ --include="*.swift" | grep -v "MCRadius"

# Find remaining hardcoded opacity values
grep -rn "opacity(0\." MomCare/ --include="*.swift" | grep -v "MCOpacity"

# Find remaining Color.black backgrounds
grep -rn "Color.black" MomCare/ --include="*.swift" | grep -v "MCColor"

# Find remaining system font usage in display contexts
grep -rn "\.headline\b" MomCare/ --include="*.swift" | grep -v "MCTypography"
```

**Step 2: Fix any remaining hardcoded values**

**Step 3: Full build and test**

```bash
tuist build
tuist test
swiftlint --strict MomCare/ MomCareTests/
```

**Step 4: Remove legacy typography aliases**

If grep confirms no remaining references to `largeTimer`, `cardTitle`, `cardBody`:

Remove from Typography.swift:
```swift
    // MARK: - Legacy Aliases
    static let largeTimer: Font = timer
    static let cardTitle: Font = title3
    static let cardBody: Font = callout
```

**Step 5: Final commit**

```bash
git add -A
git commit -m "chore(design): remove legacy typography aliases and hardcoded values"
```

---

## Summary

| Task | What | Files | Commit |
|------|------|-------|--------|
| 1 | Add Nunito font | Resources, Info.plist, Project.swift | chore: add font |
| 2 | Typography tokens | Typography.swift + test | feat: typography tokens |
| 3 | Opacity/radius/elevation tokens | 4 new files + test | feat: design tokens |
| 4 | Animation curve tokens | AnimationTokens.swift + test | feat: animation curves |
| 5 | Pow wrappers | MotionTokens.swift | feat: Pow wrappers |
| 6 | MCLottieView | MCLottieView.swift | feat: Lottie wrapper |
| 7 | CelebrationOverlay | CelebrationOverlay.swift | feat: celebrations |
| 8 | Nova Canvas illustrations | Asset catalog images | feat: illustrations |
| 9 | MCIllustrationView | MCIllustrationView.swift | feat: illustration view |
| 10 | EmptyStateView | EmptyStateView.swift | feat: empty states |
| 11 | NightlightBackground | NightlightBackground.swift | feat: background |
| 12 | Apply to dashboard | NowScreen, status cards | feat: dashboard tokens |
| 13 | Apply to baby screen | BabyScreen, action cards | feat: baby tokens |
| 14 | Apply to feeding timer | FeedingTimerView | feat: feeding tokens |
| 15 | Apply to sleep timer | SleepTimerView | feat: sleep tokens |
| 16 | Apply to remaining screens | Growth, diapers, journal, selfcare | feat: remaining tokens |
| 17 | Source Lottie files | Animation JSON files | feat: Lottie files |
| 18 | Wire celebrations | Feature ViewModels/Views | feat: wire celebrations |
| 19 | Update onboarding | Onboarding views | feat: onboarding illustrations |
| 20 | Cleanup | Remove hardcoded values + aliases | chore: cleanup |
