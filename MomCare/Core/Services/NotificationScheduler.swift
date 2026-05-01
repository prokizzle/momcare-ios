import Foundation
import OSLog
import UserNotifications

private extension Logger {
    static let notifications = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "com.feelingmindful.momcare",
        category: "Notifications"
    )
}

/// Schedules MomCare-specific local notifications (feeding reminders,
/// hydration nudges, self-care check-ins, weekly recaps).
///
/// All scheduling goes through `NotificationServiceProtocol` so tests can
/// verify scheduling logic without touching `UNUserNotificationCenter`.
struct NotificationScheduler: Sendable {

    private let service: any NotificationServiceProtocol

    init(service: any NotificationServiceProtocol = NotificationManager.shared) {
        self.service = service
    }

    // MARK: - Feeding Reminders

    /// Schedules a one-shot feeding reminder after a given interval.
    ///
    /// - Parameters:
    ///   - babyId: The baby's unique identifier for the notification ID.
    ///   - babyName: The baby's name for the notification body.
    ///   - interval: Seconds until the reminder fires (e.g., 3 hours = 10800).
    func scheduleFeedingReminder(babyId: UUID, babyName: String, afterSeconds interval: TimeInterval) async throws {
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: interval, repeats: false)
        try await service.scheduleLocal(
            id: "feeding-reminder-\(babyId.uuidString)",
            title: "Feeding reminder",
            body: "It has been a while since \(babyName)'s last feeding.",
            trigger: trigger,
            categoryIdentifier: NotificationCategory.feeding.rawValue
        )
    }

    /// Cancels any pending feeding reminder for the given baby.
    func cancelFeedingReminder(babyId: UUID) {
        service.cancelPending(ids: ["feeding-reminder-\(babyId.uuidString)"])
    }

    // MARK: - Hydration Nudges

    /// Schedules a daily hydration reminder at the given hour.
    ///
    /// - Parameter hour: Hour of day (0-23) to fire. Defaults to 10 AM.
    func scheduleHydrationNudge(hour: Int = 10) async throws {
        let trigger = UNCalendarNotificationTrigger(
            dateMatching: DateComponents(hour: hour, minute: 0),
            repeats: true
        )
        try await service.scheduleLocal(
            id: "hydration-daily",
            title: "A small hydration moment",
            body: "Staying hydrated helps you keep going. A sip goes a long way.",
            trigger: trigger,
            categoryIdentifier: NotificationCategory.selfCare.rawValue
        )
    }

    // MARK: - Self-Care Check-Ins

    /// Schedules a daily self-care check-in at the given hour.
    ///
    /// - Parameter hour: Hour of day (0-23) to fire. Defaults to 8 PM.
    func scheduleSelfCareCheckIn(hour: Int = 20) async throws {
        let trigger = UNCalendarNotificationTrigger(
            dateMatching: DateComponents(hour: hour, minute: 0),
            repeats: true
        )
        try await service.scheduleLocal(
            id: "selfcare-daily",
            title: "A quiet check-in",
            body: "How are you feeling tonight? You showed up today, and that is enough.",
            trigger: trigger,
            categoryIdentifier: NotificationCategory.selfCare.rawValue
        )
    }

    // MARK: - Weekly Recap

    /// Schedules a weekly recap notification on Sundays at the given hour.
    ///
    /// - Parameter hour: Hour of day (0-23) to fire. Defaults to 9 AM.
    func scheduleWeeklyRecap(hour: Int = 9) async throws {
        let trigger = UNCalendarNotificationTrigger(
            dateMatching: DateComponents(hour: hour, minute: 0, weekday: 1),
            repeats: true
        )
        try await service.scheduleLocal(
            id: "weekly-recap",
            title: "Your week in review",
            body: "Your week is ready. Feeding patterns, sleep trends, and small acts of care.",
            trigger: trigger,
            categoryIdentifier: NotificationCategory.weeklyRecap.rawValue
        )
    }

    // MARK: - Bulk Operations

    /// Cancels all MomCare-scheduled notifications.
    func cancelAll() {
        service.cancelAll()
    }

    /// Sets up the default notification schedule for a new user.
    func setupDefaults() async {
        do {
            try await scheduleHydrationNudge()
        } catch {
            Logger.notifications.error("Failed to schedule hydration nudge: \(error)")
        }
        do {
            try await scheduleSelfCareCheckIn()
        } catch {
            Logger.notifications.error("Failed to schedule self-care check-in: \(error)")
        }
        do {
            try await scheduleWeeklyRecap()
        } catch {
            Logger.notifications.error("Failed to schedule weekly recap: \(error)")
        }
    }
}
