import Testing
import Foundation
import SwiftData
@testable import MomCare

@Suite("BabyRepository Tests")
struct BabyRepositoryTests {

    private func makeSUT() throws -> (BabyRepository, ModelContext) {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: BabyModel.self, configurations: config)
        let context = ModelContext(container)
        let repo = BabyRepository(modelContext: context)
        return (repo, context)
    }

    @Test("create inserts baby and returns it")
    func create() async throws {
        let (repo, _) = try makeSUT()
        let baby = Baby.fixture(name: "Ava")
        let created = try await repo.create(baby)
        #expect(created.name == "Ava")
    }

    @Test("getAll returns all babies")
    func getAll() async throws {
        let (repo, _) = try makeSUT()
        _ = try await repo.create(Baby.fixture(name: "A"))
        _ = try await repo.create(Baby.fixture(name: "B"))
        let all = try await repo.getAll()
        #expect(all.count == 2)
    }

    @Test("getById returns matching baby")
    func getById() async throws {
        let (repo, _) = try makeSUT()
        let baby = Baby.fixture(name: "Find Me")
        let created = try await repo.create(baby)
        let found = try await repo.getById(created.id)
        #expect(found?.name == "Find Me")
    }

    @Test("getById returns nil for unknown ID")
    func getByIdNotFound() async throws {
        let (repo, _) = try makeSUT()
        let found = try await repo.getById(UUID())
        #expect(found == nil)
    }

    @Test("update modifies existing baby")
    func update() async throws {
        let (repo, _) = try makeSUT()
        var baby = try await repo.create(Baby.fixture(name: "Old"))
        baby.name = "New"
        let updated = try await repo.update(baby)
        #expect(updated.name == "New")
    }

    @Test("delete sets isDeleted flag (soft delete)")
    func softDelete() async throws {
        let (repo, _) = try makeSUT()
        let baby = try await repo.create(Baby.fixture())
        try await repo.delete(baby.id)
        let all = try await repo.getAll()
        #expect(all.first?.isDeleted == true)
    }

    @Test("getActiveBabies excludes soft-deleted")
    func getActiveBabies() async throws {
        let (repo, _) = try makeSUT()
        _ = try await repo.create(Baby.fixture(name: "Active"))
        let toDelete = try await repo.create(Baby.fixture(name: "Deleted"))
        try await repo.delete(toDelete.id)

        let active = try await repo.getActiveBabies()
        #expect(active.count == 1)
        #expect(active.first?.name == "Active")
    }
}
