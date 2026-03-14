import Testing
import Foundation
@testable import MomCare

@Suite("GrowthViewModel")
struct GrowthViewModelTests {

    private let babyId = UUID()
    private let dob = Calendar.current.date(byAdding: .month, value: -3, to: .now)!

    @MainActor
    private func makeSUT(records: [GrowthRecord] = []) -> GrowthViewModel {
        let repo = StubGrowthRepository(records: records)
        return GrowthViewModel(repository: repo, chartService: GrowthChartService())
    }

    @Test("Initial state has no records")
    @MainActor
    func initialState() {
        let sut = makeSUT()
        #expect(sut.records.isEmpty)
        #expect(!sut.isLoading)
        #expect(sut.selectedMeasurement == .weight)
    }

    @Test("Load records for baby")
    @MainActor
    func loadRecords() async {
        let records = [
            GrowthRecord.fixture(babyId: babyId, weightGrams: 5200),
            GrowthRecord.fixture(babyId: babyId, weightGrams: 4500),
        ]
        let sut = makeSUT(records: records)
        await sut.loadRecords(babyId: babyId)
        #expect(sut.records.count == 2)
    }

    @Test("Add measurement creates record")
    @MainActor
    func addMeasurement() async {
        let sut = makeSUT()
        await sut.addMeasurement(
            babyId: babyId,
            date: .now,
            weightGrams: 5200,
            lengthCm: 58.5,
            headCircumferenceCm: 38.2,
            notes: nil
        )
        #expect(sut.records.count == 1)
        #expect(sut.records.first?.weightGrams == 5200)
    }

    @Test("Delete measurement removes record")
    @MainActor
    func deleteMeasurement() async {
        let record = GrowthRecord.fixture(babyId: babyId, weightGrams: 5200)
        let sut = makeSUT(records: [record])
        await sut.loadRecords(babyId: babyId)
        #expect(sut.records.count == 1)
        await sut.deleteRecord(id: record.id, babyId: babyId)
        #expect(sut.records.isEmpty)
    }

    @Test("Switch measurement type")
    @MainActor
    func switchMeasurement() {
        let sut = makeSUT()
        sut.selectedMeasurement = .length
        #expect(sut.selectedMeasurement == .length)
    }

    @Test("Update chart data after loading")
    @MainActor
    func updateChartData() async {
        let records = [
            GrowthRecord.fixture(babyId: babyId, date: .now, weightGrams: 5200),
        ]
        let sut = makeSUT(records: records)
        await sut.loadRecords(babyId: babyId)
        sut.updateChartData(sex: .male, dateOfBirth: dob)
        #expect(sut.chartData != nil)
        #expect(sut.chartData?.babyPoints.count == 1)
    }

    @Test("Latest percentile computed correctly")
    @MainActor
    func latestPercentile() async {
        let records = [
            GrowthRecord.fixture(babyId: babyId, date: .now, weightGrams: 5200),
        ]
        let sut = makeSUT(records: records)
        await sut.loadRecords(babyId: babyId)
        sut.updateChartData(sex: .male, dateOfBirth: dob)
        #expect(sut.latestPercentile != nil)
    }
}

// MARK: - Stub

@MainActor
private final class StubGrowthRepository: GrowthRepositoryProtocol {
    private var store: [GrowthRecord]

    init(records: [GrowthRecord] = []) {
        self.store = records
    }

    func getAll() async throws -> [GrowthRecord] { store.filter { !$0.isDeleted } }
    func getById(_ id: UUID) async throws -> GrowthRecord? { store.first { $0.id == id } }

    func create(_ entity: GrowthRecord) async throws -> GrowthRecord {
        store.append(entity)
        return entity
    }

    func update(_ entity: GrowthRecord) async throws -> GrowthRecord {
        if let index = store.firstIndex(where: { $0.id == entity.id }) {
            store[index] = entity
        }
        return entity
    }

    func delete(_ id: UUID) async throws {
        store.removeAll { $0.id == id }
    }

    func getRecordsForBaby(_ babyId: UUID, limit: Int?) async throws -> [GrowthRecord] {
        let filtered = store.filter { $0.babyId == babyId && !$0.isDeleted }
        if let limit { return Array(filtered.prefix(limit)) }
        return filtered
    }

    func getRecordsForDateRange(babyId: UUID, start: Date, end: Date) async throws -> [GrowthRecord] {
        store.filter { $0.babyId == babyId && !$0.isDeleted && $0.date >= start && $0.date < end }
    }
}
