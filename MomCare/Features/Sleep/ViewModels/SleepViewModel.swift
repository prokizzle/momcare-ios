import Foundation

@Observable
@MainActor
final class SleepViewModel {
    private(set) var sleeps: [BabySleep] = [] {
        didSet { rebuildGrouped() }
    }
    private(set) var groupedSleeps: [(String, [BabySleep])] = []
    var selectedLocation: BabySleep.SleepLocation?
    var selectedQuality: BabySleep.SleepQuality?
    var showQualitySheet = false
    var isLoading = false
    var error: Error?

    private let repository: any SleepRepositoryProtocol

    private let dateFormatter: DateFormatter = {
        let fmt = DateFormatter()
        fmt.dateFormat = "EEE MMM d"
        return fmt
    }()

    init(repository: any SleepRepositoryProtocol) {
        self.repository = repository
    }

    func loadSleeps(babyId: UUID) async {
        error = nil
        isLoading = true
        defer { isLoading = false }
        do {
            sleeps = try await repository.getSleepsForBaby(babyId, limit: nil)
        } catch {
            self.error = error
        }
    }

    func endSleep(babyId: UUID) async {
        error = nil
        let end = Date.now
        do {
            if var existing = try await repository.getInProgressSleep(babyId: babyId) {
                existing.endTime = end
                existing.updatedAt = end
                existing.quality = selectedQuality
                existing.location = selectedLocation
                let updated = try await repository.update(existing)
                sleeps.insert(updated, at: 0)
            }
            selectedQuality = nil
            selectedLocation = nil
            showQualitySheet = false
        } catch {
            self.error = error
        }
    }

    func deleteSleep(id: UUID) async {
        error = nil
        do {
            try await repository.delete(id)
            sleeps.removeAll { $0.id == id }
        } catch {
            self.error = error
        }
    }

    func dailyTotal(for sleeps: [BabySleep]) -> TimeInterval {
        sleeps.reduce(0) { $0 + $1.duration }
    }

    func formattedDuration(_ interval: TimeInterval) -> String {
        let total = Int(interval)
        let hours = total / 3600
        let minutes = (total % 3600) / 60
        if hours > 0 { return "\(hours)h \(minutes)m" }
        return "\(minutes)m"
    }

    private func rebuildGrouped() {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: sleeps) { sleep -> String in
            if calendar.isDateInToday(sleep.startTime) { return "Today" }
            if calendar.isDateInYesterday(sleep.startTime) { return "Yesterday" }
            return dateFormatter.string(from: sleep.startTime)
        }
        groupedSleeps = grouped.map { key, items in
            (key, items.sorted { $0.startTime > $1.startTime })
        }.sorted { lhs, rhs in
            (lhs.1.first?.startTime ?? .distantPast) > (rhs.1.first?.startTime ?? .distantPast)
        }
    }
}
