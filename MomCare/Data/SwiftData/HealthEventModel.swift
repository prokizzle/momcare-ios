import Foundation
import SwiftData

@Model
final class HealthEventModel {
    @Attribute(.unique) var id: UUID
    var babyId: UUID
    var date: Date
    var endDate: Date?
    var eventTypeRaw: String
    var title: String
    var notes: String?
    @Attribute(.externalStorage) var photoData: [Data]
    var isSoftDeleted: Bool
    var createdAt: Date
    var updatedAt: Date

    init(from event: HealthEvent) {
        self.id = event.id
        self.babyId = event.babyId
        self.date = event.date
        self.endDate = event.endDate
        self.eventTypeRaw = event.eventType.rawValue
        self.title = event.title
        self.notes = event.notes
        self.photoData = []
        self.isSoftDeleted = event.isDeleted
        self.createdAt = event.createdAt
        self.updatedAt = event.updatedAt
    }

    func toEntity() -> HealthEvent {
        HealthEvent(
            id: id,
            babyId: babyId,
            date: date,
            endDate: endDate,
            eventType: HealthEvent.EventType(rawValue: eventTypeRaw) ?? .milestone,
            title: title,
            notes: notes,
            isDeleted: isSoftDeleted,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }

    func update(from event: HealthEvent) {
        date = event.date
        endDate = event.endDate
        eventTypeRaw = event.eventType.rawValue
        title = event.title
        notes = event.notes
        isSoftDeleted = event.isDeleted
        updatedAt = Date.now
    }
}
