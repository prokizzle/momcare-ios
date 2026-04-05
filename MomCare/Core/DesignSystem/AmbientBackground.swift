import SwiftUI

/// Slow-moving MeshGradient background keyed to the time of day.
/// Night: warm amber/rose. Morning: lavender/gold. Afternoon: teal/sky. Evening: coral/violet.
///
/// Applied behind dashboard content via `.ambientBackground()`. Extremely subtle (opacity 0.08)
/// so it reads as a tint, not a graphic element.
@MainActor
struct AmbientBackground: View {
    @State private var phase: Double = 0
    @State private var palette: [Color] = []
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.scenePhase) private var scenePhase

    private static let animationDuration: Double = 18.0

    var body: some View {
        MeshGradient(
            width: 3,
            height: 3,
            points: controlPoints(phase: phase),
            colors: palette.isEmpty ? timeOfDayColors() : palette
        )
        .ignoresSafeArea()
        .opacity(colorScheme == .dark ? 0.08 : 0.04)
        .onAppear {
            palette = timeOfDayColors()
            guard !reduceMotion else { return }
            withAnimation(
                .easeInOut(duration: Self.animationDuration).repeatForever(autoreverses: true)
            ) {
                phase = 1.0
            }
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                palette = timeOfDayColors()
            }
        }
    }

    // MARK: - Control Points

    private func controlPoints(phase: Double) -> [SIMD2<Float>] {
        let t = Float(phase) * 0.05
        return [
            .init(0.0,     0.0    ), .init(0.5,     t      ), .init(1.0, 0.0    ),
            .init(t,       0.5    ), .init(0.5,     0.5    ), .init(1.0 - t, 0.5),
            .init(0.0,     1.0    ), .init(0.5, 1.0 - t    ), .init(1.0, 1.0    )
        ]
    }

    // MARK: - Time-of-Day Color Palettes

    private func timeOfDayColors() -> [Color] {
        let hour = Calendar.current.component(.hour, from: Date.now)
        switch hour {
        case 0...5, 22...23:
            // Night: warm amber glow
            return [
                .black, Color(red: 1.0, green: 0.45, blue: 0.1), .black,
                Color(red: 0.9, green: 0.2, blue: 0.25), Color(red: 0.8, green: 0.3, blue: 0.1), Color(red: 0.7, green: 0.15, blue: 0.05),
                .black, Color(red: 0.9, green: 0.35, blue: 0.05), .black
            ]
        case 6..<12:
            // Morning: soft gold/lavender
            return [
                .black, Color(red: 0.6, green: 0.5, blue: 0.9), .black,
                Color(red: 0.9, green: 0.7, blue: 0.3), Color(red: 0.7, green: 0.55, blue: 0.8), Color(red: 0.5, green: 0.5, blue: 0.9),
                .black, Color(red: 0.8, green: 0.65, blue: 0.3), .black
            ]
        case 12..<18:
            // Afternoon: teal/sky
            return [
                .black, Color(red: 0.1, green: 0.7, blue: 0.9), .black,
                Color(red: 0.05, green: 0.6, blue: 0.8), Color(red: 0.1, green: 0.75, blue: 0.85), Color(red: 0.05, green: 0.65, blue: 0.9),
                .black, Color(red: 0.1, green: 0.7, blue: 0.8), .black
            ]
        default:
            // Evening: coral/violet
            return [
                .black, Color(red: 0.6, green: 0.2, blue: 0.7), .black,
                Color(red: 0.9, green: 0.35, blue: 0.2), Color(red: 0.7, green: 0.25, blue: 0.6), Color(red: 0.5, green: 0.1, blue: 0.7),
                .black, Color(red: 0.8, green: 0.3, blue: 0.25), .black
            ]
        }
    }
}

extension View {
    func ambientBackground() -> some View {
        background { AmbientBackground() }
    }
}
