import Testing
@testable import MomCare

@Suite("MCHaptic Tests")
struct MCHapticTests {
    @Test("Haptic methods exist and are callable")
    @MainActor
    func hapticMethods() {
        MCHaptic.tap()
        MCHaptic.toggle()
        MCHaptic.success()
        MCHaptic.error()
        MCHaptic.select()
    }
}
