import SwiftUI

enum AppTab: String, CaseIterable, Sendable {
    case dashboard
    case feeding
    case diapers
    case selfCare
    case insights
}

@MainActor
@Observable
final class AppNavigation {
    var selectedTab: AppTab = .dashboard
    var dashboardPath = NavigationPath()
    var feedingPath = NavigationPath()
    var diapersPath = NavigationPath()
    var selfCarePath = NavigationPath()
    var insightsPath = NavigationPath()

    func handleURL(_ url: URL) {
        assertionFailure("Deep link received but routing not yet implemented: \(url)")
    }
}
