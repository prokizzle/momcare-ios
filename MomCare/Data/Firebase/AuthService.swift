import AuthenticationServices
import CryptoKit
import FirebaseAuth
import Foundation

// MARK: - Protocol

protocol AuthServiceProtocol: Sendable {
    func signInWithApple(authorization: ASAuthorization, nonce: String) async throws -> AppUser
    func signInAnonymously() async throws -> AppUser
    func linkAppleCredential(authorization: ASAuthorization, nonce: String) async throws -> AppUser
    func signOut() throws
    func currentUser() -> AppUser?
    func authStateStream() -> AsyncStream<AppUser?>
}

// MARK: - Errors

enum AuthError: LocalizedError, Sendable {
    case missingAppleCredential
    case missingIdentityToken
    case noCurrentUser
    case linkingFailed(String)

    var errorDescription: String? {
        switch self {
        case .missingAppleCredential:
            return "Could not retrieve Apple Sign-In credential."
        case .missingIdentityToken:
            return "Apple Sign-In did not provide an identity token."
        case .noCurrentUser:
            return "No signed-in user found."
        case .linkingFailed(let reason):
            return "Account linking failed: \(reason)"
        }
    }
}

// MARK: - Nonce Helper

/// Generates a random nonce for Apple Sign-In replay protection.
enum AppleSignInNonce {
    static func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        var randomBytes = [UInt8](repeating: 0, count: length)
        let errorCode = SecRandomCopyBytes(kSecRandomDefault, randomBytes.count, &randomBytes)
        precondition(errorCode == errSecSuccess, "Unable to generate nonce.")
        let charset = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        return String(randomBytes.map { charset[Int($0) % charset.count] })
    }

    static func sha256(_ input: String) -> String {
        let data = Data(input.utf8)
        let hash = SHA256.hash(data: data)
        return hash.compactMap { String(format: "%02x", $0) }.joined()
    }
}

// MARK: - Live Implementation

/// Firebase Auth service. Thread-safe via `Sendable` — `Auth.auth()` is internally
/// thread-safe and all methods are `async`.
final class AuthService: AuthServiceProtocol, @unchecked Sendable {

    private let auth: Auth

    init(auth: Auth = Auth.auth()) {
        self.auth = auth
    }

    deinit {}

    // MARK: - Sign in with Apple

    func signInWithApple(authorization: ASAuthorization, nonce: String) async throws -> AppUser {
        guard let appleCredential = authorization.credential as? ASAuthorizationAppleIDCredential else {
            throw AuthError.missingAppleCredential
        }
        guard let tokenData = appleCredential.identityToken,
              let idToken = String(data: tokenData, encoding: .utf8) else {
            throw AuthError.missingIdentityToken
        }

        let credential = OAuthProvider.appleCredential(
            withIDToken: idToken,
            rawNonce: nonce,
            fullName: appleCredential.fullName
        )
        let result = try await auth.signIn(with: credential)
        return mapUser(result.user, provider: .apple)
    }

    // MARK: - Anonymous

    func signInAnonymously() async throws -> AppUser {
        let result = try await auth.signInAnonymously()
        return mapUser(result.user, provider: .anonymous)
    }

    // MARK: - Link Anonymous → Apple

    func linkAppleCredential(authorization: ASAuthorization, nonce: String) async throws -> AppUser {
        guard let currentUser = auth.currentUser else {
            throw AuthError.noCurrentUser
        }
        guard let appleCredential = authorization.credential as? ASAuthorizationAppleIDCredential else {
            throw AuthError.missingAppleCredential
        }
        guard let tokenData = appleCredential.identityToken,
              let idToken = String(data: tokenData, encoding: .utf8) else {
            throw AuthError.missingIdentityToken
        }

        let credential = OAuthProvider.appleCredential(
            withIDToken: idToken,
            rawNonce: nonce,
            fullName: appleCredential.fullName
        )

        do {
            let result = try await currentUser.link(with: credential)
            return mapUser(result.user, provider: .apple)
        } catch {
            throw AuthError.linkingFailed(error.localizedDescription)
        }
    }

