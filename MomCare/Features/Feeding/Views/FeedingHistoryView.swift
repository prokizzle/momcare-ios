import SwiftUI

struct FeedingHistoryView: View {
    @Bindable var viewModel: FeedingViewModel
    let babyId: UUID
    @State private var feedingToDelete: Feeding?

    private var groupedFeedings: [(String, [Feeding])] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: viewModel.feedings) { feeding -> String in
            if calendar.isDateInToday(feeding.startTime) {
                return "Today"
            } else if calendar.isDateInYesterday(feeding.startTime) {
                return "Yesterday"
            } else {
                return feeding.startTime.formatted(date: .abbreviated, time: .omitted)
            }
        }
        return grouped.sorted { lhs, rhs in
            let lhsDate = lhs.value.first?.startTime ?? .distantPast
            let rhsDate = rhs.value.first?.startTime ?? .distantPast
            return lhsDate > rhsDate
        }
    }

    var body: some View {
        List {
            ForEach(groupedFeedings, id: \.0) { section in
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
        .navigationTitle("Feeding History")
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
            Text("This feeding record will be permanently removed.")
        }
    }
}
