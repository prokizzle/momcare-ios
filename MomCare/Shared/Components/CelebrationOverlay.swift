import SwiftUI

struct CelebrationOverlay: View {
    let celebration: MCCelebration
    var message: String?
    @Binding var isPresented: Bool

    var body: some View {
        if isPresented {
            ZStack {
                Color.black.opacity(MCOpacity.strong)
                    .ignoresSafeArea()
                    .onTapGesture { dismiss() }

                VStack(spacing: MCSpacing.xl) {
                    MCLottieView(
                        animation: celebration,
                        size: celebration == .breathe ? .compact : .standard,
                        looping: false
                    )

                    if let message {
                        Text(message)
                            .font(MCTypography.milestone)
                            .foregroundStyle(.white)
                            .multilineTextAlignment(.center)
                            .transition(.opacity)
                    }
                }
            }
            .transition(.opacity)
            .task {
                MCHaptic.success()
                let duration = celebration.autoDismissDuration
                guard duration > 0 else { return }
                defer { dismiss() }
                try? await Task.sleep(for: .seconds(duration))
            }
        }
    }

    private func dismiss() {
        withAnimation(MCAnimation.standard) {
            isPresented = false
        }
    }
}
