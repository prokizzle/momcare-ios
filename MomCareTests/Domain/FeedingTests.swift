import Testing
import Foundation
@testable import MomCare

@Suite("Feeding Entity Tests")
struct FeedingTests {

    @Test("isInProgress returns true when endTime is nil")
    func isInProgressTrue() {
        let feeding = Feeding.fixture(endTime: nil)
        #expect(feeding.isInProgress == true)
    }

    @Test("isInProgress returns false when endTime is set")
    func isInProgressFalse() {
        let feeding = Feeding.fixture(endTime: .now)
        #expect(feeding.isInProgress == false)
    }

    @Test("duration returns correct interval when endTime is set")
    func durationWithEndTime() {
        let start = Date.now
        let end = start.addingTimeInterval(1800) // 30 minutes
        let feeding = Feeding.fixture(startTime: start, endTime: end)
        #expect(feeding.duration == 1800)
    }

    @Test("duration returns 0 when in progress")
    func durationInProgress() {
        let feeding = Feeding.fixture(endTime: nil)
        #expect(feeding.duration == 0)
    }

    @Test("durationFormatted shows minutes for under 1 hour")
    func durationFormattedMinutes() {
        let start = Date.now
        let end = start.addingTimeInterval(25 * 60) // 25 minutes
        let feeding = Feeding.fixture(startTime: start, endTime: end)
        #expect(feeding.durationFormatted == "25 min")
    }

    @Test("durationFormatted shows hours and minutes for over 1 hour")
    func durationFormattedHoursAndMinutes() {
        let start = Date.now
        let end = start.addingTimeInterval(90 * 60) // 1h 30m
        let feeding = Feeding.fixture(startTime: start, endTime: end)
        #expect(feeding.durationFormatted == "1h 30m")
    }

    @Test("Feeding round-trips through JSON")
    func codableRoundTrip() throws {
        let original = Feeding.fixture(
            endTime: Date.now.addingTimeInterval(600),
            bottleContent: .formula,
            notes: "Test note"
        )
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(Feeding.self, from: data)
        #expect(decoded.id == original.id)
        #expect(decoded.babyId == original.babyId)
        #expect(decoded.feedingType == original.feedingType)
        #expect(decoded.quality == original.quality)
        #expect(decoded.notes == original.notes)
    }

    @Test("FeedingType round-trips through JSON")
    func feedingTypeCodable() throws {
        for type in Feeding.FeedingType.allCases {
            let data = try JSONEncoder().encode(type)
            let decoded = try JSONDecoder().decode(Feeding.FeedingType.self, from: data)
            #expect(decoded == type)
        }
    }

    @Test("BreastSide round-trips through JSON")
    func breastSideCodable() throws {
        for side in Feeding.BreastSide.allCases {
            let data = try JSONEncoder().encode(side)
            let decoded = try JSONDecoder().decode(Feeding.BreastSide.self, from: data)
            #expect(decoded == side)
        }
    }

    @Test("BottleContent round-trips through JSON")
    func bottleContentCodable() throws {
        for content in Feeding.BottleContent.allCases {
            let data = try JSONEncoder().encode(content)
            let decoded = try JSONDecoder().decode(Feeding.BottleContent.self, from: data)
            #expect(decoded == content)
        }
    }

    @Test("FeedingQuality round-trips through JSON")
    func feedingQualityCodable() throws {
        for quality in Feeding.FeedingQuality.allCases {
            let data = try JSONEncoder().encode(quality)
            let decoded = try JSONDecoder().decode(Feeding.FeedingQuality.self, from: data)
            #expect(decoded == quality)
        }
    }
}
