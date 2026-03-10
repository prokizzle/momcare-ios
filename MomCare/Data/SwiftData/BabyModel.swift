import Foundation
import SwiftData

@Model
final class BabyModel {
    @Attribute(.unique) var id: UUID
    var name: String
    var dateOfBirth: Date
    var biologicalSexRaw: String?
    var birthWeight: Double?
    var birthLength: Double?
    var birthHeadCircumference: Double?
    var feedingMethodRaw: String
    @Attribute(.externalStorage) var photoData: Data?
    var isSoftDeleted: Bool
    var createdAt: Date
    var updatedAt: Date

    @Relationship(deleteRule: .cascade, inverse: \FeedingModel.baby)
    var feedings: [FeedingModel] = []

    init(from baby: Baby) {
        self.id = baby.id
        self.name = baby.name
        self.dateOfBirth = baby.dateOfBirth
        self.biologicalSexRaw = baby.biologicalSex?.rawValue
        self.birthWeight = baby.birthWeight
        self.birthLength = baby.birthLength
        self.birthHeadCircumference = baby.birthHeadCircumference
        self.feedingMethodRaw = baby.feedingMethod.rawValue
        self.photoData = baby.photoData
        self.isSoftDeleted = baby.isDeleted
        self.createdAt = baby.createdAt
        self.updatedAt = baby.updatedAt
    }

    func toEntity() -> Baby {
        Baby(
            id: id,
            name: name,
            dateOfBirth: dateOfBirth,
            biologicalSex: biologicalSexRaw.flatMap { Baby.BiologicalSex(rawValue: $0) },
            birthWeight: birthWeight,
            birthLength: birthLength,
            birthHeadCircumference: birthHeadCircumference,
            feedingMethod: Baby.FeedingMethod(rawValue: feedingMethodRaw) ?? .breast,
            photoData: photoData,
            isDeleted: isSoftDeleted,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }

    func update(from baby: Baby) {
        name = baby.name
        dateOfBirth = baby.dateOfBirth
        biologicalSexRaw = baby.biologicalSex?.rawValue
        birthWeight = baby.birthWeight
        birthLength = baby.birthLength
        birthHeadCircumference = baby.birthHeadCircumference
        feedingMethodRaw = baby.feedingMethod.rawValue
        photoData = baby.photoData
        isSoftDeleted = baby.isDeleted
        updatedAt = Date.now
    }
}
