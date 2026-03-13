import SwiftUI

@MainActor
struct OnboardingView: View {
    @Bindable var viewModel: OnboardingViewModel

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            Group {
                switch viewModel.currentStep {
                case .welcome, .features, .philosophy:
                    WelcomePageView(viewModel: viewModel)

                case .auth:
                    AuthStepView(viewModel: viewModel)

                case .notifications:
                    PermissionStepView(viewModel: viewModel, kind: .notifications)

                case .healthKit:
                    PermissionStepView(viewModel: viewModel, kind: .healthKit)

                case .addBaby:
                    OnboardingBabyFormView(viewModel: viewModel)

                case .tourDashboard, .tourSelfCare:
                    TourPageView(viewModel: viewModel)
                }
            }
            .animation(.easeInOut(duration: 0.4), value: viewModel.currentStep)
        }
        .preferredColorScheme(.dark)
    }
}
