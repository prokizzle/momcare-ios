# MOM-2: Baby Management Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Build the baby management feature — CRUD, multi-baby support, profiles — the first vertical feature slice that everything else depends on.

**Architecture:** Domain entity (`Baby` struct) → SwiftData model (`BabyModel` @Model class) → Repository protocol + implementation → @Observable ViewModel → SwiftUI views. The repository maps between the domain struct and the SwiftData model. DI wires the repository into the ViewModel via the existing `DependencyContainer` pattern.

**Tech Stack:** SwiftUI, SwiftData, Swift Testing, @Observable, PhotosUI (PhotosPicker)

**Existing patterns (from MOM-1):**
- `Repository<Entity>` base protocol at `MomCare/Domain/Repositories/Repository.swift`
- `DependencyContainer` / `AppDependencies` at `MomCare/Core/DI/Dependencies.swift`
- `AppNavigation` with per-tab `NavigationPath` at `MomCare/App/AppNavigation.swift`
- Design tokens: `MCColor`, `MCTypography`, `MCSpacing`, `MCHaptic`
- Swift Testing: `@Suite`, `@Test`, `#expect` — no XCTest
- `@MainActor` on all `@Observable` classes
- SwiftLint `--strict` must pass before every commit

**Build & test commands:**
```bash
xcodegen generate
xcodebuild build -scheme MomCare -destination 'platform=iOS Simulator,name=iPhone 16' | tail -5
xcodebuild test -scheme MomCare -destination 'platform=iOS Simulator,name=iPhone 16' | tail -20
swiftlint --strict
```

---

### Task 1: Baby Domain Entity

**Files:**
- Create: `MomCare/Domain/Entities/Baby.swift`
- Test: `MomCareTests/Domain/BabyTests.swift`

**Step 1: Write the failing tests**

Create `MomCareTests/Domain/BabyTests.swift`:

```swift
import Testing
import Foundation
@testable import MomCare

@Suite("Baby Entity Tests")
struct BabyTests {

    // MARK: - Age Computation

    @Test("ageInDays returns correct value")
    func ageInDays() {
        let baby = Baby.fixture(dateOfBirth: Calendar.current.date(byAdding: .day, value: -5, to: .now)!)
        #expect(baby.ageInDays == 5)
    }

    @Test("ageInWeeks returns correct value")
    func ageInWeeks() {
        let baby = Baby.fixture(dateOfBirth: Calendar.current.date(byAdding: .day, value: -14, to: .now)!)
        #expect(baby.ageInWeeks == 2)
    }

    @Test("ageInMonths returns correct value")
    func ageInMonths() {
        let baby = Baby.fixture(dateOfBirth: Calendar.current.date(byAdding: .month, value: -4, to: .now)!)
        #expect(baby.ageInMonths == 4)
    }

    @Test("ageString shows days for under 2 weeks", arguments: [
        (1, "1 day"),
        (3, "3 days"),
        (13, "13 days"),
    ])
    func ageStringDays(daysAgo: Int, expected: String) {
        let baby = Baby.fixture(dateOfBirth: Calendar.current.date(byAdding: .day, value: -daysAgo, to: .now)!)
        #expect(baby.ageString == expected)
    }

    @Test("ageString shows weeks for 2 weeks to 2 months", arguments: [
        (14, "2 weeks"),
        (21, "3 weeks"),
        (49, "7 weeks"),
    ])
    func ageStringWeeks(daysAgo: Int, expected: String) {
        let baby = Baby.fixture(dateOfBirth: Calendar.current.date(byAdding: .day, value: -daysAgo, to: .now)!)
        #expect(baby.ageString == expected)
    }

    @Test("ageString shows months for 2+ months")
    func ageStringMonths() {
        let baby = Baby.fixture(dateOfBirth: Calendar.current.date(byAdding: .month, value: -4, to: .now)!)
        #expect(baby.ageString == "4 months")
    }

    // MARK: - Codable

    @Test("Baby round-trips through JSON")
    func codableRoundTrip() throws {
        let original = Baby.fixture()
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(Baby.self, from: data)
        #expect(decoded.id == original.id)
        #expect(decoded.name == original.name)
        #expect(decoded.biologicalSex == original.biologicalSex)
        #expect(decoded.feedingMethod == original.feedingMethod)
    }

    @Test("BiologicalSex round-trips through JSON")
    func biologicalSexCodable() throws {
        for sex in Baby.BiologicalSex.allCases {
            let data = try JSONEncoder().encode(sex)
            let decoded = try JSONDecoder().decode(Baby.BiologicalSex.self, from: data)
            #expect(decoded == sex)
        }
    }

    @Test("FeedingMethod round-trips through JSON")
    func feedingMethodCodable() throws {
        for method in Baby.FeedingMethod.allCases {
            let data = try JSONEncoder().encode(method)
            let decoded = try JSONDecoder().decode(Baby.FeedingMethod.self, from: data)
            #expect(decoded == method)
        }
    }
}
```

**Step 2: Run tests to verify they fail**

Run: `xcodegen generate && xcodebuild test -scheme MomCare -destination 'platform=iOS Simulator,name=iPhone 16' 2>&1 | grep -E "(Test Suite|error:|Baby)"`
Expected: Compilation errors — `Baby` type not found.

**Step 3: Write the Baby entity**

Create `MomCare/Domain/Entities/Baby.swift`:

