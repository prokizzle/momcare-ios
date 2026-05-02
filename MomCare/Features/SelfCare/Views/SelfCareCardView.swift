import SwiftUI

@MainActor
struct SelfCareCardView: View {
    let card: SelfCareCard
    let onDismiss: () -> Void

    @State private var dragOffset: CGFloat = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        HStack(alignment: .top, spacing: MCSpacing.md) {
            Image(systemName: card.type.systemImage)
                .font(.subheadline)
                .foregroundStyle(card.type.accentColor)
                .frame(width: 36, height: 36)
                .background(card.type.accentColor.opacity(MCOpacity.soft), in: Circle())
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: MCSpacing.xs) {
                Text(card.type.badgeLabel)
                    .mcBadge()
                    .foregroundStyle(card.type.accentColor)
                Text(card.message)
                    .font(card.type == .affirmation ? MCTypography.milestone : MCTypography.headline)
                    .foregroundStyle(MCColor.Foreground.level1)
            }

            Spacer()
        }
        .padding(MCSpacing.lg)
        .background {
            RoundedRectangle(cornerRadius: MCRadius.lg)
                .fill(MCElevation.elevated)
                .overlay {
                    RoundedRectangle(cornerRadius: MCRadius.lg)
                        .stroke(card.type.accentColor.opacity(MCOpacity.soft), lineWidth: 1)
                }
        }
        .offset(x: dragOffset)
        .gesture(
            DragGesture()
                .onChanged { value in
                    dragOffset = min(0, value.translation.width)
                }
                .onEnded { value in
                    if value.translation.width < -80 {
                        withAnimation(reduceMotion ? nil : MCAnimation.quick) {
                            dragOffset = -400
                        }
                        onDismiss()
                    } else {
                        withAnimation(reduceMotion ? nil : MCAnimation.quick) {
                            dragOffset = 0
                        }
                    }
                }
        )
        .accessibilityAddTraits(.isButton)
        .accessibilityAction(named: "Dismiss") { onDismiss() }
    }

}

extension SelfCareCard.CardType {
    var badgeLabel: String {
        switch self {
        case .selfCareWindow: "For you, right now"
        case .hydrationNudge: "Hydration"
        case .affirmation: "Affirmation"
        case .pepTalk: "Pep talk"
        case .checkIn: "Check-in"
        case .streak: "Streak"
        case .gentleNudge: "Gentle nudge"
        }
    }

    var systemImage: String {
        switch self {
        case .selfCareWindow: "sparkles"
        case .hydrationNudge: "cup.and.saucer.fill"
        case .affirmation: "heart.fill"
        case .pepTalk: "sun.max.fill"
        case .checkIn: "face.smiling"
        case .streak: "flame.fill"
        case .gentleNudge: "leaf.fill"
        }
    }

    var accentColor: Color {
        switch self {
        case .selfCareWindow: MCColor.selfCare
        case .hydrationNudge: .blue
        case .affirmation: .pink
        case .pepTalk: .orange
        case .checkIn: .purple
        case .streak: MCColor.selfCare
        case .gentleNudge: .green
        }
    }
}
