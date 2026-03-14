import SwiftUI

struct CelebrationOverlay: View {
    let celebration: MCCelebration
    var message: String?
    @Binding var isPresented: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        if isPresented {
            ZStack {
                Color.black.opacity(MCOpacity.ghost)
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
            .onAppear {
                MCHaptic.success()
                scheduleDismissal()
            }
        }
    }

    private func scheduleDismissal() {
        let duration: Double = switch celebration {
        case .confetti: 2.5
        case .sparkle: 1.5
        case .warmglow: 2.0
        case .breathe: 0
        }

        guard duration > 0 else { return }

        Task {
            try? await Task.sleep(for: .seconds(duration))
            await MainActor.run { dismiss() }
        }
    }

    private func dismiss() {
        withAnimation(MCAnimation.standard) {
            isPresented = false
        }
    }
}
