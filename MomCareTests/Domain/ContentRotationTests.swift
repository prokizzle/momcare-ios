import Testing
import Foundation
@testable import MomCare

@Suite("Content Rotation Tests")
struct ContentRotationTests {

    private let referenceDate = Calendar.current.date(
        from: DateComponents(year: 2026, month: 3, day: 10, hour: 14)
    )!

    private func makeLibrary(
        affirmations: [Affirmation] = [],
        nudgeTemplates: [NudgeTemplate] = []
    ) -> ContentLibrary {
        ContentLibrary(
            affirmations: affirmations,
            pepTalks: [],
            checkInPrompts: [],
            nudgeTemplates: nudgeTemplates
        )
    }

    private func makeEngine(
        library: ContentLibrary,
        shownContentIds: Set<String> = []
    ) -> SelfCareEngine {
        SelfCareEngine(
            logs: [],
            patterns: [],
            contentLibrary: library,
            shownContentIds: shownContentIds,
            currentDate: referenceDate
        )
    }

    @Test("Rotation skips already-shown content ID and picks next unseen item")
    func rotationSkipsShownContent() {
        let library = makeLibrary(affirmations: [
            Affirmation(id: "aff-1", text: "First affirmation.", tags: [.general]),
            Affirmation(id: "aff-2", text: "Second affirmation.", tags: [.general])
        ])
        let engine = makeEngine(library: library, shownContentIds: ["aff-1"])

        let cards = engine.scoreCards(after: .appOpened)
        let affirmation = cards.first { $0.type == .affirmation }

        #expect(affirmation?.contentId == "aff-2")
        #expect(affirmation?.message == "Second affirmation.")
    }

    @Test("Fallback to first item when all content IDs have been shown")
    func rotationFallsBackToFirstWhenAllShown() {
        let library = makeLibrary(affirmations: [
            Affirmation(id: "aff-1", text: "First affirmation.", tags: [.general]),
            Affirmation(id: "aff-2", text: "Second affirmation.", tags: [.general])
        ])
        let engine = makeEngine(library: library, shownContentIds: ["aff-1", "aff-2"])

        let cards = engine.scoreCards(after: .appOpened)
        let affirmation = cards.first { $0.type == .affirmation }

        #expect(affirmation?.contentId == "aff-1")
        #expect(affirmation?.message == "First affirmation.")
    }

    @Test("Streak card carries contentId from selected nudge template")
    func streakCardCarriesContentId() {
        let template = NudgeTemplate(
            id: "streak-tpl-1",
            template: "{count} days of {action}.",
            type: .streak
        )
        let library = makeLibrary(nudgeTemplates: [template])
        let pattern = ActionPattern(
            actionType: .water,
            averageTimesPerDay: 1.0,
            typicalTimestamps: [],
            relativeToFeeding: nil,
            streakDays: 4,
            compliance: 1.0,
            confidence: 0.9
        )
        let engine = SelfCareEngine(
            logs: [],
            patterns: [pattern],
            contentLibrary: library,
            shownContentIds: [],
            currentDate: referenceDate
        )

        let cards = engine.scoreCards(after: .timeTick)
        let streakCard = cards.first { $0.type == .streak }

        #expect(streakCard?.contentId == "streak-tpl-1")
        #expect(streakCard?.message == "4 days of Water.")
    }
}
