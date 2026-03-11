import SwiftUI

@MainActor
struct BabyScreen: View {
    let babyId: UUID?

    var body: some View {
        ScrollView {
            if let babyId {
                BabyCardGrid(babyId: babyId)
                    .padding(.horizontal, MCSpacing.lg)
                    .padding(.vertical, MCSpacing.lg)
            } else {
                Text("Select a baby to get started")
                    .foregroundStyle(.secondary)
                    .padding(.top, MCSpacing.xl)
            }
        }
        .navigationTitle("Baby")
    }
}

@MainActor
private struct BabyCardGrid: View {
    let babyId: UUID
    private let columns = [
        GridItem(.flexible(), spacing: MCSpacing.sm),
        GridItem(.flexible(), spacing: MCSpacing.sm),
        GridItem(.flexible(), spacing: MCSpacing.sm)
    ]

    var body: some View {
        LazyVGrid(columns: columns, spacing: MCSpacing.sm) {
            BabyActionCard(cardType: .nap, babyId: babyId)
            BabyActionCard(cardType: .feeding, babyId: babyId)
            BabyActionCard(cardType: .diaper, babyId: babyId)
        }
    }
}
