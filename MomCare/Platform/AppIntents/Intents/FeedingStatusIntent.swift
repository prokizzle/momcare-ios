import AppIntents

/// Returns the current feeding status without opening the app.
///
/// Reads from `SharedDataManager` (App Group UserDefaults) so there is no
/// SwiftData I/O and the intent completes almost instantly.
struct FeedingStatusIntent: AppIntent {
    nonisolated(unsafe) static var title: LocalizedStringResource = "Get Feeding Status"
    nonisolated(unsafe) static var description = IntentDescription("Check whether a feeding is in progress.")
    nonisolated(unsafe) static var openAppWhenRun: Bool = false
    nonisolated(unsafe) static var isDiscoverable: Bool = true

    func perform() async throws -> some IntentResult & ProvidesDialog {
        let baby = SharedDataManager.babyName
        if SharedDataManager.isFeedingInProgress {
            let detail = SharedDataManager.feedingDetail ?? ""
            return .result(
                dialog: "\(baby) is currently feeding\(detail.isEmpty ? "" : " — \(detail)")."
            )
        }
        let count = SharedDataManager.todayFeedingCount
        return .result(
            dialog: "\(baby) has had \(count) feeding\(count == 1 ? "" : "s") today."
        )
    }
}
