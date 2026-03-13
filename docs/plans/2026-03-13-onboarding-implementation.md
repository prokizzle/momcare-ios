# Onboarding Flow Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Build a 9-step onboarding funnel (welcome, auth, permissions, baby setup, tour) using DSKit, Lottie, Pow, SkeletonUI, and ComponentsKit.

**Architecture:** Single `OnboardingView` container routes between steps via an `OnboardingStep` enum driven by `OnboardingViewModel`. The ViewModel uses microapps-style DI (function-typed `Dependencies` struct). `@AppStorage("hasCompletedOnboarding")` in `MomCareApp.swift` gates the flow.

**Tech Stack:** SwiftUI, DSKit, Lottie, Pow, SkeletonUI, ComponentsKit, Firebase Auth, HealthKit, UserNotifications

**Design doc:** `docs/plans/2026-03-13-onboarding-design.md`

---

## Task 1: OnboardingViewModel with Step Progression

**Files:**
- Create: `MomCare/Features/Onboarding/ViewModels/OnboardingViewModel.swift`
- Test: `MomCareTests/Features/Onboarding/OnboardingViewModelTests.swift`

**Step 1: Write the failing test**

```swift
// MomCareTests/Features/Onboarding/OnboardingViewModelTests.swift
import Testing
import Foundation
@testable import MomCare

@Suite("OnboardingViewModel")
struct OnboardingViewModelTests {

    @MainActor
    private func makeSUT(
        requestNotifications: @escaping () async -> Bool = { true },
        requestHealthKit: @escaping () async -> Bool = { true },
        signInWithApple: @escaping () async throws -> Void = {},
        signInWithGoogle: @escaping () async throws -> Void = {},
        signInAnonymously: @escaping () async throws -> Void = {},
        createBaby: @escaping (BabyFormData) async throws -> Baby = { form in
            Baby(
                id: UUID(), name: form.name, dateOfBirth: form.dateOfBirth,
                biologicalSex: nil, birthWeight: nil, birthLength: nil,
                birthHeadCircumference: nil, feedingMethod: .breast,
                photoData: nil, isDeleted: false, createdAt: .now, updatedAt: .now
            )
        }
    ) -> OnboardingViewModel {
        OnboardingViewModel(dependencies: .init(
            requestNotifications: requestNotifications,
            requestHealthKit: requestHealthKit,
            signInWithApple: signInWithApple,
            signInWithGoogle: signInWithGoogle,
            signInAnonymously: signInAnonymously,
            createBaby: createBaby
        ))
    }

    @Test("Initial step is welcome")
    @MainActor
    func initialStep() {
        let sut = makeSUT()
        #expect(sut.currentStep == .welcome)
    }

    @Test("advance moves through all steps in order")
    @MainActor
    func advanceThroughSteps() {
        let sut = makeSUT()
        let expectedOrder: [OnboardingStep] = [
            .welcome, .features, .philosophy,
            .auth, .notifications, .healthKit,
            .addBaby, .tourDashboard, .tourSelfCare
        ]
        for (index, expected) in expectedOrder.enumerated() {
            #expect(sut.currentStep == expected, "Step \(index) should be \(expected)")
            if index < expectedOrder.count - 1 {
                sut.advance()
            }
        }
    }

    @Test("advance past last step marks completed")
    @MainActor
    func advancePastEnd() {
        let sut = makeSUT()
        // Advance to the last step
        for _ in 0..<8 { sut.advance() }
        #expect(sut.currentStep == .tourSelfCare)
        sut.advance()
        #expect(sut.isCompleted)
    }

    @Test("skipAuth calls signInAnonymously and advances")
    @MainActor
    func skipAuth() async {
        var anonymousCalled = false
        let sut = makeSUT(signInAnonymously: { anonymousCalled = true })
        // Navigate to auth step
        sut.currentStep = .auth
        await sut.skipAuth()
        #expect(anonymousCalled)
        #expect(sut.currentStep == .notifications)
    }

    @Test("signInWithApple advances on success")
    @MainActor
    func signInApple() async {
        let sut = makeSUT()
        sut.currentStep = .auth
        await sut.performSignInWithApple()
        #expect(sut.currentStep == .notifications)
        #expect(sut.authError == nil)
    }

    @Test("signInWithApple sets error on failure")
    @MainActor
    func signInAppleFails() async {
        let sut = makeSUT(signInWithApple: { throw NSError(domain: "test", code: 1) })
        sut.currentStep = .auth
        await sut.performSignInWithApple()
        #expect(sut.currentStep == .auth)
        #expect(sut.authError != nil)
    }

    @Test("requestNotificationPermission advances regardless of result")
    @MainActor
    func notificationPermission() async {
        let sut = makeSUT(requestNotifications: { false })
        sut.currentStep = .notifications
        await sut.requestNotificationPermission()
        #expect(sut.currentStep == .healthKit)
    }

    @Test("requestHealthKitPermission advances regardless of result")
    @MainActor
    func healthKitPermission() async {
        let sut = makeSUT(requestHealthKit: { false })
        sut.currentStep = .healthKit
        await sut.requestHealthKitPermission()
        #expect(sut.currentStep == .addBaby)
    }

    @Test("submitBaby creates baby and advances to tour")
    @MainActor
    func submitBaby() async {
        var createdName: String?
        let sut = makeSUT(createBaby: { form in
            createdName = form.name
            return Baby(
                id: UUID(), name: form.name, dateOfBirth: form.dateOfBirth,
                biologicalSex: nil, birthWeight: nil, birthLength: nil,
                birthHeadCircumference: nil, feedingMethod: .breast,
                photoData: nil, isDeleted: false, createdAt: .now, updatedAt: .now
            )
        })
        sut.currentStep = .addBaby
        sut.babyName = "Luna"
        sut.babyDateOfBirth = Date.now
        await sut.submitBaby()
        #expect(createdName == "Luna")
        #expect(sut.currentStep == .tourDashboard)
        #expect(sut.babyError == nil)
    }

    @Test("submitBaby sets error on failure")
    @MainActor
    func submitBabyFails() async {
        let sut = makeSUT(createBaby: { _ in throw NSError(domain: "test", code: 1) })
        sut.currentStep = .addBaby
        sut.babyName = "Luna"
        await sut.submitBaby()
        #expect(sut.currentStep == .addBaby)
        #expect(sut.babyError != nil)
    }

    @Test("babyFormIsValid requires non-empty name")
    @MainActor
    func formValidation() {
        let sut = makeSUT()
        sut.babyName = "   "
        #expect(!sut.babyFormIsValid)
        sut.babyName = "Luna"
        #expect(sut.babyFormIsValid)
    }
}
```

