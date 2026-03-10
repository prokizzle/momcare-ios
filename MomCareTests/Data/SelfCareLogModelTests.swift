import Testing
import Foundation
import SwiftData
@testable import MomCare

@Suite("SelfCareLogModel Tests")
struct SelfCareLogModelTests {

    @Test("Converts from entity and back")
    @MainActor
    func roundTrip() {
        let entity = SelfCareLog.fixture(actionType: .water, detail: .water(glasses: 3))
        let model = SelfCareLogModel(from: entity)
        let result = model.toEntity()
        #expect(result.id == entity.id)
        #expect(result.actionType == .water)
        if case .water(let glasses) = result.detail {
            #expect(glasses == 3)
        } else {
            Issue.record("Expected water detail")
        }
    }

    @Test("Converts meal detail correctly")
    @MainActor
    func mealRoundTrip() {
        let entity = SelfCareLog.fixture(actionType: .meal, detail: .meal(.lunch))
        let model = SelfCareLogModel(from: entity)
        let result = model.toEntity()
        if case .meal(let mealType) = result.detail {
            #expect(mealType == .lunch)
        } else {
            Issue.record("Expected meal detail")
        }
    }

    @Test("Handles nil detail")
    @MainActor
    func nilDetail() {
        let entity = SelfCareLog.fixture(actionType: .shower, detail: nil)
        let model = SelfCareLogModel(from: entity)
        let result = model.toEntity()
        #expect(result.detail == nil)
    }

    @Test("update(from:) applies changes")
    @MainActor
    func updateFromEntity() {
        let entity = SelfCareLog.fixture(actionType: .water)
        let model = SelfCareLogModel(from: entity)
        var updated = entity
        updated.detail = .water(glasses: 5)
        model.update(from: updated)
        let result = model.toEntity()
        if case .water(let glasses) = result.detail {
            #expect(glasses == 5)
        } else {
            Issue.record("Expected water detail after update")
        }
    }

    @Test("SelfCareLogModel persists to in-memory store")
    @MainActor
    func persistence() throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(
            for: SelfCareLogModel.self,
            configurations: config
        )
        let context = ModelContext(container)

        let model = SelfCareLogModel(from: SelfCareLog.fixture())
        context.insert(model)
        try context.save()

        let descriptor = FetchDescriptor<SelfCareLogModel>()
        let results = try context.fetch(descriptor)
        #expect(results.count == 1)
    }
}
