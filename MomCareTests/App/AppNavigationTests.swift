import Testing
@testable import MomCare

@Suite("AppNavigation Tests")
struct AppNavigationTests {
    @Test("Default tab is dashboard")
    @MainActor
    func defaultTab() {
        let nav = AppNavigation()
        #expect(nav.selectedTab == .dashboard)
    }

    @Test("Each tab has its own navigation path")
    @MainActor
    func tabPaths() {
        let nav = AppNavigation()
        #expect(nav.dashboardPath.isEmpty)
        #expect(nav.feedingPath.isEmpty)
        #expect(nav.diapersPath.isEmpty)
        #expect(nav.selfCarePath.isEmpty)
        #expect(nav.insightsPath.isEmpty)
    }

    @Test("Tab enum has all five cases")
    func allTabs() {
        let tabs = AppTab.allCases
        #expect(tabs.count == 5)
        #expect(tabs.contains(.dashboard))
        #expect(tabs.contains(.feeding))
        #expect(tabs.contains(.diapers))
        #expect(tabs.contains(.selfCare))
        #expect(tabs.contains(.insights))
    }
}
