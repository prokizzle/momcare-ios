import SwiftUI

@MainActor
struct ContentView: View {
    @Environment(AppNavigation.self) private var navigation

    var babyViewModel: BabyViewModel?
    var selfCareViewModel: SelfCareViewModel?
    var dashboardViewModel: DashboardViewModel?
    var babyActivityEngine: BabyActivityEngine?
    var journalViewModel: JournalViewModel?

    @State private var showAddBaby = false

    var body: some View {
        Group {
            if let babyViewModel {
                if let engine = babyActivityEngine {
                    mainTabView(babyViewModel: babyViewModel)
                        .environment(engine)
                } else {
                    ProgressView()
                }
            } else {
                ProgressView()
            }
        }
        .onChange(of: babyViewModel?.babies.isEmpty) { _, isEmpty in
            if isEmpty == true { showAddBaby = true }
        }
        .sheet(isPresented: $showAddBaby) {
            if let babyViewModel { AddBabyView(viewModel: babyViewModel) }
        }
    }

    @ViewBuilder
    private func mainTabView(babyViewModel: BabyViewModel) -> some View {
        @Bindable var navigation = navigation
        TabView(selection: $navigation.selectedTab) {
            nowTab(babyViewModel: babyViewModel)
            babyTab(babyViewModel: babyViewModel)
            selfCareTab(babyViewModel: babyViewModel)
            journalTab(babyViewModel: babyViewModel)
            planTab()
        }
    }

    @ViewBuilder
    private func nowTab(babyViewModel: BabyViewModel) -> some View {
        @Bindable var navigation = navigation
        NavigationStack(path: $navigation.nowPath) {
            NowScreen(
                dashboardViewModel: dashboardViewModel,
                babyId: babyViewModel.selectedBaby?.id
            )
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    BabySelectorView(viewModel: babyViewModel)
                }
            }
        }
        .tabItem { Label("Now", systemImage: "sun.horizon.fill") }
        .tag(AppTab.now)
    }

    @ViewBuilder
    private func babyTab(babyViewModel: BabyViewModel) -> some View {
        @Bindable var navigation = navigation
        NavigationStack(path: $navigation.babyPath) {
            BabyScreen(babyId: babyViewModel.selectedBaby?.id)
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        BabySelectorView(viewModel: babyViewModel)
                    }
                }
        }
        .tabItem { Label("Baby", systemImage: "figure.and.child.holdinghands") }
        .tag(AppTab.baby)
    }

    @ViewBuilder
    private func selfCareTab(babyViewModel: BabyViewModel) -> some View {
        @Bindable var navigation = navigation
        NavigationStack(path: $navigation.selfCarePath) {
            SelfCareScreen(viewModel: selfCareViewModel)
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        BabySelectorView(viewModel: babyViewModel)
                    }
                }
        }
        .tabItem { Label("Self-Care", systemImage: "sparkles") }
        .tag(AppTab.selfCare)
    }

    @ViewBuilder
    private func journalTab(babyViewModel: BabyViewModel) -> some View {
        @Bindable var navigation = navigation
        NavigationStack(path: $navigation.journalPath) {
            JournalScreen(
                viewModel: journalViewModel,
                babyId: babyViewModel.selectedBaby?.id
            )
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    BabySelectorView(viewModel: babyViewModel)
                }
            }
        }
        .tabItem { Label("Journal", systemImage: "book.pages") }
        .tag(AppTab.journal)
    }

    @ViewBuilder
    private func planTab() -> some View {
        @Bindable var navigation = navigation
        NavigationStack(path: $navigation.planPath) {
            PlanScreen()
        }
        .tabItem { Label("Plan", systemImage: "map.fill") }
        .tag(AppTab.plan)
    }
}

#Preview {
    ContentView()
        .environment(AppNavigation())
}
