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
                Image(systemName: "drop.fill")
                    .font(.title2)
                    .accessibilityHidden(true)
                Text("Start Feeding")
                    .font(MCTypography.title3)
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(MCColor.feeding)
            .clipShape(RoundedRectangle(cornerRadius: MCRadius.lg))
        }
        .changeEffect(.shine, value: tapCount)
    }
}
