import SwiftUI

// MARK: - Theme Colors (Environment-Injectable)

/// Wraps `MCColor` into a value type that can be injected via `@Environment`.
/// Views that need themed colors use `@Environment(\.themeColors)` instead of
/// accessing `MCColor` statically, enabling future theme switching and previews.
struct ThemeColors: Sendable {
    let accent: Color
    let feeding: Color
    let selfCare: Color
    let babyStatus: Color
    let diaper: Color
    let baby: Color
    let canvas: Color
    let error: Color

    // Urgency
    let urgencySafe: Color
    let urgencyWarning: Color
    let urgencyUrgent: Color
}

extension ThemeColors {
    /// Default theme derived from the existing `MCColor` token values.
    static let `default` = ThemeColors(
        accent: MCColor.accent,
        feeding: MCColor.feeding,
        selfCare: MCColor.selfCare,
        babyStatus: MCColor.babyStatus,
        diaper: MCColor.diaper,
        baby: MCColor.baby,
        canvas: MCColor.canvas,
        error: MCColor.error,
        urgencySafe: MCColor.Urgency.safe,
        urgencyWarning: MCColor.Urgency.warning,
        urgencyUrgent: MCColor.Urgency.urgent
    )
}

// MARK: - Environment Key

private struct ThemeColorsKey: EnvironmentKey {
    static let defaultValue = ThemeColors.default
}

extension EnvironmentValues {
    var themeColors: ThemeColors {
        get { self[ThemeColorsKey.self] }
        set { self[ThemeColorsKey.self] = newValue }
    }
}

// MARK: - View Modifier

extension View {
    /// Injects a theme into the view hierarchy.
    func theme(_ colors: ThemeColors) -> some View {
        environment(\.themeColors, colors)
    }
}
