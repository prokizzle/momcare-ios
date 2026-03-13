import Foundation

enum JournalEntryKind: String, CaseIterable {
    case nap, feeding, diaper

    var label: String {
        switch self {
        case .nap: "Nap"
        case .feeding: "Feeding"
        case .diaper: "Diaper"
        }
    }

    var systemImage: String {
        switch self {
        case .nap: "moon.stars.fill"
        case .feeding: "drop.fill"
        case .diaper: "circle.dotted"
        }
    }
}

struct JournalEntry: Identifiable {
    let id: UUID
    let kind: JournalEntryKind
    let timestamp: Date
    let detail: String
}
