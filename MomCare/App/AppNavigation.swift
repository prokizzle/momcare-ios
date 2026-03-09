import SwiftUI

enum AppTab: String, CaseIterable, Sendable {
    case dashboard
    case feeding
    case selfCare
    case insights
}

@Observable
final class AppNavigation {
    var selectedTab: AppTab = .dashboard
    var dashboardPath = NavigationPath()
    var feedingPath = NavigationPath()
    var selfCarePath = NavigationPath()
    var insightsPath = NavigationPath()

    func handleURL(_ url: URL) {
        // Deep link routing added per feature
    }
}
