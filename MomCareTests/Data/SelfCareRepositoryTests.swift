import Testing
import Foundation
import SwiftData
@testable import MomCare

@Suite("SelfCareRepository Tests")
struct SelfCareRepositoryTests {

    @MainActor
    private func makeSUT() throws -> SelfCareRepository {
        let container = try TestModelContainerFactory.makeContainer()
        let context = ModelContext(container)
        return SelfCareRepository(modelContext: context)
    }

    @Test("create inserts log and returns it")
    @MainActor
    func createLog() async throws {
        let repo = try makeSUT()
        let log = SelfCareLog.fixture(actionType: .water, detail: .water(glasses: 1))
        let created = try await repo.create(log)
        #expect(created.actionType == .water)
    }

    @Test("getAll returns non-deleted logs sorted by timestamp descending")
    @MainActor
    func getAll() async throws {
        let repo = try makeSUT()
        let older = SelfCareLog.fixture(timestamp: Date.now.addingTimeInterval(-3600))
        let newer = SelfCareLog.fixture(timestamp: Date.now)
        _ = try await repo.create(older)
        _ = try await repo.create(newer)
        let all = try await repo.getAll()
        #expect(all.count == 2)
        #expect(all.first?.id == newer.id)
    }

    @Test("getById returns matching log")
    @MainActor
    func getById() async throws {
        let repo = try makeSUT()
        let log = try await repo.create(SelfCareLog.fixture())
        let found = try await repo.getById(log.id)
        #expect(found?.id == log.id)
    }

    @Test("update modifies existing log")
    @MainActor
    func updateLog() async throws {
        let repo = try makeSUT()
        var log = try await repo.create(SelfCareLog.fixture(actionType: .water))
        log.actionType = .shower
        let updated = try await repo.update(log)
        #expect(updated.actionType == .shower)
    }

    @Test("getLogsForDate returns only logs from that date")
    @MainActor
    func getLogsForDate() async throws {
        let repo = try makeSUT()
        let today = Date.now
        let yesterday = try #require(Calendar.current.date(byAdding: .day, value: -1, to: today))
        _ = try await repo.create(SelfCareLog.fixture(timestamp: today))
        _ = try await repo.create(SelfCareLog.fixture(timestamp: today))
        _ = try await repo.create(SelfCareLog.fixture(timestamp: yesterday))
        let logs = try await repo.getLogsForDate(today)
        #expect(logs.count == 2)
    }

    @Test("getLogsForDateRange returns logs in range")
    @MainActor
    func getLogsForDateRange() async throws {
        let repo = try makeSUT()
        let now = Date.now
        _ = try await repo.create(SelfCareLog.fixture(timestamp: now))
        _ = try await repo.create(SelfCareLog.fixture(timestamp: now.addingTimeInterval(-172800)))
        let logs = try await repo.getLogsForDateRange(
            start: now.addingTimeInterval(-86400),
            end: now.addingTimeInterval(3600)
        )
        #expect(logs.count == 1)
    }

    @Test("getLogsByActionType returns filtered logs")
    @MainActor
    func getLogsByActionType() async throws {
        let repo = try makeSUT()
        _ = try await repo.create(SelfCareLog.fixture(actionType: .water))
        _ = try await repo.create(SelfCareLog.fixture(actionType: .water))
        _ = try await repo.create(SelfCareLog.fixture(actionType: .shower))
        let waterLogs = try await repo.getLogsByActionType(.water, limit: nil)
        #expect(waterLogs.count == 2)
    }

    @Test("getLogsByActionType respects limit")
    @MainActor
    func getLogsByActionTypeWithLimit() async throws {
        let repo = try makeSUT()
        for _ in 0..<5 {
            _ = try await repo.create(SelfCareLog.fixture(actionType: .water))
        }
        let logs = try await repo.getLogsByActionType(.water, limit: 3)
        #expect(logs.count == 3)
    }

    @Test("delete soft-deletes log")
    @MainActor
    func softDelete() async throws {
        let repo = try makeSUT()
        let log = try await repo.create(SelfCareLog.fixture())
        try await repo.delete(log.id)
        let all = try await repo.getAll()
        #expect(all.isEmpty)
    }

    @Test("getGridItems returns persisted grid configuration")
    @MainActor
    func getGridItems() async throws {
        let repo = try makeSUT()
        let items = SelfCareGridItem.defaultGrid()
        for item in items {
            try await repo.saveGridItem(item)
        }
        let retrieved = try await repo.getGridItems()
        #expect(retrieved.count == 9)
    }

    @Test("saveGridItem updates existing item")
    @MainActor
    func updateGridItem() async throws {
        let repo = try makeSUT()
        var item = SelfCareGridItem.fixture(sortOrder: 0)
        try await repo.saveGridItem(item)
        item.sortOrder = 5
        try await repo.saveGridItem(item)
        let retrieved = try await repo.getGridItems()
        #expect(retrieved.count == 1)
        #expect(retrieved.first?.sortOrder == 5)
    }

    @Test("deleteGridItem removes grid item permanently")
    @MainActor
    func deleteGridItem() async throws {
        let repo = try makeSUT()
        let item = SelfCareGridItem.fixture()
        try await repo.saveGridItem(item)
        try await repo.deleteGridItem(item.id)
        let retrieved = try await repo.getGridItems()
        #expect(retrieved.isEmpty)
    }

    @Test("recordContentShown persists and isContentRecentlyShown detects it")
    @MainActor
    func contentHistory() async throws {
        let repo = try makeSUT()
        try await repo.recordContentShown(contentId: "aff-001")
        let recent = try await repo.isContentRecentlyShown(contentId: "aff-001", within: 3600)
        #expect(recent == true)
        let notRecent = try await repo.isContentRecentlyShown(contentId: "aff-999", within: 3600)
        #expect(notRecent == false)
    }
}
