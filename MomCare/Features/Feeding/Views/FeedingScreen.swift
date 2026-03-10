import SwiftUI

struct FeedingScreen: View {
    var viewModel: FeedingViewModel?
    let babyId: UUID?

    @State private var showTimer = false

    var body: some View {
        Group {
            if let viewModel, let babyId {
                loadedView(viewModel: viewModel, babyId: babyId)
            } else {
                ProgressView()
            }
        }
    }

    @ViewBuilder
    private func loadedView(viewModel: FeedingViewModel, babyId: UUID) -> some View {
        ScrollView {
            VStack(spacing: MCSpacing.lg) {
                if let pattern = viewModel.pattern, !pattern.isInsufficient {
                    FeedingPatternCard(
                        pattern: pattern,
                        lastFeedTime: viewModel.feedings.first?.startTime
                    )
                    .padding(.horizontal, MCSpacing.md)
                }

                QuickFeedButton {
                    Task { await viewModel.startFeeding(babyId: babyId, type: viewModel.selectedType) }
                    showTimer = true
                }
                .padding(.horizontal, MCSpacing.md)

                if !viewModel.feedings.isEmpty {
                    FeedingHistoryView(viewModel: viewModel, babyId: babyId)
                }
            }
            .padding(.top, MCSpacing.md)
        }
        .navigationTitle("Feeding")
        .navigationDestination(isPresented: $showTimer) {
            FeedingTimerView(viewModel: viewModel)
        }
        .navigationDestination(for: UUID.self) { (feedingId: UUID) in
            if let feeding = viewModel.feedings.first(where: { $0.id == feedingId }) {
                FeedingDetailView(viewModel: viewModel, feedingId: feedingId, feeding: feeding)
            }
        }
        .task {
            await viewModel.loadFeedings(babyId: babyId)
            await viewModel.analyzePattern(babyId: babyId)
            if viewModel.inProgressFeeding != nil {
                showTimer = true
            }
        }
    }
}
