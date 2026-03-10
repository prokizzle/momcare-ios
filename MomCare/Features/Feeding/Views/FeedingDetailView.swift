import SwiftUI

struct FeedingDetailView: View {
    @Bindable var viewModel: FeedingViewModel
    let feedingId: UUID
    @State private var editedFeeding: Feeding
    @State private var isEditing = false
    @State private var showError = false
    @Environment(\.dismiss) private var dismiss

    private var feeding: Feeding {
        viewModel.feedings.first { $0.id == feedingId } ?? editedFeeding
    }

    init(viewModel: FeedingViewModel, feedingId: UUID, feeding: Feeding) {
        self.viewModel = viewModel
        self.feedingId = feedingId
        self._editedFeeding = State(initialValue: feeding)
    }

    var body: some View {
        Form {
            Section("Type") {
                if isEditing {
                    Picker("Feeding Type", selection: $editedFeeding.feedingType) {
                        ForEach(Feeding.FeedingType.allCases, id: \.self) { feedingType in
                            Label(feedingType.label, systemImage: feedingType.systemImage).tag(feedingType)
                        }
                    }
                } else {
                    Label(feeding.feedingType.label, systemImage: feeding.feedingType.systemImage)
                }
            }

            Section("Time") {
                if isEditing {
                    DatePicker("Start", selection: $editedFeeding.startTime, in: ...Date.now)
                    if let endTime = editedFeeding.endTime {
                        DatePicker(
                            "End",
                            selection: Binding(
                                get: { endTime },
                                set: { editedFeeding.endTime = $0 }
                            ),
                            in: editedFeeding.startTime...Date.now
                        )
                    }
                } else {
                    LabeledContent("Start", value: feeding.startTime.formatted(date: .abbreviated, time: .shortened))
                    if let endTime = feeding.endTime {
                        LabeledContent("End", value: endTime.formatted(date: .abbreviated, time: .shortened))
                        LabeledContent("Duration", value: feeding.durationFormatted)
                    }
                }
            }

            if feeding.feedingType == .breast || (isEditing && editedFeeding.feedingType == .breast) {
                Section("Breast") {
                    if isEditing {
                        Picker("Side", selection: $editedFeeding.breastSide) {
                            Text("None").tag(nil as Feeding.BreastSide?)
                            ForEach(Feeding.BreastSide.allCases, id: \.self) { side in
                                Text(side.label).tag(side as Feeding.BreastSide?)
                            }
                        }
                    } else if let side = feeding.breastSide {
                        LabeledContent("Side", value: side.label)
                    }
                }
            }

            Section("Quality & Notes") {
                if isEditing {
                    Picker("Quality", selection: $editedFeeding.quality) {
                        Text("None").tag(nil as Feeding.FeedingQuality?)
                        ForEach(Feeding.FeedingQuality.allCases, id: \.self) { quality in
                            Text(quality.displayName).tag(quality as Feeding.FeedingQuality?)
                        }
                    }
                    TextField("Notes", text: Binding(
                        get: { editedFeeding.notes ?? "" },
                        set: { editedFeeding.notes = $0.isEmpty ? nil : $0 }
                    ), axis: .vertical)
                } else {
                    if let quality = feeding.quality {
                        LabeledContent("Quality", value: quality.displayName)
                    }
                    if let notes = feeding.notes {
                        Text(notes)
                            .font(MCTypography.cardBody)
                    }
                }
            }
        }
        .navigationTitle("Feeding Details")
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
        .alert("Save Failed", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.error?.localizedDescription ?? "An unknown error occurred.")
        }
    }

    private func saveChanges() async {
        editedFeeding.updatedAt = .now
        await viewModel.updateFeeding(editedFeeding)
        if viewModel.error != nil {
            showError = true
        } else {
            MCHaptic.success()
            isEditing = false
        }
    }
}
