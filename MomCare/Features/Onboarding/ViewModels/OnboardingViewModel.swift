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

@Observable
@MainActor
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
    var authError: String?
    var babyError: String?

    // MARK: - Baby form fields

    var babyName = ""
    var babyDateOfBirth = Date.now
    var babyBiologicalSex: Baby.BiologicalSex?
    var babyFeedingMethod: Baby.FeedingMethod = .breast
    var babyBirthWeight: Double?
    var babyBirthLength: Double?
    var babyBirthHeadCircumference: Double?
    var babyPhotoData: Data?

    var babyFormIsValid: Bool {
        !babyName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    // MARK: - Init

    init(dependencies: Dependencies) {
        self.dependencies = dependencies
    }

    // MARK: - Navigation

    func advance() {
        guard let next = OnboardingStep(rawValue: currentStep.rawValue + 1) else {
            isCompleted = true
            return
        }
        currentStep = next
    }

    // MARK: - Auth

    func skipAuth() async {
        authError = nil
        do {
            try await dependencies.signInAnonymously()
            advance()
        } catch {
            authError = error.localizedDescription
        }
    }

    func performSignInWithApple() async {
        authError = nil
        do {
            try await dependencies.signInWithApple()
            advance()
        } catch {
            authError = error.localizedDescription
        }
    }

    func performSignInWithGoogle() async {
        authError = nil
        do {
            try await dependencies.signInWithGoogle()
            advance()
        } catch {
            authError = error.localizedDescription
        }
    }

    // MARK: - Permissions

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

    // MARK: - Baby

    func submitBaby() async {
        babyError = nil
        let formData = BabyFormData(
            name: babyName.trimmingCharacters(in: .whitespacesAndNewlines),
            dateOfBirth: babyDateOfBirth,
            biologicalSex: babyBiologicalSex,
            feedingMethod: babyFeedingMethod,
            birthWeight: babyBirthWeight,
            birthLength: babyBirthLength,
            birthHeadCircumference: babyBirthHeadCircumference,
            photoData: babyPhotoData
        )
        do {
            _ = try await dependencies.createBaby(formData)
            advance()
        } catch {
            babyError = error.localizedDescription
        }
    }
}
