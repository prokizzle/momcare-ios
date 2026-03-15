# Health Events Timeline Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Build health events tracking with timeline view, multi-photo support, camera integration, AAP vaccine schedule, and Nightlight design tokens.

**Architecture:** Vertical feature slice following Growth (MOM-8) pattern: Domain entity + SwiftData model + Repository + ViewModel + Views. SchemaV6 migration for new model. VaccineScheduleService loads bundled AAP JSON and matches against baby's age.

**Tech Stack:** SwiftUI, SwiftData, PhotosUI (PhotosPicker), UIImagePickerController (camera), Swift Testing, Nightlight design tokens

**Design Doc:** `docs/plans/2026-03-15-health-events-design.md`

---

### Task 1: HealthEvent Entity

**Files:**
- Create: `MomCare/Domain/Entities/HealthEvent.swift`
- Test: `MomCareTests/Domain/HealthEventTests.swift`

**Step 1: Write the test**

Create `MomCareTests/Domain/HealthEventTests.swift`:

```swift
import Testing
import Foundation
@testable import MomCare

@Suite("HealthEvent entity")
struct HealthEventTests {

    @Test("Creates with required fields")
    func creation() {
        let event = HealthEvent.fixture()
        #expect(event.eventType == .vaccine)
        #expect(!event.isDeleted)
    }

    @Test("EventType has systemImage for all cases")
    func eventTypeIcons() {
        for type in HealthEvent.EventType.allCases {
            #expect(!type.systemImage.isEmpty)
            #expect(!type.label.isEmpty)
        }
    }

    @Test("EventType rawValues are stable strings")
    func eventTypeRawValues() {
        #expect(HealthEvent.EventType.vaccine.rawValue == "vaccine")
        #expect(HealthEvent.EventType.doctorVisit.rawValue == "doctorVisit")
    }
}
```

**Step 2: Create the entity**

Create `MomCare/Domain/Entities/HealthEvent.swift`:

```swift
import SwiftUI

struct HealthEvent: Identifiable, Codable, Sendable, Equatable {
    var id: UUID
    var babyId: UUID
    var date: Date
    var endDate: Date?
    var eventType: EventType
    var title: String
    var notes: String?
    var isDeleted: Bool
    var createdAt: Date
    var updatedAt: Date

    enum EventType: String, Codable, CaseIterable, Sendable {
        case vaccine, illness, milestone, doctorVisit, allergy

        var systemImage: String {
            switch self {
            case .vaccine: "syringe.fill"
            case .illness: "cross.circle.fill"
            case .milestone: "star.fill"
            case .doctorVisit: "stethoscope"
            case .allergy: "exclamationmark.triangle.fill"
            }
        }

        var label: String {
            switch self {
            case .vaccine: "Vaccine"
            case .illness: "Illness"
            case .milestone: "Milestone"
            case .doctorVisit: "Doctor Visit"
            case .allergy: "Allergy"
            }
        }

        var color: Color {
            switch self {
            case .vaccine: MCColor.babyStatus
            case .illness: MCColor.error
            case .milestone: MCColor.accent
            case .doctorVisit: MCColor.feeding
            case .allergy: MCColor.diaper
            }
        }
    }
}

extension HealthEvent {
    static func fixture(
        id: UUID = UUID(),
        babyId: UUID = UUID(),
        date: Date = .now,
        endDate: Date? = nil,
        eventType: EventType = .vaccine,
        title: String = "DTaP - Dose 1",
        notes: String? = nil,
        isDeleted: Bool = false,
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) -> HealthEvent {
        HealthEvent(
            id: id,
            babyId: babyId,
            date: date,
            endDate: endDate,
            eventType: eventType,
            title: title,
            notes: notes,
            isDeleted: isDeleted,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
}
```

**Step 3: Build and test**

```bash
tuist generate && tuist test
```

**Step 4: Lint and commit**

```bash
swiftlint --strict MomCare/Domain/Entities/HealthEvent.swift MomCareTests/Domain/HealthEventTests.swift
git add MomCare/Domain/Entities/HealthEvent.swift MomCareTests/Domain/HealthEventTests.swift
git commit -m "feat(health-events): add HealthEvent entity with EventType enum"
```

