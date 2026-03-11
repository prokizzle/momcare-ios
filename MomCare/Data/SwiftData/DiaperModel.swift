import Foundation
import SwiftData

@Model
final class DiaperModel {
    @Attribute(.unique) var id: UUID
    var babyId: UUID
    var timestamp: Date
    var typeRaw: String
    var stoolConsistencyRaw: String?
    var stoolColorRaw: String?
    var hasRash: Bool
    var notes: String?
    var isSoftDeleted: Bool
    var createdAt: Date
    var updatedAt: Date

    init(from diaper: Diaper) {
        self.id = diaper.id
        self.babyId = diaper.babyId
        self.timestamp = diaper.timestamp
        self.typeRaw = diaper.type.rawValue
        self.stoolConsistencyRaw = diaper.stoolConsistency?.rawValue
        self.stoolColorRaw = diaper.stoolColor?.rawValue
        self.hasRash = diaper.hasRash
        self.notes = diaper.notes
        self.isSoftDeleted = false
        self.createdAt = diaper.createdAt
        self.updatedAt = diaper.updatedAt
    }

    func toEntity() -> Diaper {
        Diaper(
            id: id,
            babyId: babyId,
            timestamp: timestamp,
            type: Diaper.DiaperType(rawValue: typeRaw) ?? .wet,
            stoolConsistency: stoolConsistencyRaw.flatMap { Diaper.StoolConsistency(rawValue: $0) },
            stoolColor: stoolColorRaw.flatMap { Diaper.StoolColor(rawValue: $0) },
            hasRash: hasRash,
            notes: notes,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }

    func update(from diaper: Diaper) {
        timestamp = diaper.timestamp
        typeRaw = diaper.type.rawValue
        stoolConsistencyRaw = diaper.stoolConsistency?.rawValue
        stoolColorRaw = diaper.stoolColor?.rawValue
        hasRash = diaper.hasRash
        notes = diaper.notes
        updatedAt = .now
    }
}
