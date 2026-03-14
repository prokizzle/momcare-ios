import SwiftUI

enum BabyRoute: Hashable {
    case sleepHistory
    case sleepTimer
    case growth
}

enum FeedingRoute: Hashable {
    case detail(feedingId: UUID)
    case timer
}

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

        guard let first = pathComponents.first,
              let tab = AppTab(rawValue: first) else {
            return
        }

        selectedTab = tab
        let remainder = Array(pathComponents.dropFirst())

        switch tab {
        case .baby:
            if remainder.first == "sleep-history" {
                babyPath.append(BabyRoute.sleepHistory)
            } else if remainder.first == "sleep-timer" {
                babyPath.append(BabyRoute.sleepTimer)
            } else if remainder.first == "growth" {
                babyPath.append(BabyRoute.growth)
            }
        default:
            break
        }
    }
}
