import SwiftUI

@MainActor
struct BabyStatusStrip: View {
    @Environment(BabyActivityEngine.self) private var engine
    let babyId: UUID?

    var body: some View {
        HStack(spacing: MCSpacing.md) {
            if engine.isNapActive {
                statusPill(
                    icon: "moon.stars.fill",
                    text: "Napping \u{2022} \(engine.napElapsedFormatted)",
                    color: MCColor.baby
                )
            }
            if engine.isFeedingActive {
                statusPill(
                    icon: engine.feedMethod?.systemImage ?? "drop.fill",
                    text: "Feeding \u{2022} \(engine.feedingElapsedFormatted)",
                    color: MCColor.feeding
                )
            }
            if !engine.isNapActive, !engine.isFeedingActive {
                Text("All quiet")
                    .font(MCTypography.timestamp)
                    .foregroundStyle(MCColor.Foreground.level3)
            }
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, MCSpacing.lg)
        .padding(.vertical, MCSpacing.md)
        .background {
            RoundedRectangle(cornerRadius: MCRadius.md)
                .fill(MCElevation.elevated)
                .overlay {
                    RoundedRectangle(cornerRadius: MCRadius.md)
                        .stroke(Color.white.opacity(MCOpacity.whisper), lineWidth: 1)
                }
        }
    }

    @ViewBuilder
    private func statusPill(icon: String, text: String, color: Color) -> some View {
        HStack(spacing: MCSpacing.xs) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
                .shadow(color: color.opacity(MCOpacity.heavy), radius: 5)
            Image(systemName: icon)
                .foregroundStyle(color)
                .font(.caption)
                .accessibilityHidden(true)
            Text(text)
                .font(MCTypography.timestamp)
                .foregroundStyle(color)
        }
    }
}
