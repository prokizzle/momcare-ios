import SwiftUI
import Testing
@testable import MomCare

@Suite("Design tokens")
struct DesignTokenTests {

    @Test("Opacity tokens are in valid range")
    func opacityRange() {
        let values: [Double] = [
            MCOpacity.ghost, MCOpacity.whisper, MCOpacity.soft,
            MCOpacity.medium, MCOpacity.strong, MCOpacity.heavy
        ]
        for value in values {
            #expect(value > 0 && value < 1)
        }
    }

    @Test("Opacity tokens are ordered ascending")
    func opacityOrdering() {
        #expect(MCOpacity.ghost < MCOpacity.whisper)
        #expect(MCOpacity.whisper < MCOpacity.soft)
        #expect(MCOpacity.soft < MCOpacity.medium)
        #expect(MCOpacity.medium < MCOpacity.strong)
        #expect(MCOpacity.strong < MCOpacity.heavy)
    }

    @Test("Radius tokens are positive and ordered")
    func radiusOrdering() {
        #expect(MCRadius.sm > 0)
        #expect(MCRadius.md > MCRadius.sm)
        #expect(MCRadius.lg > MCRadius.md)
        #expect(MCRadius.xl > MCRadius.lg)
    }

    @Test("Elevation levels are ordered by brightness")
    func elevationOrdering() {
        #expect(MCElevation.surfaceOpacity > 0)
        #expect(MCElevation.elevatedOpacity > MCElevation.surfaceOpacity)
        #expect(MCElevation.overlayOpacity > MCElevation.elevatedOpacity)
    }

    @Test("Canvas color exists")
    @MainActor
    func canvasColor() {
        _ = MCColor.canvas
    }

    @Test("Animation tokens exist")
    func animationTokens() {
        _ = MCAnimation.quick
        _ = MCAnimation.standard
        _ = MCAnimation.gentle
        _ = MCAnimation.slow
    }
}
