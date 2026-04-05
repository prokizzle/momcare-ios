import SwiftUI

/// Applies a Metal-backed radial ripple distortion that expands from `origin` on `trigger`.
/// The effect decays naturally over `duration` seconds; the caller is responsible for
/// nilling `trigger` after the effect completes so the TimelineView stops running.
struct RippleModifier: ViewModifier {
    let trigger: Date?
    let origin: CGPoint

    static let duration: Double = 0.9

    func body(content: Content) -> some View {
        if let trigger {
            TimelineView(.animation) { context in
                let elapsed = Float(context.date.timeIntervalSince(trigger))
                content
                    .distortionEffect(
                        ShaderLibrary.feedingRipple(
                            .float2(origin),
                            .float(elapsed),
                            .float(10.0),
                            .float(15.0),
                            .float(9.0)
                        ),
                        maxSampleOffset: CGSize(width: 10, height: 10),
                        isEnabled: elapsed < Float(Self.duration)
                    )
            }
        } else {
            content
        }
    }
}

extension View {
    func rippleEffect(trigger: Date?, origin: CGPoint) -> some View {
        modifier(RippleModifier(trigger: trigger, origin: origin))
    }
}
