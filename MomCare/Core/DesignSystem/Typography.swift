import SwiftUI

enum MCTypography {

    // MARK: - Nunito Font Helpers

    private static func nunito(_ name: String, size: CGFloat, relativeTo style: Font.TextStyle) -> Font {
        .custom(name, size: size, relativeTo: style)
    }

    // MARK: - Display Tier (Nunito -- brand identity)

    static let display: Font = nunito("Nunito-ExtraLight", size: 48, relativeTo: .largeTitle)
    static let timer: Font = nunito("Nunito-Light", size: 72, relativeTo: .largeTitle)
    static let title1: Font = nunito("Nunito-SemiBold", size: 28, relativeTo: .title)
    static let title2: Font = nunito("Nunito-SemiBold", size: 22, relativeTo: .title2)
    static let title3: Font = nunito("Nunito-Medium", size: 20, relativeTo: .title3)
    static let headline: Font = nunito("Nunito-SemiBold", size: 17, relativeTo: .headline)
    static let stat: Font = nunito("Nunito-Bold", size: 20, relativeTo: .title3).monospacedDigit()
    static let button: Font = nunito("Nunito-SemiBold", size: 17, relativeTo: .headline)
    static let badge: Font = nunito("Nunito-Bold", size: 11, relativeTo: .caption2)

    // MARK: - Body Tier (SF Pro -- readability)

    static let body: Font = .body
    static let callout: Font = .callout
    static let subheadline: Font = .subheadline
    static let footnote: Font = .footnote
    static let caption: Font = .caption
    static let caption2: Font = .caption2
    static let timestamp: Font = .caption.monospacedDigit()

    // MARK: - Emotional Tier (New York -- warmth)

    static let affirmation: Font = .system(.title3, design: .serif).italic()
    static let milestone: Font = .system(.title2, design: .serif, weight: .medium)

    // MARK: - Legacy Aliases (keep until all screens migrated)

    static let largeTimer: Font = timer
    static let cardTitle: Font = title3
    static let cardBody: Font = callout
}
