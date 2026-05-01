import Testing
import Foundation
@testable import MomCare

@Suite("FeedingPatternService Tests")
struct FeedingPatternServiceTests {

    @Test("Returns insufficient when fewer than 3 feedings")
    func insufficientData() {
        let feedings = [Feeding.fixture(), Feeding.fixture()]
        let result = FeedingPatternService.analyzePattern(from: feedings)
        #expect(result.isInsufficient == true)
    }

    @Test("Returns insufficient when no valid intervals")
    func noValidIntervals() {
        let now = Date.now
        let feedings = (0..<5).map { idx in
            let offset = TimeInterval(idx) * -600
            return Feeding.fixture(
                startTime: now.addingTimeInterval(offset),
                endTime: now.addingTimeInterval(offset + 300)
            )
        }
        let result = FeedingPatternService.analyzePattern(from: feedings)
        #expect(result.isInsufficient == true)
    }

    @Test("Calculates average interval correctly")
    func averageInterval() {
        let now = Date.now
        let feedings = (0..<4).map { idx in
            let offset = TimeInterval(idx) * -7200
            return Feeding.fixture(
                startTime: now.addingTimeInterval(offset),
                endTime: now.addingTimeInterval(offset + 1200)
            )
        }
        let result = FeedingPatternService.analyzePattern(from: feedings)
        #expect(result.isInsufficient == false)
        let avgMinutes = Int(result.averageInterval) / 60
        #expect(avgMinutes == 100)
    }

    @Test("Filters intervals outside 30-480 minute range")
    func filtersUnreasonableIntervals() {
        let now = Date.now
        let feedings = [
            Feeding.fixture(startTime: now, endTime: now.addingTimeInterval(600)),
            Feeding.fixture(
                startTime: now.addingTimeInterval(-7800),
                endTime: now.addingTimeInterval(-7200)
            ),
            Feeding.fixture(
                startTime: now.addingTimeInterval(-8400),
                endTime: now.addingTimeInterval(-7900)
            ),
            Feeding.fixture(
                startTime: now.addingTimeInterval(-44400),
                endTime: now.addingTimeInterval(-44100)
            )
        ]
        let result = FeedingPatternService.analyzePattern(from: feedings)
        #expect(result.sampleSize == 4)
    }

    @Test("High confidence for consistent intervals with large sample")
    func highConfidence() {
        let now = Date.now
        let feedings = (0..<25).map { idx in
            let offset = TimeInterval(idx) * -9000
            return Feeding.fixture(
                startTime: now.addingTimeInterval(offset),
                endTime: now.addingTimeInterval(offset + 1200)
            )
        }
        let result = FeedingPatternService.analyzePattern(from: feedings)
        #expect(result.confidence >= 0.8)
    }

    @Test("Low confidence for small inconsistent sample")
    func lowConfidence() {
        let now = Date.now
        let feedings = [
            Feeding.fixture(startTime: now, endTime: now.addingTimeInterval(600)),
            Feeding.fixture(
                startTime: now.addingTimeInterval(-3600),
                endTime: now.addingTimeInterval(-3000)
            ),
            Feeding.fixture(
                startTime: now.addingTimeInterval(-18000),
                endTime: now.addingTimeInterval(-17400)
            )
        ]
        let result = FeedingPatternService.analyzePattern(from: feedings)
        #expect(result.confidence <= 0.6)
    }

    @Test("Uses endTime when available for interval calculation")
    func usesEndTime() {
        let now = Date.now
        let feedings = [
            Feeding.fixture(
                startTime: now.addingTimeInterval(-3600),
                endTime: now.addingTimeInterval(-3000)
            ),
            Feeding.fixture(
                startTime: now.addingTimeInterval(-7200),
                endTime: now.addingTimeInterval(-6000)
            ),
            Feeding.fixture(
                startTime: now.addingTimeInterval(-10800),
                endTime: now.addingTimeInterval(-9600)
            )
        ]
        let result = FeedingPatternService.analyzePattern(from: feedings)
        #expect(result.isInsufficient == false)
    }

    @Test("formatTimeSince returns correct strings")
    func formatTimeSince() {
        #expect(FeedingPatternService.formatTimeSince(nil) == "No feedings yet")
        #expect(FeedingPatternService.formatTimeSince(2700) == "45 min ago")
        #expect(FeedingPatternService.formatTimeSince(3600) == "1h ago")
        #expect(FeedingPatternService.formatTimeSince(8100) == "2h 15m ago")
    }
}
