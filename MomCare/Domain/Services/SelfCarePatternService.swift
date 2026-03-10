import Foundation

enum SelfCarePatternService {
    static let analysisDays = 14
    private static let minDataPointsForRelativePattern = 3
    private static let maxRelativeToFeedingMinutes = 120
    private static let relativeToFeedingVarianceThreshold = 0.5

    static func analyzePatterns(
        logs: [SelfCareLog],
        feedingEndTimes: [Date],
        now: Date = .now
    ) -> [ActionPattern] {
        let calendar = Calendar.current
        guard let analysisStart = calendar.date(byAdding: .day, value: -analysisDays, to: now) else {
            return []
        }
        let recentLogs = logs.filter { $0.timestamp >= analysisStart && $0.timestamp <= now }

        let grouped = Dictionary(grouping: recentLogs) { $0.actionType }

        return grouped.map { actionType, actionLogs in
            analyzeAction(
                actionType: actionType,
                logs: actionLogs,
                feedingEndTimes: feedingEndTimes,
                analysisDayCount: analysisDays,
                calendar: calendar,
                now: now
            )
        }
    }

    // swiftlint:disable:next function_parameter_count
    private static func analyzeAction(
        actionType: SelfCareActionType,
        logs: [SelfCareLog],
        feedingEndTimes: [Date],
        analysisDayCount: Int,
        calendar: Calendar,
        now: Date
    ) -> ActionPattern {
        let sortedLogs = logs.sorted { $0.timestamp > $1.timestamp }

        // Compute unique days once — reused for average, streak, and compliance
        let uniqueDays = Set(sortedLogs.lazy.map { calendar.startOfDay(for: $0.timestamp) })

        // Average times per day
        let activeDays = max(uniqueDays.count, 1)
        let averageTimesPerDay = Double(sortedLogs.count) / Double(min(activeDays, analysisDayCount))

        // Streak
        let streakDays = calculateStreak(uniqueDays: uniqueDays, calendar: calendar, now: now)
        let earliestDay = uniqueDays.min() ?? calendar.startOfDay(for: now)
        let spanDays = max(
            calendar.dateComponents([.day], from: earliestDay, to: calendar.startOfDay(for: now)).day ?? 0,
            0
        ) + 1
        let totalDays = min(spanDays, analysisDayCount)
        let compliance = Double(uniqueDays.count) / Double(max(totalDays, 1))

        // Relative to feeding
        let relativeToFeeding = detectRelativeToFeeding(
            logs: sortedLogs,
            feedingEndTimes: feedingEndTimes
        )

        // Time clusters (simplified: group by hour)
        let typicalTimestamps = detectTimeClusters(logs: sortedLogs, calendar: calendar, now: now)

        // Confidence
        let confidence = calculateConfidence(
            sampleSize: sortedLogs.count,
            daysOfData: uniqueDays.count,
            hasRelativePattern: relativeToFeeding != nil
        )

        return ActionPattern(
            actionType: actionType,
            averageTimesPerDay: averageTimesPerDay,
            typicalTimestamps: typicalTimestamps,
            relativeToFeeding: relativeToFeeding,
            streakDays: streakDays,
            compliance: compliance,
            confidence: confidence
        )
    }

    private static func calculateStreak(
        uniqueDays: Set<Date>,
        calendar: Calendar,
        now: Date
    ) -> Int {
        var streak = 0
        var checkDate = calendar.startOfDay(for: now)

        for _ in 0..<365 {
            if uniqueDays.contains(checkDate) {
                streak += 1
                guard let prevDay = calendar.date(byAdding: .day, value: -1, to: checkDate) else {
                    break
                }
                checkDate = prevDay
            } else {
                break
            }
        }
        return streak
    }

    private static func detectRelativeToFeeding(
        logs: [SelfCareLog],
        feedingEndTimes: [Date]
    ) -> TimeInterval? {
        guard logs.count >= minDataPointsForRelativePattern,
              !feedingEndTimes.isEmpty else { return nil }

        let sortedFeedingEnds = feedingEndTimes.sorted()

        var offsets: [TimeInterval] = []
        for log in logs {
            // Binary search for the closest feeding end BEFORE this log
            let idx = binarySearchLastLE(sortedFeedingEnds, target: log.timestamp)
            if let idx {
                let offset = log.timestamp.timeIntervalSince(sortedFeedingEnds[idx])
                let offsetMinutes = offset / 60
                if offsetMinutes > 0 && offsetMinutes <= Double(maxRelativeToFeedingMinutes) {
                    offsets.append(offset)
                }
            }
        }

        guard offsets.count >= minDataPointsForRelativePattern else { return nil }

        let avg = offsets.reduce(0, +) / Double(offsets.count)
        let variance = offsets.reduce(0.0) { acc, offset in
            let diff = offset - avg
            return acc + diff * diff
        } / Double(offsets.count)
        let stdDev = variance.squareRoot()
        let coefficientOfVariation = avg > 0 ? stdDev / avg : 1.0

        guard coefficientOfVariation < relativeToFeedingVarianceThreshold else { return nil }

        return avg
    }

    private static func detectTimeClusters(
        logs: [SelfCareLog],
        calendar: Calendar,
        now: Date
    ) -> [DateInterval] {
        let hourGroups = Dictionary(grouping: logs) { calendar.component(.hour, from: $0.timestamp) }

        return hourGroups
            .filter { $0.value.count >= 2 }
            .sorted { $0.key < $1.key }
            .compactMap { hour, _ -> DateInterval? in
                guard let start = calendar.date(bySettingHour: hour, minute: 0, second: 0, of: now),
                      let end = calendar.date(bySettingHour: hour, minute: 59, second: 59, of: now) else {
                    return nil
                }
                return DateInterval(start: start, end: end)
            }
    }

    private static func calculateConfidence(
        sampleSize: Int,
        daysOfData: Int,
        hasRelativePattern: Bool
    ) -> Double {
        let sizeScore: Double = switch sampleSize {
        case 30...: 0.9
        case 15...: 0.7
        case 5...: 0.5
        default: 0.3
        }

        let daysScore: Double = switch daysOfData {
        case 10...: 0.9
        case 5...: 0.6
        default: 0.3
        }

        let relativeBonus: Double = hasRelativePattern ? 0.1 : 0.0

        return min(sizeScore * 0.5 + daysScore * 0.5 + relativeBonus, 1.0)
    }

    private static func binarySearchLastLE(_ dates: [Date], target: Date) -> Int? {
        var low = 0
        var high = dates.count - 1
        var result: Int?
        while low <= high {
            let mid = low + (high - low) / 2
            if dates[mid] <= target {
                result = mid
                low = mid + 1
            } else {
                high = mid - 1
            }
        }
        return result
    }
}
