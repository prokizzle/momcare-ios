import SwiftUI
import SwiftData
import FirebaseCore

@main
struct MomCareApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema(versionedSchema: SchemaV2.self)
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            groupContainer: .identifier("group.com.feelingmindful.momcare")
        )

        do {
            return try ModelContainer(
                for: schema,
                migrationPlan: MomCareMigrationPlan.self,
                configurations: [modelConfiguration]
            )
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    init() {
        if Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist") != nil {
            FirebaseApp.configure()
        } else {
            #if DEBUG
            print("Warning: GoogleService-Info.plist not found. Firebase is not configured.")
            #endif
        }
    }

    @State private var babyViewModel: BabyViewModel?
    @State private var feedingViewModel: FeedingViewModel?
    @State private var selfCareViewModel: SelfCareViewModel?

    var body: some Scene {
        WindowGroup {
            ContentView(
                babyViewModel: babyViewModel,
                feedingViewModel: feedingViewModel,
                selfCareViewModel: selfCareViewModel
            )
            .task {
                if babyViewModel == nil {
                    let deps = AppDependencies(modelContext: sharedModelContainer.mainContext)
                    let babyVM = BabyViewModel(repository: deps.makeBabyRepository())
                    await babyVM.loadBabies()
                    babyViewModel = babyVM
                    feedingViewModel = FeedingViewModel(repository: deps.makeFeedingRepository())
                    let contentLibrary = (try? ContentLibrary.loadFromBundle()) ?? ContentLibrary(
                        affirmations: [],
                        pepTalks: [],
                        checkInPrompts: [],
                        nudgeTemplates: []
                    )
                    selfCareViewModel = SelfCareViewModel(
                        repository: deps.makeSelfCareRepository(),
                        contentLibrary: contentLibrary
                    )
                    feedingViewModel?.onFeedingEnded = { @MainActor babyId, duration in
                        Task {
                            await selfCareViewModel?.handleEvent(.feedingEnded(babyId: babyId, duration: duration))
                        }
                    }
                }
            }
        }
        .modelContainer(sharedModelContainer)
    }
}