```swift
import Foundation

struct Baby: Identifiable, Codable, Sendable, Equatable {
    var id: UUID
    var name: String
    var dateOfBirth: Date
    var biologicalSex: BiologicalSex?
    var birthWeight: Double?
    var birthLength: Double?
    var birthHeadCircumference: Double?
    var feedingMethod: FeedingMethod
    var photoData: Data?
    var isDeleted: Bool
    var createdAt: Date
    var updatedAt: Date

    enum BiologicalSex: String, Codable, CaseIterable, Sendable {
        case male, female, other, preferNotToSay
    }

    enum FeedingMethod: String, Codable, CaseIterable, Sendable {
        case breast, bottle, both
    }

    var ageInDays: Int {
        Calendar.current.dateComponents([.day], from: dateOfBirth, to: .now).day ?? 0
    }

    var ageInWeeks: Int {
        ageInDays / 7
    }

    var ageInMonths: Int {
        Calendar.current.dateComponents([.month], from: dateOfBirth, to: .now).month ?? 0
    }

    var ageString: String {
        let months = ageInMonths
        if months >= 2 {
            return "\(months) months"
        }
        let days = ageInDays
        if days < 14 {
            return days == 1 ? "1 day" : "\(days) days"
        }
        let weeks = ageInWeeks
        return "\(weeks) weeks"
    }
}

extension Baby {
    static func fixture(
        id: UUID = UUID(),
        name: String = "Emma",
        dateOfBirth: Date = Calendar.current.date(byAdding: .month, value: -3, to: .now)!,
        biologicalSex: BiologicalSex? = .female,
        feedingMethod: FeedingMethod = .breast,
        isDeleted: Bool = false
    ) -> Baby {
        Baby(
            id: id,
            name: name,
            dateOfBirth: dateOfBirth,
            biologicalSex: biologicalSex,
            birthWeight: nil,
            birthLength: nil,
            birthHeadCircumference: nil,
            feedingMethod: feedingMethod,
            photoData: nil,
            isDeleted: isDeleted,
            createdAt: .now,
            updatedAt: .now
        )
    }
}
```

**Step 4: Run tests to verify they pass**

Run: `xcodegen generate && xcodebuild test -scheme MomCare -destination 'platform=iOS Simulator,name=iPhone 16' 2>&1 | tail -20`
Expected: All BabyTests pass.

**Step 5: Run SwiftLint**

Run: `swiftlint --strict`
Expected: No violations.

**Step 6: Commit**

```bash
git add MomCare/Domain/Entities/Baby.swift MomCareTests/Domain/BabyTests.swift
git commit -m "feat(MOM-2): add Baby domain entity with age computation and Codable"
```

---

### Task 2: BabyModel (SwiftData)

**Files:**
- Create: `MomCare/Data/SwiftData/BabyModel.swift`
- Modify: `MomCare/App/MomCareApp.swift:8` — register BabyModel in Schema
- Test: `MomCareTests/Data/BabyModelTests.swift`

**Step 1: Write the failing tests**

Create `MomCareTests/Data/BabyModelTests.swift`:

```swift
import Testing
import Foundation
import SwiftData
@testable import MomCare

@Suite("BabyModel Tests")
struct BabyModelTests {

    private func makeContainer() throws -> ModelContainer {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        return try ModelContainer(for: BabyModel.self, configurations: config)
    }

    @Test("BabyModel converts from Baby entity")
    func initFromEntity() {
        let baby = Baby.fixture(name: "Liam")
        let model = BabyModel(from: baby)
        #expect(model.id == baby.id)
        #expect(model.name == "Liam")
        #expect(model.feedingMethodRaw == Baby.FeedingMethod.breast.rawValue)
    }

    @Test("BabyModel converts to Baby entity")
    func toEntity() {
        let baby = Baby.fixture(name: "Olivia", biologicalSex: .female)
        let model = BabyModel(from: baby)
        let entity = model.toEntity()
        #expect(entity.id == baby.id)
        #expect(entity.name == "Olivia")
        #expect(entity.biologicalSex == .female)
        #expect(entity.feedingMethod == .breast)
    }

    @Test("BabyModel persists to in-memory store")
    @MainActor
    func persistence() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let model = BabyModel(from: Baby.fixture(name: "Noah"))
        context.insert(model)
        try context.save()

        let descriptor = FetchDescriptor<BabyModel>()
        let results = try context.fetch(descriptor)
        #expect(results.count == 1)
        #expect(results.first?.name == "Noah")
    }
}
```

**Step 2: Run tests to verify they fail**

Expected: Compilation error — `BabyModel` not found.

**Step 3: Write the BabyModel**

Create `MomCare/Data/SwiftData/BabyModel.swift`:

```swift
import Foundation
import SwiftData

@Model
final class BabyModel {
    @Attribute(.unique) var id: UUID
    var name: String
    var dateOfBirth: Date
    var biologicalSexRaw: String?
    var birthWeight: Double?
    var birthLength: Double?
    var birthHeadCircumference: Double?
    var feedingMethodRaw: String
    @Attribute(.externalStorage) var photoData: Data?
    var isDeleted: Bool
    var createdAt: Date
    var updatedAt: Date

    init(from baby: Baby) {
        self.id = baby.id
        self.name = baby.name
        self.dateOfBirth = baby.dateOfBirth
        self.biologicalSexRaw = baby.biologicalSex?.rawValue
        self.birthWeight = baby.birthWeight
        self.birthLength = baby.birthLength
        self.birthHeadCircumference = baby.birthHeadCircumference
        self.feedingMethodRaw = baby.feedingMethod.rawValue
        self.photoData = baby.photoData
        self.isDeleted = baby.isDeleted
        self.createdAt = baby.createdAt
        self.updatedAt = baby.updatedAt
    }

    func toEntity() -> Baby {
        Baby(
            id: id,
            name: name,
            dateOfBirth: dateOfBirth,
            biologicalSex: biologicalSexRaw.flatMap { Baby.BiologicalSex(rawValue: $0) },
            birthWeight: birthWeight,
            birthLength: birthLength,
            birthHeadCircumference: birthHeadCircumference,
            feedingMethod: Baby.FeedingMethod(rawValue: feedingMethodRaw) ?? .breast,
            photoData: photoData,
            isDeleted: isDeleted,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }

    func update(from baby: Baby) {
        name = baby.name
        dateOfBirth = baby.dateOfBirth
        biologicalSexRaw = baby.biologicalSex?.rawValue
        birthWeight = baby.birthWeight
        birthLength = baby.birthLength
        birthHeadCircumference = baby.birthHeadCircumference
        feedingMethodRaw = baby.feedingMethod.rawValue
        photoData = baby.photoData
        isDeleted = baby.isDeleted
        updatedAt = Date.now
    }
}
```

