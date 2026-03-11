import Foundation

protocol DiaperRepositoryProtocol: Repository where Entity == Diaper {
    func getDiapersForBaby(_ babyId: UUID, limit: Int?) async throws -> [Diaper]
    func getDiapersForDateRange(babyId: UUID, start: Date, end: Date) async throws -> [Diaper]
}
