import AppIntents
import Foundation

/// Represents a baby in Siri/Shortcuts parameter pickers.
///
/// `defaultQuery` reads from SharedDataManager (fast, no I/O) for suggestions
/// and falls back to an empty result for identifier resolution — the main app
/// is responsible for the full SwiftData store.
struct BabyIntentEntity: AppEntity {
    nonisolated(unsafe) static var typeDisplayRepresentation: TypeDisplayRepresentation = "Baby"

    var id: UUID
    var name: String

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(name)")
    }

    nonisolated(unsafe) static var defaultQuery = BabyIntentEntityQuery()
}

struct BabyIntentEntityQuery: EntityQuery {
    func entities(for identifiers: [UUID]) async throws -> [BabyIntentEntity] {
        // SharedDataManager only stores the selected baby — return it if it matches.
        if let id = SharedDataManager.selectedBabyId,
           identifiers.contains(id) {
            return [BabyIntentEntity(id: id, name: SharedDataManager.babyName)]
        }
        return []
    }

    func suggestedEntities() async throws -> [BabyIntentEntity] {
        guard let id = SharedDataManager.selectedBabyId else { return [] }
        return [BabyIntentEntity(id: id, name: SharedDataManager.babyName)]
    }
}
