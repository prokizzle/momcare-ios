import Foundation
import SwiftData

@MainActor
final class HealthEventRepository: HealthEventRepositoryProtocol {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func getAll() async throws -> [HealthEvent] {
        let descriptor = FetchDescriptor<HealthEventModel>(
            predicate: #Predicate<HealthEventModel> { $0.isSoftDeleted == false },
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        return try modelContext.fetch(descriptor).map { $0.toEntity() }
    }

    func getById(_ id: UUID) async throws -> HealthEvent? {
        let fetchId = id
        let descriptor = FetchDescriptor<HealthEventModel>(
            predicate: #Predicate<HealthEventModel> { $0.id == fetchId }
        )
        return try modelContext.fetch(descriptor).first?.toEntity()
    }

    func create(_ entity: HealthEvent) async throws -> HealthEvent {
        let model = HealthEventModel(from: entity)
        modelContext.insert(model)
        try modelContext.save()
        return model.toEntity()
    }

    func update(_ entity: HealthEvent) async throws -> HealthEvent {
        let entityId = entity.id
        let descriptor = FetchDescriptor<HealthEventModel>(
            predicate: #Predicate<HealthEventModel> { $0.id == entityId }
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
        let descriptor = FetchDescriptor<HealthEventModel>(
            predicate: #Predicate<HealthEventModel> { $0.id == deleteId }
        )
        guard let model = try modelContext.fetch(descriptor).first else {
            throw RepositoryError.notFound
        }
        model.isSoftDeleted = true
        model.updatedAt = .now
        try modelContext.save()
    }

    func getEventsForBaby(_ babyId: UUID, limit: Int?) async throws -> [HealthEvent] {
        let fetchBabyId = babyId
        var descriptor = FetchDescriptor<HealthEventModel>(
            predicate: #Predicate<HealthEventModel> {
                $0.babyId == fetchBabyId && $0.isSoftDeleted == false
            },
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        if let limit {
            descriptor.fetchLimit = limit
        }
        return try modelContext.fetch(descriptor).map { $0.toEntity() }
    }

    func getEventsForBabyByType(
        _ babyId: UUID,
        type: HealthEvent.EventType
    ) async throws -> [HealthEvent] {
        let fetchBabyId = babyId
        let fetchTypeRaw = type.rawValue
        let descriptor = FetchDescriptor<HealthEventModel>(
            predicate: #Predicate<HealthEventModel> {
                $0.babyId == fetchBabyId &&
                $0.isSoftDeleted == false &&
                $0.eventTypeRaw == fetchTypeRaw
            },
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        return try modelContext.fetch(descriptor).map { $0.toEntity() }
    }

    // MARK: - Photo Methods

    func createWithPhotos(_ entity: HealthEvent, photos: [Data]) async throws -> HealthEvent {
        let model = HealthEventModel(from: entity)
        model.photoData = photos
        modelContext.insert(model)
        try modelContext.save()
        return model.toEntity()
    }

    func getPhotos(for eventId: UUID) async throws -> [Data] {
        let fetchId = eventId
        let descriptor = FetchDescriptor<HealthEventModel>(
            predicate: #Predicate<HealthEventModel> { $0.id == fetchId }
        )
        guard let model = try modelContext.fetch(descriptor).first else {
            throw RepositoryError.notFound
        }
        return model.photoData
    }

    func updatePhotos(for eventId: UUID, photos: [Data]) async throws {
        let fetchId = eventId
        let descriptor = FetchDescriptor<HealthEventModel>(
            predicate: #Predicate<HealthEventModel> { $0.id == fetchId }
        )
        guard let model = try modelContext.fetch(descriptor).first else {
            throw RepositoryError.notFound
        }
        model.photoData = photos
        model.updatedAt = .now
        try modelContext.save()
    }
}
