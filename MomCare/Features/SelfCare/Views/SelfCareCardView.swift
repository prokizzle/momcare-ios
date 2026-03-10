import SwiftUI

@MainActor
struct SelfCareCardView: View {
    let card: SelfCareCard
    let onDismiss: () -> Void

    @State private var dragOffset: CGFloat = 0

    var body: some View {
        HStack(alignment: .top, spacing: MCSpacing.md) {
            Image(systemName: iconForCardType(card.type))
                .font(.title3)
                .foregroundStyle(colorForCardType(card.type))
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
                        withAnimation(.easeOut(duration: 0.2)) {
                            dragOffset = -400
                        }
                        onDismiss()
                    } else {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            dragOffset = 0
                        }
                    }
                }
        )
        .accessibilityAddTraits(.isButton)
        .accessibilityAction(named: "Dismiss") { onDismiss() }
    }

    private func iconForCardType(_ type: SelfCareCard.CardType) -> String {
        switch type {
        case .selfCareWindow: "sparkles"
        case .hydrationNudge: "cup.and.saucer.fill"
        case .affirmation: "heart.fill"
        case .pepTalk: "sun.max.fill"
        case .checkIn: "face.smiling"
        case .streak: "flame.fill"
        case .gentleNudge: "leaf.fill"
        }
    }

    private func colorForCardType(_ type: SelfCareCard.CardType) -> Color {
        switch type {
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
