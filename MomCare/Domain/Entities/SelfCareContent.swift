import Foundation

struct Affirmation: Codable, Identifiable, Sendable {
    var id: String
    var text: String
    var tags: [Tag]

    enum Tag: String, Codable, Sendable {
        case morning, evening, tired, overwhelmed
        case newMom, milestone, general
    }
}

struct PepTalk: Codable, Identifiable, Sendable {
    var id: String
    var text: String
    var tags: [Affirmation.Tag]
}

struct CheckInPrompt: Codable, Identifiable, Sendable {
    var id: String
    var text: String
    var responseOptions: [String]
}

struct NudgeTemplate: Codable, Identifiable, Sendable {
    var id: String
    var template: String
    var type: NudgeType

    enum NudgeType: String, Codable, Sendable {
        case timeGap
        case patternDeviation
        case streak
        case hydration
        case selfCareWindow
    }

    func render(substitutions: [String: String]) -> String {
        var result = template
        for (key, value) in substitutions {
            result = result.replacingOccurrences(of: "{\(key)}", with: value)
        }
        return result
    }
}
