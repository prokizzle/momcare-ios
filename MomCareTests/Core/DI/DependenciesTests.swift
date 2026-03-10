import Testing
import SwiftUI
import SwiftData
@testable import MomCare

@Suite("Dependencies Tests")
struct DependenciesTests {
    @Test("DependencyContainer requires makeBabyRepository")
    @MainActor
    func babyRepositoryFactory() throws {
        let container = TestDependencies()
        let repo = container.makeBabyRepository()
        #expect(repo is MockBabyRepository)
    }

    @Test("AppDependencies creates real BabyRepository")
    @MainActor
    func appDependenciesCreatesBabyRepo() throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let modelContainer = try ModelContainer(for: BabyModel.self, configurations: config)
        let deps = AppDependencies(modelContext: modelContainer.mainContext)
        let repo = deps.makeBabyRepository()
        #expect(repo is BabyRepository)
    }

    @Test("Environment key has default value")
    @MainActor
    func environmentKey() {
        let defaultValue = DependenciesKey.defaultValue
        #expect(defaultValue is AppDependencies)
    }
}

private final class MockBabyRepository: BabyRepositoryProtocol {
    func getAll() async throws -> [Baby] { [] }
    func getById(_ id: UUID) async throws -> Baby? { nil }
    func create(_ entity: Baby) async throws -> Baby { entity }
    func update(_ entity: Baby) async throws -> Baby { entity }
    func delete(_ id: UUID) async throws {}
    func getActiveBabies() async throws -> [Baby] { [] }
}

@MainActor
private final class TestDependencies: DependencyContainer {
    func makeBabyRepository() -> any BabyRepositoryProtocol {
        MockBabyRepository()
    }
}
