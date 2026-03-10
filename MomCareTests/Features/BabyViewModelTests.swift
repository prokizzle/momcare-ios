import Testing
import Foundation
@testable import MomCare

@Suite("BabyViewModel Tests")
struct BabyViewModelTests {

    @MainActor
    private func makeSUT(babies: [Baby] = []) -> BabyViewModel {
        let repo = StubBabyRepository(babies: babies)
        return BabyViewModel(repository: repo)
    }

    @Test("loadBabies populates array")
    @MainActor
    func loadBabies() async {
        let sut = makeSUT(babies: [Baby.fixture(name: "A"), Baby.fixture(name: "B")])
        await sut.loadBabies()
        #expect(sut.babies.count == 2)
    }

    @Test("loadBabies auto-selects first baby when none selected")
    @MainActor
    func autoSelectFirst() async {
        let sut = makeSUT(babies: [Baby.fixture(name: "First")])
        await sut.loadBabies()
        #expect(sut.selectedBaby?.name == "First")
    }

    @Test("loadBabies preserves existing selection")
    @MainActor
    func preserveSelection() async {
        let existing = Baby.fixture(name: "Keep")
        let sut = makeSUT(babies: [Baby.fixture(name: "Other"), existing])
        sut.selectedBaby = existing
        await sut.loadBabies()
        #expect(sut.selectedBaby?.name == "Keep")
    }

    @Test("createBaby adds to list and selects it")
    @MainActor
    func createBaby() async {
        let sut = makeSUT()
        await sut.createBaby(Baby.fixture(name: "New"))
        #expect(sut.babies.count == 1)
        #expect(sut.selectedBaby?.name == "New")
    }

    @Test("deleteBaby removes from active list")
    @MainActor
    func deleteBaby() async {
        let baby = Baby.fixture(name: "Gone")
        let sut = makeSUT(babies: [baby])
        await sut.loadBabies()
        await sut.deleteBaby(baby.id)
        #expect(sut.babies.isEmpty)
    }

    @Test("selectBaby updates selectedBaby")
    @MainActor
    func selectBaby() {
        let sut = makeSUT()
        let baby = Baby.fixture(name: "Pick Me")
        sut.selectBaby(baby)
        #expect(sut.selectedBaby?.name == "Pick Me")
    }
}

private final class StubBabyRepository: BabyRepositoryProtocol {
    private var store: [Baby]

    init(babies: [Baby] = []) {
        self.store = babies
    }

    func getAll() async throws -> [Baby] { store }
    func getById(_ id: UUID) async throws -> Baby? { store.first { $0.id == id } }
    func create(_ entity: Baby) async throws -> Baby {
        store.append(entity)
        return entity
    }
    func update(_ entity: Baby) async throws -> Baby {
        if let idx = store.firstIndex(where: { $0.id == entity.id }) {
            store[idx] = entity
        }
        return entity
    }
    func delete(_ id: UUID) async throws {
        store.removeAll { $0.id == id }
    }
    func getActiveBabies() async throws -> [Baby] {
        store.filter { !$0.isDeleted }
    }
}
