# Onboarding Flow Design

> **Goal:** Full-funnel onboarding that sells the app's value, handles auth + permissions, collects baby data, and tours key features -- all using the new UI library stack (DSKit, Lottie, Pow, SkeletonUI, ComponentsKit).

## Flow

```
Welcome 1 (hero) -> Welcome 2 (features) -> Welcome 3 (philosophy)
    -> Auth (Sign in with Apple / Google / Skip)
    -> Notifications permission -> HealthKit permission
    -> Add Baby (DSKit form)
    -> Tour 1 -> Tour 2
    -> Main App
```

9 steps total. Forward-only progression. Dark backgrounds with vibrant, colorful Lottie illustrations and bold accent colors.

## Screen-by-Screen

### 1. Welcome Hero

- Full-screen dark background
- Centered Lottie animation (mother & baby illustration, warm colors)
- "MomCare" title with Pow `.movingParts.shine` effect
- Tagline: "Track everything. Stress nothing."
- "Get Started" button (ComponentsKit DSButton)
- Page indicator dots at bottom

### 2. Feature Highlights

- 2x2 grid of feature cards (DSKit DSVStack layout)
- Each card: SF Symbol icon + title + one-line description
- Cards: Feeding Tracker, Sleep Logging, Self-Care, Smart Insights
- Pow `.transition(.movingParts.pop)` as cards appear
- "Next" button

### 3. Philosophy

- Lottie animation (peaceful nighttime scene)
- "Designed for 3am, one-handed use"
- 2-3 short bullet points with Pow staggered entry
- "Let's set up" button

### 4. Auth

- Sign in with Apple button (prominent, top)
- Sign in with Google button (secondary)
- "Continue without account" text link at bottom
- Subtitle: "Sign in to sync across devices and share with your partner"
- On skip: create anonymous Firebase auth silently

### 5. Notifications Permission

- Lottie animation (notification bell with gentle pulse)
- "Stay in the loop" heading
- 3 benefit bullets: feeding reminders, sleep alerts, self-care nudges
- "Enable Notifications" primary button -> system prompt
- "Not now" text link (no guilt)

### 6. HealthKit Permission

- Lottie animation (heart/health visual)
- "Connect your health data" heading
- 2 benefit bullets: growth tracking with WHO curves, mom's sleep/steps sync
- "Connect HealthKit" primary button -> system prompt
- "Not now" text link

### 7. Add Baby

- DSKit-styled form (DSVStack, DSText, themed inputs)
- Progressive disclosure (same fields as current AddBabyView)
- Required: name, date of birth
- Optional (collapsed): sex, feeding method, weight, length, head circumference, photo
- SkeletonUI shimmer on the "preview card" that builds as user fills fields
- Pow `.changeEffect(.spray)` on successful creation

### 8. Tour Screen 1

- Dark background with app screenshot/mockup of the Now tab
- Lottie arrow annotations pointing to key areas
- "Your mission control" heading
- Brief description of Now + Baby tabs
- "Next" button

### 9. Tour Screen 2

- App screenshot/mockup of Self-Care + Journal tabs
- "Your wellbeing matters too" heading
- Brief description of Self-Care + Journal
- "Start using MomCare" final button with Pow `.movingParts.shine`

## Architecture

### State Management

- `OnboardingViewModel` (`@Observable`, microapps DI pattern)
- `@AppStorage("hasCompletedOnboarding")` flag in `MomCareApp.swift`
- `OnboardingStep` enum tracks current position
- ViewModel holds step, auth state, permission results, baby data

### Navigation

- Single `OnboardingView` with `TabView(.page)` for welcome screens 1-3
- Remaining steps use a step-driven container (not NavigationStack -- no back button after auth/permissions)
- Forward-only progression, skip links where noted

### Library Usage

| Library | Where |
|---------|-------|
| DSKit | Baby form layout, feature cards |
| Lottie | Welcome hero, philosophy, permissions, tour |
| Pow | Title shine, card pop transitions, spray on baby creation |
| SkeletonUI | Baby preview card shimmer while filling form |
| ComponentsKit | Buttons, inputs, badges |

### Files to Create

```
MomCare/Features/Onboarding/
  Views/
    OnboardingView.swift            (container + step routing)
    WelcomePageView.swift           (3 welcome pages)
    AuthStepView.swift              (sign in / skip)
    PermissionStepView.swift        (reusable for notif + health)
    OnboardingBabyFormView.swift    (DSKit baby setup)
    TourPageView.swift              (2 tour pages)
  ViewModels/
    OnboardingViewModel.swift
```

### DI Pattern

Microapps-style (current project pattern):

```swift
@Observable
final class OnboardingViewModel {
    struct Dependencies {
        var requestNotifications: () async -> Bool
        var requestHealthKit: () async -> Bool
        var signInWithApple: () async throws -> Void
        var signInWithGoogle: () async throws -> Void
        var signInAnonymously: () async throws -> Void
        var createBaby: (Baby) async throws -> Baby
    }

    let dependencies: Dependencies
    // ...
}
```

App container maps real services to these function types. Tests use `.mock` and `.failing` static extensions.

### Testing

- `OnboardingViewModelTests.swift` -- step progression, skip logic, completion flag, permission handling, auth flow
- Stub permission and auth services for unit tests
- No UI tests in initial scope

## Visual Tone

Dark backgrounds with vibrant, colorful Lottie illustrations and bold accent colors. High contrast, energetic, modern. Consistent with the app's dark-mode-first philosophy while feeling alive and welcoming.

## Auth Behavior

- Sign in with Apple / Google: full Firebase auth, enables sync + partner sharing
- "Continue without account": creates anonymous Firebase auth silently, app works fully offline/local
- Auth state persisted -- returning users skip onboarding entirely via `hasCompletedOnboarding` flag
