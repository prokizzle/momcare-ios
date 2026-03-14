import SwiftUI

@MainActor
struct BabyStatusCard: View {
    let viewModel: DashboardViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: MCSpacing.md) {
            Label("Baby", systemImage: "heart.fill")
                .font(MCTypography.badge)
                .foregroundStyle(MCColor.feeding)

            if viewModel.inProgressFeeding != nil {
                inProgressRow
            } else {
                timeSinceRow
            }
        }
        .padding(MCSpacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            RoundedRectangle(cornerRadius: MCRadius.lg)
                .fill(MCElevation.elevated)
        }
    }

    @ViewBuilder
    private var inProgressRow: some View {
        @Environment(\.accessibilityReduceMotion) var reduceMotion

        HStack {
            VStack(alignment: .leading, spacing: MCSpacing.xs) {
                Text("Feeding in progress")
                    .font(MCTypography.headline)
                    .foregroundStyle(.primary)
                Text("Timer running")
                    .font(MCTypography.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Image(systemName: "drop.fill")
                .font(.title2)
                .foregroundStyle(MCColor.feeding)
                .symbolEffect(.pulse, isActive: !reduceMotion)
        }
    }

    @ViewBuilder
    private var timeSinceRow: some View {
        HStack {
            VStack(alignment: .leading, spacing: MCSpacing.xs) {
                Group {
                    if viewModel.timeSinceLastFeeding != nil {
                        TimelineView(.periodic(from: .now, by: 60)) { _ in
                            Text(viewModel.timeSinceLastFeedingFormatted)
                                .font(MCTypography.stat)
                                .foregroundStyle(viewModel.urgency.color)
                        }
                    } else {
                        Text("No feeding recorded")
                            .font(MCTypography.headline)
                            .foregroundStyle(.secondary)
                    }
                }

                Text(viewModel.urgency.label)
                    .font(MCTypography.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Circle()
                .fill(viewModel.urgency.color.opacity(MCOpacity.medium))
                .frame(width: 44, height: 44)
                .overlay {
                    Image(systemName: "clock.fill")
                        .font(.title3)
                        .foregroundStyle(viewModel.urgency.color)
                }
        }
    }

}
