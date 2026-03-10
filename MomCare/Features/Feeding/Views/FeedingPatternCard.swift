import SwiftUI

struct FeedingPatternCard: View {
    let pattern: FeedingPattern
    let lastFeedTime: Date?

    var body: some View {
        VStack(alignment: .leading, spacing: MCSpacing.sm) {
            Label("Feeding Pattern", systemImage: "chart.line.uptrend.xyaxis")
                .font(MCTypography.cardTitle)
                .foregroundStyle(.secondary)

            Text("Every ~\(pattern.intervalFormatted)")
                .font(.title3.weight(.semibold))

            if let lastFeedTime {
                Text("Next: \(pattern.timeUntilNextFeedFormatted(lastFeedTime: lastFeedTime))")
                    .font(MCTypography.cardBody)
                    .foregroundStyle(
                        pattern.isFeedingDue(lastFeedTime: lastFeedTime)
                            ? MCColor.feeding
                            : .secondary
                    )
            }

            confidenceIndicator
        }
        .padding(MCSpacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var confidenceIndicator: some View {
        HStack(spacing: MCSpacing.xs) {
            ForEach(0..<5, id: \.self) { dotIndex in
                Circle()
                    .fill(Double(dotIndex) / 4.0 <= pattern.confidence
                          ? MCColor.feeding
                          : Color.secondary.opacity(0.3))
                    .frame(width: 6, height: 6)
            }
            Text("\(Int(pattern.confidence * 100))% confidence")
                .font(MCTypography.timestamp)
                .foregroundStyle(.secondary)
        }
    }
}
