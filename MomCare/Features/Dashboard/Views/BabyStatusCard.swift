import SwiftUI

@MainActor
struct BabyStatusCard: View {
    let viewModel: DashboardViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: MCSpacing.md) {
            Label("Baby", systemImage: "heart.fill")
                .font(.caption.bold())
                .foregroundStyle(MCColor.feeding)

            if viewModel.inProgressFeeding != nil {
                inProgressRow
            } else {
                timeSinceRow
            }
        }
        .padding(MCSpacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
        }
    }

    @ViewBuilder
    private var inProgressRow: some View {
        @Environment(\.accessibilityReduceMotion) var reduceMotion

        HStack {
            VStack(alignment: .leading, spacing: MCSpacing.xs) {
                Text("Feeding in progress")
                    .font(.headline)
                    .foregroundStyle(.primary)
                Text("Timer running")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Image(systemName: "drop.fill")
                .font(.title2)
                .foregroundStyle(MCColor.feeding)
                .symbolEffect(reduceMotion ? nil : .pulse)
        }
    }

    @ViewBuilder
    private var timeSinceRow: some View {
        HStack {
            VStack(alignment: .leading, spacing: MCSpacing.xs) {
                Group {
                    if viewModel.timeSinceLastFeeding != nil {
                        TimelineView(.periodic(from: .now, by: 60)) { _ in
                            Text(timeSinceText)
                                .font(.headline)
                                .foregroundStyle(viewModel.urgency.color)
                        }
                    } else {
                        Text("No feeding recorded")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                    }
                }

                Text(viewModel.urgency.label)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Circle()
                .fill(viewModel.urgency.color.opacity(0.2))
                .frame(width: 44, height: 44)
                .overlay {
                    Image(systemName: "clock.fill")
                        .font(.title3)
                        .foregroundStyle(viewModel.urgency.color)
                }
        }
    }

    private var timeSinceText: String {
        guard let interval = viewModel.timeSinceLastFeeding else { return "--" }
        let totalMinutes = Int(interval) / 60
        if totalMinutes < 60 {
            return "\(totalMinutes) min ago"
        }
        let hours = totalMinutes / 60
        let mins = totalMinutes % 60
        if mins == 0 {
            return "\(hours)h ago"
        }
        return "\(hours)h \(mins)m ago"
    }
}
