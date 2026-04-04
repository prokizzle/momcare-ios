import Foundation
import UIKit
import UserNotifications

// MARK: - Protocol

/// Abstracts notification operations for testability.
protocol NotificationServiceProtocol: Sendable {
    func requestAuthorization() async -> Bool
    func authorizationStatus() async -> UNAuthorizationStatus
    func scheduleLocal(
        id: String,
        title: String,
        body: String,
        trigger: UNNotificationTrigger,
        categoryIdentifier: String?
    ) async throws
    func cancelPending(ids: [String])
    func cancelAll()
}

// MARK: - Notification Categories

enum NotificationCategory: String, CaseIterable {
    case feeding = "FEEDING"
    case selfCare = "SELFCARE"
    case weeklyRecap = "WEEKLY_RECAP"
}

enum NotificationAction: String {
    // Feeding
    case feedingLogNow = "FEEDING_LOG_NOW"
    case feedingSnooze = "FEEDING_SNOOZE"
    // Self-care
    case selfCareCheckIn = "SELFCARE_CHECK_IN"
    case selfCareDismiss = "SELFCARE_DISMISS"
}

// MARK: - Live Implementation

/// Centralized notification service. Handles authorization, category registration,
/// and local notification scheduling.
///
/// Thread-safe: `UNUserNotificationCenter` is internally thread-safe, so this
/// service does not need actor isolation. Methods are `async` for the
/// authorization and scheduling APIs that require it.
final class NotificationManager: NotificationServiceProtocol, @unchecked Sendable {

    static let shared = NotificationManager()

    private let center: UNUserNotificationCenter

    init(center: UNUserNotificationCenter = .current()) {
        self.center = center
    }

    // MARK: - Authorization

    func requestAuthorization() async -> Bool {
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
            if granted {
                await MainActor.run { UIApplication.shared.registerForRemoteNotifications() }
            }
            return granted
        } catch {
            return false
        }
    }

    func authorizationStatus() async -> UNAuthorizationStatus {
        await center.notificationSettings().authorizationStatus
    }

    // MARK: - Category Registration

    func registerCategories() {
        let feedingCategory = UNNotificationCategory(
            identifier: NotificationCategory.feeding.rawValue,
            actions: [
                UNNotificationAction(
                    identifier: NotificationAction.feedingLogNow.rawValue,
                    title: "Log Now",
                    options: .foreground
                ),
                UNNotificationAction(
                    identifier: NotificationAction.feedingSnooze.rawValue,
                    title: "Snooze 15 min",
                    options: []
                )
            ],
            intentIdentifiers: [],
            options: []
        )

        let selfCareCategory = UNNotificationCategory(
            identifier: NotificationCategory.selfCare.rawValue,
            actions: [
                UNNotificationAction(
                    identifier: NotificationAction.selfCareCheckIn.rawValue,
                    title: "Check In",
                    options: .foreground
                ),
                UNNotificationAction(
                    identifier: NotificationAction.selfCareDismiss.rawValue,
                    title: "Dismiss",
                    options: []
                )
            ],
            intentIdentifiers: [],
            options: []
        )

        let weeklyRecapCategory = UNNotificationCategory(
            identifier: NotificationCategory.weeklyRecap.rawValue,
            actions: [],
            intentIdentifiers: [],
            options: []
        )

        center.setNotificationCategories([
            feedingCategory,
            selfCareCategory,
            weeklyRecapCategory
        ])
    }

    // MARK: - Local Scheduling

    func scheduleLocal(
        id: String,
        title: String,
        body: String,
        trigger: UNNotificationTrigger,
        categoryIdentifier: String? = nil
    ) async throws {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        if let category = categoryIdentifier {
            content.categoryIdentifier = category
        }
        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
        try await center.add(request)
    }

    // MARK: - Cancellation

    func cancelPending(ids: [String]) {
        center.removePendingNotificationRequests(withIdentifiers: ids)
    }

    func cancelAll() {
        center.removeAllPendingNotificationRequests()
    }
}

// MARK: - Stub for Testing

final class StubNotificationManager: NotificationServiceProtocol, @unchecked Sendable {

    struct ScheduledEntry {
        let id: String
        let title: String
        let body: String
    }

    var grantAuthorization = true
    var stubbedStatus: UNAuthorizationStatus = .authorized
    var scheduledNotifications: [ScheduledEntry] = []

    func requestAuthorization() async -> Bool { grantAuthorization }
    func authorizationStatus() async -> UNAuthorizationStatus { stubbedStatus }

    func scheduleLocal(
        id: String,
        title: String,
        body: String,
        trigger: UNNotificationTrigger,
        categoryIdentifier: String?
    ) async throws {
        scheduledNotifications.append(ScheduledEntry(id: id, title: title, body: body))
    }

    func cancelPending(ids: [String]) {
        scheduledNotifications.removeAll { entry in ids.contains(entry.id) }
    }

    func cancelAll() {
        scheduledNotifications.removeAll()
    }
}
