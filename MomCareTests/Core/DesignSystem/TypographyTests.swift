import Testing
import SwiftUI
@testable import MomCare

@Suite("MCTypography Tests")
struct MCTypographyTests {
    @Test("All font tokens are accessible")
    func fontTokens() {
        _ = MCTypography.largeTimer
        _ = MCTypography.cardTitle
        _ = MCTypography.cardBody
        _ = MCTypography.timestamp
    }
}
