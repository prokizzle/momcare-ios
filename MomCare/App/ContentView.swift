import SwiftUI

struct ContentView: View {
    @State private var navigation = AppNavigation()
    var babyViewModel: BabyViewModel?
    var selfCareViewModel: SelfCareViewModel?
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
    private func mainTabView(babyViewModel: BabyViewModel) -> some View {
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
        NavigationStack(path: $navigation.nowPath) {
            Text("Now")
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        BabySelectorView(viewModel: babyViewModel)
                    }
                }
        }
        .tabItem {
            Label("Now", systemImage: "sun.horizon.fill")
        }
        .tag(AppTab.now)
    }

    @ViewBuilder
    private func babyTab(babyViewModel: BabyViewModel) -> some View {
        NavigationStack(path: $navigation.babyPath) {
            Text("Baby")
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        BabySelectorView(viewModel: babyViewModel)
                    }
                }
        }
        .tabItem {
            Label("Baby", systemImage: "figure.and.child.holdinghands")
        }
        .tag(AppTab.baby)
    }

    @ViewBuilder
    private func selfCareTab(babyViewModel: BabyViewModel) -> some View {
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
    }

    @ViewBuilder
    private func journalTab(babyViewModel: BabyViewModel) -> some View {
        NavigationStack(path: $navigation.journalPath) {
            Text("Journal")
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        BabySelectorView(viewModel: babyViewModel)
                    }
                }
        }
        .tabItem {
            Label("Journal", systemImage: "book.pages")
        }
        .tag(AppTab.journal)
    }

    @ViewBuilder
    private func planTab() -> some View {
        NavigationStack(path: $navigation.planPath) {
            Text("Plan")
        }
        .tabItem {
            Label("Plan", systemImage: "map")
        }
        .tag(AppTab.plan)
    }
}

#Preview {
    ContentView()
}
