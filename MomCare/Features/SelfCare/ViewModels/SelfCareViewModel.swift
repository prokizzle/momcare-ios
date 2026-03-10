import Foundation

@MainActor
@Observable
final class SelfCareViewModel {
    var todayLogs: [SelfCareLog] = []
    var gridItems: [SelfCareGridItem] = []
    var cards: [SelfCareCard] = []
    var patterns: [ActionPattern] = []
    var isLoading = false
    var error: Error?

    private let repository: any SelfCareRepositoryProtocol
    private let contentLibrary: ContentLibrary
    private var recentTaps: [SelfCareActionType: Date] = [:]
    private var shownContentIds: [String] = []
    private var allRecentLogs: [SelfCareLog] = []
    private var feedingEndTimes: [Date] = []

    init(repository: any SelfCareRepositoryProtocol, contentLibrary: ContentLibrary) {
        self.repository = repository
        self.contentLibrary = contentLibrary
    }

    var waterCountToday: Int {
        todayLogs.filter { $0.actionType == .water }.count
    }

    func isRecentlyTapped(_ actionType: SelfCareActionType) -> Bool {
        guard let lastTap = recentTaps[actionType] else { return false }
        return Date.now.timeIntervalSince(lastTap) < 7200 // 2 hours
    }

    func loadDay(_ date: Date) async {
        error = nil
        isLoading = true
        defer { isLoading = false }

        do {
            todayLogs = try await repository.getLogsForDate(date)

            let analysisStart = Calendar.current.date(
                byAdding: .day, value: -SelfCarePatternService.analysisDays, to: date
            )!
            allRecentLogs = try await repository.getLogsForDateRange(
                start: analysisStart,
                end: date.addingTimeInterval(86400)
            )

            let existingGrid = try await repository.getGridItems()
            if existingGrid.isEmpty {
                let defaults = SelfCareGridItem.defaultGrid()
                for item in defaults {
                    try await repository.saveGridItem(item)
                }
                gridItems = defaults
            } else {
                gridItems = existingGrid
            }

            patterns = SelfCarePatternService.analyzePatterns(
                logs: allRecentLogs,
                feedingEndTimes: feedingEndTimes
            )

            // Populate recent taps from today's logs
            for log in todayLogs {
                if let existing = recentTaps[log.actionType] {
                    if log.timestamp > existing {
                        recentTaps[log.actionType] = log.timestamp
                    }
                } else {
                    recentTaps[log.actionType] = log.timestamp
                }
            }
        } catch {
            self.error = error
        }
    }

    func logAction(_ actionType: SelfCareActionType, detail: LogDetail? = nil) async {
        let log = SelfCareLog(
            id: UUID(),
            actionType: actionType,
            timestamp: .now,
            detail: detail,
            createdAt: .now,
            updatedAt: .now
        )

        do {
            let created = try await repository.create(log)
            todayLogs.insert(created, at: 0)
            allRecentLogs.insert(created, at: 0)
            recentTaps[actionType] = .now

            patterns = SelfCarePatternService.analyzePatterns(
                logs: allRecentLogs,
                feedingEndTimes: feedingEndTimes
            )

            await handleEvent(.selfCareLogged(created))
        } catch {
            self.error = error
        }
    }

    func handleEvent(_ event: SelfCareEvent) async {
        if case .feedingEnded = event {
            feedingEndTimes.append(.now)
        }

        let engine = SelfCareEngine(
            logs: allRecentLogs,
            patterns: patterns,
            contentLibrary: contentLibrary,
            shownContentIds: Set(shownContentIds),
            currentDate: .now
        )

        cards = engine.scoreCards(after: event)

        // Track shown content
        for card in cards where card.type == .affirmation || card.type == .pepTalk || card.type == .checkIn {
            if !shownContentIds.contains(card.message) {
                shownContentIds.append(card.message)
            }
        }
    }

    func dismissCard(_ id: UUID) {
        cards.removeAll { $0.id == id }
    }
}
