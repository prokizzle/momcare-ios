import SwiftUI

@MainActor
struct DiaperScreen: View {
    var viewModel: DiaperViewModel?
    let babyId: UUID?

    @State private var showQuickLog = false

    var body: some View {
        Group {
            if let viewModel, let babyId {
                loadedView(viewModel: viewModel, babyId: babyId)
            } else {
                ProgressView()
            }
        }
        .navigationTitle("Diapers")
    }

    @ViewBuilder
    private func loadedView(viewModel: DiaperViewModel, babyId: UUID) -> some View {
        DiaperHistoryView(viewModel: viewModel, babyId: babyId)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        MCHaptic.tap()
                        showQuickLog = true
                    } label: {
                        Image(systemName: "plus")
                            .accessibilityLabel("Log diaper change")
                    }
                }
            }
            .sheet(isPresented: $showQuickLog) {
                QuickDiaperLogView(babyId: babyId, viewModel: viewModel) {
                    showQuickLog = false
                }
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
            }
    }
}

#Preview {
    NavigationStack {
        DiaperScreen(viewModel: nil, babyId: nil)
    }
}
