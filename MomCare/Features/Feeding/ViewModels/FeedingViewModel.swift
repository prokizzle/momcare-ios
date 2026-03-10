import Foundation

@MainActor
@Observable
final class FeedingViewModel {
    var feedings: [Feeding] = []
    var inProgressFeeding: Feeding?
    var pattern: FeedingPattern?
    var selectedType: Feeding.FeedingType = .breast
    var selectedSide: Feeding.BreastSide = .left
    var isLoading = false
    var error: Error?

    var isTimerRunning = false
    var elapsedTime: TimeInterval = 0

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

    private func updateElapsedTime() {
        guard let start = inProgressFeeding?.startTime else { return }
        elapsedTime = Date.now.timeIntervalSince(start)
    }

    private func startTimerTick() {
        stopTimerTick()
        timerTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(1))
                guard !Task.isCancelled else { break }
                self?.updateElapsedTime()
            }
        }
    }

    private func stopTimerTick() {
        timerTask?.cancel()
        timerTask = nil
    }
}