**Step 4: Register BabyModel in Schema**

Modify `MomCare/App/MomCareApp.swift` — change line 8-9:

```swift
        let schema = Schema([
            BabyModel.self,
        ])
```

**Step 5: Run tests to verify they pass**

Run: `xcodegen generate && xcodebuild test -scheme MomCare -destination 'platform=iOS Simulator,name=iPhone 16' 2>&1 | tail -20`
Expected: All BabyModelTests pass.

**Step 6: Run SwiftLint**

Run: `swiftlint --strict`

**Step 7: Commit**

```bash
git add MomCare/Data/SwiftData/BabyModel.swift MomCareTests/Data/BabyModelTests.swift MomCare/App/MomCareApp.swift
git commit -m "feat(MOM-2): add BabyModel SwiftData class with entity conversion"
```

---

### Task 3: BabyRepository Protocol + Implementation

**Files:**
- Create: `MomCare/Domain/Repositories/BabyRepositoryProtocol.swift`
- Create: `MomCare/Data/Repositories/BabyRepository.swift`
- Test: `MomCareTests/Data/BabyRepositoryTests.swift`

**Step 1: Write the failing tests**

Create `MomCareTests/Data/BabyRepositoryTests.swift`:

```swift
import Testing
import Foundation
import SwiftData
@testable import MomCare

@Suite("BabyRepository Tests")
struct BabyRepositoryTests {

    private func makeSUT() throws -> (BabyRepository, ModelContext) {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: BabyModel.self, configurations: config)
        let context = ModelContext(container)
        let repo = BabyRepository(modelContext: context)
        return (repo, context)
    }

    @Test("create inserts baby and returns it")
    func create() async throws {
        let (repo, _) = try makeSUT()
        let baby = Baby.fixture(name: "Ava")
        let created = try await repo.create(baby)
        #expect(created.name == "Ava")
    }

    @Test("getAll returns all babies")
    func getAll() async throws {
        let (repo, _) = try makeSUT()
        _ = try await repo.create(Baby.fixture(name: "A"))
        _ = try await repo.create(Baby.fixture(name: "B"))
        let all = try await repo.getAll()
        #expect(all.count == 2)
    }

    @Test("getById returns matching baby")
    func getById() async throws {
        let (repo, _) = try makeSUT()
        let baby = Baby.fixture(name: "Find Me")
        let created = try await repo.create(baby)
        let found = try await repo.getById(created.id)
        #expect(found?.name == "Find Me")
    }

    @Test("getById returns nil for unknown ID")
    func getByIdNotFound() async throws {
        let (repo, _) = try makeSUT()
        let found = try await repo.getById(UUID())
        #expect(found == nil)
    }

    @Test("update modifies existing baby")
    func update() async throws {
        let (repo, _) = try makeSUT()
        var baby = try await repo.create(Baby.fixture(name: "Old"))
        baby.name = "New"
        let updated = try await repo.update(baby)
        #expect(updated.name == "New")
    }

    @Test("delete sets isDeleted flag (soft delete)")
    func softDelete() async throws {
        let (repo, _) = try makeSUT()
        let baby = try await repo.create(Baby.fixture())
        try await repo.delete(baby.id)
        let all = try await repo.getAll()
        #expect(all.first?.isDeleted == true)
    }

    @Test("getActiveBabies excludes soft-deleted")
    func getActiveBabies() async throws {
        let (repo, _) = try makeSUT()
        _ = try await repo.create(Baby.fixture(name: "Active"))
        let toDelete = try await repo.create(Baby.fixture(name: "Deleted"))
        try await repo.delete(toDelete.id)

        let active = try await repo.getActiveBabies()
        #expect(active.count == 1)
        #expect(active.first?.name == "Active")
    }
}
```

**Step 2: Run tests to verify they fail**

Expected: Compilation errors — `BabyRepositoryProtocol`, `BabyRepository` not found.

**Step 3: Write the repository protocol**

Create `MomCare/Domain/Repositories/BabyRepositoryProtocol.swift`:

```swift
import Foundation

protocol BabyRepositoryProtocol: Repository where Entity == Baby {
    func getActiveBabies() async throws -> [Baby]
}
```

**Step 4: Write the repository implementation**

Create `MomCare/Data/Repositories/BabyRepository.swift`:

