import Testing
import Foundation
@testable import MomCare

@Suite("NotificationScheduler")
struct NotificationSchedulerTests {

    private let stub = StubNotificationManager()

    // MARK: - Feeding Reminders

    @Test("scheduleFeedingReminder schedules with correct ID and category")
    func scheduleFeedingReminder() async throws {
        let scheduler = NotificationScheduler(service: stub)
        let babyId = UUID()

        try await scheduler.scheduleFeedingReminder(
            babyId: babyId,
            babyName: "Luna",
            afterSeconds: 10800
        )

        #expect(stub.scheduledNotifications.count == 1)
        let entry = try #require(stub.scheduledNotifications.first)
        #expect(entry.id == "feeding-reminder-\(babyId.uuidString)")
        #expect(entry.title == "Feeding Reminder")
        #expect(entry.categoryIdentifier == NotificationCategory.feeding.rawValue)
    }

    @Test("cancelFeedingReminder cancels the correct ID")
    func cancelFeedingReminder() async throws {
        let scheduler = NotificationScheduler(service: stub)
        let babyId = UUID()

        try await scheduler.scheduleFeedingReminder(
            babyId: babyId,
            babyName: "Luna",
            afterSeconds: 3600
        )
        #expect(stub.scheduledNotifications.count == 1)

        scheduler.cancelFeedingReminder(babyId: babyId)
        #expect(stub.scheduledNotifications.isEmpty)
    }

    // MARK: - Hydration Nudges

    @Test("scheduleHydrationNudge schedules a daily repeating notification")
    func scheduleHydrationNudge() async throws {
        let scheduler = NotificationScheduler(service: stub)

        try await scheduler.scheduleHydrationNudge(hour: 10)

        #expect(stub.scheduledNotifications.count == 1)
        let entry = try #require(stub.scheduledNotifications.first)
        #expect(entry.id == "hydration-daily")
        #expect(entry.title == "Stay Hydrated")
        #expect(entry.categoryIdentifier == NotificationCategory.selfCare.rawValue)
    }

    // MARK: - Setup Defaults

    @Test("setupDefaults schedules 3 notifications")
    func setupDefaults() async {
        let scheduler = NotificationScheduler(service: stub)

        await scheduler.setupDefaults()

        #expect(stub.scheduledNotifications.count == 3)

        let ids = Set(stub.scheduledNotifications.map(\.id))
        #expect(ids.contains("hydration-daily"))
        #expect(ids.contains("selfcare-daily"))
        #expect(ids.contains("weekly-recap"))
    }
}
