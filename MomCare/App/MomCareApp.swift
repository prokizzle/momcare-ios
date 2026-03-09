import SwiftUI
import SwiftData
import FirebaseCore

@main
struct MomCareApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            BabyModel.self
        ])
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            groupContainer: .identifier("group.com.feelingmindful.momcare")
        )

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
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

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.dependencies, AppDependencies(modelContext: sharedModelContainer.mainContext))
        }
        .modelContainer(sharedModelContainer)
    }
}
