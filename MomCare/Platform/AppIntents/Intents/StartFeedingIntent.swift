import AppIntents

/// Starts a feeding session via Siri or Shortcuts.
///
/// Because starting a feeding involves the Live Activity, timer orchestration,
/// and `BabyActivityEngine`, this intent writes the request to `SharedDataManager`
/// and then foregrounds the app to complete it. The app's init task reads
/// `pendingStartFeedingType` and calls the engine.
struct StartFeedingIntent: AppIntent {
    nonisolated(unsafe) static var title: LocalizedStringResource = "Start Feeding"
    nonisolated(unsafe) static var description = IntentDescription("Start a feeding session for your baby.")
    nonisolated(unsafe) static var openAppWhenRun: Bool = true
    nonisolated(unsafe) static var isDiscoverable: Bool = true

    @Parameter(title: "Feeding Type", default: .breast)
    var feedingType: FeedingTypeOption

    static var parameterSummary: some ParameterSummary {
        Summary("Start \(\.$feedingType) feeding")
    }

    func perform() async throws -> some IntentResult {
        SharedDataManager.markFeedingPendingStart(type: feedingType.rawValue)
        return .result()
    }
}