**Step 2: Run test to verify it fails**

Run: `tuist test 2>&1 | tail -20`
Expected: FAIL -- `OnboardingViewModel` and `OnboardingStep` not found

**Step 3: Write the implementation**

```swift
// MomCare/Features/Onboarding/ViewModels/OnboardingViewModel.swift
import Foundation

enum OnboardingStep: Int, CaseIterable, Sendable {
    case welcome
    case features
    case philosophy
    case auth
    case notifications
    case healthKit
    case addBaby
    case tourDashboard
    case tourSelfCare
}

@MainActor
@Observable
final class OnboardingViewModel {

    struct Dependencies: Sendable {
        var requestNotifications: @Sendable () async -> Bool
        var requestHealthKit: @Sendable () async -> Bool
        var signInWithApple: @Sendable () async throws -> Void
        var signInWithGoogle: @Sendable () async throws -> Void
        var signInAnonymously: @Sendable () async throws -> Void
        var createBaby: @Sendable (BabyFormData) async throws -> Baby
    }

    private let dependencies: Dependencies

    var currentStep: OnboardingStep = .welcome
    var isCompleted = false
    var authError: Error?
    var babyError: Error?

    // Baby form fields
    var babyName = ""
    var babyDateOfBirth = Date.now
    var babyBiologicalSex: Baby.BiologicalSex?
    var babyFeedingMethod: Baby.FeedingMethod = .breast
    var babyBirthWeight = ""
    var babyBirthLength = ""
    var babyBirthHeadCircumference = ""
    var babyPhotoData: Data?

    var babyFormIsValid: Bool {
        !babyName.trimmingCharacters(in: .whitespaces).isEmpty
    }

    init(dependencies: Dependencies) {
        self.dependencies = dependencies
    }

    func advance() {
        let allSteps = OnboardingStep.allCases
        guard let currentIndex = allSteps.firstIndex(of: currentStep) else { return }
        let nextIndex = allSteps.index(after: currentIndex)
        if nextIndex < allSteps.endIndex {
            currentStep = allSteps[nextIndex]
        } else {
            isCompleted = true
        }
    }

    func skipAuth() async {
        do {
            try await dependencies.signInAnonymously()
        } catch {
            // Anonymous auth failure is non-blocking
        }
        advance()
    }

    func performSignInWithApple() async {
        authError = nil
        do {
            try await dependencies.signInWithApple()
            advance()
        } catch {
            authError = error
        }
    }

    func performSignInWithGoogle() async {
        authError = nil
        do {
            try await dependencies.signInWithGoogle()
            advance()
        } catch {
            authError = error
        }
    }

    func requestNotificationPermission() async {
        _ = await dependencies.requestNotifications()
        advance()
    }

    func skipNotifications() {
        advance()
    }

    func requestHealthKitPermission() async {
        _ = await dependencies.requestHealthKit()
        advance()
    }

    func skipHealthKit() {
        advance()
    }

    func submitBaby() async {
        babyError = nil
        let formData = BabyFormData(
            name: babyName.trimmingCharacters(in: .whitespaces),
            dateOfBirth: babyDateOfBirth,
            biologicalSex: babyBiologicalSex,
            feedingMethod: babyFeedingMethod,
            birthWeight: Double(babyBirthWeight),
            birthLength: Double(babyBirthLength),
            birthHeadCircumference: Double(babyBirthHeadCircumference),
            photoData: babyPhotoData
        )
        do {
            _ = try await dependencies.createBaby(formData)
            advance()
        } catch {
            babyError = error
        }
    }
}
```

