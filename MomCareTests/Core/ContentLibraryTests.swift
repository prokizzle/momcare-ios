import Testing
import Foundation
@testable import MomCare

@Suite("ContentLibrary Tests")
struct ContentLibraryTests {

    @Test("Loads affirmations from bundle")
    func loadsAffirmations() throws {
        let library = try ContentLibrary.loadFromBundle()
        #expect(library.affirmations.count >= 20)
    }

    @Test("Loads pep talks from bundle")
    func loadsPepTalks() throws {
        let library = try ContentLibrary.loadFromBundle()
        #expect(library.pepTalks.count >= 10)
    }

    @Test("Loads check-in prompts from bundle")
    func loadsCheckInPrompts() throws {
        let library = try ContentLibrary.loadFromBundle()
        #expect(library.checkInPrompts.count >= 5)
    }

    @Test("Loads nudge templates from bundle")
    func loadsNudgeTemplates() throws {
        let library = try ContentLibrary.loadFromBundle()
        #expect(library.nudgeTemplates.count >= 5)
    }

    @Test("All affirmations have non-empty text and at least one tag")
    func affirmationQuality() throws {
        let library = try ContentLibrary.loadFromBundle()
        for affirmation in library.affirmations {
            #expect(!affirmation.text.isEmpty)
            #expect(!affirmation.tags.isEmpty)
        }
    }

    @Test("Nudge template renders with substitutions")
    func nudgeTemplateRendering() {
        let template = NudgeTemplate(
            id: "test",
            template: "You usually {action} around now.",
            type: .patternDeviation
        )
        let result = template.render(substitutions: ["action": "shower"])
        #expect(result == "You usually shower around now.")
    }

    @Test("Nudge template with missing substitution leaves placeholder")
    func nudgeTemplateMissingSub() {
        let template = NudgeTemplate(
            id: "test",
            template: "It's been {hours} hours since your last water.",
            type: .timeGap
        )
        let result = template.render(substitutions: [:])
        #expect(result == "It's been {hours} hours since your last water.")
    }
}
