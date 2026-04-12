import SwiftUI

@MainActor
struct SleepHistoryView: View {
    let viewModel: SleepViewModel
    let babyId: UUID
    @State private var sleepToDelete: BabySleep?

    var body: some View {
        Group {
            if viewModel.sleeps.isEmpty && !viewModel.isLoading {
                ContentUnavailableView(
                    "No Sleep Records",
                    systemImage: "moon.zzz",
                    description: Text("Sleep sessions will appear here.")
                )
            } else {
                sleepList
            }
        }
        .navigationTitle("Sleep History")
        .task { await viewModel.loadSleeps(babyId: babyId) }
        .confirmationDialog(
            "Delete Sleep Record?",
            isPresented: Binding(
                get: { sleepToDelete != nil },
                set: { if !$0 { sleepToDelete = nil } }
            )
        ) {
            Button("Delete", role: .destructive) {
                if let sleep = sleepToDelete {
                    MCHaptic.error()
                    Task { await viewModel.deleteSleep(id: sleep.id) }
                }
            }
        } message: {
            Text("This sleep record will be removed.")
        }
    }

    private var sleepList: some View {
        List {
            ForEach(viewModel.groupedSleeps, id: \.0) { section in
                Section {
                    ForEach(section.1) { sleep in
                        sleepRow(sleep)
                            .swipeActions(edge: .trailing) {
                                Button("Delete", role: .destructive) {
                                    sleepToDelete = sleep
                                }
                            }
                    }
                } header: {
                    sectionHeader(title: section.0, sleeps: section.1)
                }
            }
        }
        .listStyle(.insetGrouped)
        .refreshable {
                guard !viewModel.isLoading else { return }
                await viewModel.loadSleeps(babyId: babyId)
            }
    }

    private func sectionHeader(title: String, sleeps: [BabySleep]) -> some View {
        HStack {
            Text(title)
            Spacer()
            Text(viewModel.formattedDuration(viewModel.dailyTotal(for: sleeps)))
                .foregroundStyle(.secondary)
        }
    }

    private func sleepRow(_ sleep: BabySleep) -> some View {
        HStack(spacing: MCSpacing.md) {
            Image(systemName: sleep.sleepType.systemImage)
                .font(.title3)
                .foregroundStyle(MCColor.baby)
                .frame(width: 32, height: 32)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: MCSpacing.xs) {
                Text(sleep.sleepType.label)
                    .font(MCTypography.title3)
                HStack(spacing: MCSpacing.xs) {
                    Text(viewModel.formattedDuration(sleep.duration))
                    if let location = sleep.location {
                        Text("--")
                            .foregroundStyle(.tertiary)
                        Text(location.label)
                    }
                }
                .font(MCTypography.callout)
                .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: MCSpacing.xs) {
                Text(sleep.startTime, style: .time)
                    .font(MCTypography.timestamp)
                if let quality = sleep.quality {
                    Image(systemName: quality.systemImage)
                        .font(MCTypography.caption)
                        .foregroundStyle(MCColor.baby)
                        .accessibilityHidden(true)
                }
            }
            .foregroundStyle(.secondary)
        }
        .padding(.vertical, MCSpacing.xs)
    }
}
