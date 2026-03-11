import Foundation

@Observable
@MainActor
final class JournalViewModel {
    private(set) var entries: [JournalEntry] = []
    private(set) var groupedEntries: [(String, [JournalEntry])] = []
    var selectedFilter: JournalEntryKind?
    var isLoading = false

    private let sleepRepository: any SleepRepositoryProtocol
    private let feedingRepository: any FeedingRepositoryProtocol
    private let diaperRepository: any DiaperRepositoryProtocol

    init(
        sleepRepository: any SleepRepositoryProtocol,
        feedingRepository: any FeedingRepositoryProtocol,
        diaperRepository: any DiaperRepositoryProtocol
    ) {
        self.sleepRepository = sleepRepository
        self.feedingRepository = feedingRepository
        self.diaperRepository = diaperRepository
    }

    func load(babyId: UUID) async {
        isLoading = true
        defer { isLoading = false }
        var allEntries: [JournalEntry] = []

        if let sleeps = try? await sleepRepository.getSleepsForBaby(babyId, limit: 200) {
            allEntries += sleeps.compactMap { sleep in
                guard let end = sleep.endTime else { return nil }
                let mins = Int(end.timeIntervalSince(sleep.startTime) / 60)
                return JournalEntry(
                    id: sleep.id,
                    kind: .nap,
                    timestamp: sleep.startTime,
                    detail: "\(mins) min"
                )
            }
        }

        if let feedings = try? await feedingRepository.getFeedingsForBaby(babyId, limit: 200) {
            allEntries += feedings.compactMap { feeding in
                guard let end = feeding.endTime else { return nil }
                let mins = Int(end.timeIntervalSince(feeding.startTime) / 60)
                let side = feeding.breastSide?.rawValue.capitalized ?? "Bottle"
                return JournalEntry(
                    id: feeding.id,
                    kind: .feeding,
                    timestamp: feeding.startTime,
                    detail: "\(side) \(mins) min"
                )
            }
        }

        if let diapers = try? await diaperRepository.getDiapersForBaby(babyId, limit: 200) {
            allEntries += diapers.map { diaper in
                JournalEntry(
                    id: diaper.id,
                    kind: .diaper,
                    timestamp: diaper.timestamp,
                    detail: diaper.type.label
                )
            }
        }

        entries = allEntries.sorted { $0.timestamp > $1.timestamp }
        rebuildGrouped()
    }

    var filteredEntries: [JournalEntry] {
        guard let filter = selectedFilter else { return entries }
        return entries.filter { $0.kind == filter }
    }

    private func rebuildGrouped() {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: filteredEntries) { entry -> String in
            groupKey(entry, calendar: calendar)
        }
        let sortedKeys = grouped
            .sorted { lhs, rhs in
                let lDate = filteredEntries
                    .first { groupKey($0, calendar: calendar) == lhs.key }?.timestamp ?? .distantPast
                let rDate = filteredEntries
                    .first { groupKey($0, calendar: calendar) == rhs.key }?.timestamp ?? .distantPast
                return lDate > rDate
            }
        groupedEntries = sortedKeys
            .map { ($0.key, $0.value.sorted { $0.timestamp > $1.timestamp }) }
    }

    private func groupKey(_ entry: JournalEntry, calendar: Calendar = .current) -> String {
        if calendar.isDateInToday(entry.timestamp) { return "Today" }
        if calendar.isDateInYesterday(entry.timestamp) { return "Yesterday" }
        let fmt = DateFormatter()
        fmt.dateFormat = "EEE MMM d"
        return fmt.string(from: entry.timestamp)
    }
}
