import Foundation
import SwiftData

@MainActor
final class BabyRepository: BabyRepositoryProtocol {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func getAll() async throws -> [Baby] {
        let descriptor = FetchDescriptor<BabyModel>(
            sortBy: [SortDescriptor(\.createdAt)]
        )
        return try modelContext.fetch(descriptor).map { $0.toEntity() }
    }

    func getById(_ id: UUID) async throws -> Baby? {
        let fetchId = id
        let descriptor = FetchDescriptor<BabyModel>(
            predicate: #Predicate<BabyModel> { $0.id == fetchId }
        )
        return try modelContext.fetch(descriptor).first?.toEntity()
    }

    func create(_ entity: Baby) async throws -> Baby {
        let model = BabyModel(from: entity)
        modelContext.insert(model)
        try modelContext.save()
        return model.toEntity()
    }

    func update(_ entity: Baby) async throws -> Baby {
        let entityId = entity.id
        let descriptor = FetchDescriptor<BabyModel>(
            predicate: #Predicate<BabyModel> { $0.id == entityId }
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
        let descriptor = FetchDescriptor<BabyModel>(
            predicate: #Predicate<BabyModel> { $0.id == deleteId }
        )
        guard let model = try modelContext.fetch(descriptor).first else {
            throw RepositoryError.notFound
        }
        model.isSoftDeleted = true
        model.updatedAt = .now
        try modelContext.save()
    }

    func getActiveBabies() async throws -> [Baby] {
        let descriptor = FetchDescriptor<BabyModel>(
            predicate: #Predicate<BabyModel> { $0.isSoftDeleted == false },
            sortBy: [SortDescriptor(\.createdAt)]
        )
        return try modelContext.fetch(descriptor).map { $0.toEntity() }
    }
}

enum RepositoryError: Error, LocalizedError {
    case notFound

    var errorDescription: String? {
        switch self {
        case .notFound: "Entity not found"
        }
    }
}
