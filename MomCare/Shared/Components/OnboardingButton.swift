import SwiftUI

@MainActor
struct OnboardingButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button {
            MCHaptic.tap()
            action()
        } label: {
            Text(title)
                .font(.headline)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(MCColor.accent, in: RoundedRectangle(cornerRadius: 16))
        }
    }
}
