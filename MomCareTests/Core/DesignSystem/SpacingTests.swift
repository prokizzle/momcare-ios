import Testing
@testable import MomCare

@Suite("MCSpacing Tests")
struct MCSpacingTests {
    @Test("Spacing values follow 4pt grid")
    func spacingValues() {
        #expect(MCSpacing.xs == 4)
        #expect(MCSpacing.sm == 8)
        #expect(MCSpacing.md == 12)
        #expect(MCSpacing.lg == 16)
        #expect(MCSpacing.xl == 24)
        #expect(MCSpacing.xxl == 32)
        #expect(MCSpacing.section == 40)
    }
}
