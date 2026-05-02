import SwiftUI

@MainActor
struct ContentView: View {
    @Environment(AppNavigation.self) private var navigation

    var babyViewModel: BabyViewModel?
    var feedingViewModel: FeedingViewModel?
    var selfCareViewModel: SelfCareViewModel?
    var dashboardViewModel: DashboardViewModel?
    var babyActivityEngine: BabyActivityEngine?
    var journalViewModel: JournalViewModel?
    var sleepViewModel: SleepViewModel?
    var growthViewModel: GrowthViewModel?
    var healthEventsViewModel: HealthEventsViewModel?

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
    }

    @ViewBuilder
    private func mainTabView(babyViewModel: BabyViewModel) -> some View {
        @Bindable var navigation = navigation
        TabView(selection: $navigation.selectedTab) {
            nowTab(babyViewModel: babyViewModel)
            feedingTab(babyViewModel: babyViewModel)
            selfCareTab(babyViewModel: babyViewModel)
            growthTab(babyViewModel: babyViewModel)
            moreTab(babyViewModel: babyViewModel)
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
        .tabItem { Label("Now", systemImage: "house.fill") }
        .tag(AppTab.now)
    }

    @ViewBuilder
    private func feedingTab(babyViewModel: BabyViewModel) -> some View {
        @Bindable var navigation = navigation
        NavigationStack(path: $navigation.feedingPath) {
            FeedingScreen(
                viewModel: feedingViewModel,
                babyId: babyViewModel.selectedBaby?.id
            )
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    BabySelectorView(viewModel: babyViewModel)
                }
            }
        }
        .tabItem { Label("Feeding", systemImage: "drop.fill") }
        .tag(AppTab.feeding)
    }

    @ViewBuilder
    private func moreTab(babyViewModel: BabyViewModel) -> some View {
        @Bindable var navigation = navigation
        NavigationStack(path: $navigation.babyPath) {
            BabyScreen(
                babyId: babyViewModel.selectedBaby?.id,
                baby: babyViewModel.selectedBaby,
                dateOfBirth: babyViewModel.selectedBaby?.dateOfBirth,
                biologicalSex: babyViewModel.selectedBaby?.biologicalSex,
                sleepViewModel: sleepViewModel,
                growthViewModel: growthViewModel,
                healthEventsViewModel: healthEventsViewModel
            )
            .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        BabySelectorView(viewModel: babyViewModel)
                    }
                }
        }
        .tabItem { Label("More", systemImage: "person.crop.circle") }
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
        .tabItem { Label("You", systemImage: "sparkles") }
        .tag(AppTab.selfCare)
    }

    @ViewBuilder
    private func growthTab(babyViewModel: BabyViewModel) -> some View {
        @Bindable var navigation = navigation
        NavigationStack(path: $navigation.growthPath) {
            if let baby = babyViewModel.selectedBaby,
               let growthViewModel {
                GrowthScreen(
                    babyId: baby.id,
                    dateOfBirth: baby.dateOfBirth,
                    biologicalSex: baby.biologicalSex,
                    baby: baby,
                    healthEvents: healthEventsViewModel?.events ?? [],
                    viewModel: growthViewModel
                )
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        BabySelectorView(viewModel: babyViewModel)
                    }
                }
            } else {
                ContentUnavailableView(
                    "Select a baby",
                    systemImage: "figure.and.child.holdinghands",
                    description: Text("Growth charts appear once a baby profile is selected.")
                )
                .navigationTitle("Growth")
                .ambientBackground()
            }
        }
        .tabItem { Label("Growth", systemImage: "chart.line.uptrend.xyaxis") }
        .tag(AppTab.growth)
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
