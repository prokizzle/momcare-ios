import Testing
import SwiftUI
@testable import MomCare

@Suite("MCColor Tests")
struct MCColorTests {
    @Test("Semantic colors are accessible")
    func semanticColors() {
        _ = MCColor.accent
        _ = MCColor.feeding
        _ = MCColor.selfCare
        _ = MCColor.babyStatus
    }

    @Test("Urgency colors are accessible")
    func urgencyColors() {
        _ = MCColor.Urgency.safe
        _ = MCColor.Urgency.warning
        _ = MCColor.Urgency.urgent
    }
}
