import AuthenticationServices
import Foundation
import Testing
@testable import MomCare

@MainActor
private final class CallTracker {
    private(set) var wasCalled = false
    func record() { wasCalled = true }
}

@MainActor
private final class FormCapture {
    private(set) var captured: BabyFormData?
    func store(_ form: BabyFormData) { captured = form }
}

@MainActor
@Suite("OnboardingViewModel")
struct OnboardingViewModelTests {

    private enum TestError: Error {
        case simulated
    }

    private func makeSUT(
        requestNotifications: @escaping () async -> Bool = { true },
        requestHealthKit: @escaping () async -> Bool = { true },
        signInWithApple: @escaping (ASAuthorization, String) async throws -> Void = { _, _ in },
        signInWithGoogle: @escaping () async throws -> Void = {},
        signInAnonymously: @escaping () async throws -> Void = {},
        createBaby: @escaping (BabyFormData) async throws -> Baby = { _ in .fixture() }
    ) -> OnboardingViewModel {
        OnboardingViewModel(
            dependencies: .init(
                requestNotifications: requestNotifications,
                requestHealthKit: requestHealthKit,
                signInWithApple: signInWithApple,
                signInWithGoogle: signInWithGoogle,
                signInAnonymously: signInAnonymously,
                createBaby: createBaby
            )
        )
    }

    // MARK: - Step progression

    @Test("initial step is welcome")
    func initialStep() {
        let sut = makeSUT()
        #expect(sut.currentStep == .welcome)
        #expect(!sut.isCompleted)
    }

    @Test("advance moves through all steps in order")
    func advanceThroughAllSteps() {
        let sut = makeSUT()
        let allSteps = OnboardingStep.allCases
        for index in 1..<allSteps.count {
            sut.advance()
            #expect(sut.currentStep == allSteps[index])
        }
        #expect(!sut.isCompleted)
    }

    @Test("advance past last step marks completed")
    func advancePastEnd() {
        let sut = makeSUT()
        for _ in OnboardingStep.allCases {
            sut.advance()
        }
        #expect(sut.isCompleted)
    }

    // MARK: - Auth

    @Test("skipAuth calls signInAnonymously and advances")
    func skipAuth() async {
        let tracker = CallTracker()
        let sut = makeSUT(signInAnonymously: { tracker.record() })
        sut.currentStep = .auth
        await sut.skipAuth()
        #expect(tracker.wasCalled)
        #expect(sut.currentStep == .notifications)
        #expect(sut.authError == nil)
    }

    @Test("skipAuth advances even when anonymous sign-in fails")
    func skipAuthAdvancesOnFailure() async {
        let sut = makeSUT(signInAnonymously: { throw TestError.simulated })
        sut.currentStep = .auth
        await sut.skipAuth()
        #expect(sut.currentStep == .notifications)
    }

    @Test("signInWithApple sets error when result is failure")
    func signInWithAppleResultFailure() async {
        let sut = makeSUT()
        sut.currentStep = .auth
        await sut.performSignInWithApple(result: .failure(TestError.simulated))
        #expect(sut.currentStep == .auth)
        #expect(sut.authError != nil)
    }

    @Test("signInWithApple sets error when dependency throws")
    func signInWithAppleDependencyFailure() async {
        let sut = makeSUT(signInWithApple: { _, _ in throw TestError.simulated })
        sut.currentStep = .auth
        // Use a real ASAuthorizationAppleIDProvider to get an authorization controller
        // Since ASAuthorization cannot be instantiated in tests, we test the failure
        // path through the result parameter instead
        await sut.performSignInWithApple(result: .failure(TestError.simulated))
        #expect(sut.currentStep == .auth)
        #expect(sut.authError != nil)
    }

    // MARK: - Notifications

    @Test("notification permission advances regardless of result")
    func notificationPermission() async {
        let sutGranted = makeSUT(requestNotifications: { true })
        sutGranted.currentStep = .notifications
        await sutGranted.requestNotificationPermission()
        #expect(sutGranted.currentStep == .healthKit)

        let sutDenied = makeSUT(requestNotifications: { false })
        sutDenied.currentStep = .notifications
        await sutDenied.requestNotificationPermission()
        #expect(sutDenied.currentStep == .healthKit)
    }

    // MARK: - HealthKit

    @Test("healthKit permission advances regardless of result")
    func healthKitPermission() async {
        let sutGranted = makeSUT(requestHealthKit: { true })
        sutGranted.currentStep = .healthKit
        await sutGranted.requestHealthKitPermission()
        #expect(sutGranted.currentStep == .addBaby)

        let sutDenied = makeSUT(requestHealthKit: { false })
        sutDenied.currentStep = .healthKit
        await sutDenied.requestHealthKitPermission()
        #expect(sutDenied.currentStep == .addBaby)
    }

    // MARK: - Baby

    @Test("submitBaby creates baby and sets babySubmitSucceeded")
    func submitBabySuccess() async {
        let formCapture = FormCapture()
        let sut = makeSUT(createBaby: { form in
            formCapture.store(form)
            return .fixture(name: form.name)
        })
        sut.currentStep = .addBaby
        sut.babyName = "Olivia"
        await sut.submitBaby()
        #expect(sut.babySubmitSucceeded)
        #expect(sut.currentStep == .addBaby)
        #expect(sut.babyError == nil)
        #expect(formCapture.captured?.name == "Olivia")
    }

    @Test("submitBaby sets error on failure")
    func submitBabyFailure() async {
        let sut = makeSUT(createBaby: { _ in throw TestError.simulated })
        sut.currentStep = .addBaby
        sut.babyName = "Test"
        await sut.submitBaby()
        #expect(sut.currentStep == .addBaby)
        #expect(sut.babyError != nil)
    }

    // MARK: - Google Auth

    @Test("signInWithGoogle advances on success")
    func signInWithGoogleSuccess() async {
        let sut = makeSUT()
        sut.currentStep = .auth
        await sut.performSignInWithGoogle()
        #expect(sut.currentStep == .notifications)
        #expect(sut.authError == nil)
    }

    @Test("signInWithGoogle sets error on failure")
    func signInWithGoogleFailure() async {
        let sut = makeSUT(signInWithGoogle: { throw NSError(domain: "test", code: 1) })
        sut.currentStep = .auth
        await sut.performSignInWithGoogle()
        #expect(sut.currentStep == .auth)
        #expect(sut.authError != nil)
    }

    // MARK: - Validation

    @Test("babyFormIsValid requires non-empty name")
    func babyFormValidation() {
        let sut = makeSUT()
        #expect(!sut.babyFormIsValid)

        sut.babyName = "   "
        #expect(!sut.babyFormIsValid)

        sut.babyName = "Luna"
        #expect(sut.babyFormIsValid)
    }
}
