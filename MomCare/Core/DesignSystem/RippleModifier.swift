import SwiftUI

/// Applies a Metal-backed radial ripple distortion that expands from `origin` on `trigger`.
/// The effect decays naturally over `duration` seconds; the caller is responsible for
/// nilling `trigger` after the effect completes so the TimelineView stops running.
struct RippleModifier: ViewModifier {
    let trigger: Date?
    let origin: CGPoint

    static let duration: Double = 0.9
    private static let intensity: Float = 10
    private static let frequency: Float = 15
    private static let decay: Float = 9
    private static let maxSampleOffset = CGSize(width: 10, height: 10)

    func body(content: Content) -> some View {
        if let trigger {
            TimelineView(.animation) { context in
                let elapsed = max(Float(context.date.timeIntervalSince(trigger)), 0)
                content
                    .distortionEffect(
                        ShaderLibrary.feedingRipple(
                            .float2(origin),
                            .float(elapsed),
                            .float(Self.intensity),
                            .float(Self.frequency),
                            .float(Self.decay)
                        ),
                        maxSampleOffset: Self.maxSampleOffset,
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