```swift
import Foundation
import SwiftData

final class BabyRepository: BabyRepositoryProtocol, @unchecked Sendable {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func getAll() async throws -> [Baby] {
        let descriptor = FetchDescriptor<BabyModel>(
            sortBy: [SortDescriptor(\.createdAt)]
        )
        return try modelContext.fetch(descriptor).map { $0.toEntity() }
    }

    func getById(_ id: UUID) async throws -> Baby? {
        let descriptor = FetchDescriptor<BabyModel>(
            predicate: #Predicate<BabyModel> { $0.id == id }
        )
        return try modelContext.fetch(descriptor).first?.toEntity()
    }

    func create(_ entity: Baby) async throws -> Baby {
        let model = BabyModel(from: entity)
        modelContext.insert(model)
        try modelContext.save()
        return model.toEntity()
    }

    func update(_ entity: Baby) async throws -> Baby {
        let descriptor = FetchDescriptor<BabyModel>(
            predicate: #Predicate<BabyModel> { $0.id == entity.id }
        )
        guard let model = try modelContext.fetch(descriptor).first else {
            throw RepositoryError.notFound
        }
        model.update(from: entity)
        try modelContext.save()
        return model.toEntity()
    }

    func delete(_ id: UUID) async throws {
        let descriptor = FetchDescriptor<BabyModel>(
            predicate: #Predicate<BabyModel> { $0.id == id }
        )
        guard let model = try modelContext.fetch(descriptor).first else {
            throw RepositoryError.notFound
        }
        model.isDeleted = true
        model.updatedAt = .now
        try modelContext.save()
    }

    func getActiveBabies() async throws -> [Baby] {
        let descriptor = FetchDescriptor<BabyModel>(
            predicate: #Predicate<BabyModel> { $0.isDeleted == false },
            sortBy: [SortDescriptor(\.createdAt)]
        )
        return try modelContext.fetch(descriptor).map { $0.toEntity() }
    }
}

enum RepositoryError: Error, LocalizedError {
    case notFound

    var errorDescription: String? {
        switch self {
        case .notFound: "Entity not found"
        }
    }
}
```

**Note:** `@unchecked Sendable` is needed because `ModelContext` is not Sendable, but we constrain usage to a single context. This is the standard SwiftData pattern. The `RepositoryError` enum goes in this file for now — move to shared location if other repos need it later (YAGNI).

**Step 5: Run tests to verify they pass**

Run: `xcodegen generate && xcodebuild test -scheme MomCare -destination 'platform=iOS Simulator,name=iPhone 16' 2>&1 | tail -20`

**Step 6: Run SwiftLint**

Run: `swiftlint --strict`

**Step 7: Commit**

```bash
git add MomCare/Domain/Repositories/BabyRepositoryProtocol.swift MomCare/Data/Repositories/BabyRepository.swift MomCareTests/Data/BabyRepositoryTests.swift
git commit -m "feat(MOM-2): add BabyRepository with SwiftData CRUD and soft delete"
```

---

### Task 4: Wire BabyRepository into DI

**Files:**
- Modify: `MomCare/Core/DI/Dependencies.swift`
- Test: `MomCareTests/Core/DI/DependenciesTests.swift` (update existing)

**Step 1: Update the failing test**

Add to `MomCareTests/Core/DI/DependenciesTests.swift`:

```swift
    @Test("DependencyContainer requires makeBabyRepository")
    @MainActor
    func babyRepositoryFactory() throws {
        let container = try TestDependencies()
        let repo = container.makeBabyRepository()
        #expect(repo is MockBabyRepository)
    }
```

Also add a `MockBabyRepository` and `TestDependencies` at the bottom of the test file:

```swift
final class MockBabyRepository: BabyRepositoryProtocol, @unchecked Sendable {
    func getAll() async throws -> [Baby] { [] }
    func getById(_ id: UUID) async throws -> Baby? { nil }
    func create(_ entity: Baby) async throws -> Baby { entity }
    func update(_ entity: Baby) async throws -> Baby { entity }
    func delete(_ id: UUID) async throws {}
    func getActiveBabies() async throws -> [Baby] { [] }
}

final class TestDependencies: DependencyContainer, @unchecked Sendable {
    func makeBabyRepository() -> any BabyRepositoryProtocol {
        MockBabyRepository()
    }
}
```

**Step 2: Run tests to verify they fail**

Expected: Compilation error — `makeBabyRepository` not part of `DependencyContainer`.

**Step 3: Update Dependencies.swift**

Modify `MomCare/Core/DI/Dependencies.swift`:

```swift
import SwiftUI
import SwiftData

protocol DependencyContainer: Sendable {
    func makeBabyRepository() -> any BabyRepositoryProtocol
}

final class AppDependencies: DependencyContainer, @unchecked Sendable {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func makeBabyRepository() -> any BabyRepositoryProtocol {
        BabyRepository(modelContext: modelContext)
    }
}

struct DependenciesKey: EnvironmentKey {
    // Default uses an in-memory container — previews and tests work without setup
    @MainActor
    static let defaultValue: any DependencyContainer = {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        // swiftlint:disable:next force_try
        let container = try! ModelContainer(for: BabyModel.self, configurations: config)
        return AppDependencies(modelContext: container.mainContext)
    }()
}

extension EnvironmentValues {
    var dependencies: any DependencyContainer {
        get { self[DependenciesKey.self] }
        set { self[DependenciesKey.self] = newValue }
    }
}
```

**Step 4: Update MomCareApp.swift to pass ModelContext**

Modify `MomCare/App/MomCareApp.swift` — update the body to pass the model context:

```swift
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.dependencies, AppDependencies(modelContext: sharedModelContainer.mainContext))
        }
        .modelContainer(sharedModelContainer)
    }
```

**Step 5: Run tests to verify they pass**

Run: `xcodegen generate && xcodebuild test -scheme MomCare -destination 'platform=iOS Simulator,name=iPhone 16' 2>&1 | tail -20`

