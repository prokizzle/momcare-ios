import Testing
import Foundation
@testable import MomCare

@Suite("SelfCarePatternService Tests")
struct SelfCarePatternServiceTests {

    @Test("Returns empty patterns when no logs")
    func emptyLogs() {
        let patterns = SelfCarePatternService.analyzePatterns(
            logs: [],
            feedingEndTimes: []
        )
        #expect(patterns.isEmpty)
    }

    @Test("Computes averageTimesPerDay for water")
    func averageTimesPerDay() {
        let now = Date.now
        var logs: [SelfCareLog] = []
        // 3 water logs per day for 3 days
        for day in 0..<3 {
            for hour in [8, 12, 18] {
                let timestamp = Calendar.current.date(
                    byAdding: .day, value: -day,
                    to: Calendar.current.date(bySettingHour: hour, minute: 0, second: 0, of: now)!
                )!
                logs.append(SelfCareLog.fixture(actionType: .water, timestamp: timestamp))
            }
        }

        let patterns = SelfCarePatternService.analyzePatterns(logs: logs, feedingEndTimes: [])
        let waterPattern = patterns.first { $0.actionType == .water }
        #expect(waterPattern != nil)
        #expect(waterPattern!.averageTimesPerDay >= 2.5)
        #expect(waterPattern!.averageTimesPerDay <= 3.5)
    }

    @Test("Detects relativeToFeeding pattern")
    func relativeToFeeding() {
        let now = Date.now
        var logs: [SelfCareLog] = []
        var feedingEndTimes: [Date] = []

        // Pattern: she showers ~20 min after each feeding, 5 data points
        for index in 0..<5 {
            let feedingEnd = now.addingTimeInterval(Double(-index) * 10800) // every 3 hours
            feedingEndTimes.append(feedingEnd)
            let showerTime = feedingEnd.addingTimeInterval(1200) // 20 min later
            logs.append(SelfCareLog.fixture(actionType: .shower, timestamp: showerTime))
        }

        let patterns = SelfCarePatternService.analyzePatterns(
            logs: logs,
            feedingEndTimes: feedingEndTimes
        )
        let showerPattern = patterns.first { $0.actionType == .shower }
        #expect(showerPattern != nil)
        #expect(showerPattern!.relativeToFeeding != nil)
        let relativeMinutes = Int(showerPattern!.relativeToFeeding! / 60)
        #expect(relativeMinutes >= 15 && relativeMinutes <= 25)
    }

    @Test("Streak counts consecutive days")
    func streakDays() {
        let now = Date.now
        var logs: [SelfCareLog] = []
        // Skincare every day for 5 days
        for day in 0..<5 {
            let timestamp = Calendar.current.date(byAdding: .day, value: -day, to: now)!
            logs.append(SelfCareLog.fixture(actionType: .skincare, timestamp: timestamp))
        }

        let patterns = SelfCarePatternService.analyzePatterns(logs: logs, feedingEndTimes: [])
        let skincarePattern = patterns.first { $0.actionType == .skincare }
        #expect(skincarePattern != nil)
        #expect(skincarePattern!.streakDays == 5)
    }

    @Test("Confidence is low with few data points")
    func lowConfidence() {
        let logs = [SelfCareLog.fixture(actionType: .meditate)]
        let patterns = SelfCarePatternService.analyzePatterns(logs: logs, feedingEndTimes: [])
        let pattern = patterns.first { $0.actionType == .meditate }
        #expect(pattern != nil)
        #expect(pattern!.confidence <= 0.4)
    }

    @Test("Confidence is high with many consistent data points")
    func highConfidence() {
        let now = Date.now
        var logs: [SelfCareLog] = []
        // Water 6x per day for 14 days = 84 data points
        for day in 0..<14 {
            for hour in [7, 9, 11, 13, 16, 20] {
                let timestamp = Calendar.current.date(
                    byAdding: .day, value: -day,
                    to: Calendar.current.date(bySettingHour: hour, minute: 0, second: 0, of: now)!
                )!
                logs.append(SelfCareLog.fixture(actionType: .water, timestamp: timestamp))
            }
        }

        let patterns = SelfCarePatternService.analyzePatterns(logs: logs, feedingEndTimes: [])
        let waterPattern = patterns.first { $0.actionType == .water }
        #expect(waterPattern != nil)
        #expect(waterPattern!.confidence >= 0.8)
    }

    @Test("Compliance measures percentage of days with at least one log")
    func compliance() {
        let now = Date.now
        var logs: [SelfCareLog] = []
        // Skincare on 5 of the last 7 days
        for day in [0, 1, 2, 4, 6] {
            let timestamp = Calendar.current.date(byAdding: .day, value: -day, to: now)!
            logs.append(SelfCareLog.fixture(actionType: .skincare, timestamp: timestamp))
        }

        let patterns = SelfCarePatternService.analyzePatterns(logs: logs, feedingEndTimes: [])
        let skincarePattern = patterns.first { $0.actionType == .skincare }
        #expect(skincarePattern != nil)
        #expect(skincarePattern!.compliance >= 0.6)
        #expect(skincarePattern!.compliance <= 0.8)
    }
}
