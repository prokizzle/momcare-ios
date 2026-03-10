import Foundation

enum FeedingPatternService {
    static let minFeedingsForPattern = 3
    static let patternAnalysisDays = 7
    private static let minIntervalMinutes = 30
    private static let maxIntervalMinutes = 480

    static func analyzePattern(from feedings: [Feeding]) -> FeedingPattern {
        guard feedings.count >= minFeedingsForPattern else {
            return .insufficient()
        }

        var intervals: [Int] = []
        for idx in 0..<(feedings.count - 1) {
            let current = feedings[idx]
            let next = feedings[idx + 1]

            // Feedings are sorted newest-first; gap = newer.startTime - older.endTime
            let newerStart = current.startTime
            let olderEnd = next.endTime ?? next.startTime

            let intervalMinutes = Int(newerStart.timeIntervalSince(olderEnd)) / 60

            if intervalMinutes >= minIntervalMinutes && intervalMinutes <= maxIntervalMinutes {
                intervals.append(intervalMinutes)
            }
        }

        guard !intervals.isEmpty else {
            return .insufficient()
        }

        let totalMinutes = intervals.reduce(0, +)
        let avgMinutes = totalMinutes / intervals.count
        let confidence = calculateConfidence(
            intervals: intervals, totalMinutes: totalMinutes, sampleSize: feedings.count
        )

        return FeedingPattern(
            averageInterval: TimeInterval(avgMinutes * 60),
            confidence: confidence,
            sampleSize: feedings.count,
            isInsufficient: false
        )
    }

    private static func calculateConfidence(intervals: [Int], totalMinutes: Int, sampleSize: Int) -> Double {
        guard !intervals.isEmpty else { return 0 }

        let sizeConfidence: Double
        if sampleSize >= 20 {
            sizeConfidence = 0.9
        } else if sampleSize >= 10 {
            sizeConfidence = 0.7
        } else if sampleSize >= 5 {
            sizeConfidence = 0.5
        } else {
            sizeConfidence = 0.3
        }

        let avg = Double(totalMinutes) / Double(intervals.count)
        let variance = intervals
            .map { (Double($0) - avg) * (Double($0) - avg) }
            .reduce(0, +) / Double(intervals.count)
        let stdDev = variance.squareRoot()
        let coefficientOfVariation = avg > 0 ? stdDev / avg : 0

        let consistencyConfidence: Double
        if coefficientOfVariation < 0.2 {
            consistencyConfidence = 1.0
        } else if coefficientOfVariation < 0.4 {
            consistencyConfidence = 0.8
        } else if coefficientOfVariation < 0.6 {
            consistencyConfidence = 0.6
        } else {
            consistencyConfidence = 0.4
        }

        return min(max(sizeConfidence * 0.4 + consistencyConfidence * 0.6, 0.0), 1.0)
    }

    static func formatTimeSince(_ seconds: TimeInterval?) -> String {
        guard let seconds else { return "No feedings yet" }
        let hours = Int(seconds) / 3600
        let mins = (Int(seconds) % 3600) / 60
        if hours == 0 { return "\(mins) min ago" }
        if mins == 0 { return "\(hours)h ago" }
        return "\(hours)h \(mins)m ago"
    }
}
