import SwiftUI

enum MCAnimation {
    static let quick: Animation = .spring(response: 0.25, dampingFraction: 0.8)
    static let standard: Animation = .spring(response: 0.35, dampingFraction: 0.75)
    static let gentle: Animation = .spring(response: 0.5, dampingFraction: 0.8)
    static let slow: Animation = .spring(response: 0.7, dampingFraction: 0.85)
}
