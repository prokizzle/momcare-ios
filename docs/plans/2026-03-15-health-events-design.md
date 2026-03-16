# Health Events Timeline Design

## Goal

Build health events tracking with timeline view, multi-photo support, and AAP vaccine schedule reference for MomCare iOS.

## Data Model

### HealthEvent Entity

```swift
struct HealthEvent: Identifiable, Codable, Sendable {
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
```

### SwiftData Model

```swift
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
}
```

Photos stored as JPEG at 80% quality, max 5 per event. `@Attribute(.externalStorage)` moves large blobs to external files automatically.

### Schema Migration

SchemaV7 adds HealthEventModel. Lightweight migration from SchemaV6 (which was the Nightlight design system -- no model changes, but the version was bumped for the relationship removal).

Note: Check current schema version before implementation. May be SchemaV6 if no other migrations were added.

## Repository

```swift
protocol HealthEventRepositoryProtocol: Repository {
    func getEventsForBaby(_ babyId: UUID, limit: Int?) async throws -> [HealthEvent]
    func getEventsForBabyByType(_ babyId: UUID, type: HealthEvent.EventType) async throws -> [HealthEvent]
}
```

Repository handles mapping between HealthEvent (entity without photos) and HealthEventModel (with photos). Photo data is passed separately on create/update to keep the entity lightweight.

## Views

### HealthEventsScreen

- LazyVStack timeline grouped by month
- Filter chips at top: All, Vaccine, Illness, Milestone, Doctor, Allergy
- Each event row: type icon (colored) + date + title + photo count badge
- Tap row -> HealthEventDetailView via NavigationLink
- "Upcoming Vaccines" section at top when unlogged vaccines are due
- Empty state with illustration and "Log First Event" CTA
- FAB-style add button at bottom

### AddHealthEventView

- Presented as sheet
- Event type picker (segmented control for 5 types)
- Title field (pre-filled from vaccine suggestion if applicable)
- Date picker (defaults to today)
- End date toggle + picker (for illness duration)
- Notes text field (optional, multiline)
- PhotosPicker for existing photos (max 5)
- Camera button for taking new photos
- Photos displayed as horizontal thumbnail strip with remove button
- Save validates: title required, at least one field filled
- Dismiss only on successful save (show alert on failure)
- Photos compressed to JPEG 80% before storage

### HealthEventDetailView

- Full event details: type badge, title, date range, notes
- Horizontal photo gallery (ScrollView .horizontal)
- Tap photo -> fullscreen sheet with zoom
- Edit button -> AddHealthEventView in edit mode
- Delete button -> confirmation dialog -> soft delete

## Vaccine Schedule

### Data

Bundled `aap-vaccine-schedule.json` with recommended vaccines birth through 18 months:

```json
[
    { "name": "HepB - Dose 1", "ageMonths": 0, "description": "Hepatitis B" },
    { "name": "DTaP - Dose 1", "ageMonths": 2, "description": "Diphtheria, Tetanus, Pertussis" },
    ...
]
```

### VaccineScheduleService

- Loads bundled JSON
- Given baby's dateOfBirth and existing vaccine events, returns upcoming vaccines
- Matches by vaccine name prefix (e.g., "DTaP" matches "DTaP - Dose 1")
- Returns vaccines due in the next 2 months

### UI Integration

- "Upcoming Vaccines" section at top of HealthEventsScreen when results exist
- Each suggestion shows vaccine name, recommended age, "Log" button
- Tapping "Log" opens AddHealthEventView pre-filled with vaccine type and title

## Architecture

```
Domain/
  Entities/HealthEvent.swift
  Repositories/HealthEventRepositoryProtocol.swift
  Services/VaccineScheduleService.swift

Data/
  SwiftData/HealthEventModel.swift
  Repositories/HealthEventRepository.swift
  SwiftData/Schema/SchemaV7.swift (or next version)

Features/
  HealthEvents/
    ViewModels/HealthEventsViewModel.swift
    Views/HealthEventsScreen.swift
    Views/AddHealthEventView.swift
    Views/HealthEventDetailView.swift

Core/
  Content/AAP/aap-vaccine-schedule.json
  DI/Dependencies.swift (add makeHealthEventRepository)

App/
  AppNavigation.swift (add BabyRoute.healthEvents, .healthEventDetail)
  ContentView.swift (wire HealthEventsViewModel)
  MomCareApp.swift (create HealthEventsViewModel)
```

## Navigation

- BabyRoute.healthEvents -> HealthEventsScreen
- BabyRoute.healthEventDetail(UUID) -> HealthEventDetailView
- Entry point: NavigationLink in BabyScreen (same pattern as Sleep History, Growth Charts)

## Camera Integration

- `NSCameraUsageDescription` added to Info.plist
- Camera access via UIImagePickerController wrapped in UIViewControllerRepresentable
- Photos from camera compressed to JPEG 80% same as PhotosPicker photos

## Nightlight Design System

All views use:
- MCTypography tokens for all text
- MCRadius tokens for all corner radii
- MCOpacity tokens for all opacity values
- MCElevation for card backgrounds
- MCAnimation for transitions
- .nightlightBackground() where applicable
- Pow transitions for list insertions/removals
- EmptyStateView for empty state
