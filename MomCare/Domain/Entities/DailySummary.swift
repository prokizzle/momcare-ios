import Foundation

struct DailySummary: Sendable, Equatable {
    let completedActionTypes: Set<SelfCareActionType>
    let waterGlassesToday: Int
    let mealsToday: Int
    let visibleActionCount: Int

    var completionPercentage: Double {
        guard visibleActionCount > 0 else { return 0 }
        let completed = Double(completedActionTypes.count)
        return min(completed / Double(visibleActionCount), 1.0)
    }

    var totalActionsToday: Int {
        completedActionTypes.count
    }
}

extension DailySummary {
    static let empty = DailySummary(
        completedActionTypes: [],
        waterGlassesToday: 0,
        mealsToday: 0,
        visibleActionCount: 9
    )

    static func fixture(
        completedActionTypes: Set<SelfCareActionType> = [.water, .meal, .shower],
        waterGlassesToday: Int = 4,
        mealsToday: Int = 2,
        visibleActionCount: Int = 9
    ) -> DailySummary {
        DailySummary(
            completedActionTypes: completedActionTypes,
            waterGlassesToday: waterGlassesToday,
            mealsToday: mealsToday,
            visibleActionCount: visibleActionCount
        )
    }
}
