import Foundation

struct GrowthRecord: Identifiable, Codable, Sendable, Equatable {
    var id: UUID
    var babyId: UUID
    var date: Date
    var weightGrams: Double?
    var lengthCm: Double?
    var headCircumferenceCm: Double?
    var notes: String?
    var isDeleted: Bool
    var createdAt: Date
    var updatedAt: Date

    // MARK: - Locale-aware formatting

    var weightFormatted: String {
        guard let grams = weightGrams else { return "--" }
        if Locale.current.measurementSystem == .metric {
            let kilograms = grams / 1000.0
            return String(format: "%.1f kg", kilograms)
        } else {
            let lbs = grams / 453.592
            return String(format: "%.1f lbs", lbs)
        }
    }

    var lengthFormatted: String {
        guard let centimeters = lengthCm else { return "--" }
        if Locale.current.measurementSystem == .metric {
            return String(format: "%.1f cm", centimeters)
        } else {
            let inches = centimeters / 2.54
            return String(format: "%.1f in", inches)
        }
    }

    var headCircumferenceFormatted: String {
        guard let centimeters = headCircumferenceCm else { return "--" }
        if Locale.current.measurementSystem == .metric {
            return String(format: "%.1f cm", centimeters)
        } else {
            let inches = centimeters / 2.54
            return String(format: "%.1f in", inches)
        }
    }

    func ageInMonths(dateOfBirth: Date) -> Int {
        Calendar.current.dateComponents([.month], from: dateOfBirth, to: date).month ?? 0
    }
}

// MARK: - Testing Fixtures

extension GrowthRecord {
    static func fixture(
        id: UUID = UUID(),
        babyId: UUID = UUID(),
        date: Date = .now,
        weightGrams: Double? = nil,
        lengthCm: Double? = nil,
        headCircumferenceCm: Double? = nil,
        notes: String? = nil,
        isDeleted: Bool = false,
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) -> GrowthRecord {
        GrowthRecord(
            id: id,
            babyId: babyId,
            date: date,
            weightGrams: weightGrams,
            lengthCm: lengthCm,
            headCircumferenceCm: headCircumferenceCm,
            notes: notes,
            isDeleted: isDeleted,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
}
