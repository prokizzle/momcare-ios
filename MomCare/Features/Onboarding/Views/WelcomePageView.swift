import DSKit
import Pow
import SwiftUI

@MainActor
struct WelcomePageView: View {
    @Bindable var viewModel: OnboardingViewModel
    @State private var appeared = false

    private var currentPage: WelcomePage {
        switch viewModel.currentStep {
        case .features: return .features
        case .philosophy: return .philosophy
        default: return .hero
        }
    }

    var body: some View {
        TabView(selection: Binding(
            get: { currentPage },
            set: { newPage in
                switch newPage {
                case .hero: viewModel.currentStep = .welcome
                case .features: viewModel.currentStep = .features
                case .philosophy: viewModel.currentStep = .philosophy
                }
            }
        )) {
            heroPage.tag(WelcomePage.hero)
            featuresPage.tag(WelcomePage.features)
            philosophyPage.tag(WelcomePage.philosophy)
        }
        .tabViewStyle(.page(indexDisplayMode: .always))
        .onAppear { appeared = true }
    }

    // MARK: - Hero

    private var heroPage: some View {
        VStack(spacing: MCSpacing.xl) {
            Spacer()

            // Lottie placeholder - will be replaced with mother & baby illustration animation
            RoundedRectangle(cornerRadius: MCRadius.xlg)
                .fill(MCElevation.surface)
                .frame(height: 200)
                .overlay {
                    Image(systemName: "heart.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(MCColor.accent)
                }
                .accessibilityHidden(true)

            Text("MomCare")
                .font(.system(size: 40, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .conditionalEffect(.repeat(.shine, every: 3), condition: appeared)

            Text("Track everything. Stress nothing.")
                .font(.title3)
                .foregroundStyle(.white.opacity(0.7))

            Spacer()

            OnboardingButton(title: "Get Started") {
                viewModel.currentStep = .features
            }
        }
        .padding(.horizontal, MCSpacing.xl)
        .padding(.bottom, MCSpacing.section)
    }

    // MARK: - Features

    private var featuresPage: some View {
        VStack(spacing: MCSpacing.xl) {
            Spacer()

            Text("Everything you need")
                .font(.title.bold())
                .foregroundStyle(.white)

            Text("Powerful tools for the journey ahead")
                .font(.body)
                .foregroundStyle(.white.opacity(0.7))

            DSVStack(spacing: .custom(MCSpacing.lg)) {
                LazyVGrid(
                    columns: [
                        GridItem(.flexible(), spacing: MCSpacing.lg),
                        GridItem(.flexible(), spacing: MCSpacing.lg)
                    ],
                    spacing: MCSpacing.lg
                ) {
                    featureCard(
                        icon: "cup.and.saucer.fill",
                        title: "Feeding Tracker",
                        description: "Log feeds with one tap",
                        color: MCColor.feeding
                    )
                    featureCard(
                        icon: "moon.zzz.fill",
                        title: "Sleep Logging",
                        description: "Track naps and nighttime",
                        color: MCColor.babyStatus
                    )
                    featureCard(
                        icon: "heart.text.clipboard.fill",
                        title: "Self-Care",
                        description: "Your wellbeing matters too",
                        color: MCColor.selfCare
                    )
                    featureCard(
                        icon: "chart.line.uptrend.xyaxis",
                        title: "Smart Insights",
                        description: "Patterns and milestones",
                        color: MCColor.accent
                    )
                }
                .transition(.movingParts.pop)
            }
            .padding(.horizontal, MCSpacing.sm)

            Spacer()

            OnboardingButton(title: "Next") {
                viewModel.currentStep = .philosophy
            }
        }
        .padding(.horizontal, MCSpacing.xl)
        .padding(.bottom, MCSpacing.section)
    }

    // MARK: - Philosophy

    private var philosophyPage: some View {
        VStack(spacing: MCSpacing.xl) {
            Spacer()

            // Lottie placeholder - will be replaced with peaceful nighttime scene animation
            RoundedRectangle(cornerRadius: MCRadius.xlg)
                .fill(MCElevation.surface)
                .frame(height: 200)
                .overlay {
                    Image(systemName: "sparkles")
                        .font(.system(size: 48))
                        .foregroundStyle(MCColor.accent)
                }
                .accessibilityHidden(true)

            Text("Designed for 3am, one-handed use")
                .font(.title.bold())
                .foregroundStyle(.white)

            Text("Designed by parents, for parents")
                .font(.body)
                .foregroundStyle(.white.opacity(0.7))

            VStack(alignment: .leading, spacing: MCSpacing.lg) {
                bulletPoint("One-handed, dark-mode first design")
                    .transition(.asymmetric(insertion: .movingParts.pop, removal: .identity))
                bulletPoint("Local-first -- your data stays on device")
                    .transition(.asymmetric(insertion: .movingParts.pop, removal: .identity))
                bulletPoint("Optional sync to share with your partner")
                    .transition(.asymmetric(insertion: .movingParts.pop, removal: .identity))
                bulletPoint("No ads, no tracking, no compromise")
                    .transition(.asymmetric(insertion: .movingParts.pop, removal: .identity))
            }
            .padding(.horizontal, MCSpacing.lg)

            Spacer()

            OnboardingButton(title: "Let's set up") {
                viewModel.advance()
            }
        }
        .padding(.horizontal, MCSpacing.xl)
        .padding(.bottom, MCSpacing.section)
    }

    // MARK: - Components

    private func featureCard(icon: String, title: String, description: String, color: Color) -> some View {
        VStack(spacing: MCSpacing.md) {
            Image(systemName: icon)
                .font(.title)
                .foregroundStyle(color)

            Text(title)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.white)

            Text(description)
                .font(.caption)
                .foregroundStyle(.white.opacity(0.6))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, MCSpacing.xl)
        .padding(.horizontal, MCSpacing.sm)
        .background(MCElevation.elevated, in: RoundedRectangle(cornerRadius: MCRadius.lg))
        .accessibilityElement(children: .combine)
    }

    private func bulletPoint(_ text: String) -> some View {
        HStack(alignment: .top, spacing: MCSpacing.md) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(MCColor.accent)
                .font(.body)

            Text(text)
                .font(.body)
                .foregroundStyle(.white.opacity(0.9))
        }
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Welcome Page

enum WelcomePage: Int, Hashable {
    case hero
    case features
    case philosophy
}
