import Testing
import Foundation
import SwiftData
@testable import MomCare

@Suite("SelfCareGridItemModel Tests")
struct SelfCareGridItemModelTests {

    @Test("Converts from entity and back")
    @MainActor
    func roundTrip() {
        let entity = SelfCareGridItem.fixture(actionType: .shower, sortOrder: 3)
        let model = SelfCareGridItemModel(from: entity)
        let result = model.toEntity()
        #expect(result.actionType == .shower)
        #expect(result.sortOrder == 3)
        #expect(result.isVisible == true)
    }

    @Test("Handles custom items")
    @MainActor
    func customItem() {
        let entity = SelfCareGridItem.fixture(
            isCustom: true,
            customName: "Vitamins",
            customIcon: "pills.fill"
        )
        let model = SelfCareGridItemModel(from: entity)
        let result = model.toEntity()
        #expect(result.isCustom == true)
        #expect(result.customName == "Vitamins")
        #expect(result.customIcon == "pills.fill")
    }

    @Test("update(from:) applies changes")
    @MainActor
    func updateFromEntity() {
        let entity = SelfCareGridItem.fixture(sortOrder: 0)
        let model = SelfCareGridItemModel(from: entity)
        let updated = SelfCareGridItem.fixture(
            id: entity.id,
            actionType: entity.actionType,
            isVisible: false,
            sortOrder: 5
        )
        model.update(from: updated)
        let result = model.toEntity()
        #expect(result.isVisible == false)
        #expect(result.sortOrder == 5)
    }

    @Test("SelfCareGridItemModel persists to in-memory store")
    @MainActor
    func persistence() throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(
            for: SelfCareGridItemModel.self,
            configurations: config
        )
        let context = ModelContext(container)

        let model = SelfCareGridItemModel(from: SelfCareGridItem.fixture())
        context.insert(model)
        try context.save()

        let descriptor = FetchDescriptor<SelfCareGridItemModel>()
        let results = try context.fetch(descriptor)
        #expect(results.count == 1)
    }
}
