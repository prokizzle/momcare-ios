import Foundation

protocol HealthEventRepositoryProtocol: Repository where Entity == HealthEvent {
    func getEventsForBaby(_ babyId: UUID, limit: Int?) async throws -> [HealthEvent]
    func getEventsForBabyByType(
        _ babyId: UUID,
        type: HealthEvent.EventType
    ) async throws -> [HealthEvent]
}
