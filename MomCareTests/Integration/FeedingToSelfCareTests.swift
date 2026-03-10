import Testing
import Foundation
@testable import MomCare

@Suite("Feeding to Self-Care Integration Tests")
struct FeedingToSelfCareTests {

    @Test("SelfCareEngine produces window card from feeding end event")
    func feedingEndProducesWindowCard() {
        let engine = SelfCareEngine(
            logs: [],
            patterns: [],
            contentLibrary: ContentLibrary(
                affirmations: [Affirmation(id: "a1", text: "Test", tags: [.general])],
                pepTalks: [],
                checkInPrompts: [],
                nudgeTemplates: []
            ),
            shownContentIds: [],
            currentDate: .now
        )
        let cards = engine.scoreCards(after: .feedingEnded(babyId: UUID(), duration: 1200))
        let windowCard = cards.first { $0.type == .selfCareWindow }
        #expect(windowCard != nil)
    }

    @Test("Pattern service detects relative-to-feeding with mixed feeding data")
    func patternWithFeedingData() {
        let now = Date.now
        var logs: [SelfCareLog] = []
        var feedingEndTimes: [Date] = []

        // Simulate 7 feedings with shower ~15 min after each
        for index in 0..<7 {
            let feedEnd = now.addingTimeInterval(Double(-index) * 10800)
            feedingEndTimes.append(feedEnd)
            logs.append(SelfCareLog.fixture(
                actionType: .shower,
                timestamp: feedEnd.addingTimeInterval(900) // 15 min
            ))
        }

        let patterns = SelfCarePatternService.analyzePatterns(
            logs: logs,
            feedingEndTimes: feedingEndTimes
        )
        let showerPattern = patterns.first { $0.actionType == .shower }
        #expect(showerPattern?.relativeToFeeding != nil)
    }
}
