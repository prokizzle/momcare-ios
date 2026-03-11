import SwiftUI

@MainActor
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
        VStack(spacing: 0) {
            VStack(spacing: MCSpacing.md) {
                if let pattern = viewModel.pattern, !pattern.isInsufficient {
                    FeedingPatternCard(
                        pattern: pattern,
                        lastFeedTime: viewModel.feedings.first?.startTime
                    )
                    .padding(.horizontal, MCSpacing.md)
                }

                QuickFeedButton {
                    Task {
                        await viewModel.startFeeding(babyId: babyId, type: viewModel.selectedType)
                        if viewModel.inProgressFeeding != nil {
                            showTimer = true
                        }
                    }
                }
                .padding(.horizontal, MCSpacing.md)
                .padding(.bottom, MCSpacing.sm)
            }
            .padding(.top, MCSpacing.md)

            FeedingHistoryView(viewModel: viewModel, babyId: babyId)
        }
        .navigationTitle("Feeding")
        .navigationDestination(isPresented: $showTimer) {
            FeedingTimerView(viewModel: viewModel)
        }
        .navigationDestination(for: UUID.self) { (feedingId: UUID) in
            if let feeding = viewModel.feedingsById[feedingId] {
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
