import SwiftUI

@MainActor
struct FeedingTimerView: View {
    @Bindable var viewModel: FeedingViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var showEndConfirmation = false

    var body: some View {
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
        .nightlightBackground()
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
                    .font(MCTypography.title3)
            }
        }
        .foregroundStyle(.secondary)
    }

    private var timerDisplay: some View {
        FeedingTimerRing(
            startTime: viewModel.inProgressFeeding?.startTime,
            timerText: viewModel.elapsedTimeFormatted
        )
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
                .font(MCTypography.headline)
                .frame(minWidth: 80, minHeight: 80)
                .background(
                    viewModel.selectedSide == side
                        ? MCColor.feeding.opacity(MCOpacity.medium)
                        : Color.white.opacity(MCOpacity.whisper)
                )
                .clipShape(RoundedRectangle(cornerRadius: MCRadius.lg))
                .overlay(
                    RoundedRectangle(cornerRadius: MCRadius.lg)
                        .stroke(
                            viewModel.selectedSide == side
                                ? MCColor.feeding
                                : Color.clear,
                            lineWidth: 2
                        )
                )
        }
        .foregroundStyle(.white)
        .accessibilityLabel("\(side.label) breast")
        .accessibilityAddTraits(viewModel.selectedSide == side ? .isSelected : [])
    }

    private var endButton: some View {
        Button {
            showEndConfirmation = true
            MCHaptic.tap()
        } label: {
            Text("End Feeding")
                .font(MCTypography.button)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(MCColor.feeding)
                .clipShape(RoundedRectangle(cornerRadius: MCRadius.lg))
        }
        .padding(.bottom, MCSpacing.xxl)
    }
}
