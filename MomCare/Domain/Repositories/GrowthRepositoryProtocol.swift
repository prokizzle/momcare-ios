import Foundation

protocol GrowthRepositoryProtocol: Repository where Entity == GrowthRecord {
    func getRecordsForBaby(_ babyId: UUID, limit: Int?) async throws -> [GrowthRecord]
    func getRecordsForDateRange(babyId: UUID, start: Date, end: Date) async throws -> [GrowthRecord]
}
