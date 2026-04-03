import Testing
import Foundation
@testable import MomCare

/// Tests for App Intents shared state and supporting types.
///
/// Intents themselves cannot be invoked in unit tests (no AppIntents runtime),
/// so we test the SharedDataManager plumbing that intents write to and the
/// mapping helpers that feed the engine on app launch.
@Suite("AppIntents", .serialized)
final class AppIntentsTests {

    let testSuiteName: String

    init() {
        testSuiteName = "test.AppIntents.\(UUID().uuidString)"
        SharedDataManager.overrideSuiteName = testSuiteName
    }

    deinit {
        UserDefaults(suiteName: testSuiteName)?.removePersistentDomain(forName: testSuiteName)
        SharedDataManager.overrideSuiteName = nil
    }

    // MARK: - selectedBabyId

    @Test("selectedBabyId round-trips UUID through UserDefaults")
    func selectedBabyIdRoundTrip() {
        let id = UUID()
        SharedDataManager.updateSelectedBabyId(id)
        #expect(SharedDataManager.selectedBabyId == id)
    }

    @Test("selectedBabyId returns nil when not set")
    func selectedBabyIdDefaultsNil() {
        #expect(SharedDataManager.selectedBabyId == nil)
    }

    @Test("updateSelectedBabyId(nil) clears the stored value")
    func selectedBabyIdClearsToNil() {
        SharedDataManager.updateSelectedBabyId(UUID())
        SharedDataManager.updateSelectedBabyId(nil)
        #expect(SharedDataManager.selectedBabyId == nil)
    }

    // MARK: - pendingStartFeedingType

    @Test("markFeedingPendingStart writes the type and clears correctly")
    func pendingStartFeedingType() {
        SharedDataManager.markFeedingPendingStart(type: "breast")
        #expect(SharedDataManager.pendingStartFeedingType == "breast")
        SharedDataManager.clearPendingStartFeeding()
        #expect(SharedDataManager.pendingStartFeedingType == nil)
    }

    @Test("pendingStartFeedingType is nil by default")
    func pendingStartFeedingDefaultNil() {
        #expect(SharedDataManager.pendingStartFeedingType == nil)
    }

    // MARK: - FeedingTypeOption feedMethod mapping

    @Test("FeedingTypeOption.breast maps to FeedMethod.left")
    func feedingOptionBreastMapsLeft() {
        #expect(FeedingTypeOption.breast.feedMethod == .left)
    }

    @Test("FeedingTypeOption.bottle maps to FeedMethod.bottle")
    func feedingOptionBottleMapsBottle() {
        #expect(FeedingTypeOption.bottle.feedMethod == .bottle)
    }
}
