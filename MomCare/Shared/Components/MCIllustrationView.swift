import SwiftUI

enum MCIllustration: String, Sendable {
    // Empty states
    case emptyFeeding = "mc-illustration-empty-feeding"
    case emptySleep = "mc-illustration-empty-sleep"
    case emptyGrowth = "mc-illustration-empty-growth"
    case emptyDiapers = "mc-illustration-empty-diapers"
    case emptyJournal = "mc-illustration-empty-journal"
    case emptySelfCare = "mc-illustration-empty-selfcare"

    // Onboarding
    case onboardingWelcome = "mc-illustration-onboarding-welcome"
    case onboardingFeatures = "mc-illustration-onboarding-features"
    case onboardingPrivacy = "mc-illustration-onboarding-privacy"

    // Status
    case statusSleeping = "mc-illustration-status-sleeping"
    case statusFeeding = "mc-illustration-status-feeding"

    var fallbackIcon: String {
        switch self {
        case .emptyFeeding: "drop.fill"
        case .emptySleep: "moon.stars.fill"
        case .emptyGrowth: "chart.line.uptrend.xyaxis"
        case .emptyDiapers: "circle.dotted"
        case .emptyJournal: "book.pages"
        case .emptySelfCare: "heart.fill"
        case .onboardingWelcome: "hand.wave.fill"
        case .onboardingFeatures: "sparkles"
        case .onboardingPrivacy: "lock.shield.fill"
        case .statusSleeping: "moon.stars.fill"
        case .statusFeeding: "drop.fill"
        }
    }
}

struct MCIllustrationView: View {
    let illustration: MCIllustration
    var size: CGFloat = 120
    var tint: Color = MCColor.accent
    @State private var appeared = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        illustrationContent
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 8)
            .onAppear {
                if reduceMotion {
                    appeared = true
                } else {
                    withAnimation(MCAnimation.gentle.delay(0.1)) {
                        appeared = true
                    }
                }
            }
    }

    @ViewBuilder
    private var illustrationContent: some View {
        if let uiImage = UIImage(named: illustration.rawValue) {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFit()
                .frame(width: size, height: size)
                .foregroundStyle(tint)
        } else {
            fallbackImage
        }
    }

    private var fallbackImage: some View {
        #if DEBUG
        assertionFailure("Missing illustration asset: \(illustration.rawValue)")
        #endif
        return Image(systemName: illustration.fallbackIcon)
            .font(.system(size: size * 0.4))
            .foregroundStyle(tint.opacity(MCOpacity.strong))
            .frame(width: size, height: size)
    }
}
