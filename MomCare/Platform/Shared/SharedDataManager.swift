import Foundation
import WidgetKit

struct SharedDataManager: Sendable {
    static let suiteName = "group.com.feelingmindful.momcare"

    private static var defaults: UserDefaults {
        guard let defaults = UserDefaults(suiteName: suiteName) else {
            #if DEBUG
            assertionFailure("Failed to create UserDefaults for suite: \(suiteName)")
            #endif
            return .standard
        }
        return defaults
    }

    // MARK: - Baby

    static func updateBaby(name: String) {
        defaults.set(name, forKey: "mc_babyName")
        reloadWidgets()
    }

    static var babyName: String {
        defaults.string(forKey: "mc_babyName") ?? "Baby"
    }

    // MARK: - Feeding

    static func updateFeeding(_ state: SharedFeedingState) {
        defaults.set(state.lastTime, forKey: "mc_lastFeedingTime")
        defaults.set(state.lastType, forKey: "mc_lastFeedingType")
        defaults.set(state.isInProgress, forKey: "mc_isFeedingInProgress")
        defaults.set(state.startTime, forKey: "mc_feedingStartTime")
        defaults.set(state.detail, forKey: "mc_feedingDetail")
        defaults.set(state.todayCount, forKey: "mc_todayFeedingCount")
        reloadWidgets()
    }

    static var lastFeedingTime: Date? { defaults.object(forKey: "mc_lastFeedingTime") as? Date }
    static var lastFeedingType: String? { defaults.string(forKey: "mc_lastFeedingType") }
    static var isFeedingInProgress: Bool { defaults.bool(forKey: "mc_isFeedingInProgress") }
    static var feedingStartTime: Date? { defaults.object(forKey: "mc_feedingStartTime") as? Date }
    static var feedingDetail: String? { defaults.string(forKey: "mc_feedingDetail") }
    static var todayFeedingCount: Int { defaults.integer(forKey: "mc_todayFeedingCount") }

    // MARK: - Nap

    static func updateNap(isInProgress: Bool, startTime: Date?) {
        defaults.set(isInProgress, forKey: "mc_isNapInProgress")
        defaults.set(startTime, forKey: "mc_napStartTime")
        reloadWidgets()
    }

    static var isNapInProgress: Bool { defaults.bool(forKey: "mc_isNapInProgress") }
    static var napStartTime: Date? { defaults.object(forKey: "mc_napStartTime") as? Date }

    // MARK: - Self-Care

    static func updateSelfCare(items: [SharedSelfCareItem]) {
        if let data = try? JSONEncoder().encode(items) {
            defaults.set(data, forKey: "mc_selfCareItems")
        }
        reloadWidgets()
    }

    static var selfCareItems: [SharedSelfCareItem] {
        guard let data = defaults.data(forKey: "mc_selfCareItems") else { return [] }
        return (try? JSONDecoder().decode([SharedSelfCareItem].self, from: data)) ?? []
    }

    // MARK: - Vaccine

    static func updateVaccine(name: String?, ageMonths: Int?) {
        defaults.set(name, forKey: "mc_nextVaccineName")
        if let ageMonths {
            defaults.set(ageMonths, forKey: "mc_nextVaccineAgeMonths")
        } else {
            defaults.removeObject(forKey: "mc_nextVaccineAgeMonths")
        }
        reloadWidgets()
    }

    static var nextVaccineName: String? { defaults.string(forKey: "mc_nextVaccineName") }
    static var nextVaccineAgeMonths: Int? { defaults.object(forKey: "mc_nextVaccineAgeMonths") as? Int }

    // MARK: - Widget Reload

    static func reloadWidgets() {
        WidgetCenter.shared.reloadAllTimelines()
    }
}

struct SharedFeedingState: Sendable {
    let lastTime: Date?
    let lastType: String?
    let isInProgress: Bool
    let startTime: Date?
    let detail: String?
    let todayCount: Int
}

struct SharedSelfCareItem: Codable, Sendable {
    let name: String
    let icon: String
    let isDone: Bool
    let lastDoneDate: Date?
}
