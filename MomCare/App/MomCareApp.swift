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
        NotificationManager.shared.registerCategories()

        Task {
            await StoreManager.shared.startObservingTransactions()
            await StoreManager.shared.refreshEntitlements()
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
                            // Intentional direct usage: NotificationManager is a system
                            // singleton (wraps UNUserNotificationCenter) and does not
                            // belong in the AppDependencies container.
                            await NotificationManager.shared.requestAuthorization()
                        },
                        requestHealthKit: {
                            // Placeholder until MOM-13 (HealthKit)
                            return false
                        },
                        signInWithApple: { authorization, nonce in
                            guard FirebaseApp.app() != nil else { return }
                            let authService = AuthService()
                            _ = try await authService.signInWithApple(
                                authorization: authorization,
                                nonce: nonce
                            )
                        },
                        signInWithGoogle: {
                            throw AuthError.googleSignInNotAvailable
                        },
                        signInAnonymously: {
                            guard FirebaseApp.app() != nil else { return }
                            let authService = AuthService()
                            _ = try await authService.signInAnonymously()
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

                    // HealthKit
                    let healthKitSvc = HealthKitService()
                    await healthKitSvc.requestAuthorization()

                    // Dashboard
                    let dashboardVM = DashboardViewModel(
                        feedingRepository: deps.makeFeedingRepository(),
                        selfCareRepository: deps.makeSelfCareRepository(),
                        healthKit: healthKitSvc
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

                    // Resolve any pending activity end that arrived before the engine was
                    // ready: either a URL deep link on cold start or an AppIntent write.
                    let pendingType = appNavigation.pendingEndActivityType
                        ?? SharedDataManager.pendingEndActivityType
                    if let activityType = pendingType,
                       let babyId = babyVM.selectedBaby?.id {
                        appNavigation.pendingEndActivityType = nil
                        SharedDataManager.clearPendingEndActivity()
                        if activityType == "feeding", engine.isFeedingActive {
                            await engine.endFeeding(babyId: babyId)
                        } else if activityType == "nap", engine.isNapActive {
                            await engine.endNap(babyId: babyId)
                        }
                    }

                    // Resolve any pending feeding start written by StartFeedingIntent
                    // before the app was foregrounded.
                    if let feedingTypeRaw = SharedDataManager.pendingStartFeedingType,
                       let babyId = babyVM.selectedBaby?.id,
                       !engine.isFeedingActive {
                        SharedDataManager.clearPendingStartFeeding()
                        let method: FeedMethod
                        if let option = FeedingTypeOption(rawValue: feedingTypeRaw) {
                            method = option.feedMethod
                        } else {
                            method = .left
                        }
                        await engine.startFeeding(babyId: babyId, method: method)
                    }

                    // Index babies into Core Spotlight.
                    SpotlightIndexer.shared.indexBabies(babyVM.babies)

                    // Set up default notification schedule.
                    let scheduler = NotificationScheduler()
                    await scheduler.setupDefaults()

                    // Sleep
                    sleepViewModel = SleepViewModel(
                        repository: deps.makeSleepRepository()
                    )

                    // Growth
                    growthViewModel = GrowthViewModel(
                        repository: deps.makeGrowthRepository(),
                        feedingRepository: deps.makeFeedingRepository(),
                        healthKit: healthKitSvc
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
                // Only process immediately if the engine is already initialised.
                // If not (cold start from lock-screen tap), leave pendingEndActivityType
                // set so the init task above picks it up once the engine is ready.
                guard let activityType = appNavigation.pendingEndActivityType,
                      let babyId = babyViewModel?.selectedBaby?.id,
                      let engine = babyActivityEngine else { return }
                appNavigation.pendingEndActivityType = nil
                Task {
                    if activityType == "feeding", engine.isFeedingActive {
                        await engine.endFeeding(babyId: babyId)
                    } else if activityType == "nap", engine.isNapActive {
                        await engine.endNap(babyId: babyId)
                    }
                }
            }
        }
        .modelContainer(sharedModelContainer)
    }
}
