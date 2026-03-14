import Foundation
import SwiftData

@MainActor
final class GrowthRepository: GrowthRepositoryProtocol {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func getAll() async throws -> [GrowthRecord] {
        let descriptor = FetchDescriptor<GrowthRecordModel>(
            predicate: #Predicate<GrowthRecordModel> { $0.isSoftDeleted == false },
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        return try modelContext.fetch(descriptor).map { $0.toEntity() }
    }

    func getById(_ id: UUID) async throws -> GrowthRecord? {
        let fetchId = id
        let descriptor = FetchDescriptor<GrowthRecordModel>(
            predicate: #Predicate<GrowthRecordModel> { $0.id == fetchId }
        )
        return try modelContext.fetch(descriptor).first?.toEntity()
    }

    func create(_ entity: GrowthRecord) async throws -> GrowthRecord {
        let model = GrowthRecordModel(from: entity)
        modelContext.insert(model)
        try modelContext.save()
        return model.toEntity()
    }

    func update(_ entity: GrowthRecord) async throws -> GrowthRecord {
        let entityId = entity.id
        let descriptor = FetchDescriptor<GrowthRecordModel>(
            predicate: #Predicate<GrowthRecordModel> { $0.id == entityId }
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
        let descriptor = FetchDescriptor<GrowthRecordModel>(
            predicate: #Predicate<GrowthRecordModel> { $0.id == deleteId }
        )
        guard let model = try modelContext.fetch(descriptor).first else {
            throw RepositoryError.notFound
        }
        model.isSoftDeleted = true
        model.updatedAt = .now
        try modelContext.save()
    }

    func getRecordsForBaby(_ babyId: UUID, limit: Int?) async throws -> [GrowthRecord] {
        let fetchBabyId = babyId
        var descriptor = FetchDescriptor<GrowthRecordModel>(
            predicate: #Predicate<GrowthRecordModel> {
                $0.babyId == fetchBabyId && $0.isSoftDeleted == false
            },
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        if let limit {
            descriptor.fetchLimit = limit
        }
        return try modelContext.fetch(descriptor).map { $0.toEntity() }
    }

    func getRecordsForDateRange(babyId: UUID, start: Date, end: Date) async throws -> [GrowthRecord] {
        let fetchBabyId = babyId
        let rangeStart = start
        let rangeEnd = end
        let descriptor = FetchDescriptor<GrowthRecordModel>(
            predicate: #Predicate<GrowthRecordModel> {
                $0.babyId == fetchBabyId &&
                $0.isSoftDeleted == false &&
                $0.date >= rangeStart &&
                $0.date < rangeEnd
            },
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        return try modelContext.fetch(descriptor).map { $0.toEntity() }
    }
}
