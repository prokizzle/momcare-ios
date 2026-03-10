import Testing
import Foundation
import SwiftData
@testable import MomCare

@Suite("BabyModel Tests")
struct BabyModelTests {

    private func makeContainer() throws -> ModelContainer {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        return try ModelContainer(for: BabyModel.self, configurations: config)
    }

    @Test("BabyModel converts from Baby entity")
    func initFromEntity() {
        let baby = Baby.fixture(name: "Liam")
        let model = BabyModel(from: baby)
        #expect(model.id == baby.id)
        #expect(model.name == "Liam")
        #expect(model.feedingMethodRaw == Baby.FeedingMethod.breast.rawValue)
    }

    @Test("BabyModel converts to Baby entity")
    func toEntity() {
        let baby = Baby.fixture(name: "Olivia", biologicalSex: .female)
        let model = BabyModel(from: baby)
        let entity = model.toEntity()
        #expect(entity.id == baby.id)
        #expect(entity.name == "Olivia")
        #expect(entity.biologicalSex == .female)
        #expect(entity.feedingMethod == .breast)
    }

    @Test("BabyModel persists to in-memory store")
    @MainActor
    func persistence() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let model = BabyModel(from: Baby.fixture(name: "Noah"))
        context.insert(model)
        try context.save()

        let descriptor = FetchDescriptor<BabyModel>()
        let results = try context.fetch(descriptor)
        #expect(results.count == 1)
        #expect(results.first?.name == "Noah")
    }
}
