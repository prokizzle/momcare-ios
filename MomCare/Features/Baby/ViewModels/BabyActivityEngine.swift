import Foundation

// MARK: - Supporting Types

enum FeedMethod: String, Sendable {
    case left, right, bottle

    var label: String { rawValue.capitalized }

    var systemImage: String {
        switch self {
        case .left: "arrow.left.circle.fill"
        case .right: "arrow.right.circle.fill"
        case .bottle: "drop.fill"
        }
    }
}

// MARK: - BabyActivityEngine

@Observable
@MainActor
final class BabyActivityEngine {

    // MARK: - Active State

    private(set) var napStartTime: Date?
    private(set) var feedingStartTime: Date?
    private(set) var feedMethod: FeedMethod?
    private(set) var showDiaperOptions: Bool = false
    private(set) var napElapsed: TimeInterval = 0
    private(set) var feedingElapsed: TimeInterval = 0

    var isNapActive: Bool { napStartTime != nil }
    var isFeedingActive: Bool { feedingStartTime != nil }

    var napElapsedFormatted: String { formatElapsed(napElapsed) }
    var feedingElapsedFormatted: String { formatElapsed(feedingElapsed) }

    // MARK: - Dependencies

    private let sleepRepository: any SleepRepositoryProtocol
    private let feedingRepository: any FeedingRepositoryProtocol
    private let diaperRepository: any DiaperRepositoryProtocol

    nonisolated(unsafe) private var napTimerTask: Task<Void, Never>?
    nonisolated(unsafe) private var feedingTimerTask: Task<Void, Never>?
    nonisolated(unsafe) private var diaperAutoHideTask: Task<Void, Never>?

    // MARK: - Init

    init(
        sleepRepository: any SleepRepositoryProtocol,
        feedingRepository: any FeedingRepositoryProtocol,
        diaperRepository: any DiaperRepositoryProtocol
    ) {
        self.sleepRepository = sleepRepository
        self.feedingRepository = feedingRepository
        self.diaperRepository = diaperRepository
    }

    deinit {
        napTimerTask?.cancel()
        feedingTimerTask?.cancel()
        diaperAutoHideTask?.cancel()
    }

    // MARK: - Load In-Progress (on app launch)

    func loadInProgress(babyId: UUID) async {
        if let sleep = try? await sleepRepository.getInProgressSleep(babyId: babyId) {
            napStartTime = sleep.startTime
            napElapsed = Date.now.timeIntervalSince(sleep.startTime)
            startNapTick()
        }
        if let feeding = try? await feedingRepository.getInProgressFeeding(babyId: babyId) {
            feedingStartTime = feeding.startTime
            feedingElapsed = Date.now.timeIntervalSince(feeding.startTime)
            feedMethod = feeding.feedingType == .bottle ? .bottle
                : feeding.breastSide == .right ? .right : .left
            startFeedingTick()
        }
    }

    // MARK: - Nap

    func startNap(babyId: UUID) async {
        guard !isNapActive else { return }
        let start = Date.now
        napStartTime = start
        napElapsed = 0
        startNapTick()
        let sleep = BabySleep(
            id: UUID(),
            babyId: babyId,
            startTime: start,
            endTime: nil,
            sleepType: BabySleep.SleepType.autoDetect(at: start),
            location: nil,
            quality: nil,
            notes: nil,
            createdAt: start,
            updatedAt: start
        )
        do {
            _ = try await sleepRepository.create(sleep)
        } catch {
            // Creation failures are non-fatal for timers; consider logging in future
        }
    }

    func endNap(babyId: UUID) async {
        guard napStartTime != nil else { return }
        stopNapTick()
        let end = Date.now
        do {
            if var existing = try await sleepRepository.getInProgressSleep(babyId: babyId) {
                existing.endTime = end
                existing.updatedAt = end
                _ = try await sleepRepository.update(existing)
            }
        } catch {
            // Non-fatal: UI timers still stop even if persistence fails
        }
        napStartTime = nil
        napElapsed = 0
    }

    // MARK: - Feeding

