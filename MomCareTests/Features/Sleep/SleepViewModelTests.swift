import Testing
import Foundation
@testable import MomCare

@MainActor
@Suite("SleepViewModel")
struct SleepViewModelTests {
    let babyId = UUID()
    let stubRepo: StubSleepRepository

    init() {
        stubRepo = StubSleepRepository(sleeps: [
            .fixture(
                babyId: babyId,
                startTime: Date.now.addingTimeInterval(-7200),
                endTime: Date.now.addingTimeInterval(-3600),
                sleepType: .nap,
                quality: .good
            ),
            .fixture(
                babyId: babyId,
                startTime: Date.now.addingTimeInterval(-86400),
                endTime: Date.now.addingTimeInterval(-82800),
                sleepType: .nighttime,
                quality: .fair
            ),
        ])
    }

    @Test("loadSleeps populates sleeps and groupedSleeps")
    func loadSleeps() async {
        let vm = SleepViewModel(repository: stubRepo)
        await vm.loadSleeps(babyId: babyId)
        #expect(vm.sleeps.count == 2)
        #expect(!vm.groupedSleeps.isEmpty)
        #expect(!vm.isLoading)
    }

    @Test("deleteSleep removes entry")
    func deleteSleep() async {
        let vm = SleepViewModel(repository: stubRepo)
        await vm.loadSleeps(babyId: babyId)
        let idToDelete = vm.sleeps[0].id
        await vm.deleteSleep(id: idToDelete)
        #expect(vm.sleeps.count == 1)
    }

    @Test("endSleep updates in-progress sleep with quality and location")
    func endSleep() async {
        let inProgress = BabySleep.fixture(babyId: babyId, endTime: nil, sleepType: .nap)
        let repo = StubSleepRepository(sleeps: [], inProgress: inProgress)
        let vm = SleepViewModel(repository: repo)
        vm.selectedQuality = .good
        vm.selectedLocation = .crib
        await vm.endSleep(babyId: babyId)
        #expect(repo.updated.count == 1)
        #expect(repo.updated.first?.quality == .good)
        #expect(repo.updated.first?.location == .crib)
        #expect(repo.updated.first?.endTime != nil)
    }

    @Test("dailyTotal computes total duration for a day")
    func dailyTotal() async {
        let vm = SleepViewModel(repository: stubRepo)
        await vm.loadSleeps(babyId: babyId)
        let todaySleeps = vm.groupedSleeps.first?.1 ?? []
        let total = vm.dailyTotal(for: todaySleeps)
        // First fixture is 1 hour (3600s), grouped under "Today"
        #expect(total == 3600)
    }

    @Test("endSleep inserts completed sleep into list")
    func endSleepInsertsIntoList() async {
        let inProgress = BabySleep.fixture(babyId: babyId, endTime: nil, sleepType: .nap)
        let repo = StubSleepRepository(sleeps: [], inProgress: inProgress)
        let vm = SleepViewModel(repository: repo)
        #expect(vm.sleeps.isEmpty)
        await vm.endSleep(babyId: babyId)
        #expect(vm.sleeps.count == 1)
    }
}
