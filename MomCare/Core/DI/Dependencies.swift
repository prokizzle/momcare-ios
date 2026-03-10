import SwiftUI
import SwiftData

@MainActor
protocol DependencyContainer {
    func makeBabyRepository() -> any BabyRepositoryProtocol
    func makeFeedingRepository() -> any FeedingRepositoryProtocol
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
}

struct DependenciesKey: @preconcurrency EnvironmentKey {
    @MainActor
    static let defaultValue: any DependencyContainer = {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        // swiftlint:disable:next force_try
        let container = try! ModelContainer(
            for: BabyModel.self, FeedingModel.self,
            SelfCareLogModel.self, SelfCareGridItemModel.self, ContentHistoryModel.self,
            configurations: config
        )
        return AppDependencies(modelContext: container.mainContext)
    }()
}

extension EnvironmentValues {
    var dependencies: any DependencyContainer {
        get { self[DependenciesKey.self] }
        set { self[DependenciesKey.self] = newValue }
    }
}
