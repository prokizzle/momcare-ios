import UIKit

@MainActor
enum MCHaptic {
    private static let lightImpact = UIImpactFeedbackGenerator(style: .light)
    private static let mediumImpact = UIImpactFeedbackGenerator(style: .medium)
    private static let notification = UINotificationFeedbackGenerator()
    private static let selection = UISelectionFeedbackGenerator()

    static func tap() {
        lightImpact.impactOccurred()
    }

    static func toggle() {
        mediumImpact.impactOccurred()
    }

    static func success() {
        notification.notificationOccurred(.success)
    }

    static func error() {
        notification.notificationOccurred(.error)
    }

    static func select() {
        selection.selectionChanged()
    }
}