**Step 4: Run tests to verify they pass**

Run: `tuist generate --no-open && tuist test 2>&1 | tail -20`
Expected: All OnboardingViewModelTests PASS

**Step 5: Commit**

```bash
git add MomCare/Features/Onboarding/ViewModels/OnboardingViewModel.swift \
       MomCareTests/Features/Onboarding/OnboardingViewModelTests.swift
git commit -m "feat(onboarding): add OnboardingViewModel with step progression and DI"
```

---

## Task 2: OnboardingView Container + Welcome Pages

**Files:**
- Create: `MomCare/Features/Onboarding/Views/OnboardingView.swift`
- Create: `MomCare/Features/Onboarding/Views/WelcomePageView.swift`

**Step 1: Create the container view**

```swift
// MomCare/Features/Onboarding/Views/OnboardingView.swift
import SwiftUI

@MainActor
struct OnboardingView: View {
    @Bindable var viewModel: OnboardingViewModel

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            switch viewModel.currentStep {
            case .welcome, .features, .philosophy:
                welcomePages
            case .auth:
                AuthStepView(viewModel: viewModel)
            case .notifications:
                PermissionStepView(
                    viewModel: viewModel,
                    kind: .notifications
                )
            case .healthKit:
                PermissionStepView(
                    viewModel: viewModel,
                    kind: .healthKit
                )
            case .addBaby:
                OnboardingBabyFormView(viewModel: viewModel)
            case .tourDashboard, .tourSelfCare:
                tourPages
            }
        }
        .animation(.easeInOut(duration: 0.4), value: viewModel.currentStep)
    }

    private var welcomePages: some View {
        TabView(selection: Binding(
            get: { viewModel.currentStep },
            set: { viewModel.currentStep = $0 }
        )) {
            WelcomePageView(page: .hero) { viewModel.advance() }
                .tag(OnboardingStep.welcome)
            WelcomePageView(page: .features) { viewModel.advance() }
                .tag(OnboardingStep.features)
            WelcomePageView(page: .philosophy) { viewModel.advance() }
                .tag(OnboardingStep.philosophy)
        }
        .tabViewStyle(.page(indexDisplayMode: .always))
    }

    private var tourPages: some View {
        TabView(selection: Binding(
            get: { viewModel.currentStep },
            set: { viewModel.currentStep = $0 }
        )) {
            TourPageView(page: .dashboard) { viewModel.advance() }
                .tag(OnboardingStep.tourDashboard)
            TourPageView(page: .selfCare) {
                viewModel.advance() // sets isCompleted
            }
            .tag(OnboardingStep.tourSelfCare)
        }
        .tabViewStyle(.page(indexDisplayMode: .always))
    }
}
```

**Step 2: Create the welcome pages**

