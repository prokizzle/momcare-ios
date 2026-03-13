import AuthenticationServices
import SwiftUI

@MainActor
struct AuthStepView: View {
    @Bindable var viewModel: OnboardingViewModel

    var body: some View {
        VStack(spacing: MCSpacing.xl) {
            Spacer()

            Image(systemName: "person.crop.circle.badge.checkmark")
                .font(.system(size: 64))
                .foregroundStyle(MCColor.accent)

            Text("Create your account")
                .font(.title.bold())
                .foregroundStyle(.white)

            Text("Sign in to sync across devices and share with your partner")
                .font(.body)
                .foregroundStyle(.white.opacity(0.7))
                .multilineTextAlignment(.center)

            Spacer()

            VStack(spacing: MCSpacing.lg) {
                SignInWithAppleButton(.signIn) { request in
                    request.requestedScopes = [.fullName, .email]
                } onCompletion: { _ in
                    MCHaptic.tap()
                    Task {
                        await viewModel.performSignInWithApple()
                    }
                }
                .signInWithAppleButtonStyle(.white)
                .frame(height: 56)
                .clipShape(RoundedRectangle(cornerRadius: 16))

                Button {
                    MCHaptic.tap()
                    Task {
                        await viewModel.performSignInWithGoogle()
                    }
                } label: {
                    HStack(spacing: MCSpacing.md) {
                        Image(systemName: "globe")
                            .font(.title3)
                        Text("Sign in with Google")
                            .font(.headline)
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(
                        Color.white.opacity(0.12),
                        in: RoundedRectangle(cornerRadius: 16)
                    )
                }

                if let error = viewModel.authError {
                    Text(error)
                        .font(.footnote)
                        .foregroundStyle(.red)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, MCSpacing.lg)
                }
            }

            Button {
                MCHaptic.tap()
                Task {
                    await viewModel.skipAuth()
                }
            } label: {
                Text("Continue without account")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.5))
            }
            .padding(.top, MCSpacing.sm)
        }
        .padding(.horizontal, MCSpacing.xl)
        .padding(.bottom, MCSpacing.section)
    }
}
