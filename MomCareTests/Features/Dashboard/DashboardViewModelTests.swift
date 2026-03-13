import Testing
import Foundation
@testable import MomCare

@Suite("DashboardViewModel Tests")
struct DashboardViewModelTests {

    private let babyId = UUID()

    @MainActor
    private func makeSUT(
        feedings: [Feeding] = [],
        inProgressFeeding: Feeding? = nil,
        logs: [SelfCareLog] = [],
        gridItems: [SelfCareGridItem] = SelfCareGridItem.defaultGrid()
    ) -> DashboardViewModel {
        let feedingRepo = StubFeedingRepo(feedings: feedings, inProgress: inProgressFeeding)
        let selfCareRepo = StubSelfCareRepo(logs: logs, gridItems: gridItems)
        return DashboardViewModel(feedingRepository: feedingRepo, selfCareRepository: selfCareRepo)
    }

    // MARK: - Urgency

    @Test("Urgency is urgent with no feedings")
    @MainActor
    func urgencyNoFeedings() async {
        let sut = makeSUT()
        await sut.loadDashboard(babyId: babyId)
        #expect(sut.urgency == .urgent)
    }

    @Test("Urgency is safe within 2 hours")
    @MainActor
    func urgencySafe() async {
        let recent = Feeding.fixture(
            babyId: babyId,
            startTime: Date.now.addingTimeInterval(-3600),
            endTime: Date.now.addingTimeInterval(-1800)
        )
        let sut = makeSUT(feedings: [recent])
        await sut.loadDashboard(babyId: babyId)
        #expect(sut.urgency == .safe)
    }

    @Test("Urgency is warning between 2 and 3 hours")
    @MainActor
    func urgencyWarning() async {
        let twoAndHalfHoursAgo = Feeding.fixture(
            babyId: babyId,
            startTime: Date.now.addingTimeInterval(-9000),
            endTime: Date.now.addingTimeInterval(-9000 + 1200)
        )
        let sut = makeSUT(feedings: [twoAndHalfHoursAgo])
        await sut.loadDashboard(babyId: babyId)
        #expect(sut.urgency == .warning)
    }

    @Test("Urgency is urgent after 3 hours")
    @MainActor
    func urgencyUrgent() async {
        let old = Feeding.fixture(
            babyId: babyId,
            startTime: Date.now.addingTimeInterval(-14400),
            endTime: Date.now.addingTimeInterval(-14400 + 1200)
        )
        let sut = makeSUT(feedings: [old])
        await sut.loadDashboard(babyId: babyId)
        #expect(sut.urgency == .urgent)
    }

    @Test("In-progress feeding shows safe urgency")
    @MainActor
    func urgencyInProgress() async {
        let inProgress = Feeding.fixture(babyId: babyId, endTime: nil)
        let sut = makeSUT(inProgressFeeding: inProgress)
        await sut.loadDashboard(babyId: babyId)
        #expect(sut.urgency == .safe)
    }

    // MARK: - Daily Summary

    @Test("Daily summary computes completion percentage")
    @MainActor
    func dailySummaryCompletion() async {
        let logs = [
            SelfCareLog.fixture(actionType: .water, timestamp: .now, detail: .water(glasses: 2)),
            SelfCareLog.fixture(actionType: .meal, timestamp: .now),
            SelfCareLog.fixture(actionType: .shower, timestamp: .now)
        ]
        let sut = makeSUT(logs: logs)
        await sut.loadDashboard(babyId: babyId)
        #expect(sut.dailySummary.totalActionsToday == 3)
        #expect(sut.dailySummary.waterGlassesToday == 2)
        #expect(sut.dailySummary.mealsToday == 1)
        #expect(sut.dailySummary.completionPercentage > 0)
    }

    @Test("Daily summary is empty with no logs")
    @MainActor
    func dailySummaryEmpty() async {
        let sut = makeSUT()
        await sut.loadDashboard(babyId: babyId)
        #expect(sut.dailySummary.totalActionsToday == 0)
        #expect(sut.dailySummary.completionPercentage == 0)
    }

    @Test("Completion percentage caps at 1.0")
    @MainActor
    func completionPercentageCapped() async {
        let logs = SelfCareActionType.allCases.map { type in
            SelfCareLog.fixture(actionType: type, timestamp: .now)
        }
        let gridItems = SelfCareGridItem.defaultGrid()
        let sut = makeSUT(logs: logs, gridItems: gridItems)
        await sut.loadDashboard(babyId: babyId)
        #expect(sut.dailySummary.completionPercentage <= 1.0)
    }

