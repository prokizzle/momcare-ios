import Testing
import Foundation
@testable import MomCare

@Suite("Baby Entity Tests")
struct BabyTests {

    @Test("ageInDays returns correct value")
    func ageInDays() {
        let baby = Baby.fixture(dateOfBirth: Calendar.current.date(byAdding: .day, value: -5, to: .now)!)
        #expect(baby.ageInDays == 5)
    }

    @Test("ageInWeeks returns correct value")
    func ageInWeeks() {
        let baby = Baby.fixture(dateOfBirth: Calendar.current.date(byAdding: .day, value: -14, to: .now)!)
        #expect(baby.ageInWeeks == 2)
    }

    @Test("ageInMonths returns correct value")
    func ageInMonths() {
        let baby = Baby.fixture(dateOfBirth: Calendar.current.date(byAdding: .month, value: -4, to: .now)!)
        #expect(baby.ageInMonths == 4)
    }

    @Test("ageString shows days for under 2 weeks", arguments: [
        (1, "1 day"),
        (3, "3 days"),
        (13, "13 days")
    ])
    func ageStringDays(daysAgo: Int, expected: String) {
        let baby = Baby.fixture(dateOfBirth: Calendar.current.date(byAdding: .day, value: -daysAgo, to: .now)!)
        #expect(baby.ageString == expected)
    }

    @Test("ageString shows weeks for 2 weeks to 2 months", arguments: [
        (14, "2 weeks"),
        (21, "3 weeks"),
        (49, "7 weeks")
    ])
    func ageStringWeeks(daysAgo: Int, expected: String) {
        let baby = Baby.fixture(dateOfBirth: Calendar.current.date(byAdding: .day, value: -daysAgo, to: .now)!)
        #expect(baby.ageString == expected)
    }

    @Test("ageString shows months for 2+ months")
    func ageStringMonths() {
        let baby = Baby.fixture(dateOfBirth: Calendar.current.date(byAdding: .month, value: -4, to: .now)!)
        #expect(baby.ageString == "4 months")
    }

    @Test("Baby round-trips through JSON")
    func codableRoundTrip() throws {
        let original = Baby.fixture()
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(Baby.self, from: data)
        #expect(decoded.id == original.id)
        #expect(decoded.name == original.name)
        #expect(decoded.biologicalSex == original.biologicalSex)
        #expect(decoded.feedingMethod == original.feedingMethod)
    }

    @Test("BiologicalSex round-trips through JSON")
    func biologicalSexCodable() throws {
        for sex in Baby.BiologicalSex.allCases {
            let data = try JSONEncoder().encode(sex)
            let decoded = try JSONDecoder().decode(Baby.BiologicalSex.self, from: data)
            #expect(decoded == sex)
        }
    }

    @Test("FeedingMethod round-trips through JSON")
    func feedingMethodCodable() throws {
        for method in Baby.FeedingMethod.allCases {
            let data = try JSONEncoder().encode(method)
            let decoded = try JSONDecoder().decode(Baby.FeedingMethod.self, from: data)
            #expect(decoded == method)
        }
    }
}
