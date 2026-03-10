import Testing
import Foundation
@testable import MomCare

@Suite("SelfCareEngine Tests")
struct SelfCareEngineTests {

    // Fixed reference date for deterministic tests
    private let referenceDate = Calendar.current.date(
        from: DateComponents(year: 2026, month: 3, day: 10, hour: 14)
    )!

    private func makeEngine(
        logs: [SelfCareLog] = [],
        patterns: [ActionPattern] = [],
        library: ContentLibrary? = nil,
        shownContentIds: Set<String> = []
    ) -> SelfCareEngine {
        SelfCareEngine(
            logs: logs,
            patterns: patterns,
            contentLibrary: library ?? ContentLibrary(
                affirmations: [
                    Affirmation(id: "aff-1", text: "You are doing great.", tags: [.general])
                ],
                pepTalks: [
                    PepTalk(
                        id: "pep-1",
                        text: "Every day you show up for your baby is a victory.",
                        tags: [.general]
                    )
                ],
                checkInPrompts: [
                    CheckInPrompt(
                        id: "ci-1",
                        text: "How are you feeling?",
                        responseOptions: ["Great", "OK", "Tired"]
                    )
                ],
                nudgeTemplates: [
                    NudgeTemplate(
                        id: "nudge-1",
                        template: "You usually {action} around now.",
                        type: .patternDeviation
                    )
                ]
            ),
            shownContentIds: shownContentIds,
            currentDate: referenceDate
        )
    }

    @Test("feedingEnded produces selfCareWindow card with score above 0.5")
    func feedingEndedProducesSelfCareWindow() {
        let engine = makeEngine()
        let cards = engine.scoreCards(after: .feedingEnded(babyId: UUID(), duration: 600))
        let windowCards = cards.filter { $0.type == .selfCareWindow }
        #expect(!windowCards.isEmpty)
        #expect(windowCards[0].score > 0.5)
    }

    @Test("Hydration nudge when no water in 2+ hours")
    func hydrationNudgeWhenDehydrated() {
        let oldWaterLog = SelfCareLog.fixture(
            actionType: .water,
            timestamp: referenceDate.addingTimeInterval(-7800) // 2h10m ago
        )
        let engine = makeEngine(logs: [oldWaterLog])
        let cards = engine.scoreCards(after: .timeTick)
        let hydrationCards = cards.filter { $0.type == .hydrationNudge }
        #expect(!hydrationCards.isEmpty)
    }

    @Test("No hydration nudge when water logged within 30 min")
    func noHydrationNudgeWhenHydrated() {
        let recentWater = SelfCareLog.fixture(
            actionType: .water,
            timestamp: referenceDate.addingTimeInterval(-1800) // 30 min ago
        )
        let engine = makeEngine(logs: [recentWater])
        let cards = engine.scoreCards(after: .timeTick)
        let hydrationCards = cards.filter { $0.type == .hydrationNudge }
        #expect(hydrationCards.isEmpty)
    }

    @Test("Affirmation card on appOpened with score 0.6")
    func affirmationOnAppOpened() {
        let engine = makeEngine()
        let cards = engine.scoreCards(after: .appOpened)
        let affirmationCards = cards.filter { $0.type == .affirmation }
        #expect(!affirmationCards.isEmpty)
        #expect(affirmationCards[0].score == 0.6)
    }

    @Test("Streak card for 3+ day streaks with day count in message")
    func streakCardForThreePlusDays() {
        let pattern = ActionPattern(
            actionType: .skincare,
            averageTimesPerDay: 1.0,
            typicalTimestamps: [],
            relativeToFeeding: nil,
            streakDays: 5,
            compliance: 1.0,
            confidence: 0.9
        )
        let engine = makeEngine(patterns: [pattern])
        let cards = engine.scoreCards(after: .timeTick)
        let streakCards = cards.filter { $0.type == .streak }
        #expect(!streakCards.isEmpty)
        #expect(streakCards[0].message.contains("5"))
    }

    @Test("Empty content library produces minimal cards")
    func emptyContentLibraryMinimalCards() {
        let emptyLibrary = ContentLibrary(
            affirmations: [],
            pepTalks: [],
            checkInPrompts: [],
            nudgeTemplates: []
        )
        let recentWater = SelfCareLog.fixture(
            actionType: .water,
            timestamp: referenceDate.addingTimeInterval(-300) // 5 min ago
        )
        let engine = makeEngine(logs: [recentWater], library: emptyLibrary)
        let cards = engine.scoreCards(after: .timeTick)
        let contentCards = cards.filter {
            $0.type == .affirmation || $0.type == .pepTalk
                || $0.type == .checkIn || $0.type == .hydrationNudge
        }
        #expect(contentCards.isEmpty)
    }

    @Test("Cards sorted by score descending")
    func cardsSortedByScoreDescending() {
        let engine = makeEngine()
        let cards = engine.scoreCards(after: .feedingEnded(babyId: UUID(), duration: 600))
        guard cards.count >= 2 else { return }
        for index in 0..<(cards.count - 1) {
            #expect(cards[index].score >= cards[index + 1].score)
        }
    }

    @Test("Pattern nudge fires on feedingEnded with relativeToFeeding pattern")
    func patternNudgeOnFeedingEnded() {
        let pattern = ActionPattern(
            actionType: .shower,
            averageTimesPerDay: 1.0,
            typicalTimestamps: [],
            relativeToFeeding: 1200, // 20 min after feeding
            streakDays: 0,
            compliance: 0.8,
            confidence: 0.7
        )
        let engine = makeEngine(patterns: [pattern])
        let cards = engine.scoreCards(after: .feedingEnded(babyId: UUID(), duration: 600))
        let nudgeCards = cards.filter { $0.type == .gentleNudge }
        #expect(!nudgeCards.isEmpty)
        #expect(nudgeCards[0].message.contains("Shower"))
    }
}
