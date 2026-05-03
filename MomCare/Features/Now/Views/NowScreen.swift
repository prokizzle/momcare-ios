import SwiftUI

@MainActor
struct NowScreen: View {
    var dashboardViewModel: DashboardViewModel?
    let babyId: UUID?
    var sleepViewModel: SleepViewModel?
    var selfCareViewModel: SelfCareViewModel?

    @Environment(AppNavigation.self) private var navigation

    var body: some View {
        Group {
            if let viewModel = dashboardViewModel {
                loadedView(viewModel: viewModel)
            } else {
                ProgressView()
            }
        }
        .navigationTitle("Now")
    }

    @ViewBuilder
    private func loadedView(viewModel: DashboardViewModel) -> some View {
        ScrollView {
            VStack(spacing: MCSpacing.lg) {
                BabyStatusStrip(babyId: babyId)
                DashboardActionDeck(
                    babyId: babyId,
                    sleepViewModel: sleepViewModel,
                    selfCareViewModel: selfCareViewModel
                )
                BabyStatusCard(viewModel: viewModel)
                MomStatusCard(viewModel: viewModel)

                if !viewModel.visibleSuggestions.isEmpty {
                    suggestionsSection(viewModel: viewModel)
                }
            }
            .padding(.horizontal, MCSpacing.xl)
            .padding(.vertical, MCSpacing.lg)
        }
        .ambientBackground()
        .task {
            await viewModel.loadDashboard(babyId: babyId)
        }
    }

    @ViewBuilder
    private func suggestionsSection(viewModel: DashboardViewModel) -> some View {
        VStack(alignment: .leading, spacing: MCSpacing.sm) {
            Text("Suggestions")
                .font(MCTypography.badge)
                .foregroundStyle(.secondary)
                .padding(.horizontal, MCSpacing.xs)

            ForEach(viewModel.visibleSuggestions) { suggestion in
                SmartSuggestionBanner(
                    suggestion: suggestion,
                    onDismiss: { viewModel.dismissSuggestion(suggestion) },
                    onTap: suggestion.actionTab.map { tab in
                        { navigation.selectedTab = tab }
                    }
                )
            }
        }
    }
}
