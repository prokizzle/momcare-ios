import SwiftUI

@MainActor
struct AddMeasurementView: View {
    let babyId: UUID
    let dateOfBirth: Date
    @Bindable var viewModel: GrowthViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var date = Date.now
    @State private var weightInput = ""
    @State private var lengthInput = ""
    @State private var headInput = ""
    @State private var notes = ""
    @State private var showSaveError = false

    private var isMetric: Bool {
        Locale.current.measurementSystem == .metric
    }

    private var hasAtLeastOneMeasurement: Bool {
        !weightInput.isEmpty || !lengthInput.isEmpty || !headInput.isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Date") {
                    DatePicker(
                        "Measurement date",
                        selection: $date,
                        in: dateOfBirth...Date.now,
                        displayedComponents: .date
                    )
                    .labelsHidden()
                }

                Section("Measurements") {
                    HStack {
                        Text("Weight")
                        Spacer()
                        TextField(isMetric ? "kg" : "lbs", text: $weightInput)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                        Text(isMetric ? "kg" : "lbs")
                            .foregroundStyle(.secondary)
                    }

                    HStack {
                        Text("Length")
                        Spacer()
                        TextField(isMetric ? "cm" : "in", text: $lengthInput)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                        Text(isMetric ? "cm" : "in")
                            .foregroundStyle(.secondary)
                    }

                    HStack {
                        Text("Head circ.")
                        Spacer()
                        TextField(isMetric ? "cm" : "in", text: $headInput)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                        Text(isMetric ? "cm" : "in")
                            .foregroundStyle(.secondary)
                    }
                }

                Section("Notes") {
                    TextField("Optional notes", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle("Add Measurement")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        Task {
                            let success = await save()
                            if success {
                                MCHaptic.success()
                                dismiss()
                            } else {
                                showSaveError = true
                            }
                        }
                    }
                    .disabled(!hasAtLeastOneMeasurement)
                }
            }
            .alert("Failed to Save", isPresented: $showSaveError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(viewModel.error?.localizedDescription ?? "Please try again.")
            }
        }
    }

    private func save() async -> Bool {
        let weightGrams = parseWeight(weightInput)
        let lengthCm = parseLength(lengthInput)
        let headCm = parseLength(headInput)

        return await viewModel.addMeasurement(
            babyId: babyId,
            date: date,
            weightGrams: weightGrams,
            lengthCm: lengthCm,
            headCircumferenceCm: headCm,
            notes: notes.isEmpty ? nil : notes
        )
    }

    private static let numberFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.locale = .current
        return formatter
    }()

    private func parseLocaleDouble(_ input: String) -> Double? {
        let trimmed = input.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return nil }
        return Self.numberFormatter.number(from: trimmed)?.doubleValue
    }

    private func parseWeight(_ input: String) -> Double? {
        guard let value = parseLocaleDouble(input) else { return nil }
        if isMetric {
            return value * 1000 // kg to grams
        } else {
            return value * 453.592 // lbs to grams
        }
    }

    private func parseLength(_ input: String) -> Double? {
        guard let value = parseLocaleDouble(input) else { return nil }
        if isMetric {
            return value // already cm
        } else {
            return value * 2.54 // inches to cm
        }
    }
}