    func startFeeding(babyId: UUID, method: FeedMethod) async {
        guard !isFeedingActive else { return }
        let start = Date.now
        feedingStartTime = start
        feedMethod = method
        feedingElapsed = 0
        startFeedingTick()
        let feedingType: Feeding.FeedingType = method == .bottle ? .bottle : .breast
        let side: Feeding.BreastSide? = method == .left ? .left : method == .right ? .right : nil
        let feeding = Feeding(
            id: UUID(),
            babyId: babyId,
            feedingType: feedingType,
            startTime: start,
            endTime: nil,
            breastSide: side,
            breastDuration: nil,
            amountMl: nil,
            bottleContent: nil,
            foodDescription: nil,
            quality: nil,
            notes: nil,
            createdAt: start,
            updatedAt: start
        )
        do {
            _ = try await feedingRepository.create(feeding)
        } catch {
            // Non-fatal: user-visible timers remain accurate even if save fails
        }
    }

    func endFeeding(babyId: UUID) async {
        guard let start = feedingStartTime else { return }
        stopFeedingTick()
        let end = Date.now
        let duration = end.timeIntervalSince(start)
        do {
            if var existing = try await feedingRepository.getInProgressFeeding(babyId: babyId) {
                existing.endTime = end
                existing.updatedAt = end
                _ = try await feedingRepository.update(existing)
            }
        } catch {
            // Non-fatal: duration callback still fires
        }
        feedingStartTime = nil
        feedMethod = nil
        feedingElapsed = 0
    }

    // MARK: - Diaper

    func logDiaper(babyId: UUID) {
        showDiaperOptions = true
        diaperAutoHideTask?.cancel()
        diaperAutoHideTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(3))
            guard let self else { return }
            if self.showDiaperOptions {
                self.showDiaperOptions = false
            }
        }
    }

    func selectDiaperType(_ type: Diaper.DiaperType, babyId: UUID) async {
        showDiaperOptions = false
        let now = Date.now
        let diaper = Diaper(
            id: UUID(),
            babyId: babyId,
            timestamp: now,
            type: type,
            stoolConsistency: nil,
            stoolColor: nil,
            hasRash: false,
            notes: nil,
            createdAt: now,
            updatedAt: now
        )
        do {
            _ = try await diaperRepository.create(diaper)
        } catch {
            // Non-fatal: quick-log interaction should not block on persistence
        }
    }

    // MARK: - Background / Foreground

    func pauseTimers() {
        stopNapTick()
        stopFeedingTick()
    }

    func resumeTimersIfNeeded() {
        if isNapActive { updateNapElapsed(); startNapTick() }
        if isFeedingActive { updateFeedingElapsed(); startFeedingTick() }
    }

    // MARK: - Timer Internals

    private func startNapTick() {
        stopNapTick()
        napTimerTask = Task { [weak self] in
            while !Task.isCancelled {
                do { try await Task.sleep(for: .seconds(1)) } catch { break }
                guard !Task.isCancelled, let self else { break }
                self.updateNapElapsed()
            }
        }
    }

    private func stopNapTick() {
        napTimerTask?.cancel()
        napTimerTask = nil
    }

    private func updateNapElapsed() {
        guard let start = napStartTime else { return }
        napElapsed = Date.now.timeIntervalSince(start)
    }

    private func startFeedingTick() {
        stopFeedingTick()
        feedingTimerTask = Task { [weak self] in
            while !Task.isCancelled {
                do { try await Task.sleep(for: .seconds(1)) } catch { break }
                guard !Task.isCancelled, let self else { break }
                self.updateFeedingElapsed()
            }
        }
    }

    private func stopFeedingTick() {
        feedingTimerTask?.cancel()
        feedingTimerTask = nil
    }

    private func updateFeedingElapsed() {
        guard let start = feedingStartTime else { return }
        feedingElapsed = Date.now.timeIntervalSince(start)
    }

    private func formatElapsed(_ interval: TimeInterval) -> String {
        let total = Int(interval)
        let hours = total / 3600
        let minutes = (total % 3600) / 60
        let seconds = total % 60
        if hours > 0 { return String(format: "%d:%02d:%02d", hours, minutes, seconds) }
        return String(format: "%02d:%02d", minutes, seconds)
    }
}
