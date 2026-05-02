import SwiftUI

enum BabyRoute: Hashable {
    case sleepHistory
    case sleepTimer
    case growth
    case healthEvents
    case healthEventDetail(UUID)
}

enum FeedingRoute: Hashable {
    case detail(feedingId: UUID)
    case timer
}

enum AppTab: String, CaseIterable, Sendable {
    case now
    case feeding
    case baby
    case selfCare
    case growth
    case journal
    case plan
}

@MainActor
@Observable
final class AppNavigation {
    var selectedTab: AppTab = .now
    var nowPath = NavigationPath()
    var feedingPath = NavigationPath()
    var babyPath = NavigationPath()
    var selfCarePath = NavigationPath()
    var growthPath = NavigationPath()
    var journalPath = NavigationPath()
    var planPath = NavigationPath()
    var pendingEndActivityType: String?

    func handleURL(_ url: URL) {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            return
        }

        if components.host == "end-activity" {
            let type = components.queryItems?.first(where: { $0.name == "type" })?.value
            pendingEndActivityType = type ?? "feeding"
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
            } else if remainder.first == "health-events" {
                babyPath.append(BabyRoute.healthEvents)
            }
        default:
            break
        }
    }
}
