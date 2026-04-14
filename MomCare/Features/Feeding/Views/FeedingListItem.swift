import SwiftUI

@MainActor
struct FeedingListItem: View {
    let feeding: Feeding

    var body: some View {
        HStack(spacing: MCSpacing.md) {
            Image(systemName: feeding.feedingType.systemImage)
                .font(.title3)
                .foregroundStyle(MCColor.feeding)
                .frame(width: 32)
                .accessibilityLabel(feeding.feedingType.label)

            VStack(alignment: .leading, spacing: MCSpacing.xs) {
                Text(feeding.startTime.formatted(date: .omitted, time: .shortened))
                    .font(MCTypography.title3)

                HStack(spacing: MCSpacing.sm) {
                    if !feeding.isInProgress {
                        Text(feeding.durationFormatted)
                            .font(MCTypography.callout)
                            .foregroundStyle(.secondary)
                    } else {
                        Text("In progress")
                            .font(MCTypography.callout)
                            .foregroundStyle(MCColor.feeding)
                    }

                    if let side = feeding.breastSide {
                        Text("• \(side.label)")
                            .font(MCTypography.callout)
                            .foregroundStyle(.secondary)
                    }

                    if let amount = feeding.amountMl {
                        Text("• \(amount) ml")
                            .font(MCTypography.callout)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Spacer()

            if let quality = feeding.quality {
                Text(quality.displayName)
                    .font(MCTypography.timestamp)
                    .padding(.horizontal, MCSpacing.sm)
                    .padding(.vertical, MCSpacing.xs)
                    .background(Color.secondary.opacity(MCOpacity.medium))
                    .clipShape(Capsule())
            }
        }
        .padding(.vertical, MCSpacing.xs)
    }
}
