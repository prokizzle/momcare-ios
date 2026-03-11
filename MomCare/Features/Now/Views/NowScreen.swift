import SwiftUI

@MainActor
struct NowScreen: View {
    var dashboardViewModel: DashboardViewModel?
    let babyId: UUID?

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

                if !viewModel.visibleSuggestions.isEmpty {
                    suggestionsSection(viewModel: viewModel)
                }
            }
            .padding(.horizontal, MCSpacing.lg)
            .padding(.vertical, MCSpacing.lg)
        }
        .task {
            await viewModel.loadDashboard(babyId: babyId)
        }
    }

    @ViewBuilder
    private func suggestionsSection(viewModel: DashboardViewModel) -> some View {
        VStack(alignment: .leading, spacing: MCSpacing.sm) {
            Text("Suggestions")
                .font(.caption.bold())
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
