import SwiftUI

struct ContentView: View {
    @State private var navigation = AppNavigation()
    @State private var babyViewModel: BabyViewModel?
    @Environment(\.dependencies) private var dependencies
    @State private var showAddBaby = false

    var body: some View {
        Group {
            if let babyViewModel {
                mainTabView(babyViewModel: babyViewModel)
            } else {
                ProgressView()
            }
        }
        .task {
            let repo = dependencies.makeBabyRepository()
            let viewModel = BabyViewModel(repository: repo)
            await viewModel.loadBabies()
            babyViewModel = viewModel

            if viewModel.babies.isEmpty {
                showAddBaby = true
            }
        }
        .sheet(isPresented: $showAddBaby) {
            AddBabyView { baby in
                if let babyViewModel {
                    Task { await babyViewModel.createBaby(baby) }
                }
            }
        }
        .environment(navigation)
    }

    @ViewBuilder
    private func mainTabView(babyViewModel: BabyViewModel) -> some View {
        TabView(selection: $navigation.selectedTab) {
            NavigationStack(path: $navigation.dashboardPath) {
                Text("Mission Control")
                    .toolbar {
                        ToolbarItem(placement: .topBarLeading) {
                            BabySelectorView(viewModel: babyViewModel)
                        }
                    }
            }
            .tabItem {
                Label("Dashboard", systemImage: "heart.text.clipboard")
            }
            .tag(AppTab.dashboard)

            NavigationStack(path: $navigation.feedingPath) {
                Text("Feeding")
                    .toolbar {
                        ToolbarItem(placement: .topBarLeading) {
                            BabySelectorView(viewModel: babyViewModel)
                        }
                    }
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
    }
}

#Preview {
    ContentView()
}
