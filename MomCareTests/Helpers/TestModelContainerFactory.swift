import SwiftData
@testable import MomCare

@MainActor
enum TestModelContainerFactory {
    static func makeContainer() throws -> ModelContainer {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        return try ModelContainer(
            for: BabyModel.self, FeedingModel.self,
            SelfCareLogModel.self, SelfCareGridItemModel.self, ContentHistoryModel.self,
            DiaperModel.self, BabySleepModel.self, GrowthRecordModel.self,
            HealthEventModel.self,
            configurations: config
        )
    }

    static func makeDependencies() throws -> AppDependencies {
        let container = try makeContainer()
        return AppDependencies(modelContext: container.mainContext)
    }
}
