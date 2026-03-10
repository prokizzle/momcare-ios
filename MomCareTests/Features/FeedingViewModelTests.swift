import Testing
import Foundation
@testable import MomCare

@Suite("FeedingViewModel Tests")
struct FeedingViewModelTests {

    private let testBabyId = UUID()

    @MainActor
    private func makeSUT(
        feedings: [Feeding] = [],
        inProgress: Feeding? = nil
    ) -> FeedingViewModel {
        let repo = StubFeedingRepository(feedings: feedings, inProgress: inProgress)
        return FeedingViewModel(repository: repo)
    }

    @Test("loadFeedings populates array and checks in-progress")
    @MainActor
    func loadFeedings() async {
        let sut = makeSUT(feedings: [
            Feeding.fixture(babyId: testBabyId),
            Feeding.fixture(babyId: testBabyId)
        ])
        await sut.loadFeedings(babyId: testBabyId)
        #expect(sut.feedings.count == 2)
    }

    @Test("loadFeedings detects in-progress feeding")
    @MainActor
    func loadFeedingsInProgress() async {
        let inProgress = Feeding.fixture(babyId: testBabyId, endTime: nil)
        let sut = makeSUT(inProgress: inProgress)
        await sut.loadFeedings(babyId: testBabyId)
        #expect(sut.inProgressFeeding != nil)
        #expect(sut.isTimerRunning == true)
    }

    @Test("startFeeding creates in-progress entry")
    @MainActor
    func startFeeding() async {
        let sut = makeSUT()
        await sut.startFeeding(babyId: testBabyId, type: .breast)
        #expect(sut.inProgressFeeding != nil)
        #expect(sut.inProgressFeeding?.feedingType == .breast)
        #expect(sut.isTimerRunning == true)
    }

    @Test("endFeeding sets endTime and stops timer")
    @MainActor
    func endFeeding() async {
        let inProgress = Feeding.fixture(babyId: testBabyId, endTime: nil)
        let sut = makeSUT(inProgress: inProgress)
        await sut.loadFeedings(babyId: testBabyId)
        await sut.endFeeding()
        #expect(sut.inProgressFeeding == nil)
        #expect(sut.isTimerRunning == false)
    }

    @Test("toggleBreastSide alternates sides")
    @MainActor
    func toggleBreastSide() {
        let sut = makeSUT()
        #expect(sut.selectedSide == .left)
        sut.toggleBreastSide()
        #expect(sut.selectedSide == .right)
        sut.toggleBreastSide()
        #expect(sut.selectedSide == .left)
    }

    @Test("deleteFeeding removes from list")
    @MainActor
    func deleteFeeding() async {
        let feeding = Feeding.fixture(babyId: testBabyId)
        let sut = makeSUT(feedings: [feeding])
        await sut.loadFeedings(babyId: testBabyId)
        await sut.deleteFeeding(feeding.id)
        #expect(sut.feedings.isEmpty)
    }

    @Test("analyzePattern computes pattern from feedings")
    @MainActor
    func analyzePattern() async {
        let now = Date.now
        let feedings = (0..<10).map { index in
            Feeding.fixture(
                babyId: testBabyId,
                startTime: now.addingTimeInterval(Double(-index) * 7200),
                endTime: now.addingTimeInterval(Double(-index) * 7200 + 1200)
            )
        }
        let sut = makeSUT(feedings: feedings)
        await sut.loadFeedings(babyId: testBabyId)
        await sut.analyzePattern(babyId: testBabyId)
        #expect(sut.pattern != nil)
        #expect(sut.pattern?.isInsufficient == false)
    }
}

@MainActor
private final class StubFeedingRepository: FeedingRepositoryProtocol {
    private var store: [Feeding]
    private var inProgressOverride: Feeding?

    init(feedings: [Feeding] = [], inProgress: Feeding? = nil) {
        self.store = feedings
        self.inProgressOverride = inProgress
    }

    func getAll() async throws -> [Feeding] { store }
    func getById(_ id: UUID) async throws -> Feeding? { store.first { $0.id == id } }
    func create(_ entity: Feeding) async throws -> Feeding {
        store.append(entity)
        return entity
    }
    func update(_ entity: Feeding) async throws -> Feeding {
        if let index = store.firstIndex(where: { $0.id == entity.id }) {
            store[index] = entity
        }
        return entity
    }
    func delete(_ id: UUID) async throws {
        store.removeAll { $0.id == id }
    }
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
