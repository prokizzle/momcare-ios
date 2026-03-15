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
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

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
                    withAnimation(reduceMotion ? nil : MCAnimation.quick) {
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
                withAnimation(reduceMotion ? nil : MCAnimation.quick) {
                    showDetails.toggle()
                }
            } label: {
                HStack {
                    Text("Details")
                        .font(MCTypography.subheadline).fontWeight(.bold)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Image(systemName: showDetails ? "chevron.up" : "chevron.down")
                        .font(MCTypography.badge)
                        .foregroundStyle(.secondary)
                }
                .padding(MCSpacing.md)
                .background {
                    RoundedRectangle(cornerRadius: MCRadius.md)
                        .fill(MCElevation.surface)
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
                    .font(MCTypography.subheadline)
            }
            .padding(MCSpacing.md)
            .background {
                RoundedRectangle(cornerRadius: MCRadius.md)
                    .fill(MCElevation.surface)
            }

            TextField("Notes (optional)", text: $notes, axis: .vertical)
                .font(MCTypography.subheadline)
                .padding(MCSpacing.md)
                .background {
                    RoundedRectangle(cornerRadius: MCRadius.md)
                        .fill(MCElevation.surface)
                }
                .lineLimit(2...4)
        }
    }

    @ViewBuilder
    private var consistencyPicker: some View {
        VStack(alignment: .leading, spacing: MCSpacing.xs) {
            Text("Consistency")
                .font(MCTypography.badge)
                .foregroundStyle(.secondary)
            HStack(spacing: MCSpacing.xs) {
                ForEach(Diaper.StoolConsistency.allCases, id: \.self) { consistency in
                    Button {
                        MCHaptic.tap()
                        stoolConsistency = stoolConsistency == consistency ? nil : consistency
                    } label: {
                        Text(consistency.label)
                            .font(MCTypography.badge)
                            .padding(.horizontal, MCSpacing.sm)
                            .padding(.vertical, MCSpacing.xs)
                            .background {
                                Capsule()
                                    .fill(stoolConsistency == consistency
                                          ? MCColor.diaper.opacity(MCOpacity.strong)
                                          : Color.secondary.opacity(MCOpacity.soft))
                            }
                            .foregroundStyle(stoolConsistency == consistency ? MCColor.diaper : .secondary)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(MCSpacing.md)
        .background {
            RoundedRectangle(cornerRadius: MCRadius.md)
                .fill(MCElevation.surface)
        }
    }

    @ViewBuilder
    private var colorPicker: some View {
        VStack(alignment: .leading, spacing: MCSpacing.xs) {
            Text("Color")
                .font(MCTypography.badge)
                .foregroundStyle(.secondary)
            HStack(spacing: MCSpacing.xs) {
                ForEach(Diaper.StoolColor.allCases, id: \.self) { color in
                    Button {
                        MCHaptic.tap()
                        stoolColor = stoolColor == color ? nil : color
                    } label: {
                        Text(color.label)
                            .font(MCTypography.badge)
                            .padding(.horizontal, MCSpacing.sm)
                            .padding(.vertical, MCSpacing.xs)
                            .background {
                                Capsule()
                                    .fill(stoolColor == color
                                          ? MCColor.diaper.opacity(MCOpacity.strong)
                                          : Color.secondary.opacity(MCOpacity.soft))
                            }
                            .foregroundStyle(stoolColor == color ? MCColor.diaper : .secondary)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(MCSpacing.md)
        .background {
            RoundedRectangle(cornerRadius: MCRadius.md)
                .fill(MCElevation.surface)
        }
    }

    // MARK: - Log Button

    @ViewBuilder
    private var logButton: some View {
        Button {
            guard !isLogging else { return }
            isLogging = true
            Task {
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
                        .font(MCTypography.headline)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(MCColor.diaper)
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: MCRadius.lg))
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
                    .font(MCTypography.subheadline).fontWeight(.bold)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 80)
            .background {
                RoundedRectangle(cornerRadius: MCRadius.lg)
                    .fill(
                        isSelected
                            ? MCColor.diaper.opacity(MCOpacity.medium)
                            : Color.secondary.opacity(MCOpacity.whisper)
                    )
                    .overlay {
                        RoundedRectangle(cornerRadius: MCRadius.lg)
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
