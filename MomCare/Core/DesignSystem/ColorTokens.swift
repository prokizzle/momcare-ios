import SwiftUI

enum MCColor {
    static let accent = Color.accentColor
    static let feeding = Color("FeedingColor")
    static let selfCare = Color("SelfCareColor")
    static let babyStatus = Color("BabyStatusColor")
    static let diaper = Color("DiaperColor")
    static let baby = Color("BabyColor")

    static let canvas = Color(red: 0.04, green: 0.03, blue: 0.04)

    static let error = Color.red

    enum Urgency {
        static let safe = Color.green
        static let warning = Color.yellow
        static let urgent = Color.orange
    }
}

enum MCGradient {
    static func canvas() -> RadialGradient {
        RadialGradient(
            colors: [MCColor.canvas, .black],
            center: .center,
            startRadius: 0,
            endRadius: UIScreen.main.bounds.height * 0.8
        )
    }

    static func glow(color: Color, radius: CGFloat = 40) -> RadialGradient {
        RadialGradient(
            colors: [color.opacity(0.15), color.opacity(0)],
            center: .center,
            startRadius: 0,
            endRadius: radius
        )
    }
}
