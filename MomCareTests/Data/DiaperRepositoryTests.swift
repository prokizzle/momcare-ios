import Testing
import Foundation
import SwiftData
@testable import MomCare

@Suite("DiaperRepository Tests")
struct DiaperRepositoryTests {

    @MainActor
    private func makeSUT() throws -> DiaperRepository {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: DiaperModel.self, configurations: config)
        return DiaperRepository(modelContext: ModelContext(container))
    }

    private let babyId = UUID()

    @Test("create inserts diaper and returns it")
    @MainActor
    func create() async throws {
        let repo = try makeSUT()
        let diaper = Diaper.fixture(babyId: babyId)
        let created = try await repo.create(diaper)
        #expect(created.babyId == babyId)
        #expect(created.type == .wet)
    }

    @Test("getDiapersForBaby returns only that baby's entries")
    @MainActor
    func getDiapersForBaby() async throws {
        let repo = try makeSUT()
        let otherId = UUID()
        _ = try await repo.create(Diaper.fixture(babyId: babyId))
        _ = try await repo.create(Diaper.fixture(babyId: babyId))
        _ = try await repo.create(Diaper.fixture(babyId: otherId))

        let diapers = try await repo.getDiapersForBaby(babyId, limit: nil)
        #expect(diapers.count == 2)
    }

    @Test("getDiapersForBaby respects limit")
    @MainActor
    func getDiapersForBabyWithLimit() async throws {
        let repo = try makeSUT()
        for _ in 0..<5 {
            _ = try await repo.create(Diaper.fixture(babyId: babyId))
        }
        let diapers = try await repo.getDiapersForBaby(babyId, limit: 3)
        #expect(diapers.count == 3)
    }

    @Test("delete soft-deletes diaper")
    @MainActor
    func softDelete() async throws {
        let repo = try makeSUT()
        let diaper = try await repo.create(Diaper.fixture(babyId: babyId))
        try await repo.delete(diaper.id)

        let all = try await repo.getDiapersForBaby(babyId, limit: nil)
        #expect(all.isEmpty)
    }

    @Test("getDiapersForDateRange filters by timestamp")
    @MainActor
    func getDiapersForDateRange() async throws {
        let repo = try makeSUT()
        let now = Date.now
        let yesterday = now.addingTimeInterval(-86400)
        let twoDaysAgo = now.addingTimeInterval(-172800)

        _ = try await repo.create(Diaper.fixture(babyId: babyId, timestamp: now))
        _ = try await repo.create(Diaper.fixture(babyId: babyId, timestamp: yesterday))
        _ = try await repo.create(Diaper.fixture(babyId: babyId, timestamp: twoDaysAgo))

        let diapers = try await repo.getDiapersForDateRange(
            babyId: babyId,
            start: yesterday.addingTimeInterval(-3600),
            end: now.addingTimeInterval(3600)
        )
        #expect(diapers.count == 2)
    }
}
