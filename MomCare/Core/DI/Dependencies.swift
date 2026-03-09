import SwiftUI

protocol DependencyContainer: Sendable {
    // Factory methods added here as features land.
}

final class AppDependencies: DependencyContainer, @unchecked Sendable {
    // Concrete factory methods added per feature.
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
