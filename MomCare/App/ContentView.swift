import SwiftUI

struct ContentView: View {
    @State private var navigation = AppNavigation()

    var body: some View {
        TabView(selection: $navigation.selectedTab) {
            NavigationStack(path: $navigation.dashboardPath) {
                Text("Mission Control")
            }
            .tabItem {
                Label("Dashboard", systemImage: "heart.text.clipboard")
            }
            .tag(AppTab.dashboard)

            NavigationStack(path: $navigation.feedingPath) {
                Text("Feeding")
            }
            .tabItem {
                Label("Feeding", systemImage: "drop.fill")
            }
            .tag(AppTab.feeding)

            NavigationStack(path: $navigation.selfCarePath) {
                Text("Self-Care")
            }
            .tabItem {
                Label("Self-Care", systemImage: "sparkles")
            }
            .tag(AppTab.selfCare)

            NavigationStack(path: $navigation.insightsPath) {
                Text("Insights")
            }
            .tabItem {
                Label("Insights", systemImage: "chart.xyaxis.line")
            }
            .tag(AppTab.insights)
        }
        .environment(navigation)
    }
}

#Preview {
    ContentView()
}
