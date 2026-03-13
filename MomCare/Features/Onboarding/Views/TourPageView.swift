import Pow
import SwiftUI

enum TourPage: Int, Hashable {
    case dashboard
    case selfCare
}

@MainActor
struct TourPageView: View {
    @Bindable var viewModel: OnboardingViewModel
    @State private var appeared = false

    private var currentPage: TourPage {
        viewModel.currentStep == .tourSelfCare ? .selfCare : .dashboard
    }

    var body: some View {
        TabView(selection: Binding(
            get: { currentPage },
            set: { newPage in
                switch newPage {
                case .dashboard: viewModel.currentStep = .tourDashboard
                case .selfCare: viewModel.currentStep = .tourSelfCare
                }
            }
        )) {
            dashboardPage.tag(TourPage.dashboard)
            selfCarePage.tag(TourPage.selfCare)
        }
        .tabViewStyle(.page(indexDisplayMode: .always))
        .onAppear { appeared = true }
    }

    // MARK: - Dashboard

    private var dashboardPage: some View {
        VStack(spacing: MCSpacing.xl) {
            Spacer()

            Image(systemName: "rectangle.grid.2x2.fill")
                .font(.system(size: 56))
                .foregroundStyle(MCColor.accent)

            Text("Your mission control")
                .font(.title.bold())
                .foregroundStyle(.white)

            Text("Everything at a glance, designed for one hand")
                .font(.body)
                .foregroundStyle(.white.opacity(0.7))
                .multilineTextAlignment(.center)

            VStack(spacing: MCSpacing.lg) {
                tourFeatureCard(
                    icon: "clock.fill",
                    title: "Now Tab",
                    description: "Active timers, upcoming feedings, and quick actions"
                )
                tourFeatureCard(
                    icon: "face.smiling.fill",
                    title: "Baby Tab",
                    description: "Growth charts, milestones, and daily summaries"
                )
            }
            .padding(.top, MCSpacing.md)

            Spacer()

            onboardingButton(title: "Next") {
                MCHaptic.tap()
                viewModel.currentStep = .tourSelfCare
            }
        }
        .padding(.horizontal, MCSpacing.xl)
        .padding(.bottom, MCSpacing.section)
    }

    // MARK: - Self-Care

    private var selfCarePage: some View {
        VStack(spacing: MCSpacing.xl) {
            Spacer()

            Image(systemName: "leaf.fill")
                .font(.system(size: 56))
                .foregroundStyle(MCColor.selfCare)

            Text("Your wellbeing matters too")
                .font(.title.bold())
                .foregroundStyle(.white)

            Text("Taking care of yourself is taking care of your baby")
                .font(.body)
                .foregroundStyle(.white.opacity(0.7))
                .multilineTextAlignment(.center)

            VStack(spacing: MCSpacing.lg) {
                tourFeatureCard(
                    icon: "heart.fill",
                    title: "Self-Care",
                    description: "Track mood, water intake, meals, and daily essentials"
                )
                tourFeatureCard(
                    icon: "book.fill",
                    title: "Journal",
                    description: "Capture moments, milestones, and reflections"
                )
            }
            .padding(.top, MCSpacing.md)

            Spacer()

            Button {
                MCHaptic.tap()
                viewModel.advance()
            } label: {
                Text("Start using MomCare")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(MCColor.accent, in: RoundedRectangle(cornerRadius: 16))
                    .conditionalEffect(.repeat(.shine, every: 3), condition: appeared)
            }
        }
        .padding(.horizontal, MCSpacing.xl)
        .padding(.bottom, MCSpacing.section)
    }

    // MARK: - Components

    private func tourFeatureCard(icon: String, title: String, description: String) -> some View {
        HStack(spacing: MCSpacing.lg) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(MCColor.accent)
                .frame(width: 44, height: 44)

            VStack(alignment: .leading, spacing: MCSpacing.xs) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(.white)

                Text(description)
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.6))
            }

            Spacer()
        }
        .padding(MCSpacing.lg)
        .background(Color.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 16))
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
