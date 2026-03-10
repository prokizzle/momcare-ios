import Foundation

struct Feeding: Identifiable, Codable, Sendable, Equatable {
    var id: UUID
    var babyId: UUID
    var feedingType: FeedingType
    var startTime: Date
    var endTime: Date?
    var breastSide: BreastSide?
    var breastDuration: TimeInterval?
    var amountMl: Int?
    var bottleContent: BottleContent?
    var foodDescription: String?
    var quality: FeedingQuality?
    var notes: String?
    var createdAt: Date
    var updatedAt: Date

    var isInProgress: Bool { endTime == nil }

    var duration: TimeInterval {
        guard let endTime else { return 0 }
        return endTime.timeIntervalSince(startTime)
    }

    var durationFormatted: String {
        let totalMinutes = Int(duration) / 60
        if totalMinutes < 60 {
            return "\(totalMinutes) min"
        }
        let hours = totalMinutes / 60
        let mins = totalMinutes % 60
        if mins == 0 {
            return "\(hours)h"
        }
        return "\(hours)h \(mins)m"
    }

    enum FeedingType: String, Codable, CaseIterable, Sendable {
        case breast, bottle, pumping, solid
    }

    enum BreastSide: String, Codable, CaseIterable, Sendable {
        case left, right, both
    }

    enum BottleContent: String, Codable, CaseIterable, Sendable {
        case breastMilk, formula, mixed
    }

    enum FeedingQuality: String, Codable, CaseIterable, Sendable {
        case good, fussy, distracted, sleepy
    }
}

extension Feeding {
    static func fixture(
        id: UUID = UUID(),
        babyId: UUID = UUID(),
        feedingType: FeedingType = .breast,
        startTime: Date = Date.now.addingTimeInterval(-1800),
        endTime: Date? = Date.now,
        breastSide: BreastSide? = .left,
        breastDuration: TimeInterval? = nil,
        amountMl: Int? = nil,
        bottleContent: BottleContent? = nil,
        foodDescription: String? = nil,
        quality: FeedingQuality? = nil,
        notes: String? = nil,
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) -> Feeding {
        Feeding(
            id: id,
            babyId: babyId,
            feedingType: feedingType,
            startTime: startTime,
            endTime: endTime,
            breastSide: breastSide,
            breastDuration: breastDuration,
            amountMl: amountMl,
            bottleContent: bottleContent,
            foodDescription: foodDescription,
            quality: quality,
            notes: notes,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
}

extension Feeding.FeedingType {
    var label: String {
        switch self {
        case .breast: "Breast"
        case .bottle: "Bottle"
        case .pumping: "Pumping"
        case .solid: "Solid Food"
        }
    }

    var systemImage: String {
        switch self {
        case .breast: "drop.fill"
        case .bottle: "waterbottle.fill"
        case .pumping: "arrow.up.heart.fill"
        case .solid: "fork.knife"
        }
    }
}

extension Feeding.BreastSide {
    var label: String {
        switch self {
        case .left: "Left"
        case .right: "Right"
        case .both: "Both"
        }
    }
}

extension Feeding.BottleContent {
    var displayName: String {
        switch self {
        case .breastMilk: "Breast Milk"
        case .formula: "Formula"
        case .mixed: "Mixed"
        }
    }
}

extension Feeding.FeedingQuality {
    var displayName: String {
        switch self {
        case .good: "Good"
        case .fussy: "Fussy"
        case .distracted: "Distracted"
        case .sleepy: "Sleepy"
        }
    }
}
