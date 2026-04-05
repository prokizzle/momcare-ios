import Testing
@testable import MomCare

@Suite("AuthService")
struct AuthServiceTests {

    // MARK: - AppUser Entity

    @Test("AppUser equality checks all fields")
    func appUserEqualityChecksAllFields() {
        let user1 = AppUser(
            id: "uid-1", email: "a@b.com", displayName: "A",
            isAnonymous: false, photoURL: nil, provider: .apple
        )
        let user2 = AppUser(
            id: "uid-1", email: "a@b.com", displayName: "A",
            isAnonymous: false, photoURL: nil, provider: .apple
        )
        #expect(user1 == user2)

        // Same ID but different displayName => not equal (struct compares all fields)
        let user3 = AppUser(
            id: "uid-1", email: "a@b.com", displayName: "B",
            isAnonymous: false, photoURL: nil, provider: .apple
        )
        #expect(user1 != user3)
    }

    @Test("Anonymous user is anonymous")
    func anonymousUser() {
        let user = AppUser(
            id: "anon-1", email: nil, displayName: nil,
            isAnonymous: true, photoURL: nil, provider: .anonymous
        )
        #expect(user.isAnonymous)
        #expect(user.email == nil)
        #expect(user.provider == .anonymous)
    }

    // MARK: - Nonce Generation

    @Test("Nonce generates correct length")
    func nonceLength() {
        let nonce = AppleSignInNonce.randomNonceString(length: 32)
        #expect(nonce.count == 32)
    }

    @Test("Nonce generates unique values")
    func nonceUniqueness() {
        let nonce1 = AppleSignInNonce.randomNonceString()
        let nonce2 = AppleSignInNonce.randomNonceString()
        #expect(nonce1 != nonce2)
    }

    @Test("SHA256 hash produces 64-char hex string")
    func sha256Output() {
        let hash = AppleSignInNonce.sha256("test-nonce")
        #expect(hash.count == 64)
        #expect(hash.allSatisfy { $0.isHexDigit })
    }

    // MARK: - StubAuthService

    @Test("Stub signInAnonymously returns anonymous user")
    func stubAnonymousSignIn() async throws {
        let stub = StubAuthService()
        let user = try await stub.signInAnonymously()
        #expect(user.isAnonymous)
        #expect(user.provider == .anonymous)
        #expect(stub.currentUser()?.id == user.id)
    }

    @Test("Stub signOut clears current user")
    func stubSignOut() async throws {
        let stub = StubAuthService()
        _ = try await stub.signInAnonymously()
        #expect(stub.currentUser() != nil)
        try stub.signOut()
        #expect(stub.currentUser() == nil)
    }

    @Test("Stub fails when shouldFail is true")
    func stubFailure() async {
        let stub = StubAuthService()
        stub.shouldFail = true
        do {
            _ = try await stub.signInAnonymously()
            Issue.record("Expected error")
        } catch {
            // Expected
        }
    }

    @Test("Stub authStateStream yields current user")
    func stubAuthStateStream() async throws {
        let stub = StubAuthService()
        _ = try await stub.signInAnonymously()

        var received: [AppUser?] = []
        for await user in stub.authStateStream() {
            received.append(user)
        }

        #expect(received.count == 1)
        guard let first = received.first, let user = first else {
            Issue.record("Expected a non-nil user in authStateStream")
            return
        }
        #expect(user.id == "anon-uid")
    }

    @Test("AuthProvider raw values")
    func authProviderRawValues() {
        #expect(AppUser.AuthProvider.apple.rawValue == "apple")
        #expect(AppUser.AuthProvider.google.rawValue == "google")
        #expect(AppUser.AuthProvider.anonymous.rawValue == "anonymous")
    }
}
