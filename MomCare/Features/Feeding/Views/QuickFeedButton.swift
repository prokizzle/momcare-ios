import SwiftUI

struct QuickFeedButton: View {
    let action: () -> Void

    var body: some View {
        Button {
            MCHaptic.tap()
            action()
        } label: {
            HStack(spacing: MCSpacing.md) {
                Image(systemName: "drop.fill")
                    .font(.title2)
                Text("Start Feeding")
                    .font(.title3.weight(.semibold))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(MCColor.feeding)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }
}
