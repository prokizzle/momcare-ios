import SwiftUI

enum MCTypography {
    static let largeTimer: Font = .system(size: 72, weight: .thin, design: .rounded)
    static let cardTitle: Font = .headline
    static let cardBody: Font = .callout
    static let timestamp: Font = .caption.monospacedDigit()
}
