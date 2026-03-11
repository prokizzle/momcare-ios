import SwiftUI

@MainActor
struct JournalEntryRow: View {
    let entry: JournalEntry

    var body: some View {
        HStack(spacing: MCSpacing.md) {
            Image(systemName: entry.kind.systemImage)
                .font(.title3)
                .foregroundStyle(color(for: entry.kind))
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 2) {
                Text(entry.kind.label)
                    .font(.subheadline.bold())
                Text(entry.detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text(entry.timestamp, style: .time)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, MCSpacing.xs)
    }

    private func color(for kind: JournalEntryKind) -> Color {
        switch kind {
        case .nap: MCColor.baby
        case .feeding: MCColor.feeding
        case .diaper: MCColor.diaper
        }
    }
}
