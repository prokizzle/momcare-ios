import Testing
import Foundation
@testable import MomCare

@Suite("SelfCarePatternService Tests")
struct SelfCarePatternServiceTests {

    // Fixed reference date for deterministic tests
    private let referenceDate = Calendar.current.date(
        from: DateComponents(year: 2026, month: 3, day: 10, hour: 12)
    )!

    @Test("Returns empty patterns when no logs")
    func emptyLogs() {
        let patterns = SelfCarePatternService.analyzePatterns(
            logs: [],
            feedingEndTimes: [],
            now: referenceDate
        )
        #expect(patterns.isEmpty)
    }

    @Test("Computes averageTimesPerDay for water")
    func averageTimesPerDay() throws {
        var logs: [SelfCareLog] = []
        // 3 water logs per day for 3 days
        for day in 0..<3 {
            for hour in [8, 12, 18] {
                let timestamp = Calendar.current.date(
                    byAdding: .day, value: -day,
                    to: Calendar.current.date(
                        bySettingHour: hour, minute: 0, second: 0, of: referenceDate
                    )!
                )!
                logs.append(SelfCareLog.fixture(actionType: .water, timestamp: timestamp))
            }
        }

        let patterns = SelfCarePatternService.analyzePatterns(
            logs: logs, feedingEndTimes: [], now: referenceDate
        )
        let waterPattern = try #require(patterns.first { $0.actionType == .water })
        #expect(waterPattern.averageTimesPerDay >= 2.5)
        #expect(waterPattern.averageTimesPerDay <= 3.5)
    }

    @Test("Detects relativeToFeeding pattern")
    func relativeToFeeding() throws {
        var logs: [SelfCareLog] = []
        var feedingEndTimes: [Date] = []

        // Pattern: she showers ~20 min after each feeding, 5 data points
        for index in 0..<5 {
            let feedingEnd = referenceDate.addingTimeInterval(Double(-index) * 10800)
            feedingEndTimes.append(feedingEnd)
            let showerTime = feedingEnd.addingTimeInterval(1200) // 20 min later
            logs.append(SelfCareLog.fixture(actionType: .shower, timestamp: showerTime))
        }

        let patterns = SelfCarePatternService.analyzePatterns(
            logs: logs,
            feedingEndTimes: feedingEndTimes,
            now: referenceDate
        )
        let showerPattern = try #require(patterns.first { $0.actionType == .shower })
        let relativeToFeeding = try #require(showerPattern.relativeToFeeding)
        let relativeMinutes = Int(relativeToFeeding / 60)
        #expect(relativeMinutes >= 15 && relativeMinutes <= 25)
    }

    @Test("Streak counts consecutive days")
    func streakDays() throws {
        var logs: [SelfCareLog] = []
        // Skincare every day for 5 days
        for day in 0..<5 {
            let timestamp = Calendar.current.date(
                byAdding: .day, value: -day, to: referenceDate
            )!
            logs.append(SelfCareLog.fixture(actionType: .skincare, timestamp: timestamp))
        }

        let patterns = SelfCarePatternService.analyzePatterns(
            logs: logs, feedingEndTimes: [], now: referenceDate
        )
        let skincarePattern = try #require(patterns.first { $0.actionType == .skincare })
        #expect(skincarePattern.streakDays == 5)
    }

    @Test("Confidence is low with few data points")
    func lowConfidence() throws {
        let timestamp = referenceDate.addingTimeInterval(-3600)
        let logs = [SelfCareLog.fixture(actionType: .meditate, timestamp: timestamp)]
        let patterns = SelfCarePatternService.analyzePatterns(
            logs: logs, feedingEndTimes: [], now: referenceDate
        )
        let pattern = try #require(patterns.first { $0.actionType == .meditate })
        #expect(pattern.confidence <= 0.4)
    }

    @Test("Confidence is high with many consistent data points")
    func highConfidence() throws {
        var logs: [SelfCareLog] = []
        // Water 6x per day for 14 days = 84 data points
        for day in 0..<14 {
            for hour in [7, 9, 11, 13, 16, 20] {
                let timestamp = Calendar.current.date(
                    byAdding: .day, value: -day,
                    to: Calendar.current.date(
                        bySettingHour: hour, minute: 0, second: 0, of: referenceDate
                    )!
                )!
                logs.append(SelfCareLog.fixture(actionType: .water, timestamp: timestamp))
            }
        }

        let patterns = SelfCarePatternService.analyzePatterns(
            logs: logs, feedingEndTimes: [], now: referenceDate
        )
        let waterPattern = try #require(patterns.first { $0.actionType == .water })
        #expect(waterPattern.confidence >= 0.8)
    }

    @Test("Compliance measures percentage of days with at least one log")
    func compliance() throws {
        var logs: [SelfCareLog] = []
        // Skincare on 5 of the last 7 days
        for day in [0, 1, 2, 4, 6] {
            let timestamp = Calendar.current.date(
                byAdding: .day, value: -day, to: referenceDate
            )!
            logs.append(SelfCareLog.fixture(actionType: .skincare, timestamp: timestamp))
        }

        let patterns = SelfCarePatternService.analyzePatterns(
            logs: logs, feedingEndTimes: [], now: referenceDate
        )
        let skincarePattern = try #require(patterns.first { $0.actionType == .skincare })
        #expect(skincarePattern.compliance >= 0.6)
        #expect(skincarePattern.compliance <= 0.8)
    }
}
