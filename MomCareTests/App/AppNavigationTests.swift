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
        #expect(nav.journalPath.isEmpty)
        #expect(nav.planPath.isEmpty)
    }

    @Test("Tab enum has five cases")
    func allTabs() {
        let tabs = AppTab.allCases
        #expect(tabs.count == 5)
        #expect(tabs.contains(.now))
        #expect(tabs.contains(.baby))
        #expect(tabs.contains(.selfCare))
        #expect(tabs.contains(.journal))
        #expect(tabs.contains(.plan))
    }
}
