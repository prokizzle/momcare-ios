import SwiftUI

struct EmptyStateView: View {
    let illustration: MCIllustration
    let title: String
    let message: String
    var actionTitle: String?
    var action: (() -> Void)?

    @State private var step = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(spacing: MCSpacing.xl) {
            MCIllustrationView(illustration: illustration, size: 120)

            Text(title)
                .font(MCTypography.title3)
                .foregroundStyle(.white)
                .opacity(step >= 1 ? 1 : 0)

            Text(message)
                .font(MCTypography.callout)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .opacity(step >= 2 ? 1 : 0)

            if let actionTitle, let action {
                Button {
                    MCHaptic.tap()
                    action()
                } label: {
                    Text(actionTitle)
                        .font(MCTypography.button)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(MCColor.accent, in: RoundedRectangle(cornerRadius: MCRadius.lg))
                }
                .opacity(step >= 3 ? 1 : 0)
                .mcShine(trigger: step)
            }
        }
        .padding(.horizontal, MCSpacing.xl)
        .task {
            guard !reduceMotion else {
                step = 3
                return
            }
            for nextStep in 1...3 {
                try? await Task.sleep(for: .seconds(0.15))
                withAnimation(MCAnimation.standard) {
                    step = nextStep
                }
            }
        }
    }
}
