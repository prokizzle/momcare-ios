import SwiftUI

@MainActor
struct LogDetailSheet: View {
    let actionType: SelfCareActionType
    let onSave: (LogDetail) -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var glasses = 1
    @State private var selectedMealType: MealType = .breakfast
    @State private var note = ""

    var body: some View {
        NavigationStack {
            Form {
                switch actionType {
                case .water:
                    Stepper("Glasses: \(glasses)", value: $glasses, in: 1...20)
                case .meal:
                    Picker("Meal", selection: $selectedMealType) {
                        ForEach(MealType.allCases, id: \.self) { type in
                            Text(type.label).tag(type)
                        }
                    }
                    .pickerStyle(.segmented)
                default:
                    Section("Notes") {
                        TextField("Optional note", text: $note, axis: .vertical)
                            .lineLimit(3...6)
                    }
                }
            }
            .navigationTitle(actionType.label)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        MCHaptic.success()
                        let detail: LogDetail
                        switch actionType {
                        case .water:
                            detail = .water(glasses: glasses)
                        case .meal:
                            detail = .meal(selectedMealType)
                        default:
                            detail = note.isEmpty ? .freeNote("") : .freeNote(note)
                        }
                        onSave(detail)
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }
}
