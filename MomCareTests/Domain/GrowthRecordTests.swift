import Testing
import Foundation
@testable import MomCare

@Suite("GrowthRecord")
struct GrowthRecordTests {

    @Test("Create record with all measurements")
    func createWithAllMeasurements() {
        let babyId = UUID()
        let record = GrowthRecord.fixture(
            babyId: babyId,
            weightGrams: 5200,
            lengthCm: 58.5,
            headCircumferenceCm: 38.2
        )

        #expect(record.babyId == babyId)
        #expect(record.weightGrams == 5200)
        #expect(record.lengthCm == 58.5)
        #expect(record.headCircumferenceCm == 38.2)
        #expect(!record.isDeleted)
    }

    @Test("Create record with partial measurements")
    func createWithPartialMeasurements() {
        let record = GrowthRecord.fixture(weightGrams: 5200)
        #expect(record.weightGrams == 5200)
        #expect(record.lengthCm == nil)
        #expect(record.headCircumferenceCm == nil)
    }

    @Test("Weight formatted respects locale")
    func weightFormatted() {
        let record = GrowthRecord.fixture(weightGrams: 5200)
        let formatted = record.weightFormatted
        #expect(!formatted.isEmpty)
    }

    @Test("Length formatted respects locale")
    func lengthFormatted() {
        let record = GrowthRecord.fixture(lengthCm: 58.5)
        let formatted = record.lengthFormatted
        #expect(!formatted.isEmpty)
    }

    @Test("Age in months at measurement")
    func ageAtMeasurement() {
        let dob = Calendar.current.date(byAdding: .month, value: -3, to: .now)!
        let record = GrowthRecord.fixture(date: .now)
        let ageMonths = record.ageInMonths(dateOfBirth: dob)
        #expect(ageMonths == 3)
    }
}
