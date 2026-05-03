import SwiftUI

@MainActor
struct FeedingTimerView: View {
    @Bindable var viewModel: FeedingViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var showEndConfirmation = false

    var body: some View {
        VStack(spacing: MCSpacing.xl) {
            header
            Spacer()
            VStack(spacing: MCSpacing.xxl) {
                timerDisplay
                if viewModel.inProgressFeeding?.feedingType == .breast {
                    breastSideToggle
                }
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

    private var header: some View {
        HStack {
            Button("Cancel") {
                MCHaptic.tap()
                dismiss()
            }
            .frame(minWidth: 44, minHeight: 44, alignment: .leading)
            .contentShape(Rectangle())
            .font(MCTypography.button)
            .foregroundStyle(MCColor.Foreground.level2)

            Spacer()

            HStack(spacing: MCSpacing.sm) {
                if let feedingType = viewModel.inProgressFeeding?.feedingType {
                    Image(systemName: feedingType.systemImage)
                        .font(.subheadline)
                        .accessibilityHidden(true)
                    Text(feedingType.label)
                        .font(MCTypography.headline)
                }
            }
            .foregroundStyle(MCColor.Foreground.level2)

            Spacer()
            Color.clear.frame(width: 60, height: 1)
        }
    }

    private var timerDisplay: some View {
        ZStack {
            FeedingTimerRing(
                startTime: viewModel.inProgressFeeding?.startTime,
                timerText: viewModel.elapsedTimeFormatted
            )
            VStack(spacing: 90) {
                Text("Active")
                    .mcBadge()
                    .foregroundStyle(MCColor.feeding)
                Text("Hold steady")
                    .font(MCTypography.footnote)
                    .foregroundStyle(MCColor.Foreground.level3)
                    .tracking(MCTypography.badgeTracking)
                    .textCase(.uppercase)
            }
        }
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
                        : MCElevation.surface
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