**Step 6: Run SwiftLint**

Run: `swiftlint --strict`

**Step 7: Commit**

```bash
git add MomCare/Core/DI/Dependencies.swift MomCare/App/MomCareApp.swift MomCareTests/Core/DI/DependenciesTests.swift
git commit -m "feat(MOM-2): wire BabyRepository into DependencyContainer"
```

---

### Task 5: BabyViewModel

**Files:**
- Create: `MomCare/Features/Baby/ViewModels/BabyViewModel.swift`
- Test: `MomCareTests/Features/BabyViewModelTests.swift`

**Step 1: Write the failing tests**

Create `MomCareTests/Features/BabyViewModelTests.swift`:

```swift
import Testing
import Foundation
@testable import MomCare

@Suite("BabyViewModel Tests")
struct BabyViewModelTests {

    private func makeSUT(babies: [Baby] = []) -> BabyViewModel {
        let repo = StubBabyRepository(babies: babies)
        return BabyViewModel(repository: repo)
    }

    @Test("loadBabies populates array")
    @MainActor
    func loadBabies() async {
        let vm = makeSUT(babies: [Baby.fixture(name: "A"), Baby.fixture(name: "B")])
        await vm.loadBabies()
        #expect(vm.babies.count == 2)
    }

    @Test("loadBabies auto-selects first baby when none selected")
    @MainActor
    func autoSelectFirst() async {
        let vm = makeSUT(babies: [Baby.fixture(name: "First")])
        await vm.loadBabies()
        #expect(vm.selectedBaby?.name == "First")
    }

    @Test("loadBabies preserves existing selection")
    @MainActor
    func preserveSelection() async {
        let existing = Baby.fixture(name: "Keep")
        let vm = makeSUT(babies: [Baby.fixture(name: "Other"), existing])
        vm.selectedBaby = existing
        await vm.loadBabies()
        #expect(vm.selectedBaby?.name == "Keep")
    }

    @Test("createBaby adds to list and selects it")
    @MainActor
    func createBaby() async {
        let vm = makeSUT()
        await vm.createBaby(Baby.fixture(name: "New"))
        #expect(vm.babies.count == 1)
        #expect(vm.selectedBaby?.name == "New")
    }

    @Test("deleteBaby removes from active list")
    @MainActor
    func deleteBaby() async {
        let baby = Baby.fixture(name: "Gone")
        let vm = makeSUT(babies: [baby])
        await vm.loadBabies()
        await vm.deleteBaby(baby.id)
        #expect(vm.babies.isEmpty)
    }

    @Test("selectBaby updates selectedBaby")
    @MainActor
    func selectBaby() {
        let vm = makeSUT()
        let baby = Baby.fixture(name: "Pick Me")
        vm.selectBaby(baby)
        #expect(vm.selectedBaby?.name == "Pick Me")
    }
}

// MARK: - Stub Repository

private final class StubBabyRepository: BabyRepositoryProtocol, @unchecked Sendable {
    private var store: [Baby]

    init(babies: [Baby] = []) {
        self.store = babies
    }

    func getAll() async throws -> [Baby] { store }
    func getById(_ id: UUID) async throws -> Baby? { store.first { $0.id == id } }
    func create(_ entity: Baby) async throws -> Baby {
        store.append(entity)
        return entity
    }
    func update(_ entity: Baby) async throws -> Baby {
        if let idx = store.firstIndex(where: { $0.id == entity.id }) {
            store[idx] = entity
        }
        return entity
    }
    func delete(_ id: UUID) async throws {
        store.removeAll { $0.id == id }
    }
    func getActiveBabies() async throws -> [Baby] {
        store.filter { !$0.isDeleted }
    }
}
```

**Step 2: Run tests to verify they fail**

Expected: Compilation error — `BabyViewModel` not found.

**Step 3: Write the ViewModel**

Create `MomCare/Features/Baby/ViewModels/BabyViewModel.swift`:

```swift
import Foundation

@MainActor
@Observable
final class BabyViewModel {
    var babies: [Baby] = []
    var selectedBaby: Baby?
    var isLoading = false
    var error: Error?

    private let repository: any BabyRepositoryProtocol

    init(repository: any BabyRepositoryProtocol) {
        self.repository = repository
    }

    func loadBabies() async {
        isLoading = true
        defer { isLoading = false }
        do {
            babies = try await repository.getActiveBabies()
            if selectedBaby == nil || !babies.contains(where: { $0.id == selectedBaby?.id }) {
                selectedBaby = babies.first
            }
        } catch {
            self.error = error
        }
    }

    func createBaby(_ baby: Baby) async {
        do {
            let created = try await repository.create(baby)
            babies.append(created)
            selectedBaby = created
        } catch {
            self.error = error
        }
    }

    func updateBaby(_ baby: Baby) async {
        do {
            let updated = try await repository.update(baby)
            if let idx = babies.firstIndex(where: { $0.id == updated.id }) {
                babies[idx] = updated
            }
            if selectedBaby?.id == updated.id {
                selectedBaby = updated
            }
        } catch {
            self.error = error
        }
    }

    func deleteBaby(_ id: UUID) async {
        do {
            try await repository.delete(id)
            babies.removeAll { $0.id == id }
            if selectedBaby?.id == id {
                selectedBaby = babies.first
            }
        } catch {
            self.error = error
        }
    }

    func selectBaby(_ baby: Baby) {
        selectedBaby = baby
    }
}
```

**Step 4: Run tests to verify they pass**

