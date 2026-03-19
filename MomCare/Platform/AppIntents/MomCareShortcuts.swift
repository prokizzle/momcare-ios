import AppIntents

/// Registers pre-built App Shortcuts so users can invoke MomCare actions
/// via Siri without any setup — just say the phrase.
struct MomCareShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: StartFeedingIntent(),
            phrases: [
                "Start feeding in \(.applicationName)",
                "Log feeding in \(.applicationName)",
                "Begin \(\.$feedingType) feeding in \(.applicationName)"
            ],
            shortTitle: "Start Feeding",
            systemImageName: "drop.fill"
        )

        AppShortcut(
            intent: FeedingStatusIntent(),
            phrases: [
                "How is feeding going in \(.applicationName)",
                "Check feeding in \(.applicationName)",
                "Feeding status in \(.applicationName)"
            ],
            shortTitle: "Feeding Status",
            systemImageName: "chart.bar.fill"
        )

        AppShortcut(
            intent: LogDiaperIntent(),
            phrases: [
                "Log diaper in \(.applicationName)",
                "Diaper change in \(.applicationName)",
                "Log \(\.$diaperType) diaper in \(.applicationName)"
            ],
            shortTitle: "Log Diaper",
            systemImageName: "drop.triangle.fill"
        )

        AppShortcut(
            intent: LogWaterIntent(),
            phrases: [
                "Log water in \(.applicationName)",
                "I drank water in \(.applicationName)",
                "Record water in \(.applicationName)"
            ],
            shortTitle: "Log Water",
            systemImageName: "cup.and.saucer.fill"
        )
    }
}
