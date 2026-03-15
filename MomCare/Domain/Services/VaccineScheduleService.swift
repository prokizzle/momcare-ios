import Foundation

struct VaccineScheduleService: Sendable {
    struct ScheduledVaccine: Codable, Sendable, Identifiable {
        var id: String { name }
        let name: String
        let ageMonths: Int
        let description: String
    }

    let bundle: Bundle

    init(bundle: Bundle = .main) {
        self.bundle = bundle
    }

    func loadSchedule() throws -> [ScheduledVaccine] {
        guard let url = bundle.url(forResource: "aap-vaccine-schedule", withExtension: "json") else {
            throw VaccineScheduleError.dataNotFound
        }
        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode([ScheduledVaccine].self, from: data)
    }

    func upcomingVaccines(
        dateOfBirth: Date,
        existingEvents: [HealthEvent],
        windowMonths: Int = 2
    ) throws -> [ScheduledVaccine] {
        let schedule = try loadSchedule()
        let ageInMonths = Calendar.current.dateComponents(
            [.month],
            from: dateOfBirth,
            to: .now
        ).month ?? 0
        let loggedNames = Set(
            existingEvents
                .filter { $0.eventType == .vaccine }
                .map { $0.title.lowercased() }
        )

        return schedule.filter { vaccine in
            let isDue = vaccine.ageMonths >= ageInMonths
                && vaccine.ageMonths <= ageInMonths + windowMonths
            let isLogged = loggedNames.contains(vaccine.name.lowercased())
            return isDue && !isLogged
        }
    }
}

enum VaccineScheduleError: Error, LocalizedError {
    case dataNotFound

    var errorDescription: String? {
        switch self {
        case .dataNotFound: "AAP vaccine schedule data not found"
        }
    }
}
