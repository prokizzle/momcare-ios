import SwiftUI

enum MCElevation {
    static let surfaceOpacity: Double = MCOpacity.whisper
    static let elevatedOpacity: Double = MCOpacity.soft
    static let overlayOpacity: Double = MCOpacity.medium

    static var surface: Color { Color.white.opacity(surfaceOpacity) }
    static var elevated: Color { Color.white.opacity(elevatedOpacity) }
    static var overlay: Color { Color.white.opacity(overlayOpacity) }
}
