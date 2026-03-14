import Testing
import SwiftUI
@testable import MomCare

@Suite("MCTypography tokens")
struct TypographyTests {

    @Test("Display tier tokens exist")
    func displayTier() {
        _ = MCTypography.display
        _ = MCTypography.timer
        _ = MCTypography.title1
        _ = MCTypography.title2
        _ = MCTypography.title3
        _ = MCTypography.stat
        _ = MCTypography.button
        _ = MCTypography.badge
    }

    @Test("Body tier tokens exist")
    func bodyTier() {
        _ = MCTypography.body
        _ = MCTypography.callout
        _ = MCTypography.subheadline
        _ = MCTypography.footnote
        _ = MCTypography.caption
        _ = MCTypography.caption2
        _ = MCTypography.timestamp
    }

    @Test("Emotional tier tokens exist")
    func emotionalTier() {
        _ = MCTypography.affirmation
        _ = MCTypography.milestone
    }

    @Test("Headline token exists")
    func headlineToken() {
        _ = MCTypography.headline
    }

    @Test("Legacy aliases still work")
    func legacyAliases() {
        _ = MCTypography.largeTimer
        _ = MCTypography.cardTitle
        _ = MCTypography.cardBody
    }
}
