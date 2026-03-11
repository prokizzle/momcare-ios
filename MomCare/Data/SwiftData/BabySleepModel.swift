import Foundation
import SwiftData

@Model
final class BabySleepModel {
    @Attribute(.unique) var id: UUID
    var babyId: UUID
    var startTime: Date
    var endTime: Date?
    var sleepTypeRaw: String
    var locationRaw: String?
    var qualityRaw: String?
    var notes: String?
    var isSoftDeleted: Bool
    var createdAt: Date
    var updatedAt: Date

    init(from sleep: BabySleep) {
        self.id = sleep.id
        self.babyId = sleep.babyId
        self.startTime = sleep.startTime
        self.endTime = sleep.endTime
        self.sleepTypeRaw = sleep.sleepType.rawValue
        self.locationRaw = sleep.location?.rawValue
        self.qualityRaw = sleep.quality?.rawValue
        self.notes = sleep.notes
        self.isSoftDeleted = false
        self.createdAt = sleep.createdAt
        self.updatedAt = sleep.updatedAt
    }

    func toEntity() -> BabySleep {
        BabySleep(
            id: id,
            babyId: babyId,
            startTime: startTime,
            endTime: endTime,
            sleepType: BabySleep.SleepType(rawValue: sleepTypeRaw) ?? .nap,
            location: locationRaw.flatMap { BabySleep.SleepLocation(rawValue: $0) },
            quality: qualityRaw.flatMap { BabySleep.SleepQuality(rawValue: $0) },
            notes: notes,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }

    func update(from sleep: BabySleep) {
        startTime = sleep.startTime
        endTime = sleep.endTime
        sleepTypeRaw = sleep.sleepType.rawValue
        locationRaw = sleep.location?.rawValue
        qualityRaw = sleep.quality?.rawValue
        notes = sleep.notes
        updatedAt = .now
    }
}
