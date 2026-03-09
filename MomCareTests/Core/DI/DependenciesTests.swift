import Testing
import SwiftUI
@testable import MomCare

@Suite("Dependencies Tests")
struct DependenciesTests {
    @Test("AppDependencies conforms to DependencyContainer")
    func conformance() {
        let deps: any DependencyContainer = AppDependencies()
        #expect(deps is AppDependencies)
    }

    @Test("Environment key has default value")
    func environmentKey() {
        let defaultValue = DependenciesKey.defaultValue
        #expect(defaultValue is AppDependencies)
    }
}
