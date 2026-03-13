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

            Image(systemName: "heart.fill")
                .font(.system(size: 80))
                .foregroundStyle(MCColor.accent)

            Text("MomCare")
                .font(.system(size: 40, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .conditionalEffect(.repeat(.shine, every: 3), condition: appeared)

            Text("Your baby care companion")
                .font(.title3)
                .foregroundStyle(.white.opacity(0.7))

            Spacer()

            onboardingButton(title: "Get Started") {
                MCHaptic.tap()
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

            LazyVGrid(
                columns: [
                    GridItem(.flexible(), spacing: MCSpacing.lg),
                    GridItem(.flexible(), spacing: MCSpacing.lg)
                ],
                spacing: MCSpacing.lg
            ) {
                featureCard(icon: "cup.and.saucer.fill", title: "Feeding", color: MCColor.feeding)
                featureCard(icon: "moon.zzz.fill", title: "Sleep", color: MCColor.babyStatus)
                featureCard(icon: "heart.text.clipboard.fill", title: "Self-Care", color: MCColor.selfCare)
                featureCard(icon: "chart.line.uptrend.xyaxis", title: "Insights", color: MCColor.accent)
            }
            .transition(.movingParts.pop)
            .padding(.horizontal, MCSpacing.sm)

            Spacer()

            onboardingButton(title: "Continue") {
                MCHaptic.tap()
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

            Image(systemName: "sparkles")
                .font(.system(size: 56))
                .foregroundStyle(MCColor.accent)

            Text("Built for 3am")
                .font(.title.bold())
                .foregroundStyle(.white)

            Text("Designed by parents, for parents")
                .font(.body)
                .foregroundStyle(.white.opacity(0.7))

            VStack(alignment: .leading, spacing: MCSpacing.lg) {
                bulletPoint("One-handed, dark-mode first design")
                bulletPoint("Local-first -- your data stays on device")
                bulletPoint("Optional sync to share with your partner")
                bulletPoint("No ads, no tracking, no compromise")
            }
            .padding(.horizontal, MCSpacing.lg)

            Spacer()

            onboardingButton(title: "Let's go") {
                MCHaptic.tap()
                viewModel.advance()
            }
        }
        .padding(.horizontal, MCSpacing.xl)
        .padding(.bottom, MCSpacing.section)
    }

    // MARK: - Components

    private func featureCard(icon: String, title: String, color: Color) -> some View {
        VStack(spacing: MCSpacing.md) {
            Image(systemName: icon)
                .font(.title)
                .foregroundStyle(color)

            Text(title)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.white)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, MCSpacing.xl)
        .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 16))
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
    }

    private func onboardingButton(title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.headline)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(MCColor.accent, in: RoundedRectangle(cornerRadius: 16))
        }
    }
}

// MARK: - Welcome Page

enum WelcomePage: Int, Hashable {
    case hero
    case features
    case philosophy
}
