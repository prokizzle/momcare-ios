import Foundation

struct FeedingPattern: Sendable {
    let averageInterval: TimeInterval
    let confidence: Double
    let sampleSize: Int
    let isInsufficient: Bool

    static func insufficient() -> FeedingPattern {
        FeedingPattern(averageInterval: 0, confidence: 0, sampleSize: 0, isInsufficient: true)
    }

    var intervalFormatted: String {
        if isInsufficient { return "Not enough data" }
        let totalMinutes = Int(averageInterval) / 60
        let hours = totalMinutes / 60
        let mins = totalMinutes % 60
        if hours == 0 { return "\(mins) min" }
        if mins == 0 { return "\(hours)h" }
        return "\(hours)h \(mins)m"
    }

    func isFeedingDue(lastFeedTime: Date) -> Bool {
        if isInsufficient { return false }
        let elapsed = Date.now.timeIntervalSince(lastFeedTime)
        return elapsed >= averageInterval * 0.9
    }

    func timeUntilNextFeed(lastFeedTime: Date) -> TimeInterval {
        if isInsufficient { return 0 }
        let elapsed = Date.now.timeIntervalSince(lastFeedTime)
        return max(averageInterval - elapsed, 0)
    }

    func timeUntilNextFeedFormatted(lastFeedTime: Date) -> String {
        let remaining = timeUntilNextFeed(lastFeedTime: lastFeedTime)
        if remaining == 0 { return "Now" }
        let totalMinutes = Int(remaining) / 60
        let hours = totalMinutes / 60
        let mins = totalMinutes % 60
        if hours == 0 { return "in \(mins) min" }
        if mins == 0 { return "in \(hours)h" }
        return "in \(hours)h \(mins)m"
    }
}
