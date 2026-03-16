import Testing
import Foundation
@testable import MomCare

@Suite("VaccineScheduleService")
struct VaccineScheduleServiceTests {

    @Test("Loads schedule from bundle")
    func loadSchedule() throws {
        let service = VaccineScheduleService()
        let schedule = try service.loadSchedule()
        #expect(schedule.count >= 20)
        #expect(schedule.first?.name == "HepB - Dose 1")
    }

    @Test("Returns upcoming vaccines for newborn")
    func upcomingForNewborn() throws {
        let service = VaccineScheduleService()
        let dob = Date.now
        let upcoming = try service.upcomingVaccines(dateOfBirth: dob, existingEvents: [])
        #expect(upcoming.contains { $0.name == "HepB - Dose 1" })
    }

    @Test("Filters out already-logged vaccines")
    func filtersLogged() throws {
        let service = VaccineScheduleService()
        let dob = Date.now
        let logged = HealthEvent.fixture(
            eventType: .vaccine,
            title: "HepB - Dose 1"
        )
        let upcoming = try service.upcomingVaccines(
            dateOfBirth: dob,
            existingEvents: [logged]
        )
        #expect(!upcoming.contains { $0.name == "HepB - Dose 1" })
    }
}
