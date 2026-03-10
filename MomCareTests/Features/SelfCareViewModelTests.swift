import Testing
import Foundation
@testable import MomCare

@Suite("SelfCareViewModel Tests")
struct SelfCareViewModelTests {

    @MainActor
    private func makeSUT(
        logs: [SelfCareLog] = [],
        gridItems: [SelfCareGridItem] = SelfCareGridItem.defaultGrid()
    ) -> SelfCareViewModel {
        let repo = StubSelfCareRepository(logs: logs, gridItems: gridItems)
        let library = ContentLibrary(
            affirmations: [Affirmation(id: "a1", text: "Test", tags: [.general])],
            pepTalks: [],
            checkInPrompts: [],
            nudgeTemplates: []
        )
        return SelfCareViewModel(repository: repo, contentLibrary: library)
    }

    @Test("loadDay populates logs and grid items")
    @MainActor
    func loadDay() async {
        let log = SelfCareLog.fixture(actionType: .water, timestamp: .now)
        let sut = makeSUT(logs: [log])
        await sut.loadDay(.now)
        #expect(sut.todayLogs.count == 1)
        #expect(sut.gridItems.count == 9)
    }

    @Test("logAction creates a new log and refreshes state")
    @MainActor
    func logAction() async {
        let sut = makeSUT()
        await sut.loadDay(.now)
        await sut.logAction(.water)
        #expect(sut.todayLogs.count == 1)
        #expect(sut.todayLogs.first?.actionType == .water)
    }

    @Test("logAction with detail attaches detail")
    @MainActor
    func logActionWithDetail() async {
        let sut = makeSUT()
        await sut.loadDay(.now)
        await sut.logAction(.water, detail: .water(glasses: 2))
        #expect(sut.todayLogs.first?.detail != nil)
        if case .water(let glasses) = sut.todayLogs.first?.detail {
            #expect(glasses == 2)
        }
    }

    @Test("waterCountToday counts water logs for today")
    @MainActor
    func waterCount() async {
        let sut = makeSUT(logs: [
            SelfCareLog.fixture(actionType: .water, timestamp: .now),
            SelfCareLog.fixture(actionType: .water, timestamp: .now),
            SelfCareLog.fixture(actionType: .shower, timestamp: .now)
        ])
        await sut.loadDay(.now)
        #expect(sut.waterCountToday == 2)
    }

    @Test("handleEvent updates cards")
    @MainActor
    func handleEvent() async {
        let sut = makeSUT()
        await sut.loadDay(.now)
        await sut.handleEvent(.appOpened)
        #expect(!sut.cards.isEmpty)
    }

    @Test("recentlyTappedActions tracks last tap time")
    @MainActor
    func recentlyTapped() async {
        let sut = makeSUT()
        await sut.loadDay(.now)
        await sut.logAction(.shower)
        #expect(sut.isRecentlyTapped(.shower))
    }
}

@MainActor
private final class StubSelfCareRepository: SelfCareRepositoryProtocol {
    private var logStore: [SelfCareLog]
    private var gridStore: [SelfCareGridItem]
    private var contentHistory: [String: Date] = [:]

    init(logs: [SelfCareLog] = [], gridItems: [SelfCareGridItem] = []) {
        self.logStore = logs
        self.gridStore = gridItems
    }

    func getAll() async throws -> [SelfCareLog] { logStore.filter { _ in true } }
    func getById(_ id: UUID) async throws -> SelfCareLog? { logStore.first { $0.id == id } }
    func create(_ entity: SelfCareLog) async throws -> SelfCareLog {
        logStore.append(entity)
        return entity
    }
    func update(_ entity: SelfCareLog) async throws -> SelfCareLog {
        if let idx = logStore.firstIndex(where: { $0.id == entity.id }) {
            logStore[idx] = entity
        }
        return entity
    }
    func delete(_ id: UUID) async throws {
        logStore.removeAll { $0.id == id }
    }

    func getLogsForDate(_ date: Date) async throws -> [SelfCareLog] {
        logStore.filter { Calendar.current.isDate($0.timestamp, inSameDayAs: date) }
    }
    func getLogsForDateRange(start: Date, end: Date) async throws -> [SelfCareLog] {
        logStore.filter { $0.timestamp >= start && $0.timestamp < end }
    }
    func getLogsByActionType(_ type: SelfCareActionType, limit: Int?) async throws -> [SelfCareLog] {
        let filtered = logStore.filter { $0.actionType == type }
        if let limit { return Array(filtered.prefix(limit)) }
        return filtered
    }

    func getGridItems() async throws -> [SelfCareGridItem] { gridStore }
    func saveGridItem(_ item: SelfCareGridItem) async throws {
        if let idx = gridStore.firstIndex(where: { $0.id == item.id }) {
            gridStore[idx] = item
        } else {
            gridStore.append(item)
        }
    }
    func deleteGridItem(_ id: UUID) async throws {
        gridStore.removeAll { $0.id == id }
    }

    func recordContentShown(contentId: String) async throws {
        contentHistory[contentId] = .now
    }
    func isContentRecentlyShown(contentId: String, within seconds: TimeInterval) async throws -> Bool {
        guard let shown = contentHistory[contentId] else { return false }
        return Date.now.timeIntervalSince(shown) < seconds
    }
}
