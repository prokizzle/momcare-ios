import SwiftUI

@MainActor
struct FeedingPatternCard: View {
    let pattern: FeedingPattern
    let lastFeedTime: Date?

    var body: some View {
        VStack(alignment: .leading, spacing: MCSpacing.md) {
            Text("Pattern")
                .mcBadge()
                .foregroundStyle(MCColor.feeding)

            HStack(alignment: .bottom, spacing: MCSpacing.md) {
                VStack(alignment: .leading, spacing: MCSpacing.xs) {
                    Text("every")
                        .font(MCTypography.footnote)
                        .foregroundStyle(MCColor.Foreground.level3)
                    Text(pattern.intervalFormatted)
                        .font(MCTypography.display)
                        .foregroundStyle(MCColor.Foreground.level1)
                        .monospacedDigit()
                }

                Spacer(minLength: 0)
                rhythmStrip
            }

            if let lastFeedTime {
                HStack(spacing: MCSpacing.xs) {
                    Image(systemName: "clock.fill")
                        .font(.caption)
                        .foregroundStyle(MCColor.feeding)
                        .accessibilityHidden(true)
                    Text("Next likely feed \(pattern.timeUntilNextFeedFormatted(lastFeedTime: lastFeedTime))")
                        .font(MCTypography.footnote)
                        .foregroundStyle(MCColor.Foreground.level2)
                }
                .padding(.top, MCSpacing.sm)
                .overlay(alignment: .top) {
                    Rectangle()
                        .fill(MCColor.Foreground.level1.opacity(MCOpacity.whisper))
                        .frame(height: 1)
                }
            }

            confidenceIndicator
        }
        .padding(MCSpacing.xl)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            RoundedRectangle(cornerRadius: MCRadius.xl)
                .fill(MCElevation.elevated)
                .overlay {
                    RoundedRectangle(cornerRadius: MCRadius.xl)
                        .stroke(MCColor.feeding.opacity(MCOpacity.soft), lineWidth: 1)
                }
                .shadow(color: MCColor.feeding.opacity(MCOpacity.soft), radius: 24)
        }
    }

    private var confidenceIndicator: some View {
        HStack(spacing: MCSpacing.xs) {
            ForEach(0..<5, id: \.self) { dotIndex in
                Circle()
                    .fill(Double(dotIndex) / 4.0 <= pattern.confidence
                          ? MCColor.feeding
                          : Color.secondary.opacity(MCOpacity.strong))
                    .frame(width: 6, height: 6)
            }
            Text("\(Int(pattern.confidence * 100))% confidence")
                .font(MCTypography.timestamp)
                .foregroundStyle(.secondary)
        }
    }

    private var rhythmStrip: some View {
        HStack(alignment: .bottom, spacing: 4) {
            ForEach(Array(rhythmValues.enumerated()), id: \.offset) { _, value in
                RoundedRectangle(cornerRadius: 2.5)
                    .fill(MCColor.feeding.opacity(0.30 + 0.70 * value))
                    .frame(width: 9, height: 42 * value)
            }
        }
        .frame(height: 48, alignment: .bottom)
        .accessibilityHidden(true)
    }

    private var rhythmValues: [Double] {
        [0.70, 0.47, 0.92, 0.63, 1.00, 0.50, 0.87, 0.60, 0.80]
    }
}
