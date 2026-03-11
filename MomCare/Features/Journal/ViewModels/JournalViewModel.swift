import Foundation

@Observable
@MainActor
final class JournalViewModel {
    private(set) var entries: [JournalEntry] = []
    private(set) var groupedEntries: [(String, [JournalEntry])] = []
    var selectedFilter: JournalEntryKind? {
        didSet {
            rebuildGrouped()
        }
    }
    var isLoading = false

    private let sleepRepository: any SleepRepositoryProtocol
    private let feedingRepository: any FeedingRepositoryProtocol
    private let diaperRepository: any DiaperRepositoryProtocol

    private lazy var dateFormatter: DateFormatter = {
        let fmt = DateFormatter()
        fmt.dateFormat = "EEE MMM d"
        return fmt
    }()

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
        let groupedDict = Dictionary(grouping: filteredEntries) { entry -> String in
            groupKey(entry, calendar: calendar)
        }

        let keyedEntries: [(key: String, entries: [JournalEntry])] = groupedDict.map { key, value in
            let sortedEntries = value.sorted { $0.timestamp > $1.timestamp }
            return (key: key, entries: sortedEntries)
        }

        let sorted = keyedEntries.sorted { lhs, rhs in
            let lDate = lhs.entries.first?.timestamp ?? .distantPast
            let rDate = rhs.entries.first?.timestamp ?? .distantPast
            return lDate > rDate
        }

        groupedEntries = sorted.map { ($0.key, $0.entries) }
    }

    private func groupKey(_ entry: JournalEntry, calendar: Calendar = .current) -> String {
        if calendar.isDateInToday(entry.timestamp) { return "Today" }
        if calendar.isDateInYesterday(entry.timestamp) { return "Yesterday" }
        return dateFormatter.string(from: entry.timestamp)
    }
}
