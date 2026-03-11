import Foundation

struct BabySleep: Identifiable, Codable, Sendable, Equatable {
    var id: UUID
    var babyId: UUID
    var startTime: Date
    var endTime: Date?
    var sleepType: SleepType
    var location: SleepLocation?
    var quality: SleepQuality?
    var notes: String?
    var createdAt: Date
    var updatedAt: Date

    var isInProgress: Bool { endTime == nil }

    var duration: TimeInterval {
        let end = endTime ?? .now
        return end.timeIntervalSince(startTime)
    }

    enum SleepType: String, Codable, CaseIterable, Sendable {
        case nap, nighttime

        var label: String {
            switch self {
            case .nap: "Nap"
            case .nighttime: "Night Sleep"
            }
        }

        var systemImage: String {
            switch self {
            case .nap: "sun.max.fill"
            case .nighttime: "moon.stars.fill"
            }
        }

        static func autoDetect(at date: Date = .now) -> SleepType {
            let hour = Calendar.current.component(.hour, from: date)
            return (hour >= 19 || hour < 6) ? .nighttime : .nap
        }
    }

    enum SleepLocation: String, Codable, CaseIterable, Sendable {
        case crib, bassinet, coSleep, stroller, carSeat, other

        var label: String {
            switch self {
            case .crib: "Crib"
            case .bassinet: "Bassinet"
            case .coSleep: "Co-Sleep"
            case .stroller: "Stroller"
            case .carSeat: "Car Seat"
            case .other: "Other"
            }
        }
    }

    enum SleepQuality: String, Codable, CaseIterable, Sendable {
        case good, fair, poor

        var label: String { rawValue.capitalized }

        var systemImage: String {
            switch self {
            case .good: "star.fill"
            case .fair: "star.leadinghalf.filled"
            case .poor: "star"
            }
        }
    }
}

// MARK: - Testing Fixtures

extension BabySleep {
    static func fixture(
        id: UUID = UUID(),
        babyId: UUID = UUID(),
        startTime: Date = .now,
        endTime: Date? = Date().addingTimeInterval(3600),
        sleepType: SleepType = .nap,
        location: SleepLocation? = nil,
        quality: SleepQuality? = nil,
        notes: String? = nil,
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) -> BabySleep {
        BabySleep(
            id: id,
            babyId: babyId,
            startTime: startTime,
            endTime: endTime,
            sleepType: sleepType,
            location: location,
            quality: quality,
            notes: notes,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
}