    // MARK: - Sign Out

    func signOut() throws {
        try auth.signOut()
    }

    // MARK: - Current User

    func currentUser() -> AppUser? {
        guard let user = auth.currentUser else { return nil }
        let provider = detectProvider(user)
        return mapUser(user, provider: provider)
    }

    // MARK: - Auth State Stream

    func authStateStream() -> AsyncStream<AppUser?> {
        let auth = self.auth
        return AsyncStream { continuation in
            let handle = auth.addStateDidChangeListener { _, user in
                if let user {
                    let isAnon = user.isAnonymous
                    let providerIDs = user.providerData.map(\.providerID)
                    let provider: AppUser.AuthProvider
                    if isAnon {
                        provider = .anonymous
                    } else if providerIDs.contains("apple.com") {
                        provider = .apple
                    } else if providerIDs.contains("google.com") {
                        provider = .google
                    } else {
                        provider = .anonymous
                    }
                    continuation.yield(AppUser(
                        id: user.uid,
                        email: user.email,
                        displayName: user.displayName,
                        isAnonymous: isAnon,
                        photoURL: user.photoURL,
                        provider: provider
                    ))
                } else {
                    continuation.yield(nil)
                }
            }
            nonisolated(unsafe) let unsafeHandle = handle
            continuation.onTermination = { @Sendable _ in
                auth.removeStateDidChangeListener(unsafeHandle)
            }
        }
    }

    // MARK: - Private Helpers

    private func mapUser(_ user: FirebaseAuth.User, provider: AppUser.AuthProvider) -> AppUser {
        AppUser(
            id: user.uid,
            email: user.email,
            displayName: user.displayName,
            isAnonymous: user.isAnonymous,
            photoURL: user.photoURL,
            provider: provider
        )
    }

    private func detectProvider(_ user: FirebaseAuth.User) -> AppUser.AuthProvider {
        if user.isAnonymous { return .anonymous }
        let providerIDs = user.providerData.map(\.providerID)
        if providerIDs.contains("apple.com") { return .apple }
        if providerIDs.contains("google.com") { return .google }
        return .anonymous
    }
}

// MARK: - Stub for Testing

#if DEBUG
final class StubAuthService: AuthServiceProtocol, @unchecked Sendable {
    var stubbedUser: AppUser?
    var shouldFail = false

    deinit {}

    func signInWithApple(authorization: ASAuthorization, nonce: String) async throws -> AppUser {
        if shouldFail { throw AuthError.missingAppleCredential }
        let user = AppUser(
            id: "apple-uid",
            email: "test@example.com",
            displayName: "Test User",
            isAnonymous: false,
            photoURL: nil,
            provider: .apple
        )
        stubbedUser = user
        return user
    }

    func signInAnonymously() async throws -> AppUser {
        if shouldFail { throw AuthError.noCurrentUser }
        let user = AppUser(
            id: "anon-uid",
            email: nil,
            displayName: nil,
            isAnonymous: true,
            photoURL: nil,
            provider: .anonymous
        )
        stubbedUser = user
        return user
    }

    func linkAppleCredential(authorization: ASAuthorization, nonce: String) async throws -> AppUser {
        if shouldFail { throw AuthError.linkingFailed("Stub failure") }
        let user = AppUser(
            id: stubbedUser?.id ?? "linked-uid",
            email: "linked@example.com",
            displayName: "Linked User",
            isAnonymous: false,
            photoURL: nil,
            provider: .apple
        )
        stubbedUser = user
        return user
    }

    func signOut() throws {
        stubbedUser = nil
    }

    func currentUser() -> AppUser? {
        stubbedUser
    }

    func authStateStream() -> AsyncStream<AppUser?> {
        AsyncStream { continuation in
            continuation.yield(stubbedUser)
            continuation.finish()
        }
    }
}
#endif
