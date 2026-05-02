import SwiftUI

@MainActor
struct MomStatusCard: View {
    let viewModel: DashboardViewModel

    var body: some View {
        HStack(spacing: MCSpacing.lg) {
            CompletionRingView(
                percentage: viewModel.dailySummary.completionPercentage,
                size: 56,
                lineWidth: 5
            )

            VStack(alignment: .leading, spacing: MCSpacing.xs) {
                Text("Your day")
                    .mcBadge()
                    .foregroundStyle(MCColor.selfCare)

                Text("You're tracking gently")
                    .font(MCTypography.headline)
                    .foregroundStyle(MCColor.Foreground.level1)

                Text(summaryText)
                    .font(MCTypography.footnote)
                    .foregroundStyle(MCColor.Foreground.level3)
            }

            Spacer(minLength: 0)
        }
        .padding(MCSpacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            RoundedRectangle(cornerRadius: MCRadius.lg)
                .fill(MCElevation.elevated)
                .overlay {
                    RoundedRectangle(cornerRadius: MCRadius.lg)
                        .stroke(MCColor.selfCare.opacity(MCOpacity.soft), lineWidth: 1)
                }
        }
    }

    private var summaryText: String {
        "\(viewModel.dailySummary.waterGlassesToday) glasses · \(viewModel.dailySummary.mealsToday) meals · "
        + "\(viewModel.dailySummary.totalActionsToday) actions"
    }
}
