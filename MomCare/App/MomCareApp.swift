import AuthenticationServices
import FirebaseCore
import SwiftData
import SwiftUI
import UserNotifications

@main
struct MomCareApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema(versionedSchema: SchemaV6.self)
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
#if DEBUG
            // In development, an unknown schema version means a store from a previous
            // intermediate build is on disk. Delete it and start fresh rather than crashing.
            print("ModelContainer failed (\(error)). Attempting store recovery in DEBUG mode.")
            let storeURL = modelConfiguration.url
            let fileManager = FileManager.default
            let storeFiles = [storeURL, storeURL.appendingPathExtension("shm"), storeURL.appendingPathExtension("wal")]
            for url in storeFiles where fileManager.fileExists(atPath: url.path) {
                try? fileManager.removeItem(at: url)
            }
            print("Deleted corrupt store at \(storeURL). Starting fresh.")
            do {
                return try ModelContainer(for: schema, configurations: [modelConfiguration])
            } catch {
                fatalError("Could not create ModelContainer even after store reset: \(error)")
            }
#else
            fatalError("Could not create ModelContainer: \(error)")
#endif
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

    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var onboardingViewModel: OnboardingViewModel?
    @State private var babyViewModel: BabyViewModel?
    @State private var selfCareViewModel: SelfCareViewModel?
    @State private var dashboardViewModel: DashboardViewModel?
    @State private var babyActivityEngine: BabyActivityEngine?
    @State private var journalViewModel: JournalViewModel?
    @State private var sleepViewModel: SleepViewModel?
    @State private var growthViewModel: GrowthViewModel?
    @State private var healthEventsViewModel: HealthEventsViewModel?
    @State private var appNavigation = AppNavigation()
    @State private var splashFinished = false
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            Group {
                if !splashFinished {
                    SplashView(isFinished: $splashFinished)
                } else if hasCompletedOnboarding {
                    ContentView(
                        babyViewModel: babyViewModel,
                        selfCareViewModel: selfCareViewModel,
                        dashboardViewModel: dashboardViewModel,
                        babyActivityEngine: babyActivityEngine,
                        journalViewModel: journalViewModel,
                        sleepViewModel: sleepViewModel,
                        growthViewModel: growthViewModel,
                        healthEventsViewModel: healthEventsViewModel
                    )
                    .environment(appNavigation)
                } else if let onboardingViewModel {
                    OnboardingView(viewModel: onboardingViewModel)
                        .onChange(of: onboardingViewModel.isCompleted) { _, completed in
                            if completed {
                                hasCompletedOnboarding = true
                            }
                        }
                } else {
                    ProgressView()
                }
            }
            .task(id: hasCompletedOnboarding) {
                if !hasCompletedOnboarding && onboardingViewModel == nil {
                    let deps = AppDependencies(modelContext: sharedModelContainer.mainContext)
                    let babyRepo = deps.makeBabyRepository()
                    onboardingViewModel = OnboardingViewModel(dependencies: .init(
                        requestNotifications: {
                            let center = UNUserNotificationCenter.current()
                            return (try? await center.requestAuthorization(options: [.alert, .badge, .sound])) ?? false
                        },
                        requestHealthKit: {
                            // Placeholder until MOM-13 (HealthKit)
                            return false
                        },
                        signInWithApple: { _ in
                            // Placeholder until MOM-12 (Firebase Auth)
                        },
                        signInWithGoogle: {
                            // Placeholder until MOM-12 (Firebase Auth)
                        },
                        signInAnonymously: {
                            // Placeholder until MOM-12 (Firebase Auth)
                        },
                        createBaby: { formData in
                            let baby = Baby(
                                id: UUID(),
                                name: formData.name,
                                dateOfBirth: formData.dateOfBirth,
                                biologicalSex: formData.biologicalSex,
                                birthWeight: formData.birthWeight,
                                birthLength: formData.birthLength,
                                birthHeadCircumference: formData.birthHeadCircumference,
                                feedingMethod: formData.feedingMethod,
                                photoData: formData.photoData,
                                isDeleted: false,
                                createdAt: .now,
                                updatedAt: .now
                            )
                            return try await babyRepo.create(baby)
                        }
                    ))
                }
                if hasCompletedOnboarding && babyViewModel == nil {
                    let deps = AppDependencies(modelContext: sharedModelContainer.mainContext)
                    let babyVM = BabyViewModel(repository: deps.makeBabyRepository())
                    await babyVM.loadBabies()
                    babyViewModel = babyVM

                    if let baby = babyVM.selectedBaby {
                        SharedDataManager.updateBaby(name: baby.name)
                    }
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

                    // Dashboard
                    let dashboardVM = DashboardViewModel(
                        feedingRepository: deps.makeFeedingRepository(),
                        selfCareRepository: deps.makeSelfCareRepository()
                    )
                    dashboardViewModel = dashboardVM

                    // BabyActivityEngine
                    let engine = BabyActivityEngine(
                        sleepRepository: deps.makeSleepRepository(),
                        feedingRepository: deps.makeFeedingRepository(),
                        diaperRepository: deps.makeDiaperRepository()
                    )
                    if let babyId = babyVM.selectedBaby?.id {
                        await engine.loadInProgress(babyId: babyId)
                    }
                    babyActivityEngine = engine

                    // Sleep
                    sleepViewModel = SleepViewModel(
                        repository: deps.makeSleepRepository()
                    )

                    // Growth
                    growthViewModel = GrowthViewModel(
                        repository: deps.makeGrowthRepository()
                    )

                    // Health Events
                    healthEventsViewModel = HealthEventsViewModel(
                        repository: deps.makeHealthEventRepository()
                    )

                    // Journal
                    journalViewModel = JournalViewModel(
                        sleepRepository: deps.makeSleepRepository(),
                        feedingRepository: deps.makeFeedingRepository(),
                        diaperRepository: deps.makeDiaperRepository()
                    )
                }
            }
            .onChange(of: scenePhase) { _, newPhase in
                switch newPhase {
                case .background:
                    babyActivityEngine?.pauseTimers()
                case .active:
                    babyActivityEngine?.resumeTimersIfNeeded()
                default:
                    break
                }
            }
            .onChange(of: hasCompletedOnboarding) { _, completed in
                if completed {
                    onboardingViewModel = nil
                }
            }
            .onOpenURL { url in
                appNavigation.handleURL(url)
                if appNavigation.pendingEndActivity {
                    appNavigation.pendingEndActivity = false
                    Task {
                        if let babyId = babyViewModel?.selectedBaby?.id {
                            if babyActivityEngine?.isFeedingActive == true {
                                await babyActivityEngine?.endFeeding(babyId: babyId)
                            }
                            if babyActivityEngine?.isNapActive == true {
                                await babyActivityEngine?.endNap(babyId: babyId)
                            }
                        }
                    }
                }
            }
        }
        .modelContainer(sharedModelContainer)
    }
}
