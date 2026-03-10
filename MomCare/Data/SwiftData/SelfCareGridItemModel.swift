import Foundation
import SwiftData

@Model
final class SelfCareGridItemModel {
    @Attribute(.unique) var id: UUID
    var actionTypeRaw: String
    var isVisible: Bool
    var sortOrder: Int
    var isCustom: Bool
    var customName: String?
    var customIcon: String?

    init(from entity: SelfCareGridItem) {
        self.id = entity.id
        self.actionTypeRaw = entity.actionType.rawValue
        self.isVisible = entity.isVisible
        self.sortOrder = entity.sortOrder
        self.isCustom = entity.isCustom
        self.customName = entity.customName
        self.customIcon = entity.customIcon
    }

    func toEntity() -> SelfCareGridItem {
        SelfCareGridItem(
            id: id,
            actionType: SelfCareActionType(rawValue: actionTypeRaw) ?? .water,
            isVisible: isVisible,
            sortOrder: sortOrder,
            isCustom: isCustom,
            customName: customName,
            customIcon: customIcon
        )
    }

    func update(from entity: SelfCareGridItem) {
        self.actionTypeRaw = entity.actionType.rawValue
        self.isVisible = entity.isVisible
        self.sortOrder = entity.sortOrder
        self.isCustom = entity.isCustom
        self.customName = entity.customName
        self.customIcon = entity.customIcon
    }
}
