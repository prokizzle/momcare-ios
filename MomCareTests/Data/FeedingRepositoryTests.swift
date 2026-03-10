import Testing
import Foundation
import SwiftData
@testable import MomCare

@Suite("FeedingRepository Tests")
struct FeedingRepositoryTests {

    @MainActor
    private func makeSUT() throws -> FeedingRepository {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(
            for: BabyModel.self, FeedingModel.self,
            configurations: config
        )
        let context = ModelContext(container)
        return FeedingRepository(modelContext: context)
    }

    private let testBabyId = UUID()

    @Test("create inserts feeding and returns it")
    @MainActor
    func create() async throws {
        let repo = try makeSUT()
        let feeding = Feeding.fixture(babyId: testBabyId)
        let created = try await repo.create(feeding)
        #expect(created.babyId == testBabyId)
    }

    @Test("getFeedingsForBaby returns feedings for specific baby")
    @MainActor
    func getFeedingsForBaby() async throws {
        let repo = try makeSUT()
        let otherBabyId = UUID()
        _ = try await repo.create(Feeding.fixture(babyId: testBabyId))
        _ = try await repo.create(Feeding.fixture(babyId: testBabyId))
        _ = try await repo.create(Feeding.fixture(babyId: otherBabyId))

        let feedings = try await repo.getFeedingsForBaby(testBabyId, limit: nil)
        #expect(feedings.count == 2)
    }

    @Test("getFeedingsForBaby respects limit")
    @MainActor
    func getFeedingsForBabyWithLimit() async throws {
        let repo = try makeSUT()
        for _ in 0..<5 {
            _ = try await repo.create(Feeding.fixture(babyId: testBabyId))
        }
        let feedings = try await repo.getFeedingsForBaby(testBabyId, limit: 3)
        #expect(feedings.count == 3)
    }

    @Test("getFeedingsForDateRange filters by date")
    @MainActor
    func getFeedingsForDateRange() async throws {
        let repo = try makeSUT()
        let now = Date.now
        let yesterday = now.addingTimeInterval(-86400)
        let twoDaysAgo = now.addingTimeInterval(-172800)

        _ = try await repo.create(Feeding.fixture(babyId: testBabyId, startTime: now))
        _ = try await repo.create(Feeding.fixture(babyId: testBabyId, startTime: yesterday))
        _ = try await repo.create(Feeding.fixture(babyId: testBabyId, startTime: twoDaysAgo))

        let feedings = try await repo.getFeedingsForDateRange(
            babyId: testBabyId,
            start: yesterday.addingTimeInterval(-3600),
            end: now.addingTimeInterval(3600)
        )
        #expect(feedings.count == 2)
    }

    @Test("getInProgressFeeding returns feeding with nil endTime")
    @MainActor
    func getInProgressFeeding() async throws {
        let repo = try makeSUT()
        _ = try await repo.create(Feeding.fixture(babyId: testBabyId, endTime: Date.now))
        _ = try await repo.create(Feeding.fixture(babyId: testBabyId, endTime: nil))

        let inProgress = try await repo.getInProgressFeeding(babyId: testBabyId)
        #expect(inProgress != nil)
        #expect(inProgress?.isInProgress == true)
    }

    @Test("getInProgressFeeding returns nil when none in progress")
    @MainActor
    func getInProgressFeedingNone() async throws {
        let repo = try makeSUT()
        _ = try await repo.create(Feeding.fixture(babyId: testBabyId, endTime: Date.now))

        let inProgress = try await repo.getInProgressFeeding(babyId: testBabyId)
        #expect(inProgress == nil)
    }

    @Test("update modifies existing feeding")
    @MainActor
    func update() async throws {
        let repo = try makeSUT()
        var feeding = try await repo.create(Feeding.fixture(babyId: testBabyId, endTime: nil))
        feeding.endTime = Date.now
        let updated = try await repo.update(feeding)
        #expect(updated.endTime != nil)
    }

    @Test("delete soft-deletes feeding")
    @MainActor
    func softDelete() async throws {
        let repo = try makeSUT()
        let feeding = try await repo.create(Feeding.fixture(babyId: testBabyId))
        try await repo.delete(feeding.id)

        let all = try await repo.getFeedingsForBaby(testBabyId, limit: nil)
        #expect(all.isEmpty)
    }
}