Run: `xcodegen generate && xcodebuild test -scheme MomCare -destination 'platform=iOS Simulator,name=iPhone 16' 2>&1 | tail -20`

**Step 5: Run SwiftLint**

Run: `swiftlint --strict`

**Step 6: Commit**

```bash
git add MomCare/Features/Baby/ViewModels/BabyViewModel.swift MomCareTests/Features/BabyViewModelTests.swift
git commit -m "feat(MOM-2): add BabyViewModel with CRUD, auto-selection, and mock tests"
```

---

### Task 6: BabyAvatarView (Shared Component)

**Files:**
- Create: `MomCare/Shared/Components/BabyAvatarView.swift`

**Step 1: Write the view**

Create `MomCare/Shared/Components/BabyAvatarView.swift`:

```swift
import SwiftUI

struct BabyAvatarView: View {
    let baby: Baby
    var size: CGFloat = 40

    var body: some View {
        Group {
            if let photoData = baby.photoData, let uiImage = UIImage(data: photoData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
            } else {
                Text(baby.name.prefix(1).uppercased())
                    .font(.system(size: size * 0.45, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(MCColor.accent.gradient)
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
        .overlay(Circle().stroke(MCColor.accent.opacity(0.3), lineWidth: 1))
    }
}

#Preview("With initial") {
    BabyAvatarView(baby: Baby.fixture(name: "Emma"), size: 60)
}

#Preview("Large") {
    BabyAvatarView(baby: Baby.fixture(name: "Noah"), size: 120)
}
```

**Step 2: Build to verify it compiles**

Run: `xcodegen generate && xcodebuild build -scheme MomCare -destination 'platform=iOS Simulator,name=iPhone 16' 2>&1 | tail -5`
Expected: BUILD SUCCEEDED.

**Step 3: Run SwiftLint**

Run: `swiftlint --strict`

**Step 4: Commit**

```bash
git add MomCare/Shared/Components/BabyAvatarView.swift
git commit -m "feat(MOM-2): add BabyAvatarView shared component"
```

---

### Task 7: AddBabyView

**Files:**
- Create: `MomCare/Features/Baby/Views/AddBabyView.swift`

**Step 1: Write the view**

Create `MomCare/Features/Baby/Views/AddBabyView.swift`:

```swift
import SwiftUI
import PhotosUI

struct AddBabyView: View {
    @Environment(\.dismiss) private var dismiss
    let onSave: (Baby) -> Void

    @State private var name = ""
    @State private var dateOfBirth = Date.now
    @State private var biologicalSex: Baby.BiologicalSex?
    @State private var feedingMethod: Baby.FeedingMethod = .breast
    @State private var birthWeight: String = ""
    @State private var birthLength: String = ""
    @State private var birthHeadCircumference: String = ""
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var photoData: Data?
    @State private var showOptionalDetails = false

    private var isValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                requiredSection
                optionalSection
            }
            .navigationTitle("Add Baby")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") { saveBaby() }
                        .disabled(!isValid)
                }
            }
            .onChange(of: selectedPhoto) { _, newItem in
                Task {
                    photoData = try? await newItem?.loadTransferable(type: Data.self)
                }
            }
        }
    }

    // MARK: - Sections

    private var requiredSection: some View {
        Section {
            TextField("Baby's name", text: $name)
                .textContentType(.name)
            DatePicker("Birthday", selection: $dateOfBirth, displayedComponents: .date)
        }
    }

    private var optionalSection: some View {
        Section {
            DisclosureGroup("Additional Details", isExpanded: $showOptionalDetails) {
                Picker("Biological Sex", selection: $biologicalSex) {
                    Text("Not specified").tag(nil as Baby.BiologicalSex?)
                    ForEach(Baby.BiologicalSex.allCases, id: \.self) { sex in
                        Text(sex.displayName).tag(sex as Baby.BiologicalSex?)
                    }
                }

                Picker("Feeding Method", selection: $feedingMethod) {
                    ForEach(Baby.FeedingMethod.allCases, id: \.self) { method in
                        Text(method.displayName).tag(method)
                    }
                }

                TextField("Birth weight (g)", text: $birthWeight)
                    .keyboardType(.decimalPad)
                TextField("Birth length (cm)", text: $birthLength)
                    .keyboardType(.decimalPad)
                TextField("Head circumference (cm)", text: $birthHeadCircumference)
                    .keyboardType(.decimalPad)

                PhotosPicker(selection: $selectedPhoto, matching: .images) {
                    Label("Choose Photo", systemImage: "photo")
                }
            }
        }
    }

    // MARK: - Actions

    private func saveBaby() {
        let baby = Baby(
            id: UUID(),
            name: name.trimmingCharacters(in: .whitespaces),
            dateOfBirth: dateOfBirth,
            biologicalSex: biologicalSex,
            birthWeight: Double(birthWeight),
            birthLength: Double(birthLength),
            birthHeadCircumference: Double(birthHeadCircumference),
            feedingMethod: feedingMethod,
            photoData: photoData,
            isDeleted: false,
            createdAt: .now,
            updatedAt: .now
        )
        MCHaptic.success()
        onSave(baby)
        dismiss()
    }
}
```

**Step 2: Add display names for enums**

Add to `MomCare/Domain/Entities/Baby.swift` (at the bottom, before the `fixture` extension):

```swift
extension Baby.BiologicalSex {
    var displayName: String {
        switch self {
        case .male: "Male"
        case .female: "Female"
        case .other: "Other"
        case .preferNotToSay: "Prefer not to say"
        }
    }
}

extension Baby.FeedingMethod {
    var displayName: String {
        switch self {
        case .breast: "Breastfeeding"
        case .bottle: "Bottle feeding"
        case .both: "Both"
        }
    }
}
```

