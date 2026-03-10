import Testing
import Foundation
@testable import MomCare

@Suite("SelfCareLog Tests")
struct SelfCareLogTests {

    @Test("SelfCareActionType has all expected cases")
    func actionTypeCases() {
        let allCases = SelfCareActionType.allCases
        #expect(allCases.count == 9)
        #expect(allCases.contains(.shower))
        #expect(allCases.contains(.brushTeeth))
        #expect(allCases.contains(.changeClothes))
        #expect(allCases.contains(.shave))
        #expect(allCases.contains(.skincare))
        #expect(allCases.contains(.meditate))
        #expect(allCases.contains(.breathingExercise))
        #expect(allCases.contains(.water))
        #expect(allCases.contains(.meal))
    }

    @Test("SelfCareActionType provides label and systemImage")
    func actionTypeDisplay() {
        #expect(SelfCareActionType.shower.label == "Shower")
        #expect(!SelfCareActionType.shower.systemImage.isEmpty)
        #expect(SelfCareActionType.water.label == "Water")
        #expect(!SelfCareActionType.water.systemImage.isEmpty)
    }

    @Test("LogDetail water case round-trips through Codable")
    func logDetailWaterCodable() throws {
        let detail = LogDetail.water(glasses: 3)
        let data = try JSONEncoder().encode(detail)
        let decoded = try JSONDecoder().decode(LogDetail.self, from: data)
        if case .water(let glasses) = decoded {
            #expect(glasses == 3)
        } else {
            Issue.record("Expected water case")
        }
    }

    @Test("LogDetail meal case round-trips through Codable")
    func logDetailMealCodable() throws {
        let detail = LogDetail.meal(.breakfast)
        let data = try JSONEncoder().encode(detail)
        let decoded = try JSONDecoder().decode(LogDetail.self, from: data)
        if case .meal(let mealType) = decoded {
            #expect(mealType == .breakfast)
        } else {
            Issue.record("Expected meal case")
        }
    }

    @Test("LogDetail freeNote case round-trips through Codable")
    func logDetailFreeNoteCodable() throws {
        let detail = LogDetail.freeNote("Felt good")
        let data = try JSONEncoder().encode(detail)
        let decoded = try JSONDecoder().decode(LogDetail.self, from: data)
        if case .freeNote(let text) = decoded {
            #expect(text == "Felt good")
        } else {
            Issue.record("Expected freeNote case")
        }
    }

    @Test("SelfCareLog fixture creates valid default")
    func fixtureDefault() {
        let log = SelfCareLog.fixture()
        #expect(log.actionType == .water)
        #expect(log.detail == nil)
    }

    @Test("MealType has all four cases")
    func mealTypeCases() {
        let allCases = MealType.allCases
        #expect(allCases.count == 4)
        #expect(allCases.contains(.breakfast))
        #expect(allCases.contains(.lunch))
        #expect(allCases.contains(.dinner))
        #expect(allCases.contains(.snack))
    }
}