---

### Task 2: Repository Protocol

**Files:**
- Create: `MomCare/Domain/Repositories/HealthEventRepositoryProtocol.swift`

**Step 1: Create the protocol**

```swift
import Foundation

protocol HealthEventRepositoryProtocol: Repository where Entity == HealthEvent {
    func getEventsForBaby(_ babyId: UUID, limit: Int?) async throws -> [HealthEvent]
    func getEventsForBabyByType(
        _ babyId: UUID,
        type: HealthEvent.EventType
    ) async throws -> [HealthEvent]
}
```

**Step 2: Build**

```bash
tuist build
```

**Step 3: Commit**

```bash
git add MomCare/Domain/Repositories/HealthEventRepositoryProtocol.swift
git commit -m "feat(health-events): add HealthEventRepositoryProtocol"
```

---

### Task 3: SwiftData Model + Schema Migration

**Files:**
- Create: `MomCare/Data/SwiftData/HealthEventModel.swift`
- Create: `MomCare/Data/SwiftData/Schema/SchemaV6.swift`
- Modify: `MomCare/Data/SwiftData/Schema/MomCareMigrationPlan.swift`
- Modify: `MomCare/App/MomCareApp.swift` (line 10: SchemaV5 -> SchemaV6)

**Step 1: Create HealthEventModel.swift**

```swift
import Foundation
import SwiftData

@Model
final class HealthEventModel {
    @Attribute(.unique) var id: UUID
    var babyId: UUID
    var date: Date
    var endDate: Date?
    var eventTypeRaw: String
    var title: String
    var notes: String?
    @Attribute(.externalStorage) var photoData: [Data]
    var isSoftDeleted: Bool
    var createdAt: Date
    var updatedAt: Date

    init(from event: HealthEvent) {
        self.id = event.id
        self.babyId = event.babyId
        self.date = event.date
        self.endDate = event.endDate
        self.eventTypeRaw = event.eventType.rawValue
        self.title = event.title
        self.notes = event.notes
        self.photoData = []
        self.isSoftDeleted = event.isDeleted
        self.createdAt = event.createdAt
        self.updatedAt = event.updatedAt
    }

    func toEntity() -> HealthEvent {
        HealthEvent(
            id: id,
            babyId: babyId,
            date: date,
            endDate: endDate,
            eventType: HealthEvent.EventType(rawValue: eventTypeRaw) ?? .milestone,
            title: title,
            notes: notes,
            isDeleted: isSoftDeleted,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }

    func update(from event: HealthEvent) {
        date = event.date
        endDate = event.endDate
        eventTypeRaw = event.eventType.rawValue
        title = event.title
        notes = event.notes
        isSoftDeleted = event.isDeleted
        updatedAt = Date.now
    }
}
```

**Step 2: Create SchemaV6.swift**

```swift
import Foundation
import SwiftData

enum SchemaV6: VersionedSchema {
    static var versionIdentifier: Schema.Version { .init(6, 0, 0) }

    static var models: [any PersistentModel.Type] {
        [
            BabyModel.self,
            FeedingModel.self,
            SelfCareLogModel.self,
            SelfCareGridItemModel.self,
            ContentHistoryModel.self,
            DiaperModel.self,
            BabySleepModel.self,
            GrowthRecordModel.self,
            HealthEventModel.self
        ]
    }
}
```

**Step 3: Update MomCareMigrationPlan.swift**

Add `SchemaV6.self` to the schemas array and `migrateV5toV6` to stages:

```swift
static var schemas: [any VersionedSchema.Type] {
    [SchemaV1.self, SchemaV2.self, SchemaV3.self, SchemaV4.self, SchemaV5.self, SchemaV6.self]
}

static var stages: [MigrationStage] {
    [migrateV1toV2, migrateV2toV3, migrateV3toV4, migrateV4toV5, migrateV5toV6]
}

static let migrateV5toV6 = MigrationStage.lightweight(
    fromVersion: SchemaV5.self,
    toVersion: SchemaV6.self
)
```

**Step 4: Update MomCareApp.swift line 10**

Change `Schema(versionedSchema: SchemaV5.self)` to `Schema(versionedSchema: SchemaV6.self)`.

