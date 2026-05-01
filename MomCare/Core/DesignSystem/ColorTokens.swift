import SwiftUI

enum MCColor {
    static let accent = Color.accentColor
    static let feeding = Color("FeedingColor")
    static let selfCare = Color("SelfCareColor")
    static let babyStatus = Color("BabyStatusColor")
    static let diaper = Color("DiaperColor")
    static let baby = Color("BabyColor")

    static let canvas = Color(red: 0.043, green: 0.031, blue: 0.039)
    static let canvasEdge = Color.black

    static let error = Color(red: 0.937, green: 0.267, blue: 0.267)

    enum Urgency {
        static let safe = Color(red: 0.290, green: 0.871, blue: 0.502)
        static let warning = Color(red: 0.980, green: 0.800, blue: 0.082)
        static let urgent = Color(red: 0.984, green: 0.573, blue: 0.235)
    }

    enum Foreground {
        static let level1 = Color.white
        static let level2 = Color.white.opacity(0.70)
        static let level3 = Color.white.opacity(0.55)
        static let level4 = Color.white.opacity(0.40)

        enum Light {
            static let level1 = Color.black.opacity(0.92)
            static let level2 = Color.black.opacity(0.62)
        }
    }
}

enum MCGradient {
    static func canvas(height: CGFloat = 900) -> RadialGradient {
        RadialGradient(
            colors: [MCColor.canvas, MCColor.canvasEdge],
            center: .center,
            startRadius: 0,
            endRadius: height * 0.8
        )
    }

    static func glow(color: Color, radius: CGFloat = 40) -> RadialGradient {
        RadialGradient(
            colors: [color.opacity(MCOpacity.medium), color.opacity(0)],
            center: .center,
            startRadius: 0,
            endRadius: radius
        )
    }

    static let glowAccent: RadialGradient = glow(color: MCColor.accent)
    static let glowFeeding: RadialGradient = glow(color: MCColor.feeding)
    static let glowSelf: RadialGradient = glow(color: MCColor.selfCare)
    static let glowBaby: RadialGradient = glow(color: MCColor.baby)
}
