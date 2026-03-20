import Foundation

@Observable
@MainActor
final class GrowthViewModel {
    private let repository: any GrowthRepositoryProtocol
    private let chartService: GrowthChartService
    private let healthKit: (any HealthKitServiceProtocol)?

    private(set) var records: [GrowthRecord] = []
    var selectedMeasurement: GrowthChartService.MeasurementType = .weight
    var chartData: GrowthChartService.GrowthChartData?
    var latestPercentile: Double?
    var isLoading = false
    var error: Error?
    var showAddSheet = false

    init(
        repository: any GrowthRepositoryProtocol,
        chartService: GrowthChartService = GrowthChartService(),
        healthKit: (any HealthKitServiceProtocol)? = nil
    ) {
        self.repository = repository
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
