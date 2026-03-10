import SwiftUI

@MainActor
struct SelfCareScreen: View {
    var viewModel: SelfCareViewModel?

    @State private var showDetailSheet = false
    @State private var detailActionType: SelfCareActionType?
    @State private var didLoad = false

    var body: some View {
        Group {
            if let viewModel {
                loadedView(viewModel: viewModel)
            } else {
                ProgressView()
            }
        }
        .navigationTitle("Self-Care")
    }

    @ViewBuilder
    private func loadedView(viewModel: SelfCareViewModel) -> some View {
        ScrollView {
            VStack(spacing: MCSpacing.xl) {
                ActionGridView(
                    gridItems: viewModel.gridItems,
                    recentlyTapped: { viewModel.isRecentlyTapped($0) },
                    waterCount: viewModel.waterCountToday,
                    onTap: { actionType in
                        Task { await viewModel.logAction(actionType) }
                    },
                    onLongPress: { actionType in
                        detailActionType = actionType
                        showDetailSheet = true
                    }
                )

                CardFeedView(
                    cards: viewModel.cards,
                    onDismiss: { viewModel.dismissCard($0) }
                )
            }
            .padding(.vertical, MCSpacing.lg)
        }
        .task {
            guard !didLoad else { return }
            didLoad = true
            await viewModel.loadDay(.now)
            await viewModel.handleEvent(.appOpened)
        }
        .sheet(isPresented: $showDetailSheet) {
            if let actionType = detailActionType {
                LogDetailSheet(actionType: actionType) { detail in
                    Task { await viewModel.logAction(actionType, detail: detail) }
                }
            }
        }
    }
}
