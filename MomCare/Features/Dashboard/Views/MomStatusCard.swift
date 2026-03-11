import SwiftUI

@MainActor
struct MomStatusCard: View {
    let viewModel: DashboardViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: MCSpacing.md) {
            Label("Your Day", systemImage: "sparkles")
                .font(.caption.bold())
                .foregroundStyle(MCColor.selfCare)

            HStack(spacing: MCSpacing.xl) {
                CompletionRingView(
                    percentage: viewModel.dailySummary.completionPercentage,
                    size: 64,
                    lineWidth: 6
                )

                VStack(alignment: .leading, spacing: MCSpacing.xs) {
                    statsRow(
                        icon: "cup.and.saucer.fill",
                        value: "\(viewModel.dailySummary.waterGlassesToday)",
                        label: "glasses of water"
                    )
                    statsRow(
                        icon: "fork.knife",
                        value: "\(viewModel.dailySummary.mealsToday)",
                        label: viewModel.dailySummary.mealsToday == 1 ? "meal" : "meals"
                    )
                    statsRow(
                        icon: "checkmark.circle.fill",
                        value: "\(viewModel.dailySummary.totalActionsToday)",
                        label: "self-care actions"
                    )
                }

                Spacer()
            }
        }
        .padding(MCSpacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
        }
    }

    private func statsRow(icon: String, value: String, label: String) -> some View {
        HStack(spacing: MCSpacing.xs) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(MCColor.selfCare)
                .frame(width: 16)
            Text("\(value) \(label)")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}
