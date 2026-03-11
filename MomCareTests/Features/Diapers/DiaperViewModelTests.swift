import Testing
import Foundation
@testable import MomCare

@Suite("DiaperViewModel Tests")
struct DiaperViewModelTests {

    private let babyId = UUID()

    @MainActor
    private func makeSUT(diapers: [Diaper] = []) -> DiaperViewModel {
        DiaperViewModel(repository: StubDiaperRepository(diapers: diapers))
    }

    @Test("loadDiapers populates array")
    @MainActor
    func loadDiapers() async {
        let sut = makeSUT(diapers: [
            Diaper.fixture(babyId: babyId),
            Diaper.fixture(babyId: babyId)
        ])
        await sut.loadDiapers(babyId: babyId)
        #expect(sut.diapers.count == 2)
    }

    @Test("loadDiapers sets empty array when none exist")
    @MainActor
    func loadDiapersEmpty() async {
        let sut = makeSUT()
        await sut.loadDiapers(babyId: babyId)
        #expect(sut.diapers.isEmpty)
    }

    @Test("logDiaper prepends to array and returns true")
    @MainActor
    func logDiaper() async {
        let sut = makeSUT()
        await sut.loadDiapers(babyId: babyId)
        let diaper = Diaper.fixture(babyId: babyId)
        let success = await sut.logDiaper(diaper)
        #expect(success)
        #expect(sut.diapers.first?.id == diaper.id)
    }

    @Test("logDiaper returns false on error")
    @MainActor
    func logDiaperError() async {
        let repo = StubDiaperRepository(shouldThrowOnCreate: true)
        let sut = DiaperViewModel(repository: repo)
        let diaper = Diaper.fixture(babyId: babyId)
        let success = await sut.logDiaper(diaper)
        #expect(!success)
        #expect(sut.error != nil)
    }

    @Test("deleteDiaper removes from array")
    @MainActor
    func deleteDiaper() async {
        let diaper = Diaper.fixture(babyId: babyId)
        let sut = makeSUT(diapers: [diaper])
        await sut.loadDiapers(babyId: babyId)
        await sut.deleteDiaper(id: diaper.id)
        #expect(sut.diapers.isEmpty)
    }

    @Test("todayCount returns only today's entries")
    @MainActor
    func todayCount() async {
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: .now)!
        let sut = makeSUT(diapers: [
            Diaper.fixture(babyId: babyId, timestamp: .now),
            Diaper.fixture(babyId: babyId, timestamp: .now),
            Diaper.fixture(babyId: babyId, timestamp: yesterday)
        ])
        await sut.loadDiapers(babyId: babyId)
        #expect(sut.todayCount == 2)
    }

    @Test("diapersGroupedByDay groups by calendar day")
    @MainActor
    func diapersGroupedByDay() async {
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: .now)!
        let sut = makeSUT(diapers: [
            Diaper.fixture(babyId: babyId, timestamp: .now),
            Diaper.fixture(babyId: babyId, timestamp: yesterday)
        ])
        await sut.loadDiapers(babyId: babyId)
        #expect(sut.diapersGroupedByDay.count == 2)
        #expect(sut.diapersGroupedByDay[0].entries.count == 1)
    }
}

// MARK: - Stub

private final class StubDiaperRepository: DiaperRepositoryProtocol, @unchecked Sendable {
    private var store: [Diaper]
    private let shouldThrowOnCreate: Bool

    init(diapers: [Diaper] = [], shouldThrowOnCreate: Bool = false) {
        self.store = diapers
        self.shouldThrowOnCreate = shouldThrowOnCreate
    }

    func getAll() async throws -> [Diaper] { store }
    func getById(_ id: UUID) async throws -> Diaper? { store.first { $0.id == id } }

    func create(_ entity: Diaper) async throws -> Diaper {
        if shouldThrowOnCreate { throw RepositoryError.notFound }
        store.append(entity)
        return entity
    }

    func update(_ entity: Diaper) async throws -> Diaper {
        if let index = store.firstIndex(where: { $0.id == entity.id }) {
            store[index] = entity
        }
        return entity
    }

    func delete(_ id: UUID) async throws {
        store.removeAll { $0.id == id }
    }

    func getDiapersForBaby(_ babyId: UUID, limit: Int?) async throws -> [Diaper] {
        let filtered = store.filter { $0.babyId == babyId }
        if let limit { return Array(filtered.prefix(limit)) }
        return filtered
    }

    func getDiapersForDateRange(babyId: UUID, start: Date, end: Date) async throws -> [Diaper] {
        store.filter { $0.babyId == babyId && $0.timestamp >= start && $0.timestamp < end }
    }
}