**Step 5: Build**

```bash
tuist generate && tuist build
```

**Step 6: Commit**

```bash
git add MomCare/Data/SwiftData/HealthEventModel.swift MomCare/Data/SwiftData/Schema/SchemaV6.swift MomCare/Data/SwiftData/Schema/MomCareMigrationPlan.swift MomCare/App/MomCareApp.swift
git commit -m "feat(health-events): add SwiftData model and SchemaV6 migration"
```

---

### Task 4: Repository Implementation

**Files:**
- Create: `MomCare/Data/Repositories/HealthEventRepository.swift`

**Step 1: Create HealthEventRepository.swift**

Follow the exact pattern from `GrowthRepository.swift`. Key methods: `getAll`, `getById`, `create`, `update`, `delete` (soft), `getEventsForBaby`, `getEventsForBabyByType`. All filter `isSoftDeleted == false`. The `create` and `update` methods need to accept photo data separately since the entity doesn't carry photos.

Add additional methods for photo handling:

```swift
func createWithPhotos(_ entity: HealthEvent, photos: [Data]) async throws -> HealthEvent
func getPhotos(for eventId: UUID) async throws -> [Data]
func updatePhotos(for eventId: UUID, photos: [Data]) async throws
```

**Step 2: Build and test**

```bash
tuist build
```

**Step 3: Commit**

```bash
git add MomCare/Data/Repositories/HealthEventRepository.swift
git commit -m "feat(health-events): add HealthEventRepository with photo support"
```

---

### Task 5: DI Wiring

**Files:**
- Modify: `MomCare/Core/DI/Dependencies.swift`
- Modify: `MomCareTests/Core/DI/DependenciesTests.swift`

**Step 1: Add to DependencyContainer protocol**

Add `func makeHealthEventRepository() -> any HealthEventRepositoryProtocol` to the protocol.

**Step 2: Implement in AppDependencies**

```swift
func makeHealthEventRepository() -> any HealthEventRepositoryProtocol {
    HealthEventRepository(modelContext: modelContext)
}
```

**Step 3: Add test**

Add to `DependenciesTests.swift`:

```swift
@Test("AppDependencies creates real HealthEventRepository")
@MainActor
func appDependenciesCreatesHealthEventRepo() throws {
    let deps = try TestModelContainerFactory.makeDependencies()
    let repo = deps.makeHealthEventRepository()
    #expect(repo is HealthEventRepository)
}
```

Add mock to test file:

```swift
@MainActor
private final class MockHealthEventRepository: HealthEventRepositoryProtocol {
    func getAll() async throws -> [HealthEvent] { [] }
    func getById(_ id: UUID) async throws -> HealthEvent? { nil }
    func create(_ entity: HealthEvent) async throws -> HealthEvent { entity }
    func update(_ entity: HealthEvent) async throws -> HealthEvent { entity }
    func delete(_ id: UUID) async throws {}
    func getEventsForBaby(_ babyId: UUID, limit: Int?) async throws -> [HealthEvent] { [] }
    func getEventsForBabyByType(_ babyId: UUID, type: HealthEvent.EventType) async throws -> [HealthEvent] { [] }
}
```

Add to TestDependencies:

```swift
func makeHealthEventRepository() -> any HealthEventRepositoryProtocol {
    MockHealthEventRepository()
}
```

**Step 4: Build and test**

```bash
tuist generate && tuist test
```

**Step 5: Commit**

```bash
git add MomCare/Core/DI/Dependencies.swift MomCareTests/Core/DI/DependenciesTests.swift
git commit -m "feat(health-events): wire HealthEventRepository into DI"
```

---

### Task 6: AAP Vaccine Schedule Data + Service

**Files:**
- Create: `MomCare/Core/Content/AAP/aap-vaccine-schedule.json`
- Create: `MomCare/Domain/Services/VaccineScheduleService.swift`
- Test: `MomCareTests/Domain/VaccineScheduleServiceTests.swift`

**Step 1: Create vaccine schedule JSON**

Create `MomCare/Core/Content/AAP/aap-vaccine-schedule.json` with AAP recommended vaccines birth through 18 months. Include vaccine name, recommended age in months, and description. Research the current AAP schedule and include all standard childhood vaccines.

