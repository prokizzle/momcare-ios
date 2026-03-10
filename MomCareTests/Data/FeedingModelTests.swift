import Testing
import Foundation
import SwiftData
@testable import MomCare

@Suite("FeedingModel Tests")
struct FeedingModelTests {

    @Test("FeedingModel converts from Feeding entity")
    @MainActor
    func convertFromEntity() {
        let feeding = Feeding.fixture(feedingType: .breast, breastSide: .left)
        let model = FeedingModel(from: feeding)
        #expect(model.id == feeding.id)
        #expect(model.feedingTypeRaw == "breast")
        #expect(model.breastSideRaw == "left")
    }

    @Test("FeedingModel converts to Feeding entity")
    @MainActor
    func convertToEntity() {
        let feeding = Feeding.fixture(
            feedingType: .bottle,
            breastSide: nil,
            amountMl: 120,
            bottleContent: .formula
        )
        let model = FeedingModel(from: feeding)
        let entity = model.toEntity()
        #expect(entity.feedingType == Feeding.FeedingType.bottle)
        #expect(entity.bottleContent == Feeding.BottleContent.formula)
        #expect(entity.amountMl == 120)
    }

    @Test("FeedingModel persists to in-memory store")
    @MainActor
    func persistence() throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(
            for: BabyModel.self, FeedingModel.self,
            configurations: config
        )
        let context = ModelContext(container)

        let model = FeedingModel(from: Feeding.fixture())
        context.insert(model)
        try context.save()

        let descriptor = FetchDescriptor<FeedingModel>()
        let results = try context.fetch(descriptor)
        #expect(results.count == 1)
    }
}
