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
        assertionFailure("Deep link received but routing not yet implemented: \(url)")
    }
}
