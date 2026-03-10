import Foundation

struct ContentLibrary: Sendable {
    let affirmations: [Affirmation]
    let pepTalks: [PepTalk]
    let checkInPrompts: [CheckInPrompt]
    let nudgeTemplates: [NudgeTemplate]

    static func loadFromBundle(bundle: Bundle = .main) throws -> ContentLibrary {
        ContentLibrary(
            affirmations: try loadJSON("affirmations", bundle: bundle),
            pepTalks: try loadJSON("pep-talks", bundle: bundle),
            checkInPrompts: try loadJSON("check-in-prompts", bundle: bundle),
            nudgeTemplates: try loadJSON("nudge-templates", bundle: bundle)
        )
    }

    private static func loadJSON<T: Decodable>(_ name: String, bundle: Bundle) throws -> [T] {
        guard let url = bundle.url(forResource: name, withExtension: "json") else {
            throw ContentLibraryError.fileNotFound(name)
        }
        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode([T].self, from: data)
    }
}

enum ContentLibraryError: Error, LocalizedError {
    case fileNotFound(String)

    var errorDescription: String? {
        switch self {
        case .fileNotFound(let name): "Content file not found: \(name).json"
        }
    }
}
