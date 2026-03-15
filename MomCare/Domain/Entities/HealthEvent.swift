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
