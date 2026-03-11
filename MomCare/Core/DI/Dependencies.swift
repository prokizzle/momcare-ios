import SwiftUI
import SwiftData

@MainActor
protocol DependencyContainer {
    func makeBabyRepository() -> any BabyRepositoryProtocol
    func makeFeedingRepository() -> any FeedingRepositoryProtocol
    func makeSelfCareRepository() -> any SelfCareRepositoryProtocol
    func makeDiaperRepository() -> any DiaperRepositoryProtocol
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
}

struct DependenciesKey: @preconcurrency EnvironmentKey {
    @MainActor
    static let defaultValue: any DependencyContainer = {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        // swiftlint:disable:next force_try
        let container = try! ModelContainer(
            for: BabyModel.self, FeedingModel.self,
            SelfCareLogModel.self, SelfCareGridItemModel.self, ContentHistoryModel.self,
            DiaperModel.self,
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
