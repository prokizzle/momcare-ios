import Testing
import Foundation
import SwiftData
@testable import MomCare

@Suite("SleepRepository Tests")
struct SleepRepositoryTests {

    @Test("getInProgressSleep returns the first sleep with nil endTime")
    @MainActor
    func getInProgressSleep_nilEndTime() async throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: BabySleepModel.self, configurations: config)
        let context = container.mainContext

        let babyId = UUID()
        let completedEntity = BabySleep.fixture(
            babyId: babyId,
            startTime: .now.addingTimeInterval(-7200),
            endTime: .now.addingTimeInterval(-3600),
            sleepType: .nap
        )
        let completed = BabySleepModel(from: completedEntity)

        let inProgressEntity = BabySleep.fixture(
            babyId: babyId,
            startTime: .now.addingTimeInterval(-1800),
            endTime: nil,
            sleepType: .nap
        )
        let inProgress = BabySleepModel(from: inProgressEntity)

        context.insert(completed)
        context.insert(inProgress)
        try context.save()

        let repository = SleepRepository(modelContext: context)
        let result = try await repository.getInProgressSleep(babyId: babyId)

        let unwrapped = try #require(result)
        #expect(unwrapped.id == inProgressEntity.id)
    }
}
