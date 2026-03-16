import Foundation

protocol HealthEventRepositoryProtocol: Repository where Entity == HealthEvent {
    func getEventsForBaby(_ babyId: UUID, limit: Int?) async throws -> [HealthEvent]
    func getEventsForBabyByType(
        _ babyId: UUID,
        type: HealthEvent.EventType
    ) async throws -> [HealthEvent]
    func createWithPhotos(_ entity: HealthEvent, photos: [Data]) async throws -> HealthEvent
    func getPhotos(for eventId: UUID) async throws -> [Data]
    func updatePhotos(for eventId: UUID, photos: [Data]) async throws
}
