import SwiftUI

struct FeedingTimerView: View {
    @Bindable var viewModel: FeedingViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showEndConfirmation = false

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: MCSpacing.xxl) {
                feedingTypeIndicator
                timerDisplay
                if viewModel.inProgressFeeding?.feedingType == .breast {
                    breastSideToggle
                }
                Spacer()
                endButton
            }
            .padding(.horizontal, MCSpacing.xl)
            .padding(.top, MCSpacing.section)
        }
        .confirmationDialog("End Feeding?", isPresented: $showEndConfirmation) {
            Button("End Feeding") {
                Task {
                    await viewModel.endFeeding()
                    MCHaptic.success()
                    dismiss()
                }
            }
        } message: {
            Text("Save this feeding session?")
        }
    }

    private var feedingTypeIndicator: some View {
        HStack(spacing: MCSpacing.sm) {
            if let feedingType = viewModel.inProgressFeeding?.feedingType {
                Image(systemName: feedingType.systemImage)
                    .font(.title2)
                Text(feedingType.label)
                    .font(MCTypography.cardTitle)
            }
        }
        .foregroundStyle(.secondary)
    }

    private var timerDisplay: some View {
        Text(formattedTime)
            .font(MCTypography.largeTimer)
            .monospacedDigit()
            .foregroundStyle(.white)
            .contentTransition(.numericText())
    }

    private var formattedTime: String {
        let totalSeconds = Int(viewModel.elapsedTime)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        }
        return String(format: "%02d:%02d", minutes, seconds)
    }

    private var breastSideToggle: some View {
        HStack(spacing: MCSpacing.lg) {
            sideButton(side: .left)
            sideButton(side: .right)
        }
    }

    private func sideButton(side: Feeding.BreastSide) -> some View {
        Button {
            if viewModel.selectedSide != side {
                viewModel.toggleBreastSide()
                MCHaptic.toggle()
            }
        } label: {
            Text(side.label)
                .font(.title2.weight(.semibold))
                .frame(minWidth: 80, minHeight: 80)
                .background(
                    viewModel.selectedSide == side
                        ? MCColor.feeding.opacity(0.3)
                        : Color.white.opacity(0.1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            viewModel.selectedSide == side
                                ? MCColor.feeding
                                : Color.clear,
                            lineWidth: 2
                        )
                )
        }
        .foregroundStyle(.white)
    }

    private var endButton: some View {
        Button {
            showEndConfirmation = true
            MCHaptic.tap()
        } label: {
            Text("End Feeding")
                .font(.title3.weight(.semibold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(MCColor.feeding)
                .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .padding(.bottom, MCSpacing.xxl)
    }
}
