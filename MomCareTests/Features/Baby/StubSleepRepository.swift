import Foundation
@testable import MomCare

@MainActor
final class StubSleepRepository: SleepRepositoryProtocol {
    var sleeps: [BabySleep]
    var inProgress: BabySleep?
    var created: [BabySleep] = []
    var updated: [BabySleep] = []

    init(sleeps: [BabySleep] = [], inProgress: BabySleep? = nil) {
        self.sleeps = sleeps
        self.inProgress = inProgress
    }

    func getAll() async throws -> [BabySleep] { sleeps }
    func getById(_ id: UUID) async throws -> BabySleep? { sleeps.first { $0.id == id } }
    func create(_ entity: BabySleep) async throws -> BabySleep { created.append(entity); return entity }
    func update(_ entity: BabySleep) async throws -> BabySleep { updated.append(entity); return entity }
    func delete(_ id: UUID) async throws { sleeps.removeAll { $0.id == id } }
    func getSleepsForBaby(_ babyId: UUID, limit: Int?) async throws -> [BabySleep] { sleeps }
    func getSleepsForDateRange(babyId: UUID, start: Date, end: Date) async throws -> [BabySleep] { sleeps }
    func getInProgressSleep(babyId: UUID) async throws -> BabySleep? { inProgress }
}
