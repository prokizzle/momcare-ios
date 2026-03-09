import SwiftUI

struct ContentView: View {
    @State private var navigation = AppNavigation()

    var body: some View {
        TabView(selection: $navigation.selectedTab) {
            Tab("Dashboard", systemImage: "heart.text.clipboard", value: .dashboard) {
                NavigationStack(path: $navigation.dashboardPath) {
                    Text("Mission Control")
                }
            }

            Tab("Feeding", systemImage: "drop.fill", value: .feeding) {
                NavigationStack(path: $navigation.feedingPath) {
                    Text("Feeding")
                }
            }

            Tab("Self-Care", systemImage: "sparkles", value: .selfCare) {
                NavigationStack(path: $navigation.selfCarePath) {
                    Text("Self-Care")
                }
            }

            Tab("Insights", systemImage: "chart.xyaxis.line", value: .insights) {
                NavigationStack(path: $navigation.insightsPath) {
                    Text("Insights")
                }
            }
        }
        .environment(navigation)
    }
}

#Preview {
    ContentView()
}
