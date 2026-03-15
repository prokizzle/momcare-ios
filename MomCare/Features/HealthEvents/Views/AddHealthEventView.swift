import PhotosUI
import SwiftUI

@MainActor
struct AddHealthEventView: View {
    let babyId: UUID
    let dateOfBirth: Date
    @Bindable var viewModel: HealthEventsViewModel
    var prefillVaccineName: String?

    @Environment(\.dismiss) private var dismiss

    @State private var eventType: HealthEvent.EventType = .vaccine
    @State private var title = ""
    @State private var date = Date.now
    @State private var endDate = Date.now
    @State private var showEndDate = false
    @State private var notes = ""
    @State private var selectedPhotos: [PhotosPickerItem] = []
    @State private var photoImages: [UIImage] = []
    @State private var showCamera = false
    @State private var cameraImage: UIImage?
    @State private var showError = false
    @State private var isSaving = false

    private var canSave: Bool {
        !title.trimmingCharacters(in: .whitespaces).isEmpty && !isSaving
    }

    var body: some View {
        NavigationStack {
            Form {
                typeSection
                detailsSection
                notesSection
                photosSection
            }
            .navigationTitle("Add Health Event")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        MCHaptic.tap()
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        Task { await save() }
                    }
                    .font(MCTypography.button)
                    .disabled(!canSave)
                }
            }
            .alert("Failed to Save", isPresented: $showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(viewModel.error?.localizedDescription ?? "An unknown error occurred.")
            }
            .sheet(isPresented: $showCamera) {
                CameraPickerView(image: $cameraImage)
            }
            .onChange(of: selectedPhotos) { _, newItems in
                Task { await loadPhotos(from: newItems) }
            }
            .onChange(of: cameraImage) { _, newImage in
                if let newImage {
                    photoImages.append(newImage)
                    cameraImage = nil
                }
            }
            .onAppear {
                if let prefillVaccineName {
                    eventType = .vaccine
                    title = prefillVaccineName
                }
            }
        }
    }

    // MARK: - Type Section

    private var typeSection: some View {
        Section {
            Picker("Type", selection: $eventType) {
                ForEach(HealthEvent.EventType.allCases, id: \.self) { type in
                    Text(type.label).tag(type)
                }
            }
            .pickerStyle(.segmented)
            .onChange(of: eventType) { _, _ in
                MCHaptic.select()
            }
        } header: {
            Text("Type")
                .font(MCTypography.caption)
        }
    }

    // MARK: - Details Section

    private var detailsSection: some View {
        Section {
            TextField("Title", text: $title)
                .font(MCTypography.body)

            DatePicker(
                "Date",
                selection: $date,
                in: dateOfBirth...Date.now,
                displayedComponents: .date
            )
            .font(MCTypography.body)

            if eventType == .illness {
                Toggle("Add end date", isOn: $showEndDate)
                    .font(MCTypography.body)
                    .onChange(of: showEndDate) { _, _ in
                        MCHaptic.toggle()
                    }

                if showEndDate {
                    DatePicker(
                        "End Date",
                        selection: $endDate,
                        in: date...Date.now,
                        displayedComponents: .date
                    )
                    .font(MCTypography.body)
                }
            }
        } header: {
            Text("Details")
                .font(MCTypography.caption)
        }
    }

    // MARK: - Notes Section

    private var notesSection: some View {
        Section {
            TextField("Notes", text: $notes, axis: .vertical)
                .font(MCTypography.body)
                .lineLimit(3...6)
        } header: {
            Text("Notes")
                .font(MCTypography.caption)
        }
    }

    // MARK: - Photos Section

    private var photosSection: some View {
        Section {
            if !photoImages.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: MCSpacing.sm) {
                        ForEach(photoImages.indices, id: \.self) { index in
                            ZStack(alignment: .topTrailing) {
                                Image(uiImage: photoImages[index])
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 80, height: 80)
                                    .clipShape(RoundedRectangle(cornerRadius: MCRadius.sm))

                                Button {
                                    MCHaptic.tap()
                                    withAnimation(MCAnimation.quick) {
                                        _ = photoImages.remove(at: index)
                                    }
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.system(size: 20))
                                        .foregroundStyle(.white, MCColor.error)
                                }
                                .offset(x: 6, y: -6)
                                .accessibilityLabel("Remove photo \(index + 1)")
                            }
                        }
                    }
                    .padding(.vertical, MCSpacing.xs)
                }
            }

            HStack(spacing: MCSpacing.md) {
                PhotosPicker(
                    selection: $selectedPhotos,
                    maxSelectionCount: max(1, 5 - photoImages.count),
                    matching: .images
                ) {
                    Label("Add from Library", systemImage: "photo.on.rectangle")
                        .font(MCTypography.subheadline)
                }
                .disabled(photoImages.count >= 5)

                if UIImagePickerController.isSourceTypeAvailable(.camera) {
                    Button {
                        MCHaptic.tap()
                        showCamera = true
                    } label: {
                        Label("Camera", systemImage: "camera.fill")
                            .font(MCTypography.subheadline)
                    }
                    .disabled(photoImages.count >= 5)
                }
            }
        } header: {
            Text("Photos (\(photoImages.count)/5)")
                .font(MCTypography.caption)
        }
    }

    // MARK: - Actions

    private func save() async {
        MCHaptic.tap()
        isSaving = true
        defer { isSaving = false }

        let finalEndDate = (eventType == .illness && showEndDate) ? endDate : nil
        let finalNotes = notes.trimmingCharacters(in: .whitespacesAndNewlines)

        let success = await viewModel.addEvent(
            babyId: babyId,
            date: date,
            endDate: finalEndDate,
            eventType: eventType,
            title: title.trimmingCharacters(in: .whitespaces),
            notes: finalNotes.isEmpty ? nil : finalNotes
        )

        if success {
            MCHaptic.success()
            viewModel.loadUpcomingVaccines(dateOfBirth: dateOfBirth)
            dismiss()
        } else {
            MCHaptic.error()
            showError = true
        }
    }

    private func loadPhotos(from items: [PhotosPickerItem]) async {
        for item in items {
            if let data = try? await item.loadTransferable(type: Data.self),
               let uiImage = UIImage(data: data) {
                photoImages.append(uiImage)
            }
        }
        selectedPhotos.removeAll()
    }
}
