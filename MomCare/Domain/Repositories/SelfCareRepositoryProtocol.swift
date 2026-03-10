import Foundation

protocol SelfCareRepositoryProtocol: Repository where Entity == SelfCareLog {
    func getLogsForDate(_ date: Date) async throws -> [SelfCareLog]
    func getLogsForDateRange(start: Date, end: Date) async throws -> [SelfCareLog]
    func getLogsByActionType(_ type: SelfCareActionType, limit: Int?) async throws -> [SelfCareLog]

    func getGridItems() async throws -> [SelfCareGridItem]
    func saveGridItem(_ item: SelfCareGridItem) async throws
    func deleteGridItem(_ id: UUID) async throws

    func recordContentShown(contentId: String) async throws
    func isContentRecentlyShown(contentId: String, within seconds: TimeInterval) async throws -> Bool
}
