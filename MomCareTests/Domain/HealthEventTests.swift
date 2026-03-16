import Testing
import Foundation
@testable import MomCare

@Suite("HealthEvent entity")
struct HealthEventTests {

    @Test("Creates with required fields")
    func creation() {
        let event = HealthEvent.fixture()
        #expect(event.eventType == .vaccine)
        #expect(!event.isDeleted)
        #expect(event.title == "DTaP - Dose 1")
    }

    @Test("EventType has systemImage for all cases")
    func eventTypeIcons() {
        for type in HealthEvent.EventType.allCases {
            #expect(!type.systemImage.isEmpty)
            #expect(!type.label.isEmpty)
        }
    }

    @Test("EventType rawValues are stable strings")
    func eventTypeRawValues() {
        #expect(HealthEvent.EventType.vaccine.rawValue == "vaccine")
        #expect(HealthEvent.EventType.doctorVisit.rawValue == "doctorVisit")
        #expect(HealthEvent.EventType.allCases.count == 5)
    }
}
