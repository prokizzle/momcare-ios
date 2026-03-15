import Testing
import Foundation
@testable import MomCare

@Suite("HealthEventsViewModel")
struct HealthEventsViewModelTests {

    private let babyId = UUID()

    @MainActor
    private func makeSUT(events: [HealthEvent] = []) -> HealthEventsViewModel {
        let repo = StubHealthEventRepository(events: events)
        return HealthEventsViewModel(repository: repo)
    }

    @Test("Initial state has no events")
    @MainActor
    func initialState() {
        let sut = makeSUT()
        #expect(sut.events.isEmpty)
        #expect(!sut.isLoading)
        #expect(sut.selectedFilter == nil)
    }

    @Test("Load events for baby")
    @MainActor
    func loadEvents() async {
        let events = [
            HealthEvent.fixture(babyId: babyId, eventType: .vaccine),
            HealthEvent.fixture(babyId: babyId, eventType: .illness)
        ]
        let sut = makeSUT(events: events)
        await sut.loadEvents(babyId: babyId)
        #expect(sut.events.count == 2)
    }

    @Test("Add event creates record")
    @MainActor
    func addEvent() async {
        let sut = makeSUT()
        let success = await sut.addEvent(
            babyId: babyId,
            date: .now,
            endDate: nil,
            eventType: .vaccine,
            title: "DTaP - Dose 1",
            notes: nil
        )
        #expect(success)
        #expect(sut.events.count == 1)
    }

    @Test("Delete event removes record")
    @MainActor
    func deleteEvent() async {
        let event = HealthEvent.fixture(babyId: babyId)
        let sut = makeSUT(events: [event])
        await sut.loadEvents(babyId: babyId)
        await sut.deleteEvent(id: event.id)
        #expect(sut.events.isEmpty)
    }

    @Test("Filter by event type")
    @MainActor
    func filterByType() async {
        let events = [
            HealthEvent.fixture(babyId: babyId, eventType: .vaccine, title: "V1"),
            HealthEvent.fixture(babyId: babyId, eventType: .illness, title: "I1")
        ]
        let sut = makeSUT(events: events)
        await sut.loadEvents(babyId: babyId)
        sut.selectedFilter = .vaccine
        #expect(sut.filteredEvents.count == 1)
        #expect(sut.filteredEvents.first?.eventType == .vaccine)
    }
}

// MARK: - Stub

@MainActor
private final class StubHealthEventRepository: HealthEventRepositoryProtocol {
    private var store: [HealthEvent]

    init(events: [HealthEvent] = []) {
        self.store = events
    }

    func getAll() async throws -> [HealthEvent] { store.filter { !$0.isDeleted } }
    func getById(_ id: UUID) async throws -> HealthEvent? { store.first { $0.id == id } }

    func create(_ entity: HealthEvent) async throws -> HealthEvent {
        store.append(entity)
        return entity
    }

    func update(_ entity: HealthEvent) async throws -> HealthEvent {
        if let index = store.firstIndex(where: { $0.id == entity.id }) {
            store[index] = entity
        }
        return entity
    }

    func delete(_ id: UUID) async throws {
        store.removeAll { $0.id == id }
    }

    func getEventsForBaby(_ babyId: UUID, limit: Int?) async throws -> [HealthEvent] {
        let filtered = store.filter { $0.babyId == babyId && !$0.isDeleted }
        if let limit { return Array(filtered.prefix(limit)) }
        return filtered
    }

    func getEventsForBabyByType(
        _ babyId: UUID,
        type: HealthEvent.EventType
    ) async throws -> [HealthEvent] {
        store.filter { $0.babyId == babyId && !$0.isDeleted && $0.eventType == type }
    }
}