```swift
// MomCare/Features/Onboarding/Views/WelcomePageView.swift
import SwiftUI
import Pow

enum WelcomePage {
    case hero
    case features
    case philosophy

    var title: String {
        switch self {
        case .hero: "MomCare"
        case .features: "Everything you need"
        case .philosophy: "Designed for 3am"
        }
    }

    var subtitle: String {
        switch self {
        case .hero: "Track everything. Stress nothing."
        case .features: "Feeding, sleep, self-care, and smart insights -- all in one place."
        case .philosophy: "One-handed use. Dark mode first. No guilt, no pressure."
        }
    }

    var buttonLabel: String {
        switch self {
        case .hero: "Get Started"
        case .features: "Next"
        case .philosophy: "Let's set up"
        }
    }

    var systemImage: String {
        switch self {
        case .hero: "heart.fill"
        case .features: "square.grid.2x2.fill"
        case .philosophy: "moon.stars.fill"
        }
    }
}

@MainActor
struct WelcomePageView: View {
    let page: WelcomePage
    let onNext: () -> Void

    @State private var appeared = false

    var body: some View {
        VStack(spacing: MCSpacing.xxl) {
            Spacer()

            // Placeholder for Lottie -- use SF Symbol for now
            Image(systemName: page.systemImage)
                .font(.system(size: 80))
                .foregroundStyle(MCColor.accent.gradient)
                .conditionalEffect(
                    .repeat(.shine, every: 3),
                    condition: page == .hero && appeared
                )

            VStack(spacing: MCSpacing.md) {
                Text(page.title)
                    .font(.largeTitle.weight(.bold))
                    .foregroundStyle(.white)

                Text(page.subtitle)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, MCSpacing.xl)
            }

            if page == .features {
                featureGrid
            }

            if page == .philosophy {
                philosophyBullets
            }

            Spacer()

            Button {
                MCHaptic.tap()
                onNext()
            } label: {
                Text(page.buttonLabel)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(MCColor.accent)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .padding(.horizontal, MCSpacing.xl)
            .padding(.bottom, MCSpacing.xxl)
        }
        .onAppear { appeared = true }
    }

    private var featureGrid: some View {
        LazyVGrid(
            columns: [
                GridItem(.flexible(), spacing: MCSpacing.md),
                GridItem(.flexible(), spacing: MCSpacing.md)
            ],
            spacing: MCSpacing.md
        ) {
            featureCard(icon: "drop.fill", title: "Feeding", description: "Timer, patterns, history")
            featureCard(icon: "moon.stars.fill", title: "Sleep", description: "Track naps and nighttime")
            featureCard(icon: "sparkles", title: "Self-Care", description: "Your wellbeing matters")
            featureCard(icon: "chart.line.uptrend.xyaxis", title: "Insights", description: "Smart recommendations")
        }
        .padding(.horizontal, MCSpacing.xl)
        .transition(.movingParts.pop)
    }

    private func featureCard(icon: String, title: String, description: String) -> some View {
        VStack(spacing: MCSpacing.sm) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(MCColor.accent)
            Text(title)
                .font(.callout.weight(.semibold))
                .foregroundStyle(.white)
            Text(description)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(MCSpacing.md)
        .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
    }

    private var philosophyBullets: some View {
        VStack(alignment: .leading, spacing: MCSpacing.md) {
            bulletPoint("Built for exhausted parents, not power users")
            bulletPoint("The app learns your rhythm -- you don't configure it")
            bulletPoint("No guilt, no streaks, no judgement")
        }
        .padding(.horizontal, MCSpacing.xxl)
    }

    private func bulletPoint(_ text: String) -> some View {
        HStack(alignment: .top, spacing: MCSpacing.sm) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(MCColor.accent)
                .font(.callout)
            Text(text)
                .font(.callout)
                .foregroundStyle(.white)
        }
    }
}
```

**Step 3: Build to verify compilation**

