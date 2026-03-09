import SwiftUI
import PhotosUI

struct BabyProfileView: View {
    @Bindable var viewModel: BabyViewModel
    let baby: Baby

    @State private var editedBaby: Baby
    @State private var isEditing = false
    @State private var showDeleteConfirmation = false
    @State private var selectedPhoto: PhotosPickerItem?
    @Environment(\.dismiss) private var dismiss

    init(viewModel: BabyViewModel, baby: Baby) {
        self.viewModel = viewModel
        self.baby = baby
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
                        saveChanges()
                    }
                    isEditing.toggle()
                    MCHaptic.tap()
                }
            }
        }
        .confirmationDialog("Delete Baby", isPresented: $showDeleteConfirmation) {
            Button("Delete", role: .destructive) {
                Task {
                    await viewModel.deleteBaby(baby.id)
                    dismiss()
                }
            }
        } message: {
            Text("This will remove \(baby.name) from your babies. This action cannot be undone.")
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
                DatePicker("Birthday", selection: $editedBaby.dateOfBirth, displayedComponents: .date)
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

    private func saveChanges() {
        editedBaby.updatedAt = .now
        Task {
            await viewModel.updateBaby(editedBaby)
        }
        MCHaptic.success()
    }
}
