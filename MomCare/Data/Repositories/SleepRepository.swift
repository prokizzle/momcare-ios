import Foundation
import SwiftData

// MARK: - Implementation

@MainActor
final class SleepRepository: SleepRepositoryProtocol {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func getAll() async throws -> [BabySleep] {
        let descriptor = FetchDescriptor<BabySleepModel>(
            predicate: #Predicate<BabySleepModel> { $0.isSoftDeleted == false },
            sortBy: [SortDescriptor(\.startTime, order: .reverse)]
        )
        return try modelContext.fetch(descriptor).map { $0.toEntity() }
    }

    func getById(_ id: UUID) async throws -> BabySleep? {
        let fetchId = id
        let descriptor = FetchDescriptor<BabySleepModel>(
            predicate: #Predicate<BabySleepModel> { $0.id == fetchId }
        )
        return try modelContext.fetch(descriptor).first?.toEntity()
    }

    func create(_ entity: BabySleep) async throws -> BabySleep {
        let model = BabySleepModel(from: entity)
        modelContext.insert(model)
        try modelContext.save()
        return model.toEntity()
    }

    func update(_ entity: BabySleep) async throws -> BabySleep {
        let entityId = entity.id
        let descriptor = FetchDescriptor<BabySleepModel>(
            predicate: #Predicate<BabySleepModel> { $0.id == entityId }
        )
        guard let model = try modelContext.fetch(descriptor).first else {
            throw RepositoryError.notFound
        }
        model.update(from: entity)
        try modelContext.save()
        return model.toEntity()
    }

    func delete(_ id: UUID) async throws {
        let deleteId = id
        let descriptor = FetchDescriptor<BabySleepModel>(
            predicate: #Predicate<BabySleepModel> { $0.id == deleteId }
        )
        guard let model = try modelContext.fetch(descriptor).first else {
            throw RepositoryError.notFound
        }
        model.isSoftDeleted = true
        model.updatedAt = .now
        try modelContext.save()
    }

    func getSleepsForBaby(_ babyId: UUID, limit: Int?) async throws -> [BabySleep] {
        let fetchBabyId = babyId
        var descriptor = FetchDescriptor<BabySleepModel>(
            predicate: #Predicate<BabySleepModel> {
                $0.babyId == fetchBabyId && $0.isSoftDeleted == false
            },
            sortBy: [SortDescriptor(\.startTime, order: .reverse)]
        )
        if let limit {
            descriptor.fetchLimit = limit
        }
        return try modelContext.fetch(descriptor).map { $0.toEntity() }
    }

    func getSleepsForDateRange(babyId: UUID, start: Date, end: Date) async throws -> [BabySleep] {
        let fetchBabyId = babyId
        let rangeStart = start
        let rangeEnd = end
        let descriptor = FetchDescriptor<BabySleepModel>(
            predicate: #Predicate<BabySleepModel> {
                $0.babyId == fetchBabyId &&
                $0.isSoftDeleted == false &&
                $0.startTime >= rangeStart &&
                $0.startTime < rangeEnd
            },
            sortBy: [SortDescriptor(\.startTime, order: .reverse)]
        )
        return try modelContext.fetch(descriptor).map { $0.toEntity() }
    }

    func getInProgressSleep(babyId: UUID) async throws -> BabySleep? {
        let fetchBabyId = babyId
        // #Predicate nil comparison ($0.endTime == nil) doesn't compile under Swift 6;
        // limit fetch to recent sleeps to keep the in-memory scan cheap.
        var descriptor = FetchDescriptor<BabySleepModel>(
            predicate: #Predicate<BabySleepModel> {
                $0.babyId == fetchBabyId &&
                $0.isSoftDeleted == false
            },
            sortBy: [SortDescriptor(\.startTime, order: .reverse)]
        )
        descriptor.fetchLimit = 20
        return try modelContext.fetch(descriptor).first { $0.endTime == nil }?.toEntity()
    }
}
