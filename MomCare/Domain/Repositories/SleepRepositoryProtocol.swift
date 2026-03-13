import Foundation

protocol SleepRepositoryProtocol: Repository where Entity == BabySleep {
    func getSleepsForBaby(_ babyId: UUID, limit: Int?) async throws -> [BabySleep]
    func getSleepsForDateRange(babyId: UUID, start: Date, end: Date) async throws -> [BabySleep]
    func getInProgressSleep(babyId: UUID) async throws -> BabySleep?
}
