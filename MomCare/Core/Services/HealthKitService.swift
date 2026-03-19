import Foundation
import HealthKit

// MARK: - Protocol

/// Abstracts HealthKit reads and writes for testability.
/// All methods degrade gracefully when HealthKit is unavailable or unauthorized.
protocol HealthKitServiceProtocol: Sendable {
    var isAvailable: Bool { get }
    func requestAuthorization() async
    func writeBabyMeasurement(
        weightGrams: Double?,
        heightCm: Double?,
        headCircumferenceCm: Double?,
        date: Date
    ) async
    func readStepCount(for date: Date) async -> Int
}

// MARK: - Live Implementation

/// Actor-isolated HealthKit service. `HKHealthStore` is not `Sendable`, so the
/// actor boundary is the only safe way to share it under Swift 6 strict concurrency.
actor HealthKitService: HealthKitServiceProtocol {

    private let store: HKHealthStore

    nonisolated var isAvailable: Bool { HKHealthStore.isHealthDataAvailable() }

    init(store: HKHealthStore = HKHealthStore()) {
        self.store = store
    }

    // MARK: - Authorization

    func requestAuthorization() async {
        guard isAvailable else { return }
        let writeTypes: Set<HKSampleType> = [
            HKQuantityType(.bodyMass),
            HKQuantityType(.height)
        ]
        let readTypes: Set<HKObjectType> = [
            HKQuantityType(.stepCount)
        ]
        _ = try? await store.requestAuthorization(toShare: writeTypes, read: readTypes)
    }

    // MARK: - Write

    func writeBabyMeasurement(
        weightGrams: Double?,
        heightCm: Double?,
        headCircumferenceCm: Double?,
        date: Date
    ) async {
        guard isAvailable else { return }
        var samples: [HKSample] = []

        if let weightGrams {
            let quantity = HKQuantity(unit: .gram(), doubleValue: weightGrams)
            samples.append(HKQuantitySample(
                type: HKQuantityType(.bodyMass),
                quantity: quantity,
                start: date,
                end: date
            ))
        }
        if let heightCm {
            let quantity = HKQuantity(unit: .meterUnit(with: .centi), doubleValue: heightCm)
            samples.append(HKQuantitySample(
                type: HKQuantityType(.height),
                quantity: quantity,
                start: date,
                end: date
            ))
        }
        // headCircumferenceCm is captured for future use when the identifier
        // becomes available in the targeted SDK.
        _ = headCircumferenceCm

        guard !samples.isEmpty else { return }
        _ = try? await store.save(samples)
    }

    // MARK: - Read

    func readStepCount(for date: Date) async -> Int {
        guard isAvailable else { return 0 }
        let type = HKQuantityType(.stepCount)
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: date)
        let end = calendar.date(byAdding: .day, value: 1, to: start) ?? date
        let predicate = HKQuery.predicateForSamples(withStart: start, end: end)

        do {
            let stats: HKStatistics? = try await withCheckedThrowingContinuation { continuation in
                let query = HKStatisticsQuery(
                    quantityType: type,
                    quantitySamplePredicate: predicate,
                    options: .cumulativeSum
                ) { _, result, error in
                    if let error {
                        continuation.resume(throwing: error)
                    } else {
                        continuation.resume(returning: result)
                    }
                }
                store.execute(query)
            }
            return Int(stats?.sumQuantity()?.doubleValue(for: .count()) ?? 0)
        } catch {
            return 0
        }
    }
}

// MARK: - Stub (for tests and previews)

struct StubHealthKitService: HealthKitServiceProtocol {
    var isAvailable: Bool = false
    func requestAuthorization() async {}
    func writeBabyMeasurement(
        weightGrams: Double?,
        heightCm: Double?,
        headCircumferenceCm: Double?,
        date: Date
    ) async {}
    func readStepCount(for date: Date) async -> Int { 0 }
}
