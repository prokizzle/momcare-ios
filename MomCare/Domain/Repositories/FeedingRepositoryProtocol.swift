import Foundation

protocol FeedingRepositoryProtocol: Repository where Entity == Feeding {
    func getFeedingsForBaby(_ babyId: UUID, limit: Int?) async throws -> [Feeding]
    func getFeedingsForDateRange(babyId: UUID, start: Date, end: Date) async throws -> [Feeding]
    func getInProgressFeeding(babyId: UUID) async throws -> Feeding?
}
