import Testing
import Foundation
@testable import MomCare

@Suite("SharedDataManager")
struct SharedDataManagerTests {

    @Test("Baby name round-trips through UserDefaults")
    func babyName() {
        SharedDataManager.updateBaby(name: "Emma")
        #expect(SharedDataManager.babyName == "Emma")
    }

    @Test("Feeding state round-trips")
    func feedingState() {
        let now = Date.now
        let state = SharedFeedingState(
            lastTime: now,
            lastType: "breast",
            isInProgress: true,
            startTime: now,
            detail: "Left breast",
            todayCount: 5
        )
        SharedDataManager.updateFeeding(state)
        #expect(SharedDataManager.isFeedingInProgress == true)
        #expect(SharedDataManager.todayFeedingCount == 5)
        #expect(SharedDataManager.feedingDetail == "Left breast")
        #expect(SharedDataManager.lastFeedingType == "breast")
    }

    @Test("Nap state round-trips")
    func napState() {
        let now = Date.now
        SharedDataManager.updateNap(isInProgress: true, startTime: now)
        #expect(SharedDataManager.isNapInProgress == true)
        #expect(SharedDataManager.napStartTime != nil)
    }

    @Test("Self-care items round-trip")
    func selfCareItems() {
        let items = [
            SharedSelfCareItem(name: "Water", icon: "cup.and.saucer.fill", isDone: false, lastDoneDate: nil),
            SharedSelfCareItem(name: "Lunch", icon: "fork.knife", isDone: true, lastDoneDate: .now)
        ]
        SharedDataManager.updateSelfCare(items: items)
        let loaded = SharedDataManager.selfCareItems
        #expect(loaded.count == 2)
        #expect(loaded[0].name == "Water")
        #expect(loaded[1].isDone == true)
    }

    @Test("Vaccine state round-trips")
    func vaccineState() {
        SharedDataManager.updateVaccine(name: "DTaP - Dose 1", ageMonths: 2)
        #expect(SharedDataManager.nextVaccineName == "DTaP - Dose 1")
        #expect(SharedDataManager.nextVaccineAgeMonths == 2)
    }

    @Test("Default baby name is Baby")
    func defaultBabyName() {
        // Clear any existing value
        UserDefaults(suiteName: SharedDataManager.suiteName)?.removeObject(forKey: "mc_babyName")
        #expect(SharedDataManager.babyName == "Baby")
    }
}
