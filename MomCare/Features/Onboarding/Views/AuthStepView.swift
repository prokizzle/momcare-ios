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
                    let hashedNonce = viewModel.prepareNonce()
                    request.requestedScopes = [.fullName, .email]
                    request.nonce = hashedNonce
                } onCompletion: { result in
                    MCHaptic.tap()
                    Task {
                        await viewModel.performSignInWithApple(result: result)
                    }
                }
                .signInWithAppleButtonStyle(.white)
                .frame(height: 56)
                .clipShape(RoundedRectangle(cornerRadius: MCRadius.lg))

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
                        MCElevation.elevated,
                        in: RoundedRectangle(cornerRadius: MCRadius.lg)
                    )
                }
                .accessibilityLabel("Sign in with Google")

                if let error = viewModel.authError {
                    Text(error)
                        .font(.footnote)
                        .foregroundStyle(MCColor.error)
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
            .accessibilityLabel("Continue without creating an account")
            .padding(.top, MCSpacing.sm)
        }
        .padding(.horizontal, MCSpacing.xl)
        .padding(.bottom, MCSpacing.section)
    }
}
