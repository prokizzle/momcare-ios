import Foundation

struct Diaper: Identifiable, Codable, Sendable, Equatable {
    var id: UUID
    var babyId: UUID
    var timestamp: Date
    var type: DiaperType
    var stoolConsistency: StoolConsistency?
    var stoolColor: StoolColor?
    var hasRash: Bool
    var notes: String?
    var createdAt: Date
    var updatedAt: Date

    var hasStoolDetails: Bool {
        type == .dirty || type == .both
    }

    enum DiaperType: String, Codable, CaseIterable, Sendable {
        case wet, dirty, both

        var systemImage: String {
            switch self {
            case .wet: "drop.fill"
            case .dirty: "circle.fill"
            case .both: "drop.circle.fill"
            }
        }

        var label: String {
            switch self {
            case .wet: "Wet"
            case .dirty: "Dirty"
            case .both: "Both"
            }
        }
    }

    enum StoolConsistency: String, Codable, CaseIterable, Sendable {
        case loose, normal, hard

        var label: String { rawValue.capitalized }
    }

    enum StoolColor: String, Codable, CaseIterable, Sendable {
        case yellow, green, brown, black, red

        var label: String { rawValue.capitalized }
    }
}

// MARK: - Testing Fixtures

extension Diaper {
    static func fixture(
        id: UUID = UUID(),
        babyId: UUID = UUID(),
        timestamp: Date = .now,
        type: DiaperType = .wet,
        stoolConsistency: StoolConsistency? = nil,
        stoolColor: StoolColor? = nil,
        hasRash: Bool = false,
        notes: String? = nil,
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) -> Diaper {
        Diaper(
            id: id,
            babyId: babyId,
            timestamp: timestamp,
            type: type,
            stoolConsistency: stoolConsistency,
            stoolColor: stoolColor,
            hasRash: hasRash,
            notes: notes,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
}
