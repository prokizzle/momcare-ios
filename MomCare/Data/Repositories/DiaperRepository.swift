import Foundation
import SwiftData

// MARK: - Protocol

protocol DiaperRepositoryProtocol: Sendable {
    func getAll() async throws -> [Diaper]
    func getById(_ id: UUID) async throws -> Diaper?
    func create(_ entity: Diaper) async throws -> Diaper
    func update(_ entity: Diaper) async throws -> Diaper
    func delete(_ id: UUID) async throws
    func getDiapersForBaby(_ babyId: UUID, limit: Int?) async throws -> [Diaper]
    func getDiapersForDateRange(babyId: UUID, start: Date, end: Date) async throws -> [Diaper]
}

// MARK: - Implementation

@MainActor
final class DiaperRepository: DiaperRepositoryProtocol {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func getAll() async throws -> [Diaper] {
        let descriptor = FetchDescriptor<DiaperModel>(
            predicate: #Predicate<DiaperModel> { $0.isSoftDeleted == false },
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )
        return try modelContext.fetch(descriptor).map { $0.toEntity() }
    }

    func getById(_ id: UUID) async throws -> Diaper? {
        let fetchId = id
        let descriptor = FetchDescriptor<DiaperModel>(
            predicate: #Predicate<DiaperModel> { $0.id == fetchId }
        )
        return try modelContext.fetch(descriptor).first?.toEntity()
    }

    func create(_ entity: Diaper) async throws -> Diaper {
        let model = DiaperModel(from: entity)
        modelContext.insert(model)
        try modelContext.save()
        return model.toEntity()
    }

    func update(_ entity: Diaper) async throws -> Diaper {
        let entityId = entity.id
        let descriptor = FetchDescriptor<DiaperModel>(
            predicate: #Predicate<DiaperModel> { $0.id == entityId }
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
        let descriptor = FetchDescriptor<DiaperModel>(
            predicate: #Predicate<DiaperModel> { $0.id == deleteId }
        )
        guard let model = try modelContext.fetch(descriptor).first else {
            throw RepositoryError.notFound
        }
        model.isSoftDeleted = true
        model.updatedAt = .now
        try modelContext.save()
    }

    func getDiapersForBaby(_ babyId: UUID, limit: Int?) async throws -> [Diaper] {
        let fetchBabyId = babyId
        var descriptor = FetchDescriptor<DiaperModel>(
            predicate: #Predicate<DiaperModel> {
                $0.babyId == fetchBabyId && $0.isSoftDeleted == false
            },
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )
        if let limit {
            descriptor.fetchLimit = limit
        }
        return try modelContext.fetch(descriptor).map { $0.toEntity() }
    }

    func getDiapersForDateRange(babyId: UUID, start: Date, end: Date) async throws -> [Diaper] {
        let fetchBabyId = babyId
        let rangeStart = start
        let rangeEnd = end
        let descriptor = FetchDescriptor<DiaperModel>(
            predicate: #Predicate<DiaperModel> {
                $0.babyId == fetchBabyId &&
                $0.isSoftDeleted == false &&
                $0.timestamp >= rangeStart &&
                $0.timestamp < rangeEnd
            },
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )
        return try modelContext.fetch(descriptor).map { $0.toEntity() }
    }
}
