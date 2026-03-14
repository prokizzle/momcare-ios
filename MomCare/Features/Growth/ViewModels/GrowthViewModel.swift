import Foundation

@Observable
@MainActor
final class GrowthViewModel {
    private let repository: any GrowthRepositoryProtocol
    private let chartService: GrowthChartService

    private(set) var records: [GrowthRecord] = []
    var selectedMeasurement: GrowthChartService.MeasurementType = .weight
    var chartData: GrowthChartService.GrowthChartData?
    var latestPercentile: Double?
    var isLoading = false
    var error: Error?
    var showAddSheet = false

    init(
        repository: any GrowthRepositoryProtocol,
        chartService: GrowthChartService = GrowthChartService()
    ) {
        self.repository = repository
        self.chartService = chartService
    }

    func loadRecords(babyId: UUID) async {
        isLoading = true
        defer { isLoading = false }
        do {
            records = try await repository.getRecordsForBaby(babyId, limit: nil)
        } catch {
            self.error = error
        }
    }

    // swiftlint:disable:next function_parameter_count
    func addMeasurement(
        babyId: UUID,
        date: Date,
        weightGrams: Double?,
        lengthCm: Double?,
        headCircumferenceCm: Double?,
        notes: String?
    ) async {
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
        } catch {
            self.error = error
        }
    }

    func deleteRecord(id: UUID, babyId: UUID) async {
        do {
            try await repository.delete(id)
            records.removeAll { $0.id == id }
        } catch {
            self.error = error
        }
    }

    func updateChartData(sex: Baby.BiologicalSex?, dateOfBirth: Date) {
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
