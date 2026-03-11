import SwiftUI

enum AppTab: String, CaseIterable, Sendable {
    case now
    case baby
    case selfCare
    case journal
    case plan
}

@MainActor
@Observable
final class AppNavigation {
    var selectedTab: AppTab = .now
    var nowPath = NavigationPath()
    var babyPath = NavigationPath()
    var selfCarePath = NavigationPath()
    var journalPath = NavigationPath()
    var planPath = NavigationPath()

    func handleURL(_ url: URL) {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            return
        }

        let pathComponents = components.path
            .split(separator: "/")
            .map(String.init)

        if let first = pathComponents.first,
           let tab = AppTab(rawValue: first) {
            selectedTab = tab
        }
    }
}
