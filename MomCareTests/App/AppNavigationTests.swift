import Testing
@testable import MomCare

@Suite("AppNavigation Tests")
struct AppNavigationTests {
    @Test("Default tab is now")
    @MainActor
    func defaultTab() {
        let nav = AppNavigation()
        #expect(nav.selectedTab == .now)
    }

    @Test("Each tab has its own navigation path")
    @MainActor
    func tabPaths() {
        let nav = AppNavigation()
        #expect(nav.nowPath.isEmpty)
        #expect(nav.babyPath.isEmpty)
        #expect(nav.selfCarePath.isEmpty)
        #expect(nav.feedingPath.isEmpty)
        #expect(nav.growthPath.isEmpty)
    }

    @Test("Tab enum has five cases")
    func allTabs() {
        let tabs = AppTab.allCases
        #expect(tabs.count == 5)
        #expect(tabs.contains(.now))
        #expect(tabs.contains(.baby))
        #expect(tabs.contains(.feeding))
        #expect(tabs.contains(.selfCare))
        #expect(tabs.contains(.growth))
    }
}
