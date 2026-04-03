import Foundation

@Observable
@MainActor
final class GrowthViewModel {
    private let repository: any GrowthRepositoryProtocol
    private let feedingRepository: (any FeedingRepositoryProtocol)?
    private let chartService: GrowthChartService
    private let healthKit: (any HealthKitServiceProtocol)?

    private(set) var records: [GrowthRecord] = []
    private(set) var feedings: [Feeding] = []
    var selectedMeasurement: GrowthChartService.MeasurementType = .weight
    var chartData: GrowthChartService.GrowthChartData?
    var latestPercentile: Double?
    var isLoading = false
    var error: Error?
    var showAddSheet = false

    init(
        repository: any GrowthRepositoryProtocol,
        feedingRepository: (any FeedingRepositoryProtocol)? = nil,
        chartService: GrowthChartService = GrowthChartService(),
        healthKit: (any HealthKitServiceProtocol)? = nil
    ) {
        self.repository = repository
        self.feedingRepository = feedingRepository
        self.chartService = chartService
        self.healthKit = healthKit
    }

    func loadRecords(babyId: UUID) async {
        error = nil
        isLoading = true
        defer { isLoading = false }
        do {
            records = try await repository.getRecordsForBaby(babyId, limit: nil)
        } catch {
            self.error = error
            return
        }
        if let feedingRepository {
            do {
                feedings = try await feedingRepository.getFeedingsForBaby(babyId, limit: nil)
            } catch {
                // Feeding data is supplementary — keep feedings empty rather than
                // masking the successfully loaded records with a feeding error.
                feedings = []
            }
        }
    }

    @discardableResult
    // swiftlint:disable:next function_parameter_count
    func addMeasurement(
        babyId: UUID,
        date: Date,
        weightGrams: Double?,
        lengthCm: Double?,
        headCircumferenceCm: Double?,
        notes: String?
    ) async -> Bool {
        error = nil
        let record = GrowthRecord(
            id: UUID(),
            babyId: babyId,
            date: date,
            weightGrams: weightGrams,
            lengthCm: lengthCm,
            headCircumferenceCm: headCircumferenceCm,
            notes: notes,
            isDeleted: false,
            createdAt: .now,
            updatedAt: .now
        )
        do {
            let created = try await repository.create(record)
            records.insert(created, at: 0)
            records.sort { $0.date > $1.date }
            if let healthKit {
                Task {
                    await healthKit.writeBabyMeasurement(
                        weightGrams: weightGrams,
                        heightCm: lengthCm,
                        headCircumferenceCm: headCircumferenceCm,
                        date: date
                    )
                }
            }
            return true
        } catch {
            self.error = error
            return false
        }
    }

    func deleteRecord(id: UUID, babyId: UUID) async {
        error = nil
        do {
            try await repository.delete(id)
            records.removeAll { $0.id == id }
        } catch {
            self.error = error
        }
    }

    func updateChartData(sex: Baby.BiologicalSex?, dateOfBirth: Date) {
        error = nil
        do {
            let data = try chartService.chartData(
                records: records,
                sex: sex,
                measurement: selectedMeasurement,
                dateOfBirth: dateOfBirth
            )
            chartData = data
            latestPercentile = data.babyPoints.last?.percentile
        } catch {
            self.error = error
            chartData = nil
            latestPercentile = nil
        }
    }
}

#if DEBUG
// MARK: - Preview Support

private final class PreviewGrowthRepository: GrowthRepositoryProtocol {
    private let preloadedRecords: [GrowthRecord]

    init(records: [GrowthRecord]) {
        self.preloadedRecords = records
    }

    func getAll() async throws -> [GrowthRecord] { preloadedRecords }
    func getById(_ id: UUID) async throws -> GrowthRecord? { nil }
    func create(_ entity: GrowthRecord) async throws -> GrowthRecord { entity }
    func update(_ entity: GrowthRecord) async throws -> GrowthRecord { entity }
    func delete(_ id: UUID) async throws {}
    func getRecordsForBaby(_ babyId: UUID, limit: Int?) async throws -> [GrowthRecord] { preloadedRecords }
    func getRecordsForDateRange(babyId: UUID, start: Date, end: Date) async throws -> [GrowthRecord] {
        preloadedRecords.filter { $0.date >= start && $0.date <= end }
    }
}

extension GrowthViewModel {
    @MainActor
    static func preview(records: [GrowthRecord] = []) -> GrowthViewModel {
        GrowthViewModel(
            repository: PreviewGrowthRepository(records: records),
            feedingRepository: nil
        )
    }
}
#endif
