import SwiftUI
import PhotosUI

@MainActor
struct AddBabyView: View {
    @Environment(\.dismiss) private var dismiss
    let viewModel: BabyViewModel

    @State private var name = ""
    @State private var dateOfBirth = Date.now
    @State private var biologicalSex: Baby.BiologicalSex?
    @State private var feedingMethod: Baby.FeedingMethod = .breast
    @State private var birthWeight: String = ""
    @State private var birthLength: String = ""
    @State private var birthHeadCircumference: String = ""
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var photoData: Data?
    @State private var showOptionalDetails = false
    @State private var showError = false

    private var isValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                requiredSection
                optionalSection
            }
            .navigationTitle("Add Baby")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") { saveBaby() }
                        .disabled(!isValid)
                }
            }
            .onChange(of: selectedPhoto) { _, newItem in
                Task {
                    photoData = try? await newItem?.loadTransferable(type: Data.self)
                }
            }
            .alert("Save Failed", isPresented: $showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(viewModel.error?.localizedDescription ?? "An unknown error occurred.")
            }
        }
    }

    private var requiredSection: some View {
        Section {
            TextField("Baby's name", text: $name)
                .textContentType(.name)
            DatePicker("Birthday", selection: $dateOfBirth, in: ...Date.now, displayedComponents: .date)
        }
    }

    private var optionalSection: some View {
        Section {
            DisclosureGroup("Additional Details", isExpanded: $showOptionalDetails) {
                Picker("Biological Sex", selection: $biologicalSex) {
                    Text("Not specified").tag(nil as Baby.BiologicalSex?)
                    ForEach(Baby.BiologicalSex.allCases, id: \.self) { sex in
                        Text(sex.displayName).tag(sex as Baby.BiologicalSex?)
                    }
                }

                Picker("Feeding Method", selection: $feedingMethod) {
                    ForEach(Baby.FeedingMethod.allCases, id: \.self) { method in
                        Text(method.displayName).tag(method)
                    }
                }

                TextField("Birth weight (g)", text: $birthWeight)
                    .keyboardType(.decimalPad)
                TextField("Birth length (cm)", text: $birthLength)
                    .keyboardType(.decimalPad)
                TextField("Head circumference (cm)", text: $birthHeadCircumference)
                    .keyboardType(.decimalPad)

                PhotosPicker(selection: $selectedPhoto, matching: .images) {
                    Label("Choose Photo", systemImage: "photo")
                }
            }
        }
    }

    private func saveBaby() {
        let formData = BabyFormData(
            name: name,
            dateOfBirth: dateOfBirth,
            biologicalSex: biologicalSex,
            feedingMethod: feedingMethod,
            birthWeight: Double(birthWeight),
            birthLength: Double(birthLength),
            birthHeadCircumference: Double(birthHeadCircumference),
            photoData: photoData
        )
        Task {
            await viewModel.createBaby(from: formData)
            if viewModel.error == nil {
                MCHaptic.success()
                dismiss()
            } else {
                showError = true
            }
        }
    }
}
