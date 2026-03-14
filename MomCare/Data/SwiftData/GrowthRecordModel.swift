import Foundation
import SwiftData

@Model
final class GrowthRecordModel {
    @Attribute(.unique) var id: UUID
    var babyId: UUID
    var date: Date
    var weightGrams: Double?
    var lengthCm: Double?
    var headCircumferenceCm: Double?
    var notes: String?
    var isSoftDeleted: Bool
    var createdAt: Date
    var updatedAt: Date

    init(from record: GrowthRecord) {
        self.id = record.id
        self.babyId = record.babyId
        self.date = record.date
        self.weightGrams = record.weightGrams
        self.lengthCm = record.lengthCm
        self.headCircumferenceCm = record.headCircumferenceCm
        self.notes = record.notes
        self.isSoftDeleted = record.isDeleted
        self.createdAt = record.createdAt
        self.updatedAt = record.updatedAt
    }

    func toEntity() -> GrowthRecord {
        GrowthRecord(
            id: id,
            babyId: babyId,
            date: date,
            weightGrams: weightGrams,
            lengthCm: lengthCm,
            headCircumferenceCm: headCircumferenceCm,
            notes: notes,
            isDeleted: isSoftDeleted,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }

    func update(from record: GrowthRecord) {
        date = record.date
        weightGrams = record.weightGrams
        lengthCm = record.lengthCm
        headCircumferenceCm = record.headCircumferenceCm
        notes = record.notes
        updatedAt = .now
    }
}