**Step 2: Create VaccineScheduleService**

```swift
import Foundation

struct VaccineScheduleService: Sendable {
    struct ScheduledVaccine: Codable, Sendable, Identifiable {
        var id: String { name }
        let name: String
        let ageMonths: Int
        let description: String
    }

    nonisolated(unsafe) let bundle: Bundle

    init(bundle: Bundle = .main) {
        self.bundle = bundle
    }

    func loadSchedule() throws -> [ScheduledVaccine] {
        guard let url = bundle.url(forResource: "aap-vaccine-schedule", withExtension: "json") else {
            throw VaccineScheduleError.dataNotFound
        }
        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode([ScheduledVaccine].self, from: data)
    }

    func upcomingVaccines(
        dateOfBirth: Date,
        existingEvents: [HealthEvent],
        windowMonths: Int = 2
    ) throws -> [ScheduledVaccine] {
        let schedule = try loadSchedule()
        let ageInMonths = Calendar.current.dateComponents([.month], from: dateOfBirth, to: .now).month ?? 0
        let loggedVaccineNames = Set(
            existingEvents
                .filter { $0.eventType == .vaccine }
                .map { $0.title.lowercased() }
        )

        return schedule.filter { vaccine in
            let isDue = vaccine.ageMonths >= ageInMonths && vaccine.ageMonths <= ageInMonths + windowMonths
            let isLogged = loggedVaccineNames.contains(vaccine.name.lowercased())
            return isDue && !isLogged
        }
    }
}

enum VaccineScheduleError: Error, LocalizedError {
    case dataNotFound

    var errorDescription: String? {
        switch self {
        case .dataNotFound: "AAP vaccine schedule data not found"
        }
    }
}
```

**Step 3: Write tests**

Test that the service loads the schedule, returns upcoming vaccines correctly, and filters out already-logged vaccines.

**Step 4: Build, test, lint, commit**

```bash
tuist generate && tuist test
git commit -m "feat(health-events): add AAP vaccine schedule data and service"
```

---

### Task 7: HealthEventsViewModel

**Files:**
- Create: `MomCare/Features/HealthEvents/ViewModels/HealthEventsViewModel.swift`
- Test: `MomCareTests/Features/HealthEvents/HealthEventsViewModelTests.swift`

**Step 1: Create ViewModel**

Follow GrowthViewModel pattern exactly:

```swift
import Foundation

@Observable
@MainActor
final class HealthEventsViewModel {
    private let repository: any HealthEventRepositoryProtocol
    private let vaccineService: VaccineScheduleService

    private(set) var events: [HealthEvent] = []
    var selectedFilter: HealthEvent.EventType?
    var upcomingVaccines: [VaccineScheduleService.ScheduledVaccine] = []
    var isLoading = false
    var error: Error?
    var showAddSheet = false

    init(
        repository: any HealthEventRepositoryProtocol,
        vaccineService: VaccineScheduleService = VaccineScheduleService()
    ) {
        self.repository = repository
        self.vaccineService = vaccineService
    }

    var filteredEvents: [HealthEvent] { ... }
    var groupedEvents: [(String, [HealthEvent])] { ... }

    func loadEvents(babyId: UUID) async { ... }
    func addEvent(...) async -> Bool { ... }
    func deleteEvent(id: UUID) async { ... }
    func loadUpcomingVaccines(dateOfBirth: Date) { ... }
}
```

Key behaviors:
- `loadEvents` fetches from repository, clears error first
- `filteredEvents` filters by `selectedFilter` when set
- `groupedEvents` groups by month (same pattern as JournalViewModel)
- `addEvent` returns Bool for dismiss-on-success pattern
- `loadUpcomingVaccines` calls VaccineScheduleService with existing vaccine events

**Step 2: Write tests**

Follow GrowthViewModelTests pattern: initial state, load, add, delete, filter, upcoming vaccines.

**Step 3: Build, test, lint, commit**

```bash
git commit -m "feat(health-events): add HealthEventsViewModel with vaccine suggestions"
```

---

### Task 8: HealthEventsScreen

