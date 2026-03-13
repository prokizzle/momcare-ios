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
            )
        ])
    }

    @Test("loadSleeps populates sleeps and groupedSleeps")
    func loadSleeps() async {
        let viewModel = SleepViewModel(repository: stubRepo)
        await viewModel.loadSleeps(babyId: babyId)
        #expect(viewModel.sleeps.count == 2)
        #expect(!viewModel.groupedSleeps.isEmpty)
        #expect(!viewModel.isLoading)
    }

    @Test("deleteSleep removes entry")
    func deleteSleep() async {
        let viewModel = SleepViewModel(repository: stubRepo)
        await viewModel.loadSleeps(babyId: babyId)
        let idToDelete = viewModel.sleeps[0].id
        await viewModel.deleteSleep(id: idToDelete)
        #expect(viewModel.sleeps.count == 1)
    }

    @Test("endSleep updates in-progress sleep with quality and location")
    func endSleep() async {
        let inProgress = BabySleep.fixture(babyId: babyId, endTime: nil, sleepType: .nap)
        let repo = StubSleepRepository(sleeps: [], inProgress: inProgress)
        let viewModel = SleepViewModel(repository: repo)
        viewModel.selectedQuality = .good
        viewModel.selectedLocation = .crib
        await viewModel.endSleep(babyId: babyId)
        #expect(repo.updated.count == 1)
        #expect(repo.updated.first?.quality == .good)
        #expect(repo.updated.first?.location == .crib)
        #expect(repo.updated.first?.endTime != nil)
    }

    @Test("dailyTotal computes total duration for a day")
    func dailyTotal() async {
        let viewModel = SleepViewModel(repository: stubRepo)
        await viewModel.loadSleeps(babyId: babyId)
        let todaySleeps = viewModel.groupedSleeps.first?.1 ?? []
        let total = viewModel.dailyTotal(for: todaySleeps)
        // First fixture is 1 hour (3600s), grouped under "Today"
        #expect(total == 3600)
    }

    @Test("endSleep inserts completed sleep into list")
    func endSleepInsertsIntoList() async {
        let inProgress = BabySleep.fixture(babyId: babyId, endTime: nil, sleepType: .nap)
        let repo = StubSleepRepository(sleeps: [], inProgress: inProgress)
        let viewModel = SleepViewModel(repository: repo)
        #expect(viewModel.sleeps.isEmpty)
        await viewModel.endSleep(babyId: babyId)
        #expect(viewModel.sleeps.count == 1)
    }
}