**Step 3: Build to verify it compiles**

Run: `xcodegen generate && xcodebuild build -scheme MomCare -destination 'platform=iOS Simulator,name=iPhone 16' 2>&1 | tail -5`

**Step 4: Run SwiftLint**

Run: `swiftlint --strict`

**Step 5: Commit**

```bash
git add MomCare/Features/Baby/Views/AddBabyView.swift MomCare/Domain/Entities/Baby.swift
git commit -m "feat(MOM-2): add AddBabyView with progressive disclosure form"
```

---

### Task 8: BabyProfileView

**Files:**
- Create: `MomCare/Features/Baby/Views/BabyProfileView.swift`

**Step 1: Write the view**

Create `MomCare/Features/Baby/Views/BabyProfileView.swift`:

```swift
import SwiftUI
import PhotosUI

struct BabyProfileView: View {
    @Bindable var viewModel: BabyViewModel
    let baby: Baby

    @State private var editedBaby: Baby
    @State private var isEditing = false
    @State private var showDeleteConfirmation = false
    @State private var selectedPhoto: PhotosPickerItem?
    @Environment(\.dismiss) private var dismiss

    init(viewModel: BabyViewModel, baby: Baby) {
        self.viewModel = viewModel
        self.baby = baby
        self._editedBaby = State(initialValue: baby)
    }

    var body: some View {
        List {
            heroSection
            detailsSection
            if isEditing {
                deleteSection
            }
        }
        .navigationTitle(baby.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(isEditing ? "Done" : "Edit") {
                    if isEditing {
                        saveChanges()
                    }
                    isEditing.toggle()
                    MCHaptic.tap()
                }
            }
        }
        .confirmationDialog("Delete Baby", isPresented: $showDeleteConfirmation) {
            Button("Delete", role: .destructive) {
                Task {
                    await viewModel.deleteBaby(baby.id)
                    dismiss()
                }
            }
        } message: {
            Text("This will remove \(baby.name) from your babies. This action cannot be undone.")
        }
        .onChange(of: selectedPhoto) { _, newItem in
            Task {
                editedBaby.photoData = try? await newItem?.loadTransferable(type: Data.self)
            }
        }
    }

    // MARK: - Sections

    private var heroSection: some View {
        Section {
            VStack(spacing: MCSpacing.md) {
                BabyAvatarView(baby: isEditing ? editedBaby : baby, size: 100)

                if isEditing {
                    PhotosPicker(selection: $selectedPhoto, matching: .images) {
                        Label("Change Photo", systemImage: "photo")
                            .font(MCTypography.cardBody)
                    }
                }

                Text(baby.ageString)
                    .font(MCTypography.cardBody)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .listRowBackground(Color.clear)
        }
    }

    private var detailsSection: some View {
        Section("Details") {
            if isEditing {
                TextField("Name", text: $editedBaby.name)
                DatePicker("Birthday", selection: $editedBaby.dateOfBirth, displayedComponents: .date)
                Picker("Biological Sex", selection: $editedBaby.biologicalSex) {
                    Text("Not specified").tag(nil as Baby.BiologicalSex?)
                    ForEach(Baby.BiologicalSex.allCases, id: \.self) { sex in
                        Text(sex.displayName).tag(sex as Baby.BiologicalSex?)
                    }
                }
                Picker("Feeding Method", selection: $editedBaby.feedingMethod) {
                    ForEach(Baby.FeedingMethod.allCases, id: \.self) { method in
                        Text(method.displayName).tag(method)
                    }
                }
            } else {
                LabeledContent("Name", value: baby.name)
                LabeledContent("Birthday", value: baby.dateOfBirth.formatted(date: .long, time: .omitted))
                if let sex = baby.biologicalSex {
                    LabeledContent("Biological Sex", value: sex.displayName)
                }
                LabeledContent("Feeding Method", value: baby.feedingMethod.displayName)
                if let weight = baby.birthWeight {
                    LabeledContent("Birth Weight", value: "\(Int(weight))g")
                }
                if let length = baby.birthLength {
                    LabeledContent("Birth Length", value: String(format: "%.1f cm", length))
                }
            }
        }
    }

    private var deleteSection: some View {
        Section {
            Button("Delete Baby", role: .destructive) {
                showDeleteConfirmation = true
            }
        }
    }

    // MARK: - Actions

    private func saveChanges() {
        editedBaby.updatedAt = .now
        Task {
            await viewModel.updateBaby(editedBaby)
        }
        MCHaptic.success()
    }
}
```

**Step 2: Build to verify it compiles**

Run: `xcodegen generate && xcodebuild build -scheme MomCare -destination 'platform=iOS Simulator,name=iPhone 16' 2>&1 | tail -5`

**Step 3: Run SwiftLint**

Run: `swiftlint --strict`

**Step 4: Commit**

```bash
git add MomCare/Features/Baby/Views/BabyProfileView.swift
git commit -m "feat(MOM-2): add BabyProfileView with inline edit and delete"
```

---

### Task 9: BabySelectorView

**Files:**
- Create: `MomCare/Features/Baby/Views/BabySelectorView.swift`

**Step 1: Write the view**

Create `MomCare/Features/Baby/Views/BabySelectorView.swift`:

