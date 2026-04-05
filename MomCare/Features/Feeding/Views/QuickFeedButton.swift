import SwiftUI

struct QuickFeedButton: View {
    let action: () -> Void
    @State private var rippleTrigger: Date? = nil
    @State private var rippleOrigin: CGPoint = .zero
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

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
        .simultaneousGesture(
            SpatialTapGesture().onEnded { value in
                rippleOrigin = value.location
            }
        )
        .rippleEffect(trigger: reduceMotion ? nil : rippleTrigger, origin: rippleOrigin)
        .task(id: rippleTrigger) {
            guard rippleTrigger != nil else { return }
            do {
                try await Task.sleep(for: .seconds(RippleModifier.duration + 0.1))
            } catch {
                return
            }
            rippleTrigger = nil
        }
    }
}
