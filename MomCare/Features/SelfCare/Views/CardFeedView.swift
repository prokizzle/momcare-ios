import SwiftUI

@MainActor
struct CardFeedView: View {
    let cards: [SelfCareCard]
    let onDismiss: (UUID) -> Void
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        if cards.isEmpty {
            emptyState
        } else {
            LazyVStack(spacing: MCSpacing.md) {
                ForEach(cards) { card in
                    SelfCareCardView(card: card, onDismiss: { onDismiss(card.id) })
                        .transition(.asymmetric(
                            insertion: .opacity.combined(with: .move(edge: .top)),
                            removal: .opacity.combined(with: .move(edge: .trailing))
                        ))
                }
            }
            .padding(.horizontal, MCSpacing.lg)
            .animation(reduceMotion ? nil : MCAnimation.quick, value: cards.map(\.id))
        }
    }

    private var emptyState: some View {
        Text("Everything's good. You know what you need.")
            .font(MCTypography.callout)
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
            .padding(.vertical, MCSpacing.xxl)
            .padding(.horizontal, MCSpacing.lg)
    }
}
