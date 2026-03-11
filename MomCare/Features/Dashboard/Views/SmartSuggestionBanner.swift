import SwiftUI

@MainActor
struct SmartSuggestionBanner: View {
    let suggestion: DashboardViewModel.SmartSuggestion
    let onDismiss: () -> Void
    let onTap: (() -> Void)?

    @State private var dragOffset: CGFloat = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        HStack(spacing: MCSpacing.md) {
            Image(systemName: "sparkles")
                .font(.subheadline)
                .foregroundStyle(MCColor.selfCare)
                .frame(width: 20)

            Text(suggestion.message)
                .font(.subheadline)
                .foregroundStyle(.primary)
                .multilineTextAlignment(.leading)

            Spacer()

            if suggestion.actionTab != nil {
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(MCSpacing.lg)
        .background {
            RoundedRectangle(cornerRadius: 14)
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
        .onTapGesture {
            onTap?()
        }
        .accessibilityAddTraits(.isButton)
        .accessibilityLabel(suggestion.message)
        .accessibilityAction(named: "Dismiss") { onDismiss() }
    }
}
