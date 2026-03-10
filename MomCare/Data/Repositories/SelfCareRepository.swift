import Foundation
import SwiftData

@MainActor
final class SelfCareRepository: SelfCareRepositoryProtocol {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - CRUD

    func getAll() async throws -> [SelfCareLog] {
        let descriptor = FetchDescriptor<SelfCareLogModel>(
            predicate: #Predicate<SelfCareLogModel> { $0.isSoftDeleted == false },
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )
        return try modelContext.fetch(descriptor).map { $0.toEntity() }
    }

    func getById(_ id: UUID) async throws -> SelfCareLog? {
        let fetchId = id
        let descriptor = FetchDescriptor<SelfCareLogModel>(
            predicate: #Predicate<SelfCareLogModel> { $0.id == fetchId }
        )
        return try modelContext.fetch(descriptor).first?.toEntity()
    }

    func create(_ entity: SelfCareLog) async throws -> SelfCareLog {
        let model = SelfCareLogModel(from: entity)
        modelContext.insert(model)
        try modelContext.save()
        return model.toEntity()
    }

    func update(_ entity: SelfCareLog) async throws -> SelfCareLog {
        let entityId = entity.id
        let descriptor = FetchDescriptor<SelfCareLogModel>(
            predicate: #Predicate<SelfCareLogModel> { $0.id == entityId }
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
        let descriptor = FetchDescriptor<SelfCareLogModel>(
            predicate: #Predicate<SelfCareLogModel> { $0.id == deleteId }
        )
        guard let model = try modelContext.fetch(descriptor).first else {
            throw RepositoryError.notFound
        }
        model.isSoftDeleted = true
        model.updatedAt = .now
        try modelContext.save()
    }

    // MARK: - Date Queries

    func getLogsForDate(_ date: Date) async throws -> [SelfCareLog] {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else {
            return []
        }
        return try await getLogsForDateRange(start: startOfDay, end: endOfDay)
    }

    func getLogsForDateRange(start: Date, end: Date) async throws -> [SelfCareLog] {
        let rangeStart = start
        let rangeEnd = end
        let descriptor = FetchDescriptor<SelfCareLogModel>(
            predicate: #Predicate<SelfCareLogModel> {
                $0.isSoftDeleted == false &&
                $0.timestamp >= rangeStart &&
                $0.timestamp < rangeEnd
            },
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )
        return try modelContext.fetch(descriptor).map { $0.toEntity() }
    }

    func getLogsByActionType(_ type: SelfCareActionType, limit: Int?) async throws -> [SelfCareLog] {
        let typeRaw = type.rawValue
        var descriptor = FetchDescriptor<SelfCareLogModel>(
            predicate: #Predicate<SelfCareLogModel> {
                $0.actionTypeRaw == typeRaw && $0.isSoftDeleted == false
            },
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )
        if let limit {
            descriptor.fetchLimit = limit
        }
        return try modelContext.fetch(descriptor).map { $0.toEntity() }
    }

    // MARK: - Grid Items

    func getGridItems() async throws -> [SelfCareGridItem] {
        let descriptor = FetchDescriptor<SelfCareGridItemModel>(
            sortBy: [SortDescriptor(\.sortOrder)]
        )
        return try modelContext.fetch(descriptor).map { $0.toEntity() }
    }

    func saveGridItem(_ item: SelfCareGridItem) async throws {
        let itemId = item.id
        let descriptor = FetchDescriptor<SelfCareGridItemModel>(
            predicate: #Predicate<SelfCareGridItemModel> { $0.id == itemId }
        )
        if let existing = try modelContext.fetch(descriptor).first {
            existing.update(from: item)
        } else {
            let model = SelfCareGridItemModel(from: item)
            modelContext.insert(model)
        }
        try modelContext.save()
    }

    func deleteGridItem(_ id: UUID) async throws {
        let deleteId = id
        let descriptor = FetchDescriptor<SelfCareGridItemModel>(
            predicate: #Predicate<SelfCareGridItemModel> { $0.id == deleteId }
        )
        guard let model = try modelContext.fetch(descriptor).first else {
            throw RepositoryError.notFound
        }
        modelContext.delete(model)
        try modelContext.save()
    }

    // MARK: - Content History

    func recordContentShown(contentId: String) async throws {
        let fetchContentId = contentId
        let descriptor = FetchDescriptor<ContentHistoryModel>(
            predicate: #Predicate<ContentHistoryModel> { $0.contentId == fetchContentId }
        )
        if let existing = try modelContext.fetch(descriptor).first {
            existing.lastShownAt = .now
        } else {
            let model = ContentHistoryModel(contentId: contentId)
            modelContext.insert(model)
        }
        try modelContext.save()
    }

    func isContentRecentlyShown(contentId: String, within seconds: TimeInterval) async throws -> Bool {
        let fetchContentId = contentId
        let descriptor = FetchDescriptor<ContentHistoryModel>(
            predicate: #Predicate<ContentHistoryModel> { $0.contentId == fetchContentId }
        )
        guard let model = try modelContext.fetch(descriptor).first else {
            return false
        }
        let cutoff = Date.now.addingTimeInterval(-seconds)
        return model.lastShownAt >= cutoff
    }
}
