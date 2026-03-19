import AppIntents
import SwiftData
import Foundation

/// Logs a diaper change in the background without opening the app.
///
/// Creates a short-lived `ModelContainer` pointing at the shared App Group
/// SQLite store and inserts a `DiaperModel` via the domain entity initializer.
/// Falls back to `SharedDataManager.selectedBabyId` for the baby identifier.
struct LogDiaperIntent: AppIntent {
    nonisolated(unsafe) static var title: LocalizedStringResource = "Log Diaper Change"
    nonisolated(unsafe) static var description = IntentDescription("Record a diaper change without opening MomCare.")
    nonisolated(unsafe) static var openAppWhenRun: Bool = false
    nonisolated(unsafe) static var isDiscoverable: Bool = true

    @Parameter(title: "Diaper Type", default: .wet)
    var diaperType: DiaperTypeOption

    static var parameterSummary: some ParameterSummary {
        Summary("Log \(\.$diaperType) diaper")
    }

    func perform() async throws -> some IntentResult & ProvidesDialog {
        guard let babyId = SharedDataManager.selectedBabyId else {
            return .result(dialog: "Please open MomCare and select a baby first.")
        }

        let domainType = Diaper.DiaperType(rawValue: diaperType.rawValue) ?? .wet
        let now = Date()
        let diaper = Diaper(
            id: UUID(),
            babyId: babyId,
            timestamp: now,
            type: domainType,
            stoolConsistency: nil,
            stoolColor: nil,
            hasRash: false,
            notes: nil,
            createdAt: now,
            updatedAt: now
        )

        let container = try IntentModelContainer.make()
        let context = ModelContext(container)
        context.insert(DiaperModel(from: diaper))
        try context.save()

        let baby = SharedDataManager.babyName
        return .result(dialog: "Logged a \(diaperType.rawValue) diaper for \(baby).")
    }
}
