import SwiftUI
import UIKit

/// Applies MomCare's design system tokens to all native UIKit chrome — nav bar,
/// tab bar, and toolbar — at app startup via appearance proxies.
///
/// Must be applied once at the root view. Uses `configureWithDefaultBackground()`
/// throughout to preserve Liquid Glass on iOS 26+.
struct ChromeThemingModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .tint(MCColor.accent)
            .onAppear { configureGlobalAppearance() }
    }

    private func configureGlobalAppearance() {
        configureNavigationBar()
        configureTabBar()
        configureToolbar()
    }

    // MARK: - Navigation Bar

    private func configureNavigationBar() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithDefaultBackground() // preserves Liquid Glass on iOS 26

        if let titleFont = UIFont(name: "Nunito-SemiBold", size: 17) {
            let scaled = UIFontMetrics(forTextStyle: .headline).scaledFont(for: titleFont)
            appearance.titleTextAttributes = [.font: scaled]
        }
        if let largeTitleFont = UIFont(name: "Nunito-Bold", size: 34) {
            let scaled = UIFontMetrics(forTextStyle: .largeTitle).scaledFont(for: largeTitleFont)
            appearance.largeTitleTextAttributes = [.font: scaled]
        }

        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        UINavigationBar.appearance().compactAppearance = appearance
        UINavigationBar.appearance().tintColor = UIColor(MCColor.accent)
    }

    // MARK: - Tab Bar

    private func configureTabBar() {
        let appearance = UITabBarAppearance()
        appearance.configureWithDefaultBackground() // preserves Liquid Glass on iOS 26
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
        UITabBar.appearance().tintColor = UIColor(MCColor.accent)
        UITabBar.appearance().unselectedItemTintColor = .secondaryLabel
    }

    // MARK: - Toolbar

    private func configureToolbar() {
        let appearance = UIToolbarAppearance()
        appearance.configureWithDefaultBackground()
        UIToolbar.appearance().standardAppearance = appearance
        UIToolbar.appearance().scrollEdgeAppearance = appearance
        UIToolbar.appearance().tintColor = UIColor(MCColor.accent)
    }
}

extension View {
    func chromeTheming() -> some View {
        modifier(ChromeThemingModifier())
    }
}
