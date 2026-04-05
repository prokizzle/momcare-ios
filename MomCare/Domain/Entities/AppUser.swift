import Foundation

/// Domain-level user, decoupled from Firebase's `User` type.
struct AppUser: Sendable, Equatable, Identifiable {
    let id: String
    let email: String?
    let displayName: String?
    let isAnonymous: Bool
    let photoURL: URL?

    enum AuthProvider: String, Sendable {
        case apple
        case google
        case anonymous
    }

    let provider: AuthProvider
}
