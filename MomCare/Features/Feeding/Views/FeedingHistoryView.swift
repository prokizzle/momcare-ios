import SwiftUI

struct FeedingHistoryView: View {
    @Bindable var viewModel: FeedingViewModel
    let babyId: UUID
    @State private var feedingToDelete: Feeding?

    var body: some View {
        List {
            ForEach(viewModel.groupedFeedings, id: \.0) { section in
                Section(section.0) {
                    ForEach(section.1) { feeding in
                        NavigationLink(value: feeding.id) {
                            FeedingListItem(feeding: feeding)
                        }
                        .swipeActions(edge: .trailing) {
                            Button("Delete", role: .destructive) {
                                feedingToDelete = feeding
                            }
                        }
                    }
                }
            }
        }
        .confirmationDialog(
            "Delete Feeding?",
            isPresented: Binding(
                get: { feedingToDelete != nil },
                set: { if !$0 { feedingToDelete = nil } }
            )
        ) {
            Button("Delete", role: .destructive) {
                if let feeding = feedingToDelete {
                    Task { await viewModel.deleteFeeding(feeding.id) }
                }
            }
        } message: {
            Text("This feeding record will be removed.")
        }
    }
}
