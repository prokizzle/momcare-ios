import Foundation

@Observable
@MainActor
final class HealthEventsViewModel {
    private let repository: any HealthEventRepositoryProtocol
    private let vaccineService: VaccineScheduleService

    private(set) var events: [HealthEvent] = []
    var selectedFilter: HealthEvent.EventType?
    var upcomingVaccines: [VaccineScheduleService.ScheduledVaccine] = []
    var isLoading = false
    var error: Error?
    var showAddSheet = false

    init(
        repository: any HealthEventRepositoryProtocol,
        vaccineService: VaccineScheduleService = VaccineScheduleService()
    ) {
        self.repository = repository
        self.vaccineService = vaccineService
    }

    var filteredEvents: [HealthEvent] {
        guard let filter = selectedFilter else { return events }
        return events.filter { $0.eventType == filter }
    }

    private let monthFormatter: DateFormatter = {
        let fmt = DateFormatter()
        fmt.dateFormat = "MMMM yyyy"
        return fmt
    }()

    var groupedEvents: [(String, [HealthEvent])] {
        let grouped = Dictionary(grouping: filteredEvents) { event -> String in
            monthFormatter.string(from: event.date)
        }

        return grouped.map { key, items in
            (key, items.sorted { $0.date > $1.date })
        }.sorted { lhs, rhs in
            (lhs.1.first?.date ?? .distantPast) > (rhs.1.first?.date ?? .distantPast)
        }
    }

    func loadEvents(babyId: UUID) async {
        error = nil
        isLoading = true
        defer { isLoading = false }
        do {
            events = try await repository.getEventsForBaby(babyId, limit: nil)
        } catch {
            self.error = error
        }
    }

    @discardableResult
    // swiftlint:disable:next function_parameter_count
    func addEvent(
        babyId: UUID,
        date: Date,
        endDate: Date?,
        eventType: HealthEvent.EventType,
        title: String,
        notes: String?,
        photos: [Data] = []
    ) async -> Bool {
        error = nil
        let event = HealthEvent(
            id: UUID(),
            babyId: babyId,
            date: date,
            endDate: endDate,
            eventType: eventType,
            title: title,
            notes: notes,
            isDeleted: false,
            createdAt: .now,
            updatedAt: .now
        )
        do {
            let created = if photos.isEmpty {
                try await repository.create(event)
            } else {
                try await repository.createWithPhotos(event, photos: photos)
            }
            events.insert(created, at: 0)
            events.sort { $0.date > $1.date }
            return true
        } catch {
            self.error = error
            return false
        }
    }

    func loadPhotos(for eventId: UUID) async -> [Data] {
        do {
            return try await repository.getPhotos(for: eventId)
        } catch {
            return []
        }
    }

    func deleteEvent(id: UUID) async {
        error = nil
        do {
            try await repository.delete(id)
            events.removeAll { $0.id == id }
        } catch {
            self.error = error
        }
    }

    func loadUpcomingVaccines(dateOfBirth: Date) {
        do {
            upcomingVaccines = try vaccineService.upcomingVaccines(
                dateOfBirth: dateOfBirth,
                existingEvents: events
            )
        } catch {
            self.error = error
            upcomingVaccines = []
        }
    }
}
