import Testing
import Foundation
@testable import MomCare

@Suite("HealthKitService", .serialized)
@MainActor
struct HealthKitServiceTests {

    // MARK: - Stub conformance

    @Test("StubHealthKitService is not available")
    func stubIsNotAvailable() {
        let stub = StubHealthKitService()
        #expect(stub.isAvailable == false)
    }

    @Test("StubHealthKitService.requestAuthorization completes without hanging")
    func stubRequestAuthorization() async {
        let stub = StubHealthKitService()
        await stub.requestAuthorization()
    }

    @Test("StubHealthKitService.writeBabyMeasurement completes without hanging")
    func stubWriteBabyMeasurement() async {
        let stub = StubHealthKitService()
        await stub.writeBabyMeasurement(
            weightGrams: 3500,
            heightCm: 50,
            headCircumferenceCm: 34,
            date: .now
        )
    }

    @Test("StubHealthKitService.readStepCount returns 0")
    func stubReadStepCount() async {
        let stub = StubHealthKitService()
        let steps = await stub.readStepCount(for: .now)
        #expect(steps == 0)
    }

    // MARK: - GrowthViewModel integration

    @Test("GrowthViewModel.addMeasurement calls HealthKit write exactly once")
    func growthViewModelHealthKitWrite() async throws {
        let spy = SpyHealthKitService()
        let viewModel = GrowthViewModel(
            repository: StubGrowthRepository(),
            healthKit: spy
        )
        let success = await viewModel.addMeasurement(
            babyId: UUID(),
            date: .now,
            weightGrams: 4200,
            lengthCm: 54,
            headCircumferenceCm: 36,
            notes: nil
        )
        #expect(success == true)
        // Give the fire-and-forget Task enough scheduling opportunities to run.
        for _ in 0..<5 { await Task.yield() }
        #expect(spy.writeCallCount == 1)
        #expect(spy.lastWrittenWeight == 4200)
    }

    @Test("GrowthViewModel.addMeasurement succeeds without HealthKit service")
    func growthViewModelWithoutHealthKit() async {
        let viewModel = GrowthViewModel(repository: StubGrowthRepository())
        let success = await viewModel.addMeasurement(
            babyId: UUID(),
            date: .now,
            weightGrams: 3800,
            lengthCm: nil,
            headCircumferenceCm: nil,
            notes: nil
        )
        #expect(success == true)
    }

    // MARK: - DashboardViewModel integration

    @Test("DashboardViewModel step count nudge appears when steps are low")
    func dashboardStepNudge() async {
        let spy = SpyHealthKitService(stubbedStepCount: 1_500)
        let viewModel = DashboardViewModel(
            feedingRepository: StubDashboardFeedingRepository(),
            selfCareRepository: StubDashboardSelfCareRepository(),
            healthKit: spy
        )
        await viewModel.loadDashboard(babyId: UUID())
        let hasStepNudge = viewModel.suggestions.contains {
            $0.message.contains("steps so far")
        }
        #expect(hasStepNudge == true)
    }

    @Test("DashboardViewModel step nudge absent when steps are zero (no HealthKit data)")
    func dashboardNoStepNudgeWhenZero() async {
        let spy = SpyHealthKitService(stubbedStepCount: 0)
        let viewModel = DashboardViewModel(
            feedingRepository: StubDashboardFeedingRepository(),
            selfCareRepository: StubDashboardSelfCareRepository(),
            healthKit: spy
        )
        await viewModel.loadDashboard(babyId: UUID())
        let hasStepNudge = viewModel.suggestions.contains {
            $0.message.contains("steps so far")
        }
        #expect(hasStepNudge == false)
    }
}

// MARK: - Spy

final class SpyHealthKitService: HealthKitServiceProtocol, @unchecked Sendable {
    let isAvailable: Bool = false
    private(set) var writeCallCount: Int = 0
    private(set) var lastWrittenWeight: Double?
    private let stubbedStepCount: Int

    init(stubbedStepCount: Int = 0) {
        self.stubbedStepCount = stubbedStepCount
    }

    func requestAuthorization() async {}

    func writeBabyMeasurement(
        weightGrams: Double?,
        heightCm: Double?,
        headCircumferenceCm: Double?,
        date: Date
    ) async {
        writeCallCount += 1
        lastWrittenWeight = weightGrams
    }

    func readStepCount(for date: Date) async -> Int {
        stubbedStepCount
    }
}

// MARK: - Stubs

@MainActor
private final class StubGrowthRepository: GrowthRepositoryProtocol {
    func getAll() async throws -> [GrowthRecord] { [] }
    func getById(_ id: UUID) async throws -> GrowthRecord? { nil }
    func getRecordsForBaby(_ babyId: UUID, limit: Int?) async throws -> [GrowthRecord] { [] }
    func getRecordsForDateRange(babyId: UUID, start: Date, end: Date) async throws -> [GrowthRecord] { [] }
    func create(_ record: GrowthRecord) async throws -> GrowthRecord { record }
    func update(_ record: GrowthRecord) async throws -> GrowthRecord { record }
    func delete(_ id: UUID) async throws {}
}

@MainActor
private final class StubDashboardFeedingRepository: FeedingRepositoryProtocol {
    func getAll() async throws -> [Feeding] { [] }
    func getById(_ id: UUID) async throws -> Feeding? { nil }
    func create(_ entity: Feeding) async throws -> Feeding { entity }
    func update(_ entity: Feeding) async throws -> Feeding { entity }
    func delete(_ id: UUID) async throws {}
    func getFeedingsForBaby(_ babyId: UUID, limit: Int?) async throws -> [Feeding] { [] }
    func getFeedingsForDateRange(babyId: UUID, start: Date, end: Date) async throws -> [Feeding] { [] }
    func getInProgressFeeding(babyId: UUID) async throws -> Feeding? { nil }
}

@MainActor
private final class StubDashboardSelfCareRepository: SelfCareRepositoryProtocol {
    func getAll() async throws -> [SelfCareLog] { [] }
    func getById(_ id: UUID) async throws -> SelfCareLog? { nil }
    func create(_ entity: SelfCareLog) async throws -> SelfCareLog { entity }
    func update(_ entity: SelfCareLog) async throws -> SelfCareLog { entity }
    func delete(_ id: UUID) async throws {}
    func getLogsForDate(_ date: Date) async throws -> [SelfCareLog] { [] }
    func getLogsForDateRange(start: Date, end: Date) async throws -> [SelfCareLog] { [] }
    func getLogsByActionType(_ type: SelfCareActionType, limit: Int?) async throws -> [SelfCareLog] { [] }
    func getGridItems() async throws -> [SelfCareGridItem] { [] }
    func saveGridItem(_ item: SelfCareGridItem) async throws {}
    func deleteGridItem(_ id: UUID) async throws {}
    func recordContentShown(contentId: String) async throws {}
    func isContentRecentlyShown(contentId: String, within seconds: TimeInterval) async throws -> Bool { false }
}