**Files:**
- Create: `MomCare/Features/HealthEvents/Views/HealthEventsScreen.swift`

**Step 1: Create the screen**

Timeline view with:
- Filter chips at top (All + each EventType)
- "Upcoming Vaccines" section when vaccines are due
- LazyVStack grouped by month
- Each row: type icon (colored) + date + title + photo count if > 0
- NavigationLink to detail view
- Empty state using EmptyStateView with health illustration
- Add button at bottom

Use all Nightlight tokens: MCTypography, MCRadius, MCOpacity, MCElevation, MCAnimation, MCTransition.

**Step 2: Build**

```bash
tuist build
```

**Step 3: Commit**

```bash
git commit -m "feat(health-events): add HealthEventsScreen with timeline and vaccine suggestions"
```

---

### Task 9: CameraPickerView (UIKit bridge)

**Files:**
- Create: `MomCare/Shared/Components/CameraPickerView.swift`
- Modify: `MomCare/App/Info.plist` (add NSCameraUsageDescription)

**Step 1: Create CameraPickerView**

UIImagePickerController wrapped in UIViewControllerRepresentable:

```swift
import SwiftUI

struct CameraPickerView: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CameraPickerView

        init(_ parent: CameraPickerView) { self.parent = parent }

        func imagePickerController(
            _ picker: UIImagePickerController,
            didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
        ) {
            parent.image = info[.originalImage] as? UIImage
            parent.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}
```

**Step 2: Add camera permission to Info.plist**

```xml
<key>NSCameraUsageDescription</key>
<string>MomCare uses the camera to document health events like rashes or reactions.</string>
```

**Step 3: Build and commit**

```bash
git commit -m "feat(health-events): add CameraPickerView and camera permission"
```

---

### Task 10: AddHealthEventView

**Files:**
- Create: `MomCare/Features/HealthEvents/Views/AddHealthEventView.swift`

**Step 1: Create the view**

Sheet with:
- Event type segmented picker (5 types)
- Title text field (pre-filled if from vaccine suggestion)
- Date picker (constrained to dateOfBirth...Date.now)
- End date toggle + picker (for illness duration)
- Notes text editor
- Photo section: horizontal strip of thumbnails + PhotosPicker button + Camera button
- Max 5 photos, JPEG 80% compression
- Save only dismisses on success (same pattern as AddMeasurementView)
- Cancel button

Use all Nightlight tokens.

**Step 2: Build**

```bash
tuist build
```

**Step 3: Commit**

```bash
git commit -m "feat(health-events): add AddHealthEventView with photos and camera"
```

---

### Task 11: HealthEventDetailView

**Files:**
- Create: `MomCare/Features/HealthEvents/Views/HealthEventDetailView.swift`

**Step 1: Create the view**

Full detail view with:
- Event type badge (colored capsule)
- Title in MCTypography.title2
- Date range (start - end if illness)
- Notes section
- Horizontal photo gallery (ScrollView .horizontal)
- Tap photo -> fullscreen sheet with zoom (MagnificationGesture)
- Edit button -> AddHealthEventView in edit mode
- Delete button -> confirmation dialog -> soft delete

Use all Nightlight tokens.

**Step 2: Build**

```bash
tuist build
```

**Step 3: Commit**

```bash
git commit -m "feat(health-events): add HealthEventDetailView with photo gallery"
```

---

### Task 12: Navigation + App Wiring

**Files:**
- Modify: `MomCare/App/AppNavigation.swift` (add BabyRoute.healthEvents, .healthEventDetail)
- Modify: `MomCare/Features/Baby/Views/BabyScreen.swift` (add Health Events link + navigation destination)
- Modify: `MomCare/App/ContentView.swift` (pass healthEventsViewModel)
- Modify: `MomCare/App/MomCareApp.swift` (create HealthEventsViewModel)

**Step 1: Add navigation routes**

Add to BabyRoute enum:
```swift
case healthEvents
case healthEventDetail(UUID)
```

**Step 2: Add link in BabyScreen**