    // MARK: - Suggestions

    @Test("No feeding generates suggestion to feed")
    @MainActor
    func suggestionNoFeeding() async {
        let sut = makeSUT()
        await sut.loadDashboard(babyId: babyId)
        let hasFeeding = sut.suggestions.contains { $0.actionTab == .baby }
        #expect(hasFeeding)
    }

    @Test("No water generates hydration suggestion")
    @MainActor
    func suggestionNoWater() async {
        let recent = Feeding.fixture(
            babyId: babyId,
            startTime: Date.now.addingTimeInterval(-1800),
            endTime: Date.now
        )
        let sut = makeSUT(feedings: [recent])
        await sut.loadDashboard(babyId: babyId)
        let hasSelfCare = sut.suggestions.contains { $0.actionTab == .selfCare }
        #expect(hasSelfCare)
    }

    @Test("Dismiss removes suggestion from visible list")
    @MainActor
    func dismissSuggestion() async {
        let sut = makeSUT()
        await sut.loadDashboard(babyId: babyId)
        guard let first = sut.visibleSuggestions.first else { return }
        sut.dismissSuggestion(first)
        #expect(!sut.visibleSuggestions.contains { $0.id == first.id })
    }

    @Test("loadDashboard without babyId skips feeding data")
    @MainActor
    func loadWithoutBabyId() async {
        let sut = makeSUT()
        await sut.loadDashboard(babyId: nil)
        #expect(sut.lastFeeding == nil)
        #expect(sut.inProgressFeeding == nil)
    }
}

// MARK: - Stubs

@MainActor
private final class StubFeedingRepo: FeedingRepositoryProtocol {
    private var store: [Feeding]
    private var inProgressOverride: Feeding?

    init(feedings: [Feeding] = [], inProgress: Feeding? = nil) {
        self.store = feedings
        self.inProgressOverride = inProgress
    }

    func getAll() async throws -> [Feeding] { store }
    func getById(_ id: UUID) async throws -> Feeding? { store.first { $0.id == id } }
    func create(_ entity: Feeding) async throws -> Feeding { store.append(entity); return entity }
    func update(_ entity: Feeding) async throws -> Feeding {
        if let idx = store.firstIndex(where: { $0.id == entity.id }) { store[idx] = entity }
        return entity
    }
    func delete(_ id: UUID) async throws { store.removeAll { $0.id == id } }
    func getFeedingsForBaby(_ babyId: UUID, limit: Int?) async throws -> [Feeding] {
        let filtered = store.filter { $0.babyId == babyId }
        if let limit { return Array(filtered.prefix(limit)) }
        return filtered
    }
    func getFeedingsForDateRange(babyId: UUID, start: Date, end: Date) async throws -> [Feeding] {
        store.filter { $0.babyId == babyId && $0.startTime >= start && $0.startTime <= end }
    }
    func getInProgressFeeding(babyId: UUID) async throws -> Feeding? {
        inProgressOverride ?? store.first { $0.babyId == babyId && $0.isInProgress }
    }
}

@MainActor
private final class StubSelfCareRepo: SelfCareRepositoryProtocol {
    private var logStore: [SelfCareLog]
    private var gridStore: [SelfCareGridItem]
    private var contentHistory: [String: Date] = [:]

    init(logs: [SelfCareLog] = [], gridItems: [SelfCareGridItem] = []) {
        self.logStore = logs
        self.gridStore = gridItems
    }

    func getAll() async throws -> [SelfCareLog] { logStore }
    func getById(_ id: UUID) async throws -> SelfCareLog? { logStore.first { $0.id == id } }
    func create(_ entity: SelfCareLog) async throws -> SelfCareLog {
        logStore.append(entity); return entity
    }
    func update(_ entity: SelfCareLog) async throws -> SelfCareLog {
        if let idx = logStore.firstIndex(where: { $0.id == entity.id }) { logStore[idx] = entity }
        return entity
    }
    func delete(_ id: UUID) async throws { logStore.removeAll { $0.id == id } }

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
    func deleteGridItem(_ id: UUID) async throws { gridStore.removeAll { $0.id == id } }

    func recordContentShown(contentId: String) async throws { contentHistory[contentId] = .now }
    func isContentRecentlyShown(contentId: String, within seconds: TimeInterval) async throws -> Bool {
        guard let shown = contentHistory[contentId] else { return false }
        return Date.now.timeIntervalSince(shown) < seconds
    }
}
