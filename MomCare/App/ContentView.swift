import SwiftUI

struct ContentView: View {
    @State private var navigation = AppNavigation()
    var babyViewModel: BabyViewModel?
    var feedingViewModel: FeedingViewModel?
    var selfCareViewModel: SelfCareViewModel?
    var dashboardViewModel: DashboardViewModel?
    var diaperViewModel: DiaperViewModel?
    @State private var showAddBaby = false

    var body: some View {
        Group {
            if let babyViewModel {
                mainTabView(babyViewModel: babyViewModel)
            } else {
                ProgressView()
            }
        }
        .onChange(of: babyViewModel?.babies.isEmpty) { _, isEmpty in
            if isEmpty == true {
                showAddBaby = true
            }
        }
        .sheet(isPresented: $showAddBaby) {
            if let babyViewModel {
                AddBabyView(viewModel: babyViewModel)
            }
        }
        .environment(navigation)
    }

    @ViewBuilder
    // swiftlint:disable:next function_body_length
    private func mainTabView(babyViewModel: BabyViewModel) -> some View {
        TabView(selection: $navigation.selectedTab) {
            NavigationStack(path: $navigation.dashboardPath) {
                DashboardScreen(
                    viewModel: dashboardViewModel,
                    babyId: babyViewModel.selectedBaby?.id
                )
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
                FeedingScreen(viewModel: feedingViewModel, babyId: babyViewModel.selectedBaby?.id)
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

            NavigationStack(path: $navigation.diapersPath) {
                DiaperScreen(viewModel: diaperViewModel, babyId: babyViewModel.selectedBaby?.id)
                    .toolbar {
                        ToolbarItem(placement: .topBarLeading) {
                            BabySelectorView(viewModel: babyViewModel)
                        }
                    }
            }
            .tabItem {
                Label("Diapers", systemImage: "drop.circle")
            }
            .tag(AppTab.diapers)

            NavigationStack(path: $navigation.selfCarePath) {
                SelfCareScreen(viewModel: selfCareViewModel)
                    .toolbar {
                        ToolbarItem(placement: .topBarLeading) {
                            BabySelectorView(viewModel: babyViewModel)
                        }
                    }
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
