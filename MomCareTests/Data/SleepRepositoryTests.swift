import Testing
import SwiftData
@testable import MomCare

@Suite("SleepRepository Tests")
struct SleepRepositoryTests {

    @Test("getInProgressSleep returns the first sleep with nil endTime")
    @MainActor
    func getInProgressSleep_nilEndTime() async throws {
        let container = try ModelContainer(for: SchemaV4.self, configurations: [])
        let context = container.mainContext

        let babyId = UUID()
        let completed = BabySleepModel(
            id: UUID(),
            babyId: babyId,
            startTime: .now.addingTimeInterval(-7200),
            endTime: .now.addingTimeInterval(-3600),
            sleepType: .nap,
            location: nil,
            quality: nil,
            notes: nil,
            isSoftDeleted: false,
            createdAt: .now.addingTimeInterval(-7200),
            updatedAt: .now.addingTimeInterval(-3600)
        )

        let inProgress = BabySleepModel(
            id: UUID(),
            babyId: babyId,
            startTime: .now.addingTimeInterval(-1800),
            endTime: nil,
            sleepType: .nap,
            location: nil,
            quality: nil,
            notes: nil,
            isSoftDeleted: false,
            createdAt: .now.addingTimeInterval(-1800),
            updatedAt: .now.addingTimeInterval(-1800)
        )

        context.insert(completed)
        context.insert(inProgress)
        try context.save()

        let repository = SleepRepository(modelContext: context)
        let result = try await repository.getInProgressSleep(babyId: babyId)

        let unwrapped = #require(result)
        #expect(unwrapped.id == inProgress.id)
    }
}