```swift
import SwiftUI

struct BabySelectorView: View {
    @Bindable var viewModel: BabyViewModel
    @State private var showAddBaby = false

    var body: some View {
        Menu {
            ForEach(viewModel.babies) { baby in
                Button {
                    viewModel.selectBaby(baby)
                    MCHaptic.select()
                } label: {
                    Label {
                        Text(baby.name)
                    } icon: {
                        if baby.id == viewModel.selectedBaby?.id {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }

            Divider()

            Button {
                showAddBaby = true
                MCHaptic.tap()
            } label: {
                Label("Add Baby", systemImage: "plus")
            }
        } label: {
            HStack(spacing: MCSpacing.xs) {
                if let baby = viewModel.selectedBaby {
                    BabyAvatarView(baby: baby, size: 28)
                    Text(baby.name)
                        .font(MCTypography.cardTitle)
                } else {
                    Image(systemName: "person.crop.circle.badge.plus")
                    Text("Add Baby")
                        .font(MCTypography.cardTitle)
                }
            }
        }
        .sheet(isPresented: $showAddBaby) {
            AddBabyView { baby in
                Task {
                    await viewModel.createBaby(baby)
                }
            }
        }
    }
}
```

**Step 2: Build to verify it compiles**

Run: `xcodegen generate && xcodebuild build -scheme MomCare -destination 'platform=iOS Simulator,name=iPhone 16' 2>&1 | tail -5`

**Step 3: Run SwiftLint**

Run: `swiftlint --strict`

**Step 4: Commit**

```bash
git add MomCare/Features/Baby/Views/BabySelectorView.swift
git commit -m "feat(MOM-2): add BabySelectorView toolbar menu with add baby"
```

---

### Task 10: Wire Baby Views into ContentView

**Files:**
- Modify: `MomCare/App/ContentView.swift`

**Step 1: Update ContentView**

Replace `MomCare/App/ContentView.swift` with:

```swift
import SwiftUI

struct ContentView: View {
    @State private var navigation = AppNavigation()
    @State private var babyViewModel: BabyViewModel?
    @Environment(\.dependencies) private var dependencies
    @State private var showAddBaby = false

    var body: some View {
        Group {
            if let babyViewModel {
                mainTabView(babyViewModel: babyViewModel)
            } else {
                ProgressView()
            }
        }
        .task {
            let repo = dependencies.makeBabyRepository()
            let vm = BabyViewModel(repository: repo)
            await vm.loadBabies()
            babyViewModel = vm

            if vm.babies.isEmpty {
                showAddBaby = true
            }
        }
        .sheet(isPresented: $showAddBaby) {
            AddBabyView { baby in
                if let babyViewModel {
                    Task { await babyViewModel.createBaby(baby) }
                }
            }
        }
        .environment(navigation)
    }

    @ViewBuilder
    private func mainTabView(babyViewModel: BabyViewModel) -> some View {
        TabView(selection: $navigation.selectedTab) {
            NavigationStack(path: $navigation.dashboardPath) {
                Text("Mission Control")
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
                Text("Feeding")
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

            NavigationStack(path: $navigation.selfCarePath) {
                Text("Self-Care")
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
```

**Step 2: Build and run tests**

Run: `xcodegen generate && xcodebuild test -scheme MomCare -destination 'platform=iOS Simulator,name=iPhone 16' 2>&1 | tail -20`
Expected: All tests pass. BUILD SUCCEEDED.

**Step 3: Run SwiftLint**

Run: `swiftlint --strict`

**Step 4: Commit**

```bash
git add MomCare/App/ContentView.swift
git commit -m "feat(MOM-2): wire baby selector and add-baby flow into ContentView"
```

---

### Task 11: Final Integration Test & Cleanup

**Step 1: Run the full test suite**

```bash
xcodegen generate && xcodebuild test -scheme MomCare -destination 'platform=iOS Simulator,name=iPhone 16' 2>&1 | tail -30
```

Expected: All tests pass — Baby entity, BabyModel, BabyRepository, BabyViewModel, plus all MOM-1 tests.

**Step 2: Run SwiftLint**

```bash
swiftlint --strict
```

**Step 3: Verify build succeeds**

```bash
xcodebuild build -scheme MomCare -destination 'platform=iOS Simulator,name=iPhone 16' 2>&1 | tail -5
```

**Step 4: Final commit if any cleanup needed**

```bash
git add -A
git status  # verify only expected files
git commit -m "chore(MOM-2): final cleanup and integration verification"
```

---

## File Summary

| Action | Path |
|--------|------|
| Create | `MomCare/Domain/Entities/Baby.swift` |
| Create | `MomCare/Data/SwiftData/BabyModel.swift` |
| Create | `MomCare/Domain/Repositories/BabyRepositoryProtocol.swift` |
| Create | `MomCare/Data/Repositories/BabyRepository.swift` |
| Create | `MomCare/Features/Baby/ViewModels/BabyViewModel.swift` |
| Create | `MomCare/Shared/Components/BabyAvatarView.swift` |
| Create | `MomCare/Features/Baby/Views/AddBabyView.swift` |
| Create | `MomCare/Features/Baby/Views/BabyProfileView.swift` |
| Create | `MomCare/Features/Baby/Views/BabySelectorView.swift` |
| Modify | `MomCare/App/MomCareApp.swift` (register BabyModel in Schema) |
| Modify | `MomCare/Core/DI/Dependencies.swift` (add makeBabyRepository) |
| Modify | `MomCare/App/ContentView.swift` (wire baby views) |
| Create | `MomCareTests/Domain/BabyTests.swift` |
| Create | `MomCareTests/Data/BabyModelTests.swift` |
| Create | `MomCareTests/Data/BabyRepositoryTests.swift` |
| Create | `MomCareTests/Features/BabyViewModelTests.swift` |
