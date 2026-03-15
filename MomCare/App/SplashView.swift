import SwiftUI

struct SplashView: View {
    @Binding var isFinished: Bool
    @State private var step = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            MCGradient.canvas()
                .ignoresSafeArea()

            VStack(spacing: MCSpacing.lg) {
                Text("MomCare")
                    .font(MCTypography.title1)
                    .foregroundStyle(.white)
                    .opacity(step >= 1 ? 1 : 0)
                    .scaleEffect(step >= 1 ? 1 : 0.9)
                    .background {
                        if step >= 2 {
                            MCGradient.glow(color: MCColor.accent, radius: 80)
                                .frame(width: 200, height: 200)
                                .opacity(step >= 2 ? 1 : 0)
                        }
                    }

                Text("Care, tracked.")
                    .font(MCTypography.affirmation)
                    .foregroundStyle(.white.opacity(MCOpacity.strong))
                    .opacity(step >= 3 ? 1 : 0)
            }
        }
        .task {
            defer { finish() }

            guard !reduceMotion else {
                try? await Task.sleep(for: .seconds(0.5))
                return
            }

            try? await Task.sleep(for: .seconds(0.3))
            guard !Task.isCancelled else { return }
            withAnimation(MCAnimation.gentle) { step = 1 }

            try? await Task.sleep(for: .seconds(0.3))
            guard !Task.isCancelled else { return }
            withAnimation(MCAnimation.slow) { step = 2 }

            try? await Task.sleep(for: .seconds(0.3))
            guard !Task.isCancelled else { return }
            withAnimation(MCAnimation.standard) { step = 3 }

            try? await Task.sleep(for: .seconds(0.6))
        }
    }

    private func finish() {
        withAnimation(MCAnimation.standard) {
            isFinished = true
        }
    }
}
