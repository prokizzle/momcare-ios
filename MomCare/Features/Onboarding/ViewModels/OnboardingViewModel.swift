import AuthenticationServices
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
    struct Dependencies {
        var requestNotifications: () async -> Bool
        var requestHealthKit: () async -> Bool
        var signInWithApple: (ASAuthorization, String) async throws -> Void
        var signInWithGoogle: () async throws -> Void
        var signInAnonymously: () async throws -> Void
        var createBaby: (BabyFormData) async throws -> Baby
    }

    private let dependencies: Dependencies

    var currentStep: OnboardingStep = .welcome
    var isCompleted = false
    var authError: String?
    var babyError: String?
    var photoLoadError: String?

    // MARK: - Baby form fields

    var babyName = ""
    var babyDateOfBirth = Date.now
    var babyBiologicalSex: Baby.BiologicalSex?
    var babyFeedingMethod: Baby.FeedingMethod = .breast
    var babyBirthWeight = ""
    var babyBirthLength = ""
    var babyBirthHeadCircumference = ""
    var babyPhotoData: Data?
    var babySubmitSucceeded = false

    // MARK: - Apple Sign-In Nonce

    /// Raw nonce generated before each Apple Sign-In request. Must be set
    /// in the `SignInWithAppleButton` request block and passed to Firebase
    /// in the completion block for replay protection.
    private(set) var currentNonce: String = ""

    /// Generates a fresh nonce, stores it for later Firebase verification,
    /// and returns the SHA-256 hash to pass to the Apple Sign-In request.
    func prepareNonce() -> String {
        let nonce = AppleSignInNonce.randomNonceString()
        currentNonce = nonce
        return AppleSignInNonce.sha256(nonce)
    }

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
        } catch {
            // Log but don't block -- user chose to skip auth
            #if DEBUG
            print("Anonymous sign-in failed: \(error.localizedDescription)")
            #endif
        }
        advance()
    }

    func performSignInWithApple(result: Result<ASAuthorization, any Error>) async {
        authError = nil
        do {
            let authorization = try result.get()
            try await dependencies.signInWithApple(authorization, currentNonce)
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
            birthWeight: Double(babyBirthWeight),
            birthLength: Double(babyBirthLength),
            birthHeadCircumference: Double(babyBirthHeadCircumference),
            photoData: babyPhotoData
        )
        do {
            _ = try await dependencies.createBaby(formData)
            babySubmitSucceeded = true
        } catch {
            babyError = error.localizedDescription
        }
    }
}
