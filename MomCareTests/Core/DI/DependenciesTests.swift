import Testing
import SwiftUI
import SwiftData
@testable import MomCare

@Suite("Dependencies Tests")
struct DependenciesTests {
    @Test("DependencyContainer requires makeBabyRepository")
    @MainActor
    func babyRepositoryFactory() throws {
        let container = TestDependencies()
        let repo = container.makeBabyRepository()
        #expect(repo is MockBabyRepository)
    }

    @Test("AppDependencies creates real BabyRepository")
    @MainActor
    func appDependenciesCreatesBabyRepo() throws {
        let deps = try TestModelContainerFactory.makeDependencies()
        let repo = deps.makeBabyRepository()
        #expect(repo is BabyRepository)
    }

    @Test("AppDependencies creates real FeedingRepository")
    @MainActor
    func appDependenciesCreatesFeedingRepo() throws {
        let deps = try TestModelContainerFactory.makeDependencies()
        let repo = deps.makeFeedingRepository()
        #expect(repo is FeedingRepository)
    }

    @Test("AppDependencies creates real SelfCareRepository")
    @MainActor
    func appDependenciesCreatesSelfCareRepo() throws {
        let deps = try TestModelContainerFactory.makeDependencies()
        let repo = deps.makeSelfCareRepository()
        #expect(repo is SelfCareRepository)
    }

    @Test("AppDependencies creates real DiaperRepository")
    @MainActor
    func appDependenciesCreatesDiaperRepo() throws {
        let deps = try TestModelContainerFactory.makeDependencies()
        let repo = deps.makeDiaperRepository()
        #expect(repo is DiaperRepository)
    }

    @Test("AppDependencies creates real SleepRepository")
    @MainActor
    func appDependenciesCreatesSleepRepo() throws {
        let deps = try TestModelContainerFactory.makeDependencies()
        let repo = deps.makeSleepRepository()
        #expect(repo is SleepRepository)
    }

    @Test("AppDependencies creates real GrowthRepository")
    @MainActor
    func appDependenciesCreatesGrowthRepo() throws {
        let deps = try TestModelContainerFactory.makeDependencies()
        let repo = deps.makeGrowthRepository()
        #expect(repo is GrowthRepository)
    }

    @Test("AppDependencies creates real HealthEventRepository")
    @MainActor
    func appDependenciesCreatesHealthEventRepo() throws {
        let deps = try TestModelContainerFactory.makeDependencies()
        let repo = deps.makeHealthEventRepository()
        #expect(repo is HealthEventRepository)
    }

    @Test("Environment key has default value")
    @MainActor
    func environmentKey() {
        let defaultValue = DependenciesKey.defaultValue
        #expect(defaultValue is AppDependencies)
    }
}

@MainActor
private final class MockBabyRepository: BabyRepositoryProtocol {
    func getAll() async throws -> [Baby] { [] }
    func getById(_ id: UUID) async throws -> Baby? { nil }
    func create(_ entity: Baby) async throws -> Baby { entity }
    func update(_ entity: Baby) async throws -> Baby { entity }
    func delete(_ id: UUID) async throws {}
    func getActiveBabies() async throws -> [Baby] { [] }
}

@MainActor
private final class MockFeedingRepository: FeedingRepositoryProtocol {
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
private final class MockSelfCareRepository: SelfCareRepositoryProtocol {
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

@MainActor
private final class MockDiaperRepository: DiaperRepositoryProtocol {
    func getAll() async throws -> [Diaper] { [] }
    func getById(_ id: UUID) async throws -> Diaper? { nil }
    func create(_ entity: Diaper) async throws -> Diaper { entity }
    func update(_ entity: Diaper) async throws -> Diaper { entity }
    func delete(_ id: UUID) async throws {}
    func getDiapersForBaby(_ babyId: UUID, limit: Int?) async throws -> [Diaper] { [] }
    func getDiapersForDateRange(babyId: UUID, start: Date, end: Date) async throws -> [Diaper] { [] }
}

@MainActor
private final class MockSleepRepository: SleepRepositoryProtocol {
    func getAll() async throws -> [BabySleep] { [] }
    func getById(_ id: UUID) async throws -> BabySleep? { nil }
    func create(_ entity: BabySleep) async throws -> BabySleep { entity }
    func update(_ entity: BabySleep) async throws -> BabySleep { entity }
    func delete(_ id: UUID) async throws {}
    func getSleepsForBaby(_ babyId: UUID, limit: Int?) async throws -> [BabySleep] { [] }
    func getSleepsForDateRange(babyId: UUID, start: Date, end: Date) async throws -> [BabySleep] { [] }
    func getInProgressSleep(babyId: UUID) async throws -> BabySleep? { nil }
}

@MainActor
private final class MockGrowthRepository: GrowthRepositoryProtocol {
    func getAll() async throws -> [GrowthRecord] { [] }
    func getById(_ id: UUID) async throws -> GrowthRecord? { nil }
    func create(_ entity: GrowthRecord) async throws -> GrowthRecord { entity }
    func update(_ entity: GrowthRecord) async throws -> GrowthRecord { entity }
    func delete(_ id: UUID) async throws {}
    func getRecordsForBaby(_ babyId: UUID, limit: Int?) async throws -> [GrowthRecord] { [] }
    func getRecordsForDateRange(babyId: UUID, start: Date, end: Date) async throws -> [GrowthRecord] { [] }
}

@MainActor
private final class MockHealthEventRepository: HealthEventRepositoryProtocol {
    func getAll() async throws -> [HealthEvent] { [] }
    func getById(_ id: UUID) async throws -> HealthEvent? { nil }
    func create(_ entity: HealthEvent) async throws -> HealthEvent { entity }
    func update(_ entity: HealthEvent) async throws -> HealthEvent { entity }
    func delete(_ id: UUID) async throws {}
    func getEventsForBaby(_ babyId: UUID, limit: Int?) async throws -> [HealthEvent] { [] }
    func getEventsForBabyByType(
        _ babyId: UUID,
        type: HealthEvent.EventType
    ) async throws -> [HealthEvent] { [] }
    func createWithPhotos(_ entity: HealthEvent, photos: [Data]) async throws -> HealthEvent { entity }
    func getPhotos(for eventId: UUID) async throws -> [Data] { [] }
    func updatePhotos(for eventId: UUID, photos: [Data]) async throws {}
}

@MainActor
private final class TestDependencies: DependencyContainer {
    func makeBabyRepository() -> any BabyRepositoryProtocol {
        MockBabyRepository()
    }

    func makeFeedingRepository() -> any FeedingRepositoryProtocol {
        MockFeedingRepository()
    }

    func makeSelfCareRepository() -> any SelfCareRepositoryProtocol {
        MockSelfCareRepository()
    }

    func makeDiaperRepository() -> any DiaperRepositoryProtocol {
        MockDiaperRepository()
    }

    func makeSleepRepository() -> any SleepRepositoryProtocol {
        MockSleepRepository()
    }

    func makeGrowthRepository() -> any GrowthRepositoryProtocol {
        MockGrowthRepository()
    }

    func makeHealthEventRepository() -> any HealthEventRepositoryProtocol {
        MockHealthEventRepository()
    }
}
