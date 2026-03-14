import SwiftUI
import SwiftData

@MainActor
protocol DependencyContainer {
    func makeBabyRepository() -> any BabyRepositoryProtocol
    func makeFeedingRepository() -> any FeedingRepositoryProtocol
    func makeSelfCareRepository() -> any SelfCareRepositoryProtocol
    func makeDiaperRepository() -> any DiaperRepositoryProtocol
    func makeSleepRepository() -> any SleepRepositoryProtocol
    func makeGrowthRepository() -> any GrowthRepositoryProtocol
}

@MainActor
final class AppDependencies: DependencyContainer {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func makeBabyRepository() -> any BabyRepositoryProtocol {
        BabyRepository(modelContext: modelContext)
    }

    func makeFeedingRepository() -> any FeedingRepositoryProtocol {
        FeedingRepository(modelContext: modelContext)
    }

    func makeSelfCareRepository() -> any SelfCareRepositoryProtocol {
        SelfCareRepository(modelContext: modelContext)
    }

    func makeDiaperRepository() -> any DiaperRepositoryProtocol {
        DiaperRepository(modelContext: modelContext)
    }

    func makeSleepRepository() -> any SleepRepositoryProtocol {
        SleepRepository(modelContext: modelContext)
    }

    func makeGrowthRepository() -> any GrowthRepositoryProtocol {
        GrowthRepository(modelContext: modelContext)
    }
}

// @preconcurrency needed because SwiftUI's EnvironmentKey.defaultValue is not
// guaranteed to be accessed on MainActor, but AppDependencies is @MainActor
// and only created/accessed from MainActor contexts in practice.
struct DependenciesKey: @preconcurrency EnvironmentKey {
    @MainActor
    static let defaultValue: any DependencyContainer = {
        let schema = Schema(versionedSchema: SchemaV4.self)
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        // swiftlint:disable:next force_try
        let container = try! ModelContainer(for: schema, configurations: [config])
        return AppDependencies(modelContext: container.mainContext)
    }()
}

extension EnvironmentValues {
    var dependencies: any DependencyContainer {
        get { self[DependenciesKey.self] }
        set { self[DependenciesKey.self] = newValue }
    }
}
