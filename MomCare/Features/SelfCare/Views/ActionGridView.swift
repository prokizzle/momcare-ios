import SwiftUI

struct ActionGridView: View {
    let gridItems: [SelfCareGridItem]
    let recentlyTapped: (SelfCareActionType) -> Bool
    let waterCount: Int
    let onTap: (SelfCareActionType) -> Void
    let onLongPress: (SelfCareActionType) -> Void

    private let columns = Array(repeating: GridItem(.flexible(), spacing: MCSpacing.sm), count: 3)

    var body: some View {
        LazyVGrid(columns: columns, spacing: MCSpacing.sm) {
            ForEach(gridItems) { item in
                ActionGridItemView(
                    item: item,
                    isRecentlyTapped: recentlyTapped(item.actionType),
                    waterCount: item.actionType == .water ? waterCount : nil,
                    onTap: { onTap(item.actionType) },
                    onLongPress: { onLongPress(item.actionType) }
                )
            }
        }
        .padding(.horizontal, MCSpacing.lg)
    }
}
