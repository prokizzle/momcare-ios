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
                .font(MCTypography.subheadline)
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
            RoundedRectangle(cornerRadius: MCRadius.md)
                .fill(MCElevation.surface)
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
        .onTapGesture {
            onTap?()
        }
        .accessibilityAddTraits(.isButton)
        .accessibilityLabel(suggestion.message)
        .accessibilityAction(named: "Dismiss") { onDismiss() }
    }
}
