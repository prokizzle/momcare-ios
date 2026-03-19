import ActivityKit
import AppIntents

/// Ends a running Live Activity and updates shared state so the main app can
/// finalise the timer record in the database on its next launch.
///
/// Using `AppIntent` instead of a URL `Link` means the action executes in the
/// background without foregrounding the app — appropriate for lock-screen and
/// Dynamic Island interaction.
struct EndActivityIntent: AppIntent {
    static var title: LocalizedStringResource = "End Activity"
    static var isDiscoverable: Bool = false

    @Parameter(title: "Activity Type")
    var activityType: String

    init() { activityType = "feeding" }

    init(activityType: String) {
        self.activityType = activityType
    }

    func perform() async throws -> some IntentResult {
        for activity in Activity<InProgressActivityAttributes>.activities
            where activity.attributes.activityType == activityType {
            await activity.end(
                ActivityContent(state: activity.content.state, staleDate: nil),
                dismissalPolicy: .immediate
            )
        }
        SharedDataManager.markActivityEnded(type: activityType)
        return .result()
    }
}
