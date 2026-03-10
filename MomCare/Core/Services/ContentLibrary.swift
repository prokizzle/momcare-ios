import Foundation

struct ContentLibrary: Sendable {
    let affirmations: [Affirmation]
    let pepTalks: [PepTalk]
    let checkInPrompts: [CheckInPrompt]
    let nudgeTemplates: [NudgeTemplate]

    static func loadFromBundle(bundle: Bundle = .main) throws -> ContentLibrary {
        let decoder = JSONDecoder()
        return ContentLibrary(
            affirmations: try loadJSON("affirmations", bundle: bundle, decoder: decoder),
            pepTalks: try loadJSON("pep-talks", bundle: bundle, decoder: decoder),
            checkInPrompts: try loadJSON("check-in-prompts", bundle: bundle, decoder: decoder),
            nudgeTemplates: try loadJSON("nudge-templates", bundle: bundle, decoder: decoder)
        )
    }

    private static func loadJSON<T: Decodable>(
        _ name: String,
        bundle: Bundle,
        decoder: JSONDecoder
    ) throws -> [T] {
        guard let url = bundle.url(forResource: name, withExtension: "json") else {
            throw ContentLibraryError.fileNotFound(name)
        }
        let data = try Data(contentsOf: url)
        return try decoder.decode([T].self, from: data)
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
