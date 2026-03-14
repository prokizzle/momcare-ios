import Foundation
import SwiftData

@Model
final class FeedingModel {
    @Attribute(.unique) var id: UUID
    var babyId: UUID
    var feedingTypeRaw: String
    var startTime: Date
    var endTime: Date?
    var breastSideRaw: String?
    var breastDuration: Double?
    var amountMl: Int?
    var bottleContentRaw: String?
    var foodDescription: String?
    var qualityRaw: String?
    var notes: String?
    var isSoftDeleted: Bool
    var createdAt: Date
    var updatedAt: Date

    init(from feeding: Feeding) {
        self.id = feeding.id
        self.babyId = feeding.babyId
        self.feedingTypeRaw = feeding.feedingType.rawValue
        self.startTime = feeding.startTime
        self.endTime = feeding.endTime
        self.breastSideRaw = feeding.breastSide?.rawValue
        self.breastDuration = feeding.breastDuration
        self.amountMl = feeding.amountMl
        self.bottleContentRaw = feeding.bottleContent?.rawValue
        self.foodDescription = feeding.foodDescription
        self.qualityRaw = feeding.quality?.rawValue
        self.notes = feeding.notes
        self.isSoftDeleted = false
        self.createdAt = feeding.createdAt
        self.updatedAt = feeding.updatedAt
    }

    func toEntity() -> Feeding {
        Feeding(
            id: id,
            babyId: babyId,
            feedingType: Feeding.FeedingType(rawValue: feedingTypeRaw) ?? .breast,
            startTime: startTime,
            endTime: endTime,
            breastSide: breastSideRaw.flatMap { Feeding.BreastSide(rawValue: $0) },
            breastDuration: breastDuration,
            amountMl: amountMl,
            bottleContent: bottleContentRaw.flatMap { Feeding.BottleContent(rawValue: $0) },
            foodDescription: foodDescription,
            quality: qualityRaw.flatMap { Feeding.FeedingQuality(rawValue: $0) },
            notes: notes,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }

    func update(from feeding: Feeding) {
        feedingTypeRaw = feeding.feedingType.rawValue
        startTime = feeding.startTime
        endTime = feeding.endTime
        breastSideRaw = feeding.breastSide?.rawValue
        breastDuration = feeding.breastDuration
        amountMl = feeding.amountMl
        bottleContentRaw = feeding.bottleContent?.rawValue
        foodDescription = feeding.foodDescription
        qualityRaw = feeding.quality?.rawValue
        notes = feeding.notes
        updatedAt = Date.now
    }
}
