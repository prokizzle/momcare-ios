import SwiftUI

protocol DependencyContainer: Sendable {
    // Factory methods added here as features land.
}

final class AppDependencies: DependencyContainer, Sendable {
    // Concrete factory methods added per feature.
    // All stored properties must be let-bound and Sendable.
}

struct DependenciesKey: EnvironmentKey {
    static let defaultValue: any DependencyContainer = AppDependencies()
}

extension EnvironmentValues {
    var dependencies: any DependencyContainer {
        get { self[DependenciesKey.self] }
        set { self[DependenciesKey.self] = newValue }
    }
}
