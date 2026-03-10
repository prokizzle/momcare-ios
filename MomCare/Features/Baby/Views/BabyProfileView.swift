import SwiftUI
import PhotosUI

@MainActor
struct BabyProfileView: View {
    @Bindable var viewModel: BabyViewModel
    let babyId: UUID

    @State private var editedBaby: Baby
    @State private var isEditing = false
    @State private var showDeleteConfirmation = false
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var showError = false
    @Environment(\.dismiss) private var dismiss

    private var baby: Baby {
        viewModel.babies.first { $0.id == babyId } ?? editedBaby
    }

    init(viewModel: BabyViewModel, baby: Baby) {
        self.viewModel = viewModel
        self.babyId = baby.id
        self._editedBaby = State(initialValue: baby)
    }

    var body: some View {
        List {
            heroSection
            detailsSection
            if isEditing {
                deleteSection
            }
        }
        .navigationTitle(baby.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(isEditing ? "Done" : "Edit") {
                    if isEditing {
                        Task { await saveChanges() }
                    } else {
                        isEditing = true
                        MCHaptic.tap()
                    }
                }
            }
        }
        .confirmationDialog("Delete Baby", isPresented: $showDeleteConfirmation) {
            Button("Delete", role: .destructive) {
                Task {
                    await viewModel.deleteBaby(babyId)
                    dismiss()
                }
            }
        } message: {
            Text("This will remove \(baby.name) from your babies. This action cannot be undone.")
        }
        .alert("Save Failed", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.error?.localizedDescription ?? "An unknown error occurred.")
        }
        .onChange(of: selectedPhoto) { _, newItem in
            Task {
                editedBaby.photoData = try? await newItem?.loadTransferable(type: Data.self)
            }
        }
    }

    private var heroSection: some View {
        Section {
            VStack(spacing: MCSpacing.md) {
                BabyAvatarView(baby: isEditing ? editedBaby : baby, size: 100)

                if isEditing {
                    PhotosPicker(selection: $selectedPhoto, matching: .images) {
                        Label("Change Photo", systemImage: "photo")
                            .font(MCTypography.cardBody)
                    }
                }

                Text(baby.ageString)
                    .font(MCTypography.cardBody)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .listRowBackground(Color.clear)
        }
    }

    private var detailsSection: some View {
        Section("Details") {
            if isEditing {
                TextField("Name", text: $editedBaby.name)
                DatePicker(
                    "Birthday",
                    selection: $editedBaby.dateOfBirth,
                    in: ...Date.now,
                    displayedComponents: .date
                )
                Picker("Biological Sex", selection: $editedBaby.biologicalSex) {
                    Text("Not specified").tag(nil as Baby.BiologicalSex?)
                    ForEach(Baby.BiologicalSex.allCases, id: \.self) { sex in
                        Text(sex.displayName).tag(sex as Baby.BiologicalSex?)
                    }
                }
                Picker("Feeding Method", selection: $editedBaby.feedingMethod) {
                    ForEach(Baby.FeedingMethod.allCases, id: \.self) { method in
                        Text(method.displayName).tag(method)
                    }
                }
            } else {
                LabeledContent("Name", value: baby.name)
                LabeledContent("Birthday", value: baby.dateOfBirth.formatted(date: .long, time: .omitted))
                if let sex = baby.biologicalSex {
                    LabeledContent("Biological Sex", value: sex.displayName)
                }
                LabeledContent("Feeding Method", value: baby.feedingMethod.displayName)
                if let weight = baby.birthWeight {
                    LabeledContent("Birth Weight", value: "\(Int(weight))g")
                }
                if let length = baby.birthLength {
                    LabeledContent("Birth Length", value: String(format: "%.1f cm", length))
                }
            }
        }
    }

    private var deleteSection: some View {
        Section {
            Button("Delete Baby", role: .destructive) {
                showDeleteConfirmation = true
            }
        }
    }

    private func saveChanges() async {
        editedBaby.updatedAt = .now
        await viewModel.updateBaby(editedBaby)
        if viewModel.error != nil {
            showError = true
        } else {
            MCHaptic.success()
            isEditing = false
        }
    }
}
