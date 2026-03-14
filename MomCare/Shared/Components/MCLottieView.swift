import Lottie
import SwiftUI

// MARK: - MCCelebration

enum MCCelebration: String, Sendable {
    case confetti = "celebration-confetti"
    case sparkle = "celebration-sparkle"
    case warmglow = "celebration-warmglow"
    case breathe = "loading-breathe"

    var accessibilityLabel: String {
        switch self {
        case .confetti: "Celebration: milestone achieved"
        case .sparkle: "Celebration: task completed"
        case .warmglow: "Session complete"
        case .breathe: "Loading"
        }
    }

    var fallbackIcon: String {
        switch self {
        case .confetti, .sparkle: "checkmark.circle.fill"
        case .warmglow: "sun.max.fill"
        case .breathe: "ellipsis"
        }
    }
}

// MARK: - MCLottieSize

enum MCLottieSize: Sendable {
    case compact
    case standard
    case fullscreen

    var dimension: CGFloat? {
        switch self {
        case .compact: 80
        case .standard: 160
        case .fullscreen: nil
        }
    }
}

// MARK: - MCLottieView

struct MCLottieView: View {
    let animation: MCCelebration
    var size: MCLottieSize = .standard
    var looping: Bool = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        if reduceMotion {
            staticFallback
        } else {
            lottieContent
        }
    }

    @ViewBuilder
    private var lottieContent: some View {
        if let dimension = size.dimension {
            animationView
                .frame(width: dimension, height: dimension)
        } else {
            animationView
        }
    }

    private var animationView: some View {
        Group {
            if looping {
                LottieView(animation: .named(animation.rawValue))
                    .looping()
                    .accessibilityLabel(animation.accessibilityLabel)
            } else {
                LottieView(animation: .named(animation.rawValue))
                    .playing()
                    .accessibilityLabel(animation.accessibilityLabel)
            }
        }
    }

    private var staticFallback: some View {
        Image(systemName: animation.fallbackIcon)
            .font(.title)
            .foregroundStyle(MCColor.accent)
            .accessibilityLabel(animation.accessibilityLabel)
    }
}
