import SwiftUI

@MainActor
struct BabyStatusCard: View {
    let viewModel: DashboardViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: MCSpacing.md) {
            Text(viewModel.inProgressFeeding == nil ? "Since last feed" : "Active")
                .mcBadge()
                .foregroundStyle(viewModel.urgency.color)

            if viewModel.inProgressFeeding != nil {
                inProgressRow
            } else {
                timeSinceRow
            }
        }
        .padding(MCSpacing.xl)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            RoundedRectangle(cornerRadius: MCRadius.xl)
                .fill(MCElevation.elevated)
                .overlay {
                    RoundedRectangle(cornerRadius: MCRadius.xl)
                        .stroke(viewModel.urgency.color.opacity(MCOpacity.medium), lineWidth: 1)
                }
                .shadow(color: viewModel.urgency.color.opacity(MCOpacity.soft), radius: 30)
        }
    }

    @ViewBuilder
    private var inProgressRow: some View {
        @Environment(\.accessibilityReduceMotion) var reduceMotion

        HStack(alignment: .top, spacing: MCSpacing.md) {
            VStack(alignment: .leading, spacing: MCSpacing.xs) {
                Text("Feeding in progress")
                    .font(MCTypography.headline)
                    .foregroundStyle(MCColor.Foreground.level1)
                Text("Timer running now")
                    .font(MCTypography.footnote)
                    .foregroundStyle(MCColor.Foreground.level3)
            }
            Spacer()
            iconBubble(systemName: "drop.fill", color: MCColor.feeding)
                .symbolEffect(.pulse, isActive: !reduceMotion)
        }
    }

    @ViewBuilder
    private var timeSinceRow: some View {
        HStack(alignment: .top, spacing: MCSpacing.md) {
            VStack(alignment: .leading, spacing: MCSpacing.xs) {
                Group {
                    if viewModel.timeSinceLastFeeding != nil {
                        TimelineView(.periodic(from: .now, by: 60)) { _ in
                            Text(viewModel.timeSinceLastFeedingFormatted)
                                .font(MCTypography.display)
                                .foregroundStyle(MCColor.Foreground.level1)
                                .monospacedDigit()
                        }
                    } else {
                        Text("No feeding recorded")
                            .font(MCTypography.title2)
                            .foregroundStyle(MCColor.Foreground.level1)
                    }
                }

                Text(viewModel.urgency.label)
                    .font(MCTypography.footnote)
                    .foregroundStyle(MCColor.Foreground.level3)
            }
            Spacer()
            iconBubble(systemName: "drop.fill", color: viewModel.urgency.color)
        }
    }

    private func iconBubble(systemName: String, color: Color) -> some View {
        Circle()
            .fill(color.opacity(MCOpacity.soft))
            .frame(width: 56, height: 56)
            .overlay {
                Image(systemName: systemName)
                    .font(.title2)
                    .foregroundStyle(color)
                    .accessibilityHidden(true)
            }
    }
}
