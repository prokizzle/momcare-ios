import SwiftUI

@MainActor
struct CardFeedView: View {
    let cards: [SelfCareCard]
    let onDismiss: (UUID) -> Void

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
            .animation(.easeInOut(duration: 0.3), value: cards.map(\.id))
        }
    }

    private var emptyState: some View {
        Text("Everything's good. You know what you need.")
            .font(MCTypography.cardBody)
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
            .padding(.vertical, MCSpacing.xxl)
            .padding(.horizontal, MCSpacing.lg)
    }
}
