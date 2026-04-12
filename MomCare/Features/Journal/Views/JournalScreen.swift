import SwiftUI

@MainActor
struct JournalScreen: View {
    var viewModel: JournalViewModel?
    let babyId: UUID?
    @State private var didLoad = false

    var body: some View {
        Group {
            if let viewModel {
                loadedView(viewModel: viewModel)
            } else {
                ProgressView()
            }
        }
        .navigationTitle("Journal")
    }

    @ViewBuilder
    private func loadedView(viewModel: JournalViewModel) -> some View {
        VStack(spacing: 0) {
            filterChips(viewModel: viewModel)
                .padding(.horizontal, MCSpacing.lg)
                .padding(.vertical, MCSpacing.sm)

            if !didLoad {
                ProgressView()
            } else if viewModel.groupedEntries.isEmpty {
                EmptyStateView(
                    illustration: .emptyJournal,
                    title: "No Journal Entries",
                    message: "Capture moments, milestones, and reflections for your little one."
                )
            } else {
                List {
                    ForEach(viewModel.groupedEntries, id: \.0) { section, entries in
                        Section(section) {
                            ForEach(entries) { entry in
                                JournalEntryRow(entry: entry)
                            }
                        }
                    }
                }
                .listStyle(.insetGrouped)
                .refreshable {
                    guard let babyId else { return }
                    await viewModel.load(babyId: babyId)
                }
            }
        }
        .task {
            guard !didLoad, let babyId else { return }
            didLoad = true
            await viewModel.load(babyId: babyId)
        }
    }

    @ViewBuilder
    private func filterChips(viewModel: JournalViewModel) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: MCSpacing.sm) {
                filterChip(label: "All", kind: nil, viewModel: viewModel)
                filterChip(label: "Naps", kind: .nap, viewModel: viewModel)
                filterChip(label: "Feeding", kind: .feeding, viewModel: viewModel)
                filterChip(label: "Diapers", kind: .diaper, viewModel: viewModel)
            }
        }
    }

    @ViewBuilder
    private func filterChip(
        label: String,
        kind: JournalEntryKind?,
        viewModel: JournalViewModel
    ) -> some View {
        let isSelected = viewModel.selectedFilter == kind
        Button {
            MCHaptic.tap()
            viewModel.selectedFilter = kind
        } label: {
            Text(label)
                .font(MCTypography.badge)
                .padding(.horizontal, MCSpacing.md)
                .padding(.vertical, MCSpacing.xs)
                .background {
                    Capsule()
                        .fill(isSelected ? MCColor.baby : Color.secondary.opacity(MCOpacity.medium))
                }
                .foregroundStyle(isSelected ? .white : .primary)
        }
        .buttonStyle(.plain)
    }
}
