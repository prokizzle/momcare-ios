import SwiftUI
import SwiftData

protocol DependencyContainer: Sendable {
    func makeBabyRepository() -> any BabyRepositoryProtocol
}

final class AppDependencies: DependencyContainer, @unchecked Sendable {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func makeBabyRepository() -> any BabyRepositoryProtocol {
        BabyRepository(modelContext: modelContext)
    }
}

struct DependenciesKey: @preconcurrency EnvironmentKey {
    @MainActor
    static let defaultValue: any DependencyContainer = {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        // swiftlint:disable:next force_try
        let container = try! ModelContainer(for: BabyModel.self, configurations: config)
        return AppDependencies(modelContext: container.mainContext)
    }()
}

extension EnvironmentValues {
    var dependencies: any DependencyContainer {
        get { self[DependenciesKey.self] }
        set { self[DependenciesKey.self] = newValue }
    }
}
