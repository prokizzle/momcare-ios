import Foundation

enum SelfCareActionType: String, Codable, CaseIterable, Sendable {
    case shower
    case brushTeeth
    case changeClothes
    case shave
    case skincare
    case meditate
    case breathingExercise
    case water
    case meal
}

enum MealType: String, Codable, CaseIterable, Sendable {
    case breakfast
    case lunch
    case dinner
    case snack
}

enum LogDetail: Codable, Sendable, Equatable {
    case water(glasses: Int)
    case meal(MealType)
    case exercise(minutes: Int)
    case freeNote(String)
}

struct SelfCareLog: Identifiable, Codable, Sendable, Equatable {
    var id: UUID
    var actionType: SelfCareActionType
    var timestamp: Date
    var detail: LogDetail?
    var createdAt: Date
    var updatedAt: Date
}

extension SelfCareLog {
    static func fixture(
        id: UUID = UUID(),
        actionType: SelfCareActionType = .water,
        timestamp: Date = .now,
        detail: LogDetail? = nil,
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) -> SelfCareLog {
        SelfCareLog(
            id: id,
            actionType: actionType,
            timestamp: timestamp,
            detail: detail,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
}

extension SelfCareActionType {
    var label: String {
        switch self {
        case .shower: "Shower"
        case .brushTeeth: "Brush Teeth"
        case .changeClothes: "Change Clothes"
        case .shave: "Shave"
        case .skincare: "Skincare"
        case .meditate: "Meditate"
        case .breathingExercise: "Breathing"
        case .water: "Water"
        case .meal: "Meal"
        }
    }

    var systemImage: String {
        switch self {
        case .shower: "drop.triangle.fill"
        case .brushTeeth: "mouth.fill"
        case .changeClothes: "tshirt.fill"
        case .shave: "scissors"
        case .skincare: "face.smiling"
        case .meditate: "brain.head.profile"
        case .breathingExercise: "wind"
        case .water: "cup.and.saucer.fill"
        case .meal: "fork.knife"
        }
    }
}

extension MealType {
    var label: String {
        switch self {
        case .breakfast: "Breakfast"
        case .lunch: "Lunch"
        case .dinner: "Dinner"
        case .snack: "Snack"
        }
    }
}
