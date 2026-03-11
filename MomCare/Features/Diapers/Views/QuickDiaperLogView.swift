import SwiftUI

@MainActor
struct QuickDiaperLogView: View {
    let babyId: UUID
    let viewModel: DiaperViewModel
    let onDismiss: () -> Void

    @State private var selectedType: Diaper.DiaperType = .wet
    @State private var stoolConsistency: Diaper.StoolConsistency?
    @State private var stoolColor: Diaper.StoolColor?
    @State private var hasRash = false
    @State private var notes = ""
    @State private var showDetails = false
    @State private var isLogging = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: MCSpacing.xl) {
                    typeSelector
                    detailsToggle
                    logButton
                }
                .padding(MCSpacing.lg)
            }
            .navigationTitle("Log Diaper")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { onDismiss() }
                }
            }
        }
    }

    // MARK: - Type Selector

    @ViewBuilder
    private var typeSelector: some View {
        HStack(spacing: MCSpacing.sm) {
            ForEach(Diaper.DiaperType.allCases, id: \.self) { type in
                TypeToggleButton(
                    type: type,
                    isSelected: selectedType == type
                ) {
                    MCHaptic.tap()
                    withAnimation(.spring(response: 0.2, dampingFraction: 0.7)) {
                        selectedType = type
                        if !type.hasStoolContext {
                            stoolConsistency = nil
                            stoolColor = nil
                        }
                    }
                }
            }
        }
    }

    // MARK: - Details

    @ViewBuilder
    private var detailsToggle: some View {
        VStack(spacing: 0) {
            Button {
                MCHaptic.tap()
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    showDetails.toggle()
                }
            } label: {
                HStack {
                    Text("Details")
                        .font(.subheadline.bold())
                        .foregroundStyle(.secondary)
                    Spacer()
                    Image(systemName: showDetails ? "chevron.up" : "chevron.down")
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)
                }
                .padding(MCSpacing.md)
                .background {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.ultraThinMaterial)
                }
            }

            if showDetails {
                detailsSection
                    .padding(.top, MCSpacing.sm)
            }
        }
    }

    @ViewBuilder
    private var detailsSection: some View {
        VStack(spacing: MCSpacing.md) {
            if selectedType.hasStoolContext {
                consistencyPicker
                colorPicker
            }

            Toggle(isOn: $hasRash) {
                Label("Diaper Rash", systemImage: "exclamationmark.circle")
                    .font(.subheadline)
            }
            .padding(MCSpacing.md)
            .background {
                RoundedRectangle(cornerRadius: 12)
                    .fill(.ultraThinMaterial)
            }

            TextField("Notes (optional)", text: $notes, axis: .vertical)
                .font(.subheadline)
                .padding(MCSpacing.md)
                .background {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.ultraThinMaterial)
                }
                .lineLimit(2...4)
        }
    }

    @ViewBuilder
    private var consistencyPicker: some View {
        VStack(alignment: .leading, spacing: MCSpacing.xs) {
            Text("Consistency")
                .font(.caption.bold())
                .foregroundStyle(.secondary)
            HStack(spacing: MCSpacing.xs) {
                ForEach(Diaper.StoolConsistency.allCases, id: \.self) { consistency in
                    Button {
                        MCHaptic.tap()
                        stoolConsistency = stoolConsistency == consistency ? nil : consistency
                    } label: {
                        Text(consistency.label)
                            .font(.caption.bold())
                            .padding(.horizontal, MCSpacing.sm)
                            .padding(.vertical, MCSpacing.xs)
                            .background {
                                Capsule()
                                    .fill(stoolConsistency == consistency
                                          ? MCColor.diaper.opacity(0.3)
                                          : Color.secondary.opacity(0.1))
                            }
                            .foregroundStyle(stoolConsistency == consistency ? MCColor.diaper : .secondary)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(MCSpacing.md)
        .background {
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
        }
    }

    @ViewBuilder
    private var colorPicker: some View {
        VStack(alignment: .leading, spacing: MCSpacing.xs) {
            Text("Color")
                .font(.caption.bold())
                .foregroundStyle(.secondary)
            HStack(spacing: MCSpacing.xs) {
                ForEach(Diaper.StoolColor.allCases, id: \.self) { color in
                    Button {
                        MCHaptic.tap()
                        stoolColor = stoolColor == color ? nil : color
                    } label: {
                        Text(color.label)
                            .font(.caption.bold())
                            .padding(.horizontal, MCSpacing.sm)
                            .padding(.vertical, MCSpacing.xs)
                            .background {
                                Capsule()
                                    .fill(stoolColor == color
                                          ? MCColor.diaper.opacity(0.3)
                                          : Color.secondary.opacity(0.1))
                            }
                            .foregroundStyle(stoolColor == color ? MCColor.diaper : .secondary)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(MCSpacing.md)
        .background {
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
        }
    }

    // MARK: - Log Button

    @ViewBuilder
    private var logButton: some View {
        Button {
            guard !isLogging else { return }
            isLogging = true
            Task { @MainActor in
                let params = DiaperViewModel.QuickLogParams(
                    babyId: babyId,
                    type: selectedType,
                    stoolConsistency: stoolConsistency,
                    stoolColor: stoolColor,
                    hasRash: hasRash,
                    notes: notes
                )
                if await viewModel.logQuickDiaper(params) {
                    MCHaptic.success()
                    onDismiss()
                } else {
                    isLogging = false
                }
            }
        } label: {
            Group {
                if isLogging {
                    ProgressView()
                        .tint(.white)
                } else {
                    Text("Log Diaper")
                        .font(.headline)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(MCColor.diaper)
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .disabled(isLogging)
    }
}

// MARK: - Type Toggle Button

private struct TypeToggleButton: View {
    let type: Diaper.DiaperType
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: MCSpacing.xs) {
                Image(systemName: type.systemImage)
                    .font(.title2)
                Text(type.label)
                    .font(.subheadline.bold())
            }
            .frame(maxWidth: .infinity)
            .frame(height: 80)
            .background {
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ? MCColor.diaper.opacity(0.2) : Color.secondary.opacity(0.08))
                    .overlay {
                        RoundedRectangle(cornerRadius: 16)
                            .strokeBorder(
                                isSelected ? MCColor.diaper : Color.clear,
                                lineWidth: 2
                            )
                    }
            }
            .foregroundStyle(isSelected ? MCColor.diaper : .secondary)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - DiaperType Helpers (view-layer only)

private extension Diaper.DiaperType {
    var hasStoolContext: Bool { self == .dirty || self == .both }
}
