import Testing
import Foundation
@testable import MomCare

@Suite("HealthKitService")
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

    @Test("GrowthViewModel.addMeasurement succeeds and fires HealthKit write")
    func growthViewModelHealthKitWrite() async {
        let repo = StubGrowthRepository()
        let viewModel = await GrowthViewModel(
            repository: repo,
            healthKit: StubHealthKitService()
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
    }

    @Test("GrowthViewModel.addMeasurement succeeds without HealthKit service")
    func growthViewModelWithoutHealthKit() async {
        let viewModel = await GrowthViewModel(repository: StubGrowthRepository())
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
}

// MARK: - Test Double

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