Run: `tuist generate --no-open && tuist build 2>&1 | tail -5`
Expected: Build succeeds (AuthStepView, PermissionStepView, OnboardingBabyFormView, TourPageView referenced but not yet created -- these are behind switch cases that won't compile yet, so we need stubs)

**Important:** If build fails because the other views don't exist yet, add temporary stub files:

```swift
// Temporary stubs -- replace in later tasks
// MomCare/Features/Onboarding/Views/AuthStepView.swift
import SwiftUI
@MainActor struct AuthStepView: View {
    let viewModel: OnboardingViewModel
    var body: some View { Text("Auth") }
}

// MomCare/Features/Onboarding/Views/PermissionStepView.swift
import SwiftUI
enum PermissionKind { case notifications, healthKit }
@MainActor struct PermissionStepView: View {
    let viewModel: OnboardingViewModel
    let kind: PermissionKind
    var body: some View { Text("Permission") }
}

// MomCare/Features/Onboarding/Views/OnboardingBabyFormView.swift
import SwiftUI
@MainActor struct OnboardingBabyFormView: View {
    let viewModel: OnboardingViewModel
    var body: some View { Text("Baby Form") }
}

// MomCare/Features/Onboarding/Views/TourPageView.swift
import SwiftUI
enum TourPage { case dashboard, selfCare }
@MainActor struct TourPageView: View {
    let page: TourPage
    let onNext: () -> Void
    var body: some View { Text("Tour") }
}
```

**Step 4: Run build and tests**

Run: `tuist generate --no-open && tuist build 2>&1 | tail -5`
Expected: Build succeeds

Run: `tuist test 2>&1 | tail -20`
Expected: All tests pass

**Step 5: Commit**

```bash
git add MomCare/Features/Onboarding/
git commit -m "feat(onboarding): add OnboardingView container and welcome pages with Pow effects"
```

---

## Task 3: Auth Step View

**Files:**
- Modify: `MomCare/Features/Onboarding/Views/AuthStepView.swift` (replace stub)

**Step 1: Replace the stub with the real implementation**

```swift
// MomCare/Features/Onboarding/Views/AuthStepView.swift
import SwiftUI
import AuthenticationServices

@MainActor
struct AuthStepView: View {
    let viewModel: OnboardingViewModel

    var body: some View {
        VStack(spacing: MCSpacing.xxl) {
            Spacer()

            Image(systemName: "person.crop.circle.badge.plus")
                .font(.system(size: 60))
                .foregroundStyle(MCColor.accent.gradient)

            VStack(spacing: MCSpacing.md) {
                Text("Create your account")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(.white)

                Text("Sign in to sync across devices and share with your partner.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, MCSpacing.xl)
            }

            Spacer()

            VStack(spacing: MCSpacing.md) {
                SignInWithAppleButton(.signIn) { request in
                    request.requestedScopes = [.email, .fullName]
                } onCompletion: { _ in
                    Task { await viewModel.performSignInWithApple() }
                }
                .signInWithAppleButtonStyle(.white)
                .frame(height: 56)
                .clipShape(RoundedRectangle(cornerRadius: 16))

                Button {
                    MCHaptic.tap()
                    Task { await viewModel.performSignInWithGoogle() }
                } label: {
                    HStack(spacing: MCSpacing.sm) {
                        Image(systemName: "globe")
                        Text("Sign in with Google")
                    }
                    .font(.body.weight(.medium))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(Color.white.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                }

                if let error = viewModel.authError {
                    Text(error.localizedDescription)
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            }
            .padding(.horizontal, MCSpacing.xl)

            Button {
                MCHaptic.tap()
                Task { await viewModel.skipAuth() }
            } label: {
                Text("Continue without account")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
            .padding(.bottom, MCSpacing.xxl)
        }
    }
}
```

**Step 2: Build**

Run: `tuist build 2>&1 | tail -5`
Expected: Build succeeds

**Step 3: Commit**

```bash
git add MomCare/Features/Onboarding/Views/AuthStepView.swift
git commit -m "feat(onboarding): add auth step with Sign in with Apple and Google"
```

---

## Task 4: Permission Step View (Reusable)

**Files:**
- Modify: `MomCare/Features/Onboarding/Views/PermissionStepView.swift` (replace stub)

**Step 1: Replace the stub**

```swift
// MomCare/Features/Onboarding/Views/PermissionStepView.swift
import SwiftUI
import Pow

enum PermissionKind {
    case notifications
    case healthKit

    var icon: String {
        switch self {
        case .notifications: "bell.badge.fill"
        case .healthKit: "heart.text.clipboard.fill"
        }
    }

    var title: String {
        switch self {
        case .notifications: "Stay in the loop"
        case .healthKit: "Connect your health data"
        }
    }

    var buttonLabel: String {
        switch self {
        case .notifications: "Enable Notifications"
        case .healthKit: "Connect HealthKit"
        }
    }

    var benefits: [(icon: String, text: String)] {
        switch self {
        case .notifications:
            [
                ("drop.fill", "Feeding reminders when it's time"),
                ("moon.stars.fill", "Sleep timer alerts"),
                ("sparkles", "Self-care nudges tailored to your day"),
            ]
        case .healthKit:
            [
                ("chart.line.uptrend.xyaxis", "Growth tracking with WHO curves"),
                ("figure.walk", "Sync mom's sleep and step data"),
            ]
        }
    }
}

@MainActor
struct PermissionStepView: View {
    let viewModel: OnboardingViewModel
    let kind: PermissionKind

    @State private var appeared = false

    var body: some View {
        VStack(spacing: MCSpacing.xxl) {
            Spacer()

            Image(systemName: kind.icon)
                .font(.system(size: 60))
                .foregroundStyle(MCColor.accent.gradient)
                .conditionalEffect(
                    .repeat(.pulse, every: 2),
                    condition: appeared
                )

            VStack(spacing: MCSpacing.md) {
                Text(kind.title)
                    .font(.title2.weight(.bold))
                    .foregroundStyle(.white)

                VStack(alignment: .leading, spacing: MCSpacing.md) {
                    ForEach(Array(kind.benefits.enumerated()), id: \.offset) { _, benefit in
                        HStack(spacing: MCSpacing.sm) {
                            Image(systemName: benefit.icon)
                                .foregroundStyle(MCColor.accent)
                                .frame(width: 24)
                            Text(benefit.text)
                                .font(.callout)
                                .foregroundStyle(.white)
                        }
                    }
                }
                .padding(.horizontal, MCSpacing.xxl)
            }

            Spacer()

            VStack(spacing: MCSpacing.md) {
                Button {
                    MCHaptic.tap()
                    Task {
                        switch kind {
                        case .notifications:
                            await viewModel.requestNotificationPermission()
                        case .healthKit:
                            await viewModel.requestHealthKitPermission()
                        }
                    }
                } label: {
                    Text(kind.buttonLabel)
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(MCColor.accent)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }

                Button {
                    MCHaptic.tap()
                    switch kind {
                    case .notifications: viewModel.skipNotifications()
                    case .healthKit: viewModel.skipHealthKit()
                    }
                } label: {
                    Text("Not now")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, MCSpacing.xl)
            .padding(.bottom, MCSpacing.xxl)
        }
        .onAppear { appeared = true }
    }
}
```

**Step 2: Build**

Run: `tuist build 2>&1 | tail -5`
Expected: Build succeeds

**Step 3: Commit**

```bash
git add MomCare/Features/Onboarding/Views/PermissionStepView.swift
git commit -m "feat(onboarding): add reusable permission step for notifications and HealthKit"
```

---

## Task 5: Onboarding Baby Form (DSKit + SkeletonUI)

**Files:**
- Modify: `MomCare/Features/Onboarding/Views/OnboardingBabyFormView.swift` (replace stub)

**Step 1: Replace the stub**

```swift
// MomCare/Features/Onboarding/Views/OnboardingBabyFormView.swift
import SwiftUI
import DSKit
import SkeletonUI
import Pow
import PhotosUI

@MainActor
struct OnboardingBabyFormView: View {
    @Bindable var viewModel: OnboardingViewModel
    @State private var showOptionalDetails = false
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var showSuccess = false

    var body: some View {
        ScrollView {
            VStack(spacing: MCSpacing.xl) {
                // Header
                VStack(spacing: MCSpacing.md) {
                    Image(systemName: "figure.and.child.holdinghands")
                        .font(.system(size: 50))
                        .foregroundStyle(MCColor.accent.gradient)

                    Text("Tell us about your baby")
                        .font(.title2.weight(.bold))
                        .foregroundStyle(.white)

                    Text("Just a name and birthday to get started.")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }
                .padding(.top, MCSpacing.section)

                // Preview card with skeleton
                babyPreviewCard

                // Required fields
                VStack(spacing: MCSpacing.md) {
                    formField(title: "Baby's name", text: $viewModel.babyName)
                        .textContentType(.name)

                    DatePicker(
                        "Birthday",
                        selection: $viewModel.babyDateOfBirth,
                        in: ...Date.now,
                        displayedComponents: .date
                    )
                    .datePickerStyle(.compact)
                    .tint(MCColor.accent)
                    .foregroundStyle(.white)
                    .padding(MCSpacing.md)
                    .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
                }

                // Optional details
                DisclosureGroup(isExpanded: $showOptionalDetails) {
                    VStack(spacing: MCSpacing.md) {
                        Picker("Biological Sex", selection: $viewModel.babyBiologicalSex) {
                            Text("Not specified").tag(nil as Baby.BiologicalSex?)
                            ForEach(Baby.BiologicalSex.allCases, id: \.self) { sex in
                                Text(sex.displayName).tag(sex as Baby.BiologicalSex?)
                            }
                        }
                        .tint(.white)

                        Picker("Feeding Method", selection: $viewModel.babyFeedingMethod) {
                            ForEach(Baby.FeedingMethod.allCases, id: \.self) { method in
                                Text(method.displayName).tag(method)
                            }
                        }
                        .tint(.white)

                        formField(title: "Birth weight (g)", text: $viewModel.babyBirthWeight)
                            .keyboardType(.decimalPad)
                        formField(title: "Birth length (cm)", text: $viewModel.babyBirthLength)
                            .keyboardType(.decimalPad)
                        formField(title: "Head circumference (cm)", text: $viewModel.babyBirthHeadCircumference)
                            .keyboardType(.decimalPad)

                        PhotosPicker(selection: $selectedPhoto, matching: .images) {
                            Label("Choose Photo", systemImage: "photo")
                                .foregroundStyle(MCColor.accent)
                        }
                    }
                } label: {
                    Text("Additional Details")
                        .foregroundStyle(.secondary)
                }
                .tint(.secondary)

                if let error = viewModel.babyError {
                    Text(error.localizedDescription)
                        .font(.caption)
                        .foregroundStyle(.red)
                }

                // Submit button
                Button {
                    MCHaptic.tap()
                    Task { await viewModel.submitBaby() }
                } label: {
                    Text("Add Baby")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(viewModel.babyFormIsValid ? MCColor.accent : Color.gray)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .disabled(!viewModel.babyFormIsValid)
                .changeEffect(.spray(origin: UnitPoint(x: 0.5, y: 0.5)) {
                    Image(systemName: "star.fill")
                        .foregroundStyle(MCColor.accent)
                }, value: showSuccess)
            }
            .padding(.horizontal, MCSpacing.xl)
        }
        .onChange(of: selectedPhoto) { _, newItem in
            Task {
                viewModel.babyPhotoData = try? await newItem?.loadTransferable(type: Data.self)
            }
        }
    }

    private var babyPreviewCard: some View {
        HStack(spacing: MCSpacing.md) {
            Circle()
                .fill(MCColor.accent.opacity(0.3))
                .frame(width: 50, height: 50)
                .overlay {
                    if viewModel.babyName.isEmpty {
                        Image(systemName: "questionmark")
                            .foregroundStyle(.secondary)
                    } else {
                        Text(viewModel.babyName.prefix(1).uppercased())
                            .font(.title2.weight(.semibold))
                            .foregroundStyle(.white)
                    }
                }

            VStack(alignment: .leading, spacing: MCSpacing.xs) {
                if viewModel.babyName.isEmpty {
                    Text(" ")
                        .skeleton(with: true, shape: .capsule)
                        .frame(width: 120, height: 16)
                } else {
                    Text(viewModel.babyName)
                        .font(.headline)
                        .foregroundStyle(.white)
                }
                Text(viewModel.babyDateOfBirth.formatted(date: .abbreviated, time: .omitted))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(MCSpacing.md)
        .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 16))
    }

    private func formField(title: String, text: Binding<String>) -> some View {
        TextField(title, text: text)
            .foregroundStyle(.white)
            .padding(MCSpacing.md)
            .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
    }
}
```

**Step 2: Build**

Run: `tuist build 2>&1 | tail -5`
Expected: Build succeeds

**Step 3: Commit**

```bash
git add MomCare/Features/Onboarding/Views/OnboardingBabyFormView.swift
git commit -m "feat(onboarding): add baby form with DSKit styling, SkeletonUI preview, and Pow spray effect"
```

---

## Task 6: Tour Pages

**Files:**
- Modify: `MomCare/Features/Onboarding/Views/TourPageView.swift` (replace stub)

**Step 1: Replace the stub**

```swift
// MomCare/Features/Onboarding/Views/TourPageView.swift
import SwiftUI
import Pow

enum TourPage {
    case dashboard
    case selfCare

    var title: String {
        switch self {
        case .dashboard: "Your mission control"
        case .selfCare: "Your wellbeing matters too"
        }
    }

    var subtitle: String {
        switch self {
        case .dashboard:
            "The Now tab shows what needs attention. The Baby tab tracks feeding, sleep, and diapers."
        case .selfCare:
            "Self-Care logs your daily essentials. Journal captures the moments that matter."
        }
    }

    var features: [(icon: String, label: String)] {
        switch self {
        case .dashboard:
            [
                ("sun.horizon.fill", "Now -- what's happening right now"),
                ("figure.and.child.holdinghands", "Baby -- feeding, sleep, diapers"),
            ]
        case .selfCare:
            [
                ("sparkles", "Self-Care -- water, meals, wellness"),
                ("book.pages", "Journal -- timeline of everything"),
            ]
        }
    }

    var buttonLabel: String {
        switch self {
        case .dashboard: "Next"
        case .selfCare: "Start using MomCare"
        }
    }
}

@MainActor
struct TourPageView: View {
    let page: TourPage
    let onNext: () -> Void

    @State private var appeared = false

    var body: some View {
        VStack(spacing: MCSpacing.xxl) {
            Spacer()

            VStack(spacing: MCSpacing.lg) {
                Text(page.title)
                    .font(.title2.weight(.bold))
                    .foregroundStyle(.white)

                Text(page.subtitle)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, MCSpacing.xl)
            }

            VStack(spacing: MCSpacing.md) {
                ForEach(Array(page.features.enumerated()), id: \.offset) { _, feature in
                    HStack(spacing: MCSpacing.md) {
                        Image(systemName: feature.icon)
                            .font(.title2)
                            .foregroundStyle(MCColor.accent)
                            .frame(width: 40)
                        Text(feature.label)
                            .font(.body)
                            .foregroundStyle(.white)
                        Spacer()
                    }
                    .padding(MCSpacing.md)
                    .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
                }
            }
            .padding(.horizontal, MCSpacing.xl)

            Spacer()

            Button {
                MCHaptic.tap()
                onNext()
            } label: {
                Text(page.buttonLabel)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(MCColor.accent)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .conditionalEffect(
                        .repeat(.shine, every: 3),
                        condition: page == .selfCare && appeared
                    )
            }
            .padding(.horizontal, MCSpacing.xl)
            .padding(.bottom, MCSpacing.xxl)
        }
        .onAppear { appeared = true }
    }
}
```

**Step 2: Build**

Run: `tuist build 2>&1 | tail -5`
Expected: Build succeeds

**Step 3: Commit**

```bash
git add MomCare/Features/Onboarding/Views/TourPageView.swift
git commit -m "feat(onboarding): add tour pages with Pow shine effect on final button"
```

---

## Task 7: Wire Onboarding into MomCareApp

**Files:**
- Modify: `MomCare/App/MomCareApp.swift`
- Modify: `MomCare/App/ContentView.swift`

**Step 1: Add onboarding gate to MomCareApp.swift**

Add `@AppStorage("hasCompletedOnboarding")` and `@State private var onboardingViewModel: OnboardingViewModel?`. In the body, show `OnboardingView` when onboarding is not completed, otherwise show `ContentView`.

```swift
// In MomCareApp.swift, add these properties:
@AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
@State private var onboardingViewModel: OnboardingViewModel?

// Replace the WindowGroup body with:
WindowGroup {
    Group {
        if hasCompletedOnboarding {
            ContentView(
                babyViewModel: babyViewModel,
                selfCareViewModel: selfCareViewModel,
                dashboardViewModel: dashboardViewModel,
                babyActivityEngine: babyActivityEngine,
                journalViewModel: journalViewModel,
                sleepViewModel: sleepViewModel
            )
            .environment(appNavigation)
        } else if let onboardingViewModel {
            OnboardingView(viewModel: onboardingViewModel)
                .onChange(of: onboardingViewModel.isCompleted) { _, completed in
                    if completed {
                        hasCompletedOnboarding = true
                    }
                }
        } else {
            ProgressView()
        }
    }
    .task {
        if !hasCompletedOnboarding && onboardingViewModel == nil {
            let deps = AppDependencies(modelContext: sharedModelContainer.mainContext)
            let babyRepo = deps.makeBabyRepository()
            onboardingViewModel = OnboardingViewModel(dependencies: .init(
                requestNotifications: {
                    let center = UNUserNotificationCenter.current()
                    return (try? await center.requestAuthorization(options: [.alert, .badge, .sound])) ?? false
                },
                requestHealthKit: {
                    // Placeholder until MOM-13 (HealthKit) is implemented
                    return false
                },
                signInWithApple: {
                    // Placeholder until MOM-12 (Firebase Auth) is implemented
                },
                signInWithGoogle: {
                    // Placeholder until MOM-12 (Firebase Auth) is implemented
                },
                signInAnonymously: {
                    // Placeholder until MOM-12 (Firebase Auth) is implemented
                },
                createBaby: { formData in
                    let baby = Baby(
                        id: UUID(),
                        name: formData.name,
                        dateOfBirth: formData.dateOfBirth,
                        biologicalSex: formData.biologicalSex,
                        birthWeight: formData.birthWeight,
                        birthLength: formData.birthLength,
                        birthHeadCircumference: formData.birthHeadCircumference,
                        feedingMethod: formData.feedingMethod,
                        photoData: formData.photoData,
                        isDeleted: false,
                        createdAt: .now,
                        updatedAt: .now
                    )
                    return try await babyRepo.create(baby)
                }
            ))
        }
        if hasCompletedOnboarding && babyViewModel == nil {
            // existing .task code for setting up ViewModels (unchanged)
            let deps = AppDependencies(modelContext: sharedModelContainer.mainContext)
            let babyVM = BabyViewModel(repository: deps.makeBabyRepository())
            await babyVM.loadBabies()
            babyViewModel = babyVM
            let contentLibrary = (try? ContentLibrary.loadFromBundle()) ?? ContentLibrary(
                affirmations: [], pepTalks: [], checkInPrompts: [], nudgeTemplates: []
            )
            selfCareViewModel = SelfCareViewModel(
                repository: deps.makeSelfCareRepository(),
                contentLibrary: contentLibrary
            )
            let dashboardVM = DashboardViewModel(
                feedingRepository: deps.makeFeedingRepository(),
                selfCareRepository: deps.makeSelfCareRepository()
            )
            dashboardViewModel = dashboardVM
            let engine = BabyActivityEngine(
                sleepRepository: deps.makeSleepRepository(),
                feedingRepository: deps.makeFeedingRepository(),
                diaperRepository: deps.makeDiaperRepository()
            )
            if let babyId = babyVM.selectedBaby?.id {
                await engine.loadInProgress(babyId: babyId)
            }
            babyActivityEngine = engine
            sleepViewModel = SleepViewModel(repository: deps.makeSleepRepository())
            journalViewModel = JournalViewModel(
                sleepRepository: deps.makeSleepRepository(),
                feedingRepository: deps.makeFeedingRepository(),
                diaperRepository: deps.makeDiaperRepository()
            )
        }
    }
    // ... keep existing .onChange(of: scenePhase) and .onOpenURL
}
```

**Step 2: Add import for UserNotifications**

At the top of MomCareApp.swift, add:
```swift
import UserNotifications
```

**Step 3: Remove the empty-babies sheet from ContentView**

In `ContentView.swift`, remove these lines since onboarding now handles first baby creation:

```swift
// REMOVE:
@State private var showAddBaby = false

// REMOVE:
.onChange(of: babyViewModel?.babies.isEmpty) { _, isEmpty in
    if isEmpty == true { showAddBaby = true }
}
.sheet(isPresented: $showAddBaby) {
    if let babyViewModel { AddBabyView(viewModel: babyViewModel) }
}
```

**Note:** Keep `AddBabyView` in the codebase -- it's still used for adding subsequent babies from settings. Just remove the automatic sheet trigger.

**Step 4: Build and test**

Run: `tuist generate --no-open && tuist build 2>&1 | tail -5`
Expected: Build succeeds

Run: `tuist test 2>&1 | tail -20`
Expected: All tests pass

**Step 5: Commit**

```bash
git add MomCare/App/MomCareApp.swift MomCare/App/ContentView.swift
git commit -m "feat(onboarding): wire onboarding flow into app root with AppStorage gate"
```

---

## Task 8: Lint, Final Build, Push

**Step 1: Regenerate project**

Run: `tuist generate --no-open`

**Step 2: Build**

Run: `tuist build 2>&1 | tail -5`
Expected: Build succeeds

**Step 3: Run all tests**

Run: `tuist test 2>&1 | tail -20`
Expected: All tests pass

**Step 4: Lint**

Run: `swiftlint lint --strict MomCare/ MomCareTests/ 2>&1 | tail -5`
Expected: 0 violations

Fix any violations before proceeding.

**Step 5: Commit any lint fixes and push**

```bash
git push
```
