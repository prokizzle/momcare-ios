import Foundation

@Observable
@MainActor
final class DiaperViewModel {

    // MARK: - State

    private(set) var diapers: [Diaper] = []
    private(set) var isLoading = false
    var error: Error?

    var diapersGroupedByDay: [(day: Date, entries: [Diaper])] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: diapers) { diaper in
            calendar.startOfDay(for: diaper.timestamp)
        }
        return grouped
            .sorted { $0.key > $1.key }
            .map { (day: $0.key, entries: $0.value) }
    }

    var todayCount: Int {
        let today = Calendar.current.startOfDay(for: .now)
        return diapers.filter {
            Calendar.current.startOfDay(for: $0.timestamp) == today
        }.count
    }

    // MARK: - Dependencies

    private let repository: any DiaperRepositoryProtocol

    // MARK: - Init

    init(repository: any DiaperRepositoryProtocol) {
        self.repository = repository
    }

    // MARK: - Load

    func loadDiapers(babyId: UUID) async {
        error = nil
        isLoading = true
        defer { isLoading = false }
        do {
            diapers = try await repository.getDiapersForBaby(babyId, limit: nil)
        } catch {
            self.error = error
        }
    }

    // MARK: - Mutations

    @discardableResult
    func logDiaper(_ diaper: Diaper) async -> Bool {
        error = nil
        do {
            let created = try await repository.create(diaper)
            diapers.insert(created, at: 0)
            return true
        } catch {
            self.error = error
            return false
        }
    }

    func deleteDiaper(id: UUID) async {
        error = nil
        do {
            try await repository.delete(id)
            diapers.removeAll { $0.id == id }
        } catch {
            self.error = error
        }
    }
}
