import SwiftUI
import SwiftData
import FirebaseCore

@main
struct MomCareApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema(versionedSchema: SchemaV1.self)
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

    var body: some Scene {
        WindowGroup {
            ContentView(babyViewModel: babyViewModel)
                .environment(\.dependencies, AppDependencies(modelContext: sharedModelContainer.mainContext))
                .task {
                    if babyViewModel == nil {
                        let deps = AppDependencies(modelContext: sharedModelContainer.mainContext)
                        let viewModel = BabyViewModel(repository: deps.makeBabyRepository())
                        await viewModel.loadBabies()
                        babyViewModel = viewModel
                    }
                }
        }
        .modelContainer(sharedModelContainer)
    }
}
