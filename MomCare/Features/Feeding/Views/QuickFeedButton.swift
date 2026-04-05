import SwiftUI

struct QuickFeedButton: View {
    let action: () -> Void
    @State private var rippleTrigger: Date? = nil
    @State private var buttonCenter: CGPoint = .zero

    var body: some View {
        Button {
            MCHaptic.tap()
            rippleTrigger = .now
            action()
        } label: {
            HStack(spacing: MCSpacing.md) {
                Image(systemName: "drop.fill")
                    .font(.title2)
                Text("Start Feeding")
                    .font(MCTypography.title3)
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(MCColor.feeding)
            .clipShape(RoundedRectangle(cornerRadius: MCRadius.lg))
        }
        .background(
            GeometryReader { geo in
                Color.clear.onAppear {
                    buttonCenter = CGPoint(x: geo.size.width / 2, y: geo.size.height / 2)
                }
            }
        )
        .rippleEffect(trigger: rippleTrigger, origin: buttonCenter)
        .task(id: rippleTrigger) {
            guard rippleTrigger != nil else { return }
            try? await Task.sleep(for: .seconds(RippleModifier.duration + 0.1))
            rippleTrigger = nil
        }
    }
}
