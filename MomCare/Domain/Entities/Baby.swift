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
