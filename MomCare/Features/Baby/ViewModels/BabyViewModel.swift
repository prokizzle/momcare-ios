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
        error = nil
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
        error = nil
        do {
            let created = try await repository.create(baby)
            babies.append(created)
            selectedBaby = created
        } catch {
            self.error = error
        }
    }

    func createBaby(from formData: BabyFormData) async {
        let baby = Baby(
            id: UUID(),
            name: formData.name.trimmingCharacters(in: .whitespaces),
            dateOfBirth: formData.dateOfBirth,
            biologicalSex: formData.biologicalSex,
            birthWeight: formData.birthWeight,
            birthLength: formData.birthLength,
            birthHeadCircumference: formData.birthHeadCircumference,
            feedingMethod: formData.feedingMethod,
            photoData: formData.photoData,
            isDeleted: false,
            createdAt: .now,
            updatedAt: .now
        )
        await createBaby(baby)
    }

    func updateBaby(_ baby: Baby) async {
        error = nil
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
        error = nil
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
