import AppIntents
import SwiftData
import Foundation

/// Logs a water intake self-care event in the background without opening the app.
struct LogWaterIntent: AppIntent {
    nonisolated(unsafe) static var title: LocalizedStringResource = "Log Water"
    nonisolated(unsafe) static var description = IntentDescription("Record drinking water without opening MomCare.")
    nonisolated(unsafe) static var openAppWhenRun: Bool = false
    nonisolated(unsafe) static var isDiscoverable: Bool = true

    func perform() async throws -> some IntentResult & ProvidesDialog {
        let now = Date()
        let entry = SelfCareLog(
            id: UUID(),
            actionType: .water,
            timestamp: now,
            detail: .water(glasses: 1),
            createdAt: now,
            updatedAt: now
        )

        let container = try IntentModelContainer.make()
        let context = ModelContext(container)
        context.insert(SelfCareLogModel(from: entry))
        try context.save()

        return .result(dialog: "Water logged. Stay hydrated!")
    }
}
