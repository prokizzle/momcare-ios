import ActivityKit
import Foundation

@MainActor
@Observable
final class FeedingViewModel {
    var feedings: [Feeding] = [] {
        didSet { rebuildDerivedData() }
    }
    private(set) var groupedFeedings: [(String, [Feeding])] = []
    private(set) var feedingsById: [UUID: Feeding] = [:]
    var inProgressFeeding: Feeding?
    var pattern: FeedingPattern?
    var selectedType: Feeding.FeedingType = .breast
    var selectedSide: Feeding.BreastSide = .left
    var isLoading = false
    var error: Error?

    var isTimerRunning = false
    var elapsedTime: TimeInterval = 0
    var elapsedTimeFormatted: String {
        let totalSeconds = Int(elapsedTime)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        }
        return String(format: "%02d:%02d", minutes, seconds)
    }

    private let repository: any FeedingRepositoryProtocol
    private var timerTask: Task<Void, Never>?

    init(repository: any FeedingRepositoryProtocol) {
        self.repository = repository
    }

    func loadFeedings(babyId: UUID) async {
        error = nil
        isLoading = true
        defer { isLoading = false }
        do {
            feedings = try await repository.getFeedingsForBaby(babyId, limit: nil)
            inProgressFeeding = try await repository.getInProgressFeeding(babyId: babyId)
            if inProgressFeeding != nil {
                isTimerRunning = true
                updateElapsedTime()
                startTimerTick()
            }
        } catch {
            self.error = error
        }
    }

    func startFeeding(babyId: UUID, type: Feeding.FeedingType) async {
        error = nil
        let feeding = Feeding(
            id: UUID(),
            babyId: babyId,
            feedingType: type,
            startTime: .now,
            endTime: nil,
            breastSide: type == .breast ? selectedSide : nil,
            breastDuration: nil,
            amountMl: nil,
            bottleContent: nil,
            foodDescription: nil,
            quality: nil,
            notes: nil,
            createdAt: .now,
            updatedAt: .now
        )
        do {
            let created = try await repository.create(feeding)
            inProgressFeeding = created
            isTimerRunning = true
            elapsedTime = 0
            startTimerTick()
        } catch {
            self.error = error
        }
    }

    func endFeeding() async {
        error = nil
        guard var feeding = inProgressFeeding else { return }
        feeding.endTime = .now
        feeding.updatedAt = .now
        if feeding.feedingType == .breast {
            feeding.breastDuration = feeding.duration
        }
        do {
            let updated = try await repository.update(feeding)
            feedings.insert(updated, at: 0)
            inProgressFeeding = nil
            isTimerRunning = false
            elapsedTime = 0
            stopTimerTick()
        } catch {
            self.error = error
        }
    }

    func toggleBreastSide() {
        selectedSide = selectedSide == .left ? .right : .left
        if var feeding = inProgressFeeding, feeding.feedingType == .breast {
            feeding.breastSide = selectedSide
            inProgressFeeding = feeding
            // Update feeding Live Activity with new breast side
            let sideDetail = selectedSide == .left ? "Left breast" : "Right breast"
            Task {
                for activity in Activity<InProgressActivityAttributes>.activities
                    where activity.attributes.activityType == "feeding" {
                    let state = InProgressActivityAttributes.ContentState(
                        startTime: activity.content.state.startTime,
                        detail: sideDetail
                    )
                    await activity.update(ActivityContent(state: state, staleDate: nil))
                }
            }
            // Sync to widget
            SharedDataManager.updateFeeding(SharedFeedingState(
                lastTime: SharedDataManager.lastFeedingTime,
                lastType: SharedDataManager.lastFeedingType,
                isInProgress: true,
                startTime: SharedDataManager.feedingStartTime,
                detail: sideDetail,
                todayCount: SharedDataManager.todayFeedingCount
            ))
        }
    }

    func analyzePattern(babyId: UUID) async {
        error = nil
        do {
            let now = Date.now
            let weekAgo = now.addingTimeInterval(-Double(FeedingPatternService.patternAnalysisDays) * 86400)
            let recentFeedings = try await repository.getFeedingsForDateRange(
                babyId: babyId,
                start: weekAgo,
                end: now
            )
            pattern = FeedingPatternService.analyzePattern(from: recentFeedings)
        } catch {
            self.error = error
        }
    }

    func deleteFeeding(_ id: UUID) async {
        error = nil
        do {
            try await repository.delete(id)
            feedings.removeAll { $0.id == id }
        } catch {
            self.error = error
        }
    }

    func updateFeeding(_ feeding: Feeding) async {
        error = nil
        do {
            let updated = try await repository.update(feeding)
            if let index = feedings.firstIndex(where: { $0.id == updated.id }) {
                feedings[index] = updated
            }
        } catch {
            self.error = error
        }
    }

    // MARK: - Timer

    func pauseTimer() {
        stopTimerTick()
    }

    func resumeTimerIfNeeded() {
        guard isTimerRunning, inProgressFeeding != nil else { return }
        updateElapsedTime()
        startTimerTick()
    }

    private func updateElapsedTime() {
        guard let start = inProgressFeeding?.startTime else { return }
        elapsedTime = Date.now.timeIntervalSince(start)
    }

    private func startTimerTick() {
        stopTimerTick()
        timerTask = Task { [weak self] in
            while !Task.isCancelled {
                do {
                    try await Task.sleep(for: .seconds(1))
                } catch {
                    break
                }
                guard !Task.isCancelled, let self else { break }
                self.updateElapsedTime()
            }
        }
    }

    private func stopTimerTick() {
        timerTask?.cancel()
        timerTask = nil
    }

    // MARK: - Derived Data

    private func rebuildDerivedData() {
        feedingsById = Dictionary(uniqueKeysWithValues: feedings.map { ($0.id, $0) })
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: feedings) { feeding -> String in
            if calendar.isDateInToday(feeding.startTime) {
                return "Today"
            } else if calendar.isDateInYesterday(feeding.startTime) {
                return "Yesterday"
            } else {
                return feeding.startTime.formatted(date: .abbreviated, time: .omitted)
            }
        }
        groupedFeedings = grouped.map { key, items in
            (key, items.sorted { $0.startTime > $1.startTime })
        }.sorted { lhs, rhs in
            (lhs.1.first?.startTime ?? .distantPast) > (rhs.1.first?.startTime ?? .distantPast)
        }
    }
}
