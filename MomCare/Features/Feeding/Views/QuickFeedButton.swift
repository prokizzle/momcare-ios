import Pow
import SwiftUI

struct QuickFeedButton: View {
    let action: () -> Void
    @State private var tapCount = 0

    var body: some View {
        Button {
            MCHaptic.tap()
            tapCount += 1
            action()
        } label: {
            HStack(spacing: MCSpacing.md) {
                Image(systemName: "play.fill")
                    .font(.subheadline)
                    .accessibilityHidden(true)
                Text("Start Feeding")
                    .font(MCTypography.button)
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 64)
            .background(MCColor.feeding)
            .clipShape(RoundedRectangle(cornerRadius: MCRadius.lg))
            .shadow(color: MCColor.feeding.opacity(MCOpacity.medium), radius: 18)
        }
        .changeEffect(.shine, value: tapCount)
    }
}
