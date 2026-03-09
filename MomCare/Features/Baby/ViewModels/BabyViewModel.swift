import Foundation

@MainActor
@Observable
final class BabyViewModel {
    var babies: [Baby] = []
    var selectedBaby: Baby?
    var isLoading = false
    var error: Error?

    private let repository: any BabyRepositoryProtocol

    init(repository: any BabyRepositoryProtocol) {
        self.repository = repository
    }

    func loadBabies() async {
        isLoading = true
        defer { isLoading = false }
        do {
            babies = try await repository.getActiveBabies()
            if selectedBaby == nil || !babies.contains(where: { $0.id == selectedBaby?.id }) {
                selectedBaby = babies.first
            }
        } catch {
            self.error = error
        }
    }

    func createBaby(_ baby: Baby) async {
        do {
            let created = try await repository.create(baby)
            babies.append(created)
            selectedBaby = created
        } catch {
            self.error = error
        }
    }

    func updateBaby(_ baby: Baby) async {
        do {
            let updated = try await repository.update(baby)
            if let idx = babies.firstIndex(where: { $0.id == updated.id }) {
                babies[idx] = updated
            }
            if selectedBaby?.id == updated.id {
                selectedBaby = updated
            }
        } catch {
            self.error = error
        }
    }

    func deleteBaby(_ id: UUID) async {
        do {
            try await repository.delete(id)
            babies.removeAll { $0.id == id }
            if selectedBaby?.id == id {
                selectedBaby = babies.first
            }
        } catch {
            self.error = error
        }
    }

    func selectBaby(_ baby: Baby) {
        selectedBaby = baby
    }
}
