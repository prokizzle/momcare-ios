import Foundation

struct ActionPattern: Sendable, Equatable {
    let actionType: SelfCareActionType
    let averageTimesPerDay: Double
    let typicalTimestamps: [DateInterval]
    let relativeToFeeding: TimeInterval?
    let streakDays: Int
    let compliance: Double
    let confidence: Double
}
