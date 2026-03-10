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
                .font(.title3)
                .foregroundStyle(card.type.accentColor)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: MCSpacing.xs) {
                if card.type == .streak {
                    Text("Streak")
                        .font(.caption.bold())
                        .foregroundStyle(MCColor.selfCare)
                }
                Text(card.message)
                    .font(MCTypography.cardBody)
                    .foregroundStyle(.primary)
            }

            Spacer()
        }
        .padding(MCSpacing.lg)
        .background {
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
        }
        .offset(x: dragOffset)
        .gesture(
            DragGesture()
                .onChanged { value in
                    dragOffset = min(0, value.translation.width)
                }
                .onEnded { value in
                    if value.translation.width < -80 {
                        withAnimation(reduceMotion ? nil : .easeOut(duration: 0.2)) {
                            dragOffset = -400
                        }
                        onDismiss()
                    } else {
                        withAnimation(reduceMotion ? nil : .spring(response: 0.3, dampingFraction: 0.7)) {
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
