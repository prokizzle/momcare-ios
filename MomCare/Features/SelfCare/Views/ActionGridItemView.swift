import SwiftUI

@MainActor
struct ActionGridItemView: View {
    let item: SelfCareGridItem
    let isRecentlyTapped: Bool
    let waterCount: Int?
    let onTap: () -> Void
    let onLongPress: () -> Void

    @State private var isAnimating = false

    var body: some View {
        Button {
            MCHaptic.tap()
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                isAnimating = true
            }
            onTap()
            Task {
                try? await Task.sleep(for: .seconds(0.3))
                isAnimating = false
            }
        } label: {
            VStack(spacing: MCSpacing.xs) {
                ZStack(alignment: .topTrailing) {
                    Image(systemName: item.displayIcon)
                        .font(.title2)
                        .frame(width: 28, height: 28)

                    if let waterCount, item.actionType == .water, waterCount > 0 {
                        Text("x\(waterCount)")
                            .font(.caption2.bold())
                            .foregroundStyle(.secondary)
                            .offset(x: 8, y: -4)
                    }
                }

                Text(item.displayName)
                    .font(.caption2)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 80)
            .background {
                RoundedRectangle(cornerRadius: 16)
                    .fill(.ultraThinMaterial)
                    .overlay {
                        if isRecentlyTapped {
                            RoundedRectangle(cornerRadius: 16)
                                .fill(MCColor.selfCare.opacity(0.15))
                        }
                    }
            }
            .scaleEffect(isAnimating ? 0.92 : 1.0)
        }
        .buttonStyle(.plain)
        .highPriorityGesture(
            LongPressGesture(minimumDuration: 0.5)
                .onEnded { _ in
                    MCHaptic.toggle()
                    onLongPress()
                }
        )
        .accessibilityLabel(item.displayName)
        .accessibilityHint(isRecentlyTapped ? "Logged recently" : "Tap to log")
    }
}
