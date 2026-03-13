import Testing
import Foundation
@testable import MomCare

@Suite("BabyActivityEngine Tests")
struct BabyActivityEngineTests {

    private let babyId = UUID()

    @MainActor
    private func makeSUT(inProgressSleep: BabySleep? = nil) -> BabyActivityEngine {
        BabyActivityEngine(
            sleepRepository: StubSleepRepository(inProgress: inProgressSleep),
            feedingRepository: StubBabyFeedingRepository(),
            diaperRepository: StubBabyDiaperRepository()
        )
    }

    @Test("Initial state: no active nap or feeding")
    @MainActor
    func initialState() {
        let sut = makeSUT()
        #expect(!sut.isNapActive)
        #expect(!sut.isFeedingActive)
        #expect(!sut.showDiaperOptions)
    }

    @Test("startNap sets isNapActive")
    @MainActor
    func startNap() async {
        let sut = makeSUT()
        await sut.startNap(babyId: babyId)
        #expect(sut.isNapActive)
        #expect(sut.napStartTime != nil)
    }

    @Test("endNap clears active nap")
    @MainActor
    func endNap() async {
        let sut = makeSUT()
        await sut.startNap(babyId: babyId)
        await sut.endNap(babyId: babyId)
        #expect(!sut.isNapActive)
        #expect(sut.napStartTime == nil)
    }

    @Test("startNap while active is idempotent")
    @MainActor
    func startNapIdempotent() async {
        let sut = makeSUT()
        await sut.startNap(babyId: babyId)
        let firstStart = sut.napStartTime
        await sut.startNap(babyId: babyId)
        #expect(sut.napStartTime == firstStart)
    }

    @Test("startFeeding sets isFeedingActive with correct method")
    @MainActor
    func startFeeding() async {
        let sut = makeSUT()
        await sut.startFeeding(babyId: babyId, method: .left)
        #expect(sut.isFeedingActive)
        #expect(sut.feedMethod == .left)
    }

    @Test("endFeeding clears active feeding")
    @MainActor
    func endFeeding() async {
        let sut = makeSUT()
        await sut.startFeeding(babyId: babyId, method: .bottle)
        await sut.endFeeding(babyId: babyId)
        #expect(!sut.isFeedingActive)
        #expect(sut.feedMethod == nil)
    }

    @Test("logDiaper shows options")
    @MainActor
    func logDiaper() {
        let sut = makeSUT()
        sut.logDiaper(babyId: babyId)
        #expect(sut.showDiaperOptions)
    }

    @Test("selectDiaperType hides options")
    @MainActor
    func selectDiaperType() async {
        let sut = makeSUT()
        sut.logDiaper(babyId: babyId)
        await sut.selectDiaperType(.wet, babyId: babyId)
        #expect(!sut.showDiaperOptions)
    }

    @Test("napElapsedFormatted shows mm:ss for short durations")
    @MainActor
    func napElapsedFormat() async {
        let sut = makeSUT()
        await sut.startNap(babyId: babyId)
        #expect(sut.napElapsedFormatted.contains(":"))
    }

    @Test("loadInProgress detects in-progress nap")
    @MainActor
    func loadInProgressNap() async {
        let past = Date.now.addingTimeInterval(-300)
        let sleep = BabySleep.fixture(
            babyId: babyId,
            startTime: past,
            endTime: nil
        )
        let sut = makeSUT(inProgressSleep: sleep)
        await sut.loadInProgress(babyId: babyId)
        #expect(sut.isNapActive)
        #expect(sut.napElapsed >= 300)
    }
}

// MARK: - Stubs

@MainActor
private final class StubBabyFeedingRepository: FeedingRepositoryProtocol {
    private var store: [Feeding] = []
    private var inProgressOverride: Feeding?

    func getAll() async throws -> [Feeding] { store }
    func getById(_ id: UUID) async throws -> Feeding? { store.first { $0.id == id } }
    func create(_ entity: Feeding) async throws -> Feeding { store.append(entity); return entity }
    func update(_ entity: Feeding) async throws -> Feeding {
        if let index = store.firstIndex(where: { $0.id == entity.id }) { store[index] = entity }
        return entity
    }
    func delete(_ id: UUID) async throws { store.removeAll { $0.id == id } }
    func getFeedingsForBaby(_ babyId: UUID, limit: Int?) async throws -> [Feeding] { store }
    func getFeedingsForDateRange(babyId: UUID, start: Date, end: Date) async throws -> [Feeding] { store }
    func getInProgressFeeding(babyId: UUID) async throws -> Feeding? {
        inProgressOverride ?? store.first { $0.babyId == babyId && $0.isInProgress }
    }
}

@MainActor
private final class StubBabyDiaperRepository: DiaperRepositoryProtocol {
    private var store: [Diaper] = []

    func getAll() async throws -> [Diaper] { store }
    func getById(_ id: UUID) async throws -> Diaper? { store.first { $0.id == id } }
    func create(_ entity: Diaper) async throws -> Diaper { store.append(entity); return entity }
    func update(_ entity: Diaper) async throws -> Diaper {
        if let index = store.firstIndex(where: { $0.id == entity.id }) { store[index] = entity }
        return entity
    }
    func delete(_ id: UUID) async throws { store.removeAll { $0.id == id } }
    func getDiapersForBaby(_ babyId: UUID, limit: Int?) async throws -> [Diaper] { store }
    func getDiapersForDateRange(babyId: UUID, start: Date, end: Date) async throws -> [Diaper] { store }
}
