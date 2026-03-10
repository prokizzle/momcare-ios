import Foundation

struct SelfCareGridItem: Identifiable, Codable, Sendable, Equatable {
    var id: UUID
    var actionType: SelfCareActionType
    var isVisible: Bool
    var sortOrder: Int
    var isCustom: Bool
    var customName: String?
    var customIcon: String?

    var displayName: String {
        customName ?? actionType.label
    }

    var displayIcon: String {
        customIcon ?? actionType.systemImage
    }
}

extension SelfCareGridItem {
    static func defaultGrid() -> [SelfCareGridItem] {
        let defaultOrder: [SelfCareActionType] = [
            .water, .meal, .brushTeeth,
            .shower, .skincare, .changeClothes,
            .meditate, .breathingExercise, .shave
        ]
        return defaultOrder.enumerated().map { index, actionType in
            SelfCareGridItem(
                id: UUID(),
                actionType: actionType,
                isVisible: true,
                sortOrder: index,
                isCustom: false
            )
        }
    }

    static func fixture(
        id: UUID = UUID(),
        actionType: SelfCareActionType = .water,
        isVisible: Bool = true,
        sortOrder: Int = 0,
        isCustom: Bool = false,
        customName: String? = nil,
        customIcon: String? = nil
    ) -> SelfCareGridItem {
        SelfCareGridItem(
            id: id,
            actionType: actionType,
            isVisible: isVisible,
            sortOrder: sortOrder,
            isCustom: isCustom,
            customName: customName,
            customIcon: customIcon
        )
    }
}