Same pattern as Growth Charts link:
```swift
if healthEventsViewModel != nil {
    NavigationLink(value: BabyRoute.healthEvents) {
        HStack {
            Image(systemName: "cross.case.fill")
                .foregroundStyle(MCColor.baby)
            Text("Health Events")
                .font(MCTypography.title3)
            Spacer()
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(MCSpacing.md)
        .background(MCElevation.surface, in: RoundedRectangle(cornerRadius: MCRadius.md))
    }
    .buttonStyle(.plain)
}
```

**Step 3: Add navigation destination**

In BabyScreen's `.navigationDestination(for: BabyRoute.self)`:
```swift
case .healthEvents:
    if let healthEventsViewModel, let babyId, let dateOfBirth {
        HealthEventsScreen(babyId: babyId, dateOfBirth: dateOfBirth, viewModel: healthEventsViewModel)
    }
case .healthEventDetail(let eventId):
    // Detail view wired from within HealthEventsScreen
    EmptyView()
```

**Step 4: Wire ViewModel in MomCareApp.swift**

Add `@State private var healthEventsViewModel: HealthEventsViewModel?` and create it in the task block:
```swift
healthEventsViewModel = HealthEventsViewModel(
    repository: deps.makeHealthEventRepository()
)
```

Pass through ContentView -> BabyScreen.

**Step 5: Update BabyScreen and ContentView signatures**

Add `var healthEventsViewModel: HealthEventsViewModel?` parameter to both.

**Step 6: Build, test, lint**

```bash
tuist generate && tuist build && tuist test
swiftlint --strict MomCare/App/ MomCare/Features/Baby/Views/BabyScreen.swift MomCare/Features/HealthEvents/
```

**Step 7: Commit**

```bash
git commit -m "feat(health-events): wire navigation, ViewModel, and DI into app root"
```

---

### Task 13: Add HealthEvent to BabyRepository Cascade Delete

**Files:**
- Modify: `MomCare/Data/Repositories/BabyRepository.swift`

**Step 1: Add HealthEventModel cascade**

In the `delete(_ id:)` method, after the existing growth record cascade, add:

```swift
let healthEventDescriptor = FetchDescriptor<HealthEventModel>(
    predicate: #Predicate<HealthEventModel> { $0.babyId == babyId && $0.isSoftDeleted == false }
)
for event in try modelContext.fetch(healthEventDescriptor) {
    event.isSoftDeleted = true
    event.updatedAt = now
}
```

**Step 2: Build and test**

```bash
tuist build && tuist test
```

**Step 3: Commit**

```bash
git commit -m "feat(health-events): add HealthEventModel to baby cascade soft-delete"
```

---

### Task 14: Final Lint + Verification

**Step 1: Lint all new files**

```bash
swiftlint --strict MomCare/Domain/Entities/HealthEvent.swift \
    MomCare/Domain/Repositories/HealthEventRepositoryProtocol.swift \
    MomCare/Domain/Services/VaccineScheduleService.swift \
    MomCare/Data/SwiftData/HealthEventModel.swift \
    MomCare/Data/Repositories/HealthEventRepository.swift \
    MomCare/Features/HealthEvents/ \
    MomCare/Shared/Components/CameraPickerView.swift
```

**Step 2: Full build and test**

```bash
tuist build && tuist test
```

**Step 3: Fix any issues and commit**

```bash
git commit -m "chore(health-events): lint fixes and final verification"
```

---

## Summary

| Task | What | Commit |
|------|------|--------|
| 1 | HealthEvent entity + tests | feat: entity |
| 2 | Repository protocol | feat: protocol |
| 3 | SwiftData model + SchemaV6 | feat: model + migration |
| 4 | Repository implementation | feat: repository |
| 5 | DI wiring + tests | feat: DI |
| 6 | AAP vaccine schedule + service | feat: vaccine service |
| 7 | HealthEventsViewModel + tests | feat: ViewModel |
| 8 | HealthEventsScreen | feat: timeline screen |
| 9 | CameraPickerView + permission | feat: camera |
| 10 | AddHealthEventView | feat: add event view |
| 11 | HealthEventDetailView | feat: detail view |
| 12 | Navigation + app wiring | feat: wiring |
| 13 | Cascade soft-delete | feat: cascade delete |
| 14 | Final lint + verification | chore: cleanup |
