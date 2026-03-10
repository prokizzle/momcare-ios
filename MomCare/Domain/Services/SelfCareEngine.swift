import Foundation

enum SelfCareEvent: Sendable {
    case feedingEnded(babyId: UUID, duration: TimeInterval)
    case feedingStarted(babyId: UUID)
    case selfCareLogged(SelfCareLog)
    case appOpened
    case timeTick
}

struct SelfCareEngine: Sendable {
    let logs: [SelfCareLog]
    let patterns: [ActionPattern]
    let contentLibrary: ContentLibrary
    let shownContentIds: Set<String>
    let currentDate: Date

    // Pre-computed derived state (avoids repeated O(n) scans per event)
    private let lastWaterTimestamp: Date?
    private let todayLogCount: Int

    private static let scoreThreshold = 0.2
    private static let hydrationGapSeconds: TimeInterval = 7200
    private static let minStreakForCard = 3

    init(
        logs: [SelfCareLog],
        patterns: [ActionPattern],
        contentLibrary: ContentLibrary,
        shownContentIds: Set<String>,
        currentDate: Date
    ) {
        self.logs = logs
        self.patterns = patterns
        self.contentLibrary = contentLibrary
        self.shownContentIds = shownContentIds
        self.currentDate = currentDate

        self.lastWaterTimestamp = logs
            .lazy
            .filter { $0.actionType == .water }
            .map(\.timestamp)
            .max()

        let calendar = Calendar.current
        self.todayLogCount = logs.filter {
            calendar.isDate($0.timestamp, inSameDayAs: currentDate)
        }.count
    }

    func scoreCards(after event: SelfCareEvent) -> [SelfCareCard] {
        var candidates: [SelfCareCard] = []
        candidates.reserveCapacity(7)
        candidates.append(contentsOf: scoreSelfCareWindow(event: event))
        candidates.append(contentsOf: scoreHydrationNudge())
        candidates.append(contentsOf: scoreAffirmation(event: event))
        candidates.append(contentsOf: scorePepTalk())
        candidates.append(contentsOf: scoreCheckIn())
        candidates.append(contentsOf: scoreStreaks())
        candidates.append(contentsOf: scorePatternNudges(event: event))

        return candidates
            .filter { $0.score >= Self.scoreThreshold }
            .sorted { $0.score > $1.score }
    }

    // MARK: - Scorers

    private func scoreSelfCareWindow(event: SelfCareEvent) -> [SelfCareCard] {
        guard case .feedingEnded = event else { return [] }

        let windowTemplates = contentLibrary.nudgeTemplates.filter {
            $0.type == .selfCareWindow
        }
        let message = rotateContent(windowTemplates, idKeyPath: \.id)?
            .render(substitutions: [:])
            ?? "You have a moment. What do you need?"

        return [
            SelfCareCard(
                id: UUID(),
                type: .selfCareWindow,
                message: message,
                score: 0.9,
                relatedAction: nil,
                timestamp: currentDate
            )
        ]
    }

    private func scoreHydrationNudge() -> [SelfCareCard] {
        let gap: TimeInterval
        if let lastWaterTimestamp {
            gap = currentDate.timeIntervalSince(lastWaterTimestamp)
        } else {
            gap = Self.hydrationGapSeconds + 1
        }

        guard gap >= Self.hydrationGapSeconds else { return [] }

        let hours = gap / 3600.0
        let score = min(0.3 + hours * 0.1, 0.8)

        let hydrationTemplates = contentLibrary.nudgeTemplates.filter {
            $0.type == .hydration
        }
        let message = rotateContent(hydrationTemplates, idKeyPath: \.id)?
            .render(substitutions: ["hours": "\(Int(hours))"])
            ?? "Staying hydrated helps you keep going."

        return [
            SelfCareCard(
                id: UUID(),
                type: .hydrationNudge,
                message: message,
                score: score,
                relatedAction: .water,
                timestamp: currentDate
            )
        ]
    }

    private func scoreAffirmation(event: SelfCareEvent) -> [SelfCareCard] {
        guard let affirmation = rotateContent(
            contentLibrary.affirmations,
            idKeyPath: \.id
        ) else { return [] }

        let score: Double
        switch event {
        case .appOpened:
            score = 0.6
        case .feedingEnded:
            score = 0.4
        default:
            score = 0.3
        }

        return [
            SelfCareCard(
                id: UUID(),
                type: .affirmation,
                message: affirmation.text,
                score: score,
                relatedAction: nil,
                timestamp: currentDate
            )
        ]
    }

    private func scorePepTalk() -> [SelfCareCard] {
        guard todayLogCount <= 2 else { return [] }

        guard let pepTalk = rotateContent(
            contentLibrary.pepTalks,
            idKeyPath: \.id
        ) else { return [] }

        return [
            SelfCareCard(
                id: UUID(),
                type: .pepTalk,
                message: pepTalk.text,
                score: 0.35,
                relatedAction: nil,
                timestamp: currentDate
            )
        ]
    }

    private func scoreCheckIn() -> [SelfCareCard] {
        guard let prompt = rotateContent(
            contentLibrary.checkInPrompts,
            idKeyPath: \.id
        ) else { return [] }

        return [
            SelfCareCard(
                id: UUID(),
                type: .checkIn,
                message: prompt.text,
                score: 0.25,
                relatedAction: nil,
                timestamp: currentDate
            )
        ]
    }

    private func scoreStreaks() -> [SelfCareCard] {
        let streakTemplates = contentLibrary.nudgeTemplates.filter {
            $0.type == .streak
        }

        return patterns
            .filter { $0.streakDays >= Self.minStreakForCard }
            .map { pattern in
                let score = 0.5 + min(Double(pattern.streakDays) * 0.05, 0.3)
                let message = rotateContent(streakTemplates, idKeyPath: \.id)?
                    .render(substitutions: [
                        "count": "\(pattern.streakDays)",
                        "action": pattern.actionType.label
                    ])
                    ?? "\(pattern.streakDays) days of \(pattern.actionType.label) -- look at you."
                return SelfCareCard(
                    id: UUID(),
                    type: .streak,
                    message: message,
                    score: score,
                    relatedAction: pattern.actionType,
                    timestamp: currentDate
                )
            }
    }

    private func scorePatternNudges(event: SelfCareEvent) -> [SelfCareCard] {
        guard case .feedingEnded = event else { return [] }

        let relevantPatterns = patterns.filter {
            $0.relativeToFeeding != nil && $0.confidence >= 0.5
        }
        guard !relevantPatterns.isEmpty else { return [] }

        let nudgeTemplates = contentLibrary.nudgeTemplates.filter {
            $0.type == .patternDeviation
        }
        guard let template = rotateContent(nudgeTemplates, idKeyPath: \.id) else {
            return []
        }

        return relevantPatterns.map { pattern in
            let message = template.render(substitutions: [
                "action": pattern.actionType.label
            ])
            let score = 0.9 * pattern.confidence
            return SelfCareCard(
                id: UUID(),
                type: .gentleNudge,
                message: message,
                score: score,
                relatedAction: pattern.actionType,
                timestamp: currentDate
            )
        }
    }

    // MARK: - Helpers

    private func rotateContent<T>(
        _ items: [T],
        idKeyPath: KeyPath<T, String>
    ) -> T? {
        guard !items.isEmpty else { return nil }
        return items.lazy.first { !shownContentIds.contains($0[keyPath: idKeyPath]) }
            ?? items.first
    }
}
