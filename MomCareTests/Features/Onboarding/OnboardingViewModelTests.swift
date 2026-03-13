import Testing
import Foundation
@testable import MomCare

private actor CallTracker {
    private(set) var wasCalled = false
    func record() { wasCalled = true }
}

private actor FormCapture {
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
        requestNotifications: @escaping @Sendable () async -> Bool = { true },
        requestHealthKit: @escaping @Sendable () async -> Bool = { true },
        signInWithApple: @escaping @Sendable () async throws -> Void = {},
        signInWithGoogle: @escaping @Sendable () async throws -> Void = {},
        signInAnonymously: @escaping @Sendable () async throws -> Void = {},
        createBaby: @escaping @Sendable (BabyFormData) async throws -> Baby = { _ in .fixture() }
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
        let sut = makeSUT(signInAnonymously: { await tracker.record() })
        sut.currentStep = .auth
        await sut.skipAuth()
        let wasCalled = await tracker.wasCalled
        #expect(wasCalled)
        #expect(sut.currentStep == .notifications)
        #expect(sut.authError == nil)
    }

    @Test("signInWithApple advances on success")
    func signInWithAppleSuccess() async {
        let sut = makeSUT()
        sut.currentStep = .auth
        await sut.performSignInWithApple()
        #expect(sut.currentStep == .notifications)
        #expect(sut.authError == nil)
    }

    @Test("signInWithApple sets error on failure")
    func signInWithAppleFailure() async {
        let sut = makeSUT(signInWithApple: { throw TestError.simulated })
        sut.currentStep = .auth
        await sut.performSignInWithApple()
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

    @Test("submitBaby creates baby and advances")
    func submitBabySuccess() async {
        let formCapture = FormCapture()
        let sut = makeSUT(createBaby: { form in
            await formCapture.store(form)
            return .fixture(name: form.name)
        })
        sut.currentStep = .addBaby
        sut.babyName = "Olivia"
        await sut.submitBaby()
        #expect(sut.currentStep == .tourDashboard)
        #expect(sut.babyError == nil)
        let captured = await formCapture.captured
        #expect(captured?.name == "Olivia")
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
