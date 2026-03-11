import SwiftUI

@MainActor
struct DiaperHistoryView: View {
    let viewModel: DiaperViewModel
    let babyId: UUID
    @State private var diaperToDelete: Diaper?

    private let dayFormatter: DateFormatter = {
        let fmt = DateFormatter()
        fmt.dateStyle = .medium
        fmt.timeStyle = .none
        return fmt
    }()

    private let timeFormatter: DateFormatter = {
        let fmt = DateFormatter()
        fmt.dateStyle = .none
        fmt.timeStyle = .short
        return fmt
    }()

    var body: some View {
        Group {
            if viewModel.diapersGroupedByDay.isEmpty {
                emptyState
            } else {
                diaperList
            }
        }
        .navigationTitle("Diaper History")
        .task(id: babyId) {
            await viewModel.loadDiapers(babyId: babyId)
        }
        .confirmationDialog(
            "Delete Diaper?",
            isPresented: Binding(
                get: { diaperToDelete != nil },
                set: { if !$0 { diaperToDelete = nil } }
            )
        ) {
            Button("Delete", role: .destructive) {
                if let diaper = diaperToDelete {
                    Task { await viewModel.deleteDiaper(id: diaper.id) }
                }
            }
        } message: {
            Text("This diaper record will be removed.")
        }
    }

    @ViewBuilder
    private var diaperList: some View {
        List {
            ForEach(viewModel.diapersGroupedByDay, id: \.day) { group in
                Section {
                    ForEach(group.entries) { diaper in
                        DiaperRow(diaper: diaper, timeFormatter: timeFormatter)
                            .swipeActions(edge: .trailing) {
                                Button("Delete", role: .destructive) {
                                    diaperToDelete = diaper
                                }
                            }
                    }
                } header: {
                    DayHeader(day: group.day, count: group.entries.count, formatter: dayFormatter)
                }
            }
        }
        .listStyle(.insetGrouped)
    }

    @ViewBuilder
    private var emptyState: some View {
        ContentUnavailableView(
            "No Diapers Logged",
            systemImage: "drop.circle",
            description: Text("Tap the + button to log a diaper change.")
        )
    }
}

// MARK: - Day Header

private struct DayHeader: View {
    let day: Date
    let count: Int
    let formatter: DateFormatter

    var body: some View {
        HStack {
            Text(formatter.string(from: day))
                .font(.subheadline.bold())
            Spacer()
            Text("\(count) change\(count == 1 ? "" : "s")")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Diaper Row

private struct DiaperRow: View {
    let diaper: Diaper
    let timeFormatter: DateFormatter

    var body: some View {
        HStack(spacing: MCSpacing.md) {
            Image(systemName: diaper.type.systemImage)
                .font(.title3)
                .foregroundStyle(MCColor.diaper)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 2) {
                Text(diaper.type.label)
                    .font(.subheadline.bold())

                HStack(spacing: MCSpacing.xs) {
                    if let consistency = diaper.stoolConsistency {
                        badge(consistency.label)
                    }
                    if let color = diaper.stoolColor {
                        badge(color.label)
                    }
                    if diaper.hasRash {
                        badge("Rash")
                    }
                }
            }

            Spacer()

            Text(timeFormatter.string(from: diaper.timestamp))
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, MCSpacing.xs)
    }

    @ViewBuilder
    private func badge(_ text: String) -> some View {
        Text(text)
            .font(.caption2.bold())
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(MCColor.diaper.opacity(0.15))
            .foregroundStyle(MCColor.diaper)
            .clipShape(Capsule())
    }
}
